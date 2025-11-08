# routes/guardian.py
from flask import Blueprint, request, jsonify
from routes import get_current_user_id
from models import db, User, FundingSource, Transaction
from services.guardian_engine import apply_guardian_logic, create_pending_override
from services.stripe_client import init_stripe, get_or_create_customer, charge_card

guardian_bp = Blueprint("guardian", __name__)

@guardian_bp.route("/authorize", methods=["POST"])
def authorize():
    uid = get_current_user_id()
    data = request.get_json(force=True)
    amount_cents = int(data.get("amount_cents", 0))
    merchant = data.get("merchant", "Unknown")
    category = data.get("category")  # optional

    decision, reason = apply_guardian_logic(uid, amount_cents, merchant, category)
    db.session.add(Transaction(
        user_id=uid,
        event_type="authorize" if decision == "APPROVE" else "decline",
        decision=decision, reason=reason,
        amount_cents=amount_cents, currency="usd",
        merchant=merchant, category=(category or None)
    ))
    db.session.commit()
    res = {"decision": decision, "reason": reason}
    if decision == "DECLINE":
        res["message"] = "This looks risky based on your rule."
    return jsonify(res)

@guardian_bp.route("/override", methods=["POST"])
def override_once():
    uid = get_current_user_id()
    data = request.get_json(force=True)
    amount_cents = int(data.get("amount_cents", 0))
    merchant = data.get("merchant")
    if not merchant or amount_cents <= 0:
        return jsonify({"error": "merchant and amount_cents required"}), 400
    create_pending_override(uid, merchant, amount_cents)
    db.session.add(Transaction(
        user_id=uid,
        event_type="override",
        amount_cents=amount_cents, currency="usd",
        merchant=merchant
    ))
    db.session.commit()
    return jsonify({"status": "ok"})

@guardian_bp.route("/charge", methods=["POST"])
def charge():
    uid = get_current_user_id()
    data = request.get_json(force=True)
    amount_cents = int(data.get("amount_cents", 0))
    currency = data.get("currency", "usd")
    fs_id = data.get("funding_source_id")

    if amount_cents <= 0:
        return jsonify({"error": "amount_cents must be > 0"}), 400

    # Pick funding source
    if fs_id:
        fs = FundingSource.query.filter_by(id=fs_id, user_id=uid).first()
    else:
        fs = FundingSource.query.filter_by(user_id=uid, is_default=True).first()
    if not fs:
        return jsonify({"error": "No funding source found"}), 400

    init_stripe()
    user = User.query.get(uid)
    cust = get_or_create_customer(user)

    result = charge_card(cust, fs.external_id, amount_cents, currency)

    db.session.add(Transaction(
        user_id=uid,
        event_type="charge",
        provider="stripe",
        processor_status=result.get("status"),
        payment_intent_id=result.get("id"),
        amount_cents=amount_cents, currency=currency
    ))
    db.session.commit()

    

    return jsonify({
        "status": "charged",
        "provider": fs.provider,
        "payment_intent_id": result["id"],
        "processor_status": result.get("status", "succeeded")
    })
