import os, stripe
from flask import Blueprint, request, jsonify, current_app
from models import User
from services.guardian_engine import apply_guardian_logic

issuing_bp = Blueprint("issuing", __name__)
stripe.api_key = os.environ.get("STRIPE_SECRET_KEY","")

@issuing_bp.post("/issuing")
def issuing():
    payload = request.data
    sig = request.headers.get("Stripe-Signature","")
    whsec = current_app.config["STRIPE_WEBHOOK_SECRET"]
    try:
        event = stripe.Webhook.construct_event(payload, sig, whsec)
    except Exception as e:
        return jsonify({"error":str(e)}), 400

    if event["type"] == "issuing_authorization.request":
        obj = event["data"]["object"]
        auth_id = obj["id"]
        card_id = obj["card"]
        amount = obj["amount"]
        merchant = obj["merchant_data"]["name"]
        # map card -> user
        user = User.query.filter_by(guardian_card_id=card_id).first()
        if not user:
            stripe.issuing.Authorizations.decline(auth_id)
            return jsonify({"status":"declined","reason":"unknown_card"}), 200
        decision, reason = apply_guardian_logic(user.id, int(amount), merchant, None)
        if decision == "APPROVE":
            stripe.issuing.Authorizations.approve(auth_id)
        else:
            stripe.issuing.Authorizations.decline(auth_id)
        return jsonify({"status": decision.lower(), "reason":reason}), 200

    return jsonify({"status":"ok"}), 200
