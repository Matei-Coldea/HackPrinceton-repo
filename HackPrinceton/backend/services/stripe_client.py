# services/stripe_client.py
import time, uuid
from typing import Dict, Any
from flask import current_app

try:
    import stripe
except Exception:
    stripe = None

def _use_stripe() -> bool:
    return (
        current_app.config.get("PAYMENTS_PROVIDER", "mock") == "stripe"
        and bool(current_app.config.get("STRIPE_SECRET_KEY"))
        and stripe is not None
    )

def init_stripe():
    if _use_stripe():
        stripe.api_key = current_app.config["STRIPE_SECRET_KEY"]

def get_or_create_customer(user) -> str:
    if not _use_stripe():
        return f"cus_mock_{user.id}"
    if user.stripe_customer_id:
        return user.stripe_customer_id
    c = stripe.Customer.create(email=user.email or f"user{user.id}@example.com")
    user.stripe_customer_id = c["id"]
    from models import db
    db.session.commit()
    return c["id"]

def create_card_setup_intent(customer_id: str) -> Dict[str, Any]:
    if not _use_stripe():
        return {"client_secret": f"seti_mock_{uuid.uuid4().hex}"}
    si = stripe.SetupIntent.create(customer=customer_id, payment_method_types=["card"])
    return {"client_secret": si["client_secret"]}

def ensure_pm_attached_to_customer(pm_id: str, customer_id: str) -> None:
    if not _use_stripe():
        return
    pm = stripe.PaymentMethod.retrieve(pm_id)
    if pm.get("customer") != customer_id:
        stripe.PaymentMethod.attach(pm_id, customer=customer_id)

def charge_card(customer_id: str, payment_method_id: str, amount_cents: int, currency: str) -> Dict[str, Any]:
    if not _use_stripe():
        time.sleep(0.15)
        return {"id": f"pi_mock_{uuid.uuid4().hex}", "status": "succeeded"}

    ensure_pm_attached_to_customer(payment_method_id, customer_id)

    pi = stripe.PaymentIntent.create(
        amount=amount_cents,
        currency=currency,
        customer=customer_id,
        payment_method=payment_method_id,
        confirm=True,
        off_session=True,
        description="Guardian charge",
    )
    return {"id": pi["id"], "status": pi["status"]}
