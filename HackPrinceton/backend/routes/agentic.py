# routes/agentic.py
from flask import Blueprint, request, jsonify
from routes import get_current_user_id
from services.agent import run_guardian_agent

agentic_bp = Blueprint("agentic", __name__)

@agentic_bp.post("/agent/coach")
def agent_coach():
    # Auth
    auth = request.headers.get("Authorization", "")
    if not auth.startswith("Bearer "):
        return jsonify({"error": "missing bearer"}), 401
    token = auth.split(" ", 1)[1].strip()

    # Body
    uid = get_current_user_id()
    body = request.get_json(force=True) or {}
    body["user_id"] = uid  # agent policy expects user_id

    # Optional: basic input sanity (helps earlier error msgs)
    if "amount_cents" not in body or "merchant" not in body:
        return jsonify({"error": "amount_cents and merchant are required"}), 400

    try:
        agent_res = run_guardian_agent(token, body)  # returns {final_output, tool_calls, raw}

        # Normalize to ONLY {"result","message"}
        fo = agent_res.get("final_output")
        if isinstance(fo, dict) and "result" in fo and "message" in fo:
            return jsonify(fo)

        # Some SDKs shove stringified JSON into .final_output or .raw
        raw = agent_res.get("raw")
        if isinstance(raw, dict):
            maybe_fo = raw.get("final_output")
            if isinstance(maybe_fo, dict) and "result" in maybe_fo and "message" in maybe_fo:
                return jsonify(maybe_fo)

        # Last resort: bubble something readable for debugging
        return jsonify({"result": "ERROR", "message": "Agent returned unexpected format"}), 502
    except Exception as e:
        return jsonify({"result": "ERROR", "message": f"Agent failure: {e}"}), 500
