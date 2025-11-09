import os, json, asyncio, httpx
from typing import Any, Dict, Optional
from dotenv import load_dotenv
from dedalus_labs import AsyncDedalus, DedalusRunner

load_dotenv()

DEDALUS_MODEL = os.getenv("DEDALUS_MODEL", "openai/gpt-5-mini")
PUBLIC_BACKEND_URL = os.getenv("PUBLIC_BACKEND_URL", "http://localhost:8080")

def _b(): return PUBLIC_BACKEND_URL.rstrip("/")
def _h(tok: str) -> Dict[str,str]:
    return {"Authorization": f"Bearer {tok}", "Content-Type":"application/json"}

# ---------- SYNC HTTP HELPERS (use these inside tools) ----------
def _post_sync(path: str, body: Dict[str,Any], tok: str):
    with httpx.Client(timeout=15) as c:
        r = c.post(f"{_b()}{path}", headers=_h(tok), json=body)
        r.raise_for_status()
        return r.json()

def _get_sync(path: str, params: Dict[str,Any] | None, tok: str):
    with httpx.Client(timeout=15) as c:
        r = c.get(f"{_b()}{path}", headers=_h(tok), params=params or {})
        r.raise_for_status()
        return r.json()

def make_tools(user_token: str):
    # ---------- SYNC TOOL FUNCTIONS (Dedalus requires plain callables) ----------
    def analytics_summary(range: str = "7d"):
        return _get_sync("/analytics/summary", {"range": range}, user_token)

    def analytics_by_category(range: str = "7d"):
        return _get_sync("/analytics/by-category", {"range": range}, user_token)

    def analytics_rules_progress():
        return _get_sync("/analytics/rules-progress", {}, user_token)

    def rules_upsert(rule_type: str,
                     category: Optional[str] = None,
                     monthly_limit_cents: Optional[int] = None,
                     merchant: Optional[str] = None,
                     **_):
        if rule_type == "block":
            if not category:
                return {"error":"category required for block rule"}
            return _post_sync("/rules", {
                "category": category.strip().lower(),
                "monthly_limit_cents": 0
            }, user_token)

        if not category or monthly_limit_cents is None or int(monthly_limit_cents) <= 0:
            return {"error":"category and positive monthly_limit_cents required"}
        return _post_sync("/rules", {
            "category": category.strip().lower(),
            "monthly_limit_cents": int(monthly_limit_cents)
        }, user_token)

    def guardian_authorize(amount_cents: int, merchant: str, category: Optional[str] = None):
        body: Dict[str, Any] = {"amount_cents": int(amount_cents), "merchant": merchant}
        if category: body["category"] = category
        return _post_sync("/guardian/authorize", body, user_token)

    def guardian_charge(amount_cents: int, funding_source_id: int, currency: str="usd"):
        return _post_sync("/guardian/charge", {
            "amount_cents": int(amount_cents),
            "funding_source_id": int(funding_source_id),
            "currency": currency
        }, user_token)

    # MUST be a list of plain (sync) callables
    return [
        analytics_summary,
        analytics_by_category,
        analytics_rules_progress,
        rules_upsert,
        guardian_authorize,
        guardian_charge,
    ]

AGENT_POLICY = """
You are Guardian. ALWAYS return JSON: {"result": "...", "message": "..."}.

INPUT: amount_cents, merchant, category, funding_source_id (optional), user_id.

SEQUENCE
1) CATEGORY NORMALIZATION:
   If category is missing:
     - If merchant has any of ["loot","gacha","crate","pack","pulls","card pack"] => category="lootboxes"
     - If merchant has any of ["casino","bet","sportsbook","wager"] => category="gambling"

2) RISK CHECKS (use only existing tools):
   - c7 = analytics_by_category("7d")
   - c90 = analytics_by_category("90d")
   - rp = analytics_rules_progress()
   - Let spend_7d and count_7d be the row in c7 with this category (default 0).
   - Let spend_90d be the row in c90 with this category (default 0).
   - baseline_weekly = max(1, spend_90d / 13)
   - growth = spend_7d / baseline_weekly
   - From rp, find matching category rule; get utilization (default None), remaining_cents (default None).
   - RISKY if any:
       a) category in {"lootboxes","gambling"}
       b) utilization >= 0.8 or remaining_cents == 0
       c) growth >= 2.0 and spend_7d >= 2000
       d) amount_cents > max(3000, 2 * (spend_7d / max(1, count_7d)))
   If category in {"lootboxes","gambling"}:
       rules_upsert(rule_type="block", category=category)
   Else:
       rules_upsert(rule_type="budget", category=category, monthly_limit_cents=20000)

3) AUTHORIZE:
   auth = guardian_authorize(amount_cents, merchant, category)

4) BRANCH:
   - If auth.decision == "DECLINE":
       Return {"result":"DECLINED","message":"BLOCKED: " + (auth.reason or "policy")}
   - If auth.decision == "APPROVE":
           ch = guardian_charge(amount_cents, funding_source_id)
           Return {"result":"APPROVED","message":"Approved and charged successfully with processor_status=" + (ch.processor_status or "succeeded")}

HARD RULES:
- Never charge if authorization is DECLINED.
- Output ONLY {"result","message"}.
"""

async def _run_agent_async(user_token: str, context: Dict[str,Any]) -> Dict[str,Any]:
    client = AsyncDedalus()
    runner = DedalusRunner(client)
    tools = make_tools(user_token)

    # Extra guard for Dedalus’ requirements
    if not isinstance(tools, (list, tuple)) or not all(callable(t) for t in tools):
        raise TypeError("tools must be a list of callable functions or None")

    result = await runner.run(
        model=DEDALUS_MODEL,
        tools=tools,
        instructions=AGENT_POLICY,
        input=json.dumps(context),
        stream=False
    )

    final_output = getattr(result, "final_output", None) or getattr(result, "output", None)
    if isinstance(final_output, str):
        try:
            final_output = json.loads(final_output)
        except Exception:
            pass

    return {
        "final_output": final_output,
        "tool_calls": getattr(result, "tool_calls", None),
        "raw": result.__dict__ if hasattr(result, "__dict__") else str(result),
    }

def run_guardian_agent(user_token: str, context: Dict[str,Any]) -> Dict[str,Any]:
    return asyncio.run(_run_agent_async(user_token, context))
