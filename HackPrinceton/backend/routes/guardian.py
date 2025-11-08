from flask import Blueprint, request, jsonify, abort
from routes import get_current_user_id
from services.guardian_engine import apply_guardian_logic
from models import db, User, FundingSource
from services import stripe_client

guardian_bp = Blueprint("guardian", __name__)

@guardian_bp.post("/authorize")
def authorize():
    uid = get_current_user_id()
    body = request.get_json(force=True)
    amt = body.get("amount_cents"); merch = body.get("merchant"); cat = body.get("category")
    if amt is None or not merch: abort(400, description="amount_cents and merchant required")
    decision, reason = apply_guardian_logic(uid, int(amt), merch, cat)
    if decision == "APPROVE":
        return jsonify({"decision":"APPROVE","reason":reason})
    return jsonify({"decision":"DECLINE","reason":"risky","message":"This looks risky based on your budget."})

@guardian_bp.post("/override")
def override():
    uid = get_current_user_id()
    from services.guardian_engine import create_pending_override
    body = request.get_json(force=True)
    amt = body.get("amount_cents"); merch = body.get("merchant")
    if amt is None or not merch: abort(400, description="amount_cents and merchant required")
    create_pending_override(uid, merch, int(amt))
    return jsonify({"status":"ok"})

@guardian_bp.post("/charge")
def charge():
    uid = get_current_user_id()
    data = request.get_json(force=True)
    amount = data.get("amount_cents"); currency = data.get("currency","usd"); fs_id = data.get("funding_source_id")
    if amount is None: abort(400, description="amount_cents required")
    fs = FundingSource.query.filter_by(user_id=uid, id=fs_id).first() if fs_id \
         else FundingSource.query.filter_by(user_id=uid, is_default=True).first()
    if not fs: abort(400, description="no funding source")
    if fs.provider!="stripe" or fs.type!="card": abort(400, description="unsupported provider/type")
    user = User.query.get(uid)
    cust = stripe_client.get_or_create_customer(user)
    idem = request.headers.get("Idempotency-Key")
    try:
        res = stripe_client.charge_card(cust, fs.external_id, int(amount), currency, idem)
        return jsonify({"status":"charged","provider":"stripe","payment_intent_id":res["payment_intent_id"],"charge_status":res["status"]})
    except Exception as e:
        return jsonify({"error":str(e),"code":"stripe_error"}), 400
