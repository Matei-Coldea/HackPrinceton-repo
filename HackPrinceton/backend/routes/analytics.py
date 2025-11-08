# routes/analytics.py
from flask import Blueprint, request, jsonify
from sqlalchemy import func, case
from datetime import datetime, timedelta, timezone
from models import db, Transaction, GuardianRule
from routes import get_current_user_id
from typing import Optional
from datetime import datetime, timedelta, timezone
from sqlalchemy import func
from flask import request, jsonify
from models import db, Transaction, GuardianRule
from routes import get_current_user_id

analytics_bp = Blueprint("analytics", __name__)

def _range_bounds(range_str: str):
    now = datetime.now(timezone.utc)
    r = (range_str or "30d").lower()
    if r == "7d":   start = now - timedelta(days=7)
    elif r == "mtd":
        start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    elif r == "90d": start = now - timedelta(days=90)
    else:            start = now - timedelta(days=30)  # default 30d
    return start, now

# routes/analytics.py (append this)

RISK_KEYWORDS = {"lootbox", "loot box", "gacha", "casino", "slots", "crates"}

def _normalize_category(cat: Optional[str]) -> Optional[str]:
    if not cat:
        return None
    c = cat.strip().lower()
    return c or None

@analytics_bp.post("/analytics/assess-purchase")
def analytics_assess_purchase():
    """
    Input JSON:
      {
        "amount_cents": int,
        "merchant": "string",
        "category": "string | null"
      }

    Output JSON (agent-friendly):
      {
        "input": {...},
        "existing_rule": { "category": "...", "monthly_limit_cents": 20000 } | null,
        "metrics": {
          "spent_mtd_cents": 12345,
          "spent_7d_cents": 6789,
          "count_7d": 5,
          "limit_cents": 20000 | null,
          "remaining_cents": 123 | null
        },
        "assessment": {
          "should_block": true|false,
          "block_reason": "exceeds_limit" | "large_fraction" | "none",
          "should_create_rule": true|false,
          "suggested_rule": { "category": "...", "monthly_limit_cents": 20000 } | null,
          "rationale": "short human-readable reason"
        }
      }
    """
    uid = get_current_user_id()
    body = request.get_json(force=True)
    amount = int(body.get("amount_cents", 0))
    merchant = (body.get("merchant") or "").strip()
    category_raw = body.get("category")
    category = _normalize_category(category_raw)

    if amount <= 0 or not merchant:
        return jsonify({"error": "amount_cents > 0 and merchant are required"}), 400

    # Time windows
    now = datetime.now(timezone.utc)
    start_7d = now - timedelta(days=7)
    start_mtd = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)

    # Existing rule (if any)
    rule = None
    if category:
        rule = GuardianRule.query.filter_by(user_id=uid, category=category).first()

    # Spend MTD for this category (charges only, succeeded)
    spent_mtd = (db.session.query(func.coalesce(func.sum(Transaction.amount_cents), 0))
                 .filter(
                     Transaction.user_id == uid,
                     Transaction.event_type == "charge",
                     Transaction.processor_status == "succeeded",
                     Transaction.category == category,
                     Transaction.ts >= start_mtd, Transaction.ts < now
                 ).scalar() or 0)

    # Spend & count in last 7d for this category
    q_7d = (db.session.query(
                func.coalesce(func.sum(Transaction.amount_cents), 0),
                func.count()
            ).filter(
                Transaction.user_id == uid,
                Transaction.event_type == "charge",
                Transaction.processor_status == "succeeded",
                Transaction.category == category,
                Transaction.ts >= start_7d, Transaction.ts < now
            ))
    spent_7d, count_7d = q_7d.first() or (0, 0)
    spent_7d = int(spent_7d or 0)
    count_7d = int(count_7d or 0)

    # Heuristics
    should_block = False
    block_reason = "none"
    should_create_rule = False
    suggested_rule = None
    rationale_bits = []

    # 1) If a rule exists: block if it would exceed remaining or is a large fraction of limit
    limit = rule.monthly_limit_cents if rule else None
    remaining = None
    if rule and rule.monthly_limit_cents:
        limit = int(rule.monthly_limit_cents)
        remaining = max(0, limit - spent_mtd)
        if amount > remaining:
            should_block = True
            block_reason = "exceeds_limit"
            rationale_bits.append(f"amount ({amount}¢) exceeds remaining ({remaining}¢) for category '{category}'.")
        elif amount > (limit // 2):
            should_block = True
            block_reason = "large_fraction"
            rationale_bits.append(f"amount ({amount}¢) exceeds 50% of limit ({limit}¢) for category '{category}'.")

    # 2) If NO rule exists: suggest creating one if category looks risky
    if not rule:
        cat_flag = category in {"fun", "entertainment", "games"}
        risky_name_hit = any(k in merchant.lower() for k in RISK_KEYWORDS)
        # simple spend signal: >= $50 in last 7d for this category OR flagged names OR large single purchase
        looks_risky = (spent_7d >= 5000) or risky_name_hit or (amount >= 5000) or cat_flag
        if looks_risky and category:
            # Suggest a sensible demo default ($200) but not lower than recent 7d spend rounded up
            base = 20000
            bump = int(max(base, (spent_7d * 2)))  # give some headroom
            suggested_rule = {"category": category, "monthly_limit_cents": bump}
            should_create_rule = True
            rationale_bits.append(
                f"no existing rule; recent 7d spend {spent_7d}¢ and merchant/category pattern suggests risk — propose {bump}¢ monthly cap."
            )

    # 3) Extra nudge for ‘lootbox’/gacha merchants even if rule exists (only affects rationale)
    if any(k in merchant.lower() for k in RISK_KEYWORDS):
        rationale_bits.append("merchant matches high-risk keywords (lootbox/gacha/casino).")

    # Assemble response
    resp = {
        "input": {
            "amount_cents": amount,
            "merchant": merchant,
            "category": category or "uncategorized"
        },
        "existing_rule": (
            {"category": rule.category, "monthly_limit_cents": int(rule.monthly_limit_cents)}
            if rule and rule.monthly_limit_cents is not None else
            ({"category": rule.category, "monthly_limit_cents": None} if rule else None)
        ),
        "metrics": {
            "spent_mtd_cents": int(spent_mtd),
            "spent_7d_cents": int(spent_7d),
            "count_7d": int(count_7d),
            "limit_cents": int(limit) if limit is not None else None,
            "remaining_cents": int(remaining) if remaining is not None else None
        },
        "assessment": {
            "should_block": bool(should_block),
            "block_reason": block_reason,
            "should_create_rule": bool(should_create_rule),
            "suggested_rule": suggested_rule,
            "rationale": " ".join(rationale_bits) if rationale_bits else "no strong risk signals"
        }
    }
    return jsonify(resp)


# 1) Summary: totals, counts, risky/override rates (last 30d by default)
@analytics_bp.get("/analytics/summary")
def analytics_summary():
    uid = get_current_user_id()
    start, end = _range_bounds(request.args.get("range"))

    # Charges only for spend
    q_charges = (db.session.query(
        func.coalesce(func.sum(Transaction.amount_cents), 0),
        func.count()
    ).filter(
        Transaction.user_id == uid,
        Transaction.event_type == "charge",
        Transaction.ts >= start, Transaction.ts < end,
        Transaction.processor_status == "succeeded"
    ))

    spend_cents, charge_count = q_charges.first()

    # Authorize/decline rates
    q_auth = (db.session.query(
        func.count().label("total"),
        func.sum(case((Transaction.reason=="risky", 1), else_=0)).label("risky_count"),
        func.sum(case((Transaction.reason=="override",1), else_=0)).label("override_count")
    ).filter(
        Transaction.user_id == uid,
        Transaction.event_type.in_(["authorize","decline"]),
        Transaction.ts >= start, Transaction.ts < end
    ))
    total_auth, risky_ct, override_ct = q_auth.first() or (0,0,0)

    return jsonify({
        "range": {"start": start.isoformat(), "end": end.isoformat()},
        "spend_cents": int(spend_cents or 0),
        "charge_count": int(charge_count or 0),
        "auth_events": int(total_auth or 0),
        "risky_rate": (risky_ct / total_auth) if total_auth else 0.0,
        "override_rate": (override_ct / total_auth) if total_auth else 0.0,
    })

# 2) Spend by category
@analytics_bp.get("/analytics/by-category")
def analytics_by_category():
    uid = get_current_user_id()
    start, end = _range_bounds(request.args.get("range"))

    rows = (db.session.query(
        Transaction.category,
        func.coalesce(func.sum(Transaction.amount_cents), 0).label("spend_cents"),
        func.count().label("count")
    ).filter(
        Transaction.user_id == uid,
        Transaction.event_type == "charge",
        Transaction.processor_status == "succeeded",
        Transaction.ts >= start, Transaction.ts < end
    ).group_by(Transaction.category)
     .order_by(func.coalesce(func.sum(Transaction.amount_cents), 0).desc())
    ).all()

    return jsonify([
        {"category": c or "uncategorized", "spend_cents": int(s), "count": int(n)}
        for c, s, n in rows
    ])

# 3) Time series spend (daily)
@analytics_bp.get("/analytics/timeseries")
def analytics_timeseries():
    uid = get_current_user_id()
    start, end = _range_bounds(request.args.get("range"))

    # Postgres date_trunc
    date_trunc = func.date_trunc('day', Transaction.ts)
    rows = (db.session.query(
        date_trunc.label("day"),
        func.coalesce(func.sum(Transaction.amount_cents), 0).label("spend_cents")
    ).filter(
        Transaction.user_id == uid,
        Transaction.event_type == "charge",
        Transaction.processor_status == "succeeded",
        Transaction.ts >= start, Transaction.ts < end
    ).group_by(date_trunc).order_by(date_trunc)).all()

    return jsonify([
        {"day": d.isoformat(), "spend_cents": int(s)} for d, s in rows
    ])

# 4) Top merchants
@analytics_bp.get("/analytics/merchants")
def analytics_merchants():
    uid = get_current_user_id()
    start, end = _range_bounds(request.args.get("range"))
    rows = (db.session.query(
        Transaction.merchant,
        func.coalesce(func.sum(Transaction.amount_cents), 0).label("spend_cents"),
        func.count().label("count")
    ).filter(
        Transaction.user_id == uid,
        Transaction.event_type == "charge",
        Transaction.processor_status == "succeeded",
        Transaction.ts >= start, Transaction.ts < end
    ).group_by(Transaction.merchant)
     .order_by(func.coalesce(func.sum(Transaction.amount_cents), 0).desc())
     .limit(10)).all()

    return jsonify([
        {"merchant": m or "unknown", "spend_cents": int(s), "count": int(n)} for m, s, n in rows
    ])

# 5) Rule progress (MTD): remaining vs limit per category
@analytics_bp.get("/analytics/rules-progress")
def analytics_rules_progress():
    uid = get_current_user_id()
    # month start
    now = datetime.utcnow()
    start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)

    rules = GuardianRule.query.filter_by(user_id=uid).all()
    out = []
    for r in rules:
        spent = (db.session.query(func.coalesce(func.sum(Transaction.amount_cents), 0))
                 .filter(
                     Transaction.user_id == uid,
                     Transaction.event_type == "charge",
                     Transaction.processor_status == "succeeded",
                     Transaction.category == r.category,
                     Transaction.ts >= start
                 ).scalar() or 0)
        limit = r.monthly_limit_cents or 0
        out.append({
            "category": r.category,
            "limit_cents": int(limit),
            "spent_mtd_cents": int(spent),
            "remaining_cents": int(max(0, (limit - spent))) if limit else None,
            "utilization": (spent/limit) if limit else None
        })
    return jsonify(out)

# 6) Recent overrides
@analytics_bp.get("/analytics/overrides")
def analytics_overrides():
    uid = get_current_user_id()
    start, end = _range_bounds(request.args.get("range"))
    rows = (db.session.query(Transaction)
            .filter(
                Transaction.user_id == uid,
                Transaction.event_type == "override",
                Transaction.ts >= start, Transaction.ts < end
            ).order_by(Transaction.ts.desc()).limit(50).all())
    return jsonify([
        {
            "ts": t.ts.isoformat(),
            "merchant": t.merchant,
            "amount_cents": t.amount_cents
        } for t in rows
    ])
