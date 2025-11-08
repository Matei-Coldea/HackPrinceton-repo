# routes/funding.py
from flask import Blueprint, request, jsonify
from models import db, User, FundingSource
from routes import get_current_user_id
from services.stripe_client import init_stripe, get_or_create_customer, create_card_setup_intent, ensure_pm_attached_to_customer

funding_bp = Blueprint("funding", __name__)

@funding_bp.route("/cards/intent", methods=["POST"])
def create_setup_intent():
    uid = get_current_user_id()
    user = User.query.get(uid)
    init_stripe()
    customer_id = get_or_create_customer(user)
    si = create_card_setup_intent(customer_id)
    return jsonify({"clientSecret": si["client_secret"]})


@funding_bp.route("/cards/confirm", methods=["POST"])
def confirm_card():
    uid = get_current_user_id()
    data = request.get_json(force=True)
    pm_id = data.get("payment_method_id")
    label = data.get("label", "Card")
    if not pm_id:
        return jsonify({"error": "payment_method_id required"}), 400

    user = User.query.get(uid)
    init_stripe()
    customer_id = get_or_create_customer(user)

    provider = "stripe" if pm_id.startswith("pm_") else "mock"
    if provider == "stripe":
        try:
            ensure_pm_attached_to_customer(pm_id, customer_id)
        except Exception as e:
            return jsonify({"error": f"failed to attach payment method: {e}"}), 400

    already = FundingSource.query.filter_by(user_id=uid).count() > 0
    fs = FundingSource(
        user_id=uid,
        type="card",
        provider=provider,
        external_id=pm_id,
        label=label,
        is_default=(not already),
    )
    db.session.add(fs)
    db.session.commit()
    return jsonify({"status": "ok", "funding_source_id": fs.id})
