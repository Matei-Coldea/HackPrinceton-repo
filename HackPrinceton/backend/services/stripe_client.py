import stripe, os
from typing import Optional
from models import db, User

stripe.api_key = os.environ.get("STRIPE_SECRET_KEY","")

def get_or_create_customer(user: User) -> str:
    if user.stripe_customer_id: return user.stripe_customer_id
    cust = stripe.Customer.create(email=user.email)
    user.stripe_customer_id = cust.id; db.session.commit()
    return cust.id

def create_card_setup_intent(customer_id: str) -> dict:
    si = stripe.SetupIntent.create(customer=customer_id, payment_method_types=["card"])
    return {"client_secret": si.client_secret}

def charge_card(customer_id: str, payment_method_id: str, amount_cents: int, currency: str="usd", idempotency_key: Optional[str]=None) -> dict:
    headers = {"Idempotency-Key": idempotency_key} if idempotency_key else None
    pi = stripe.PaymentIntent.create(
        amount=amount_cents, currency=currency, customer=customer_id,
        payment_method=payment_method_id, confirm=True, off_session=True,
        automatic_payment_methods={"enabled": False},
        idempotency_key=idempotency_key
    )
    return {"payment_intent_id": pi.id, "status": pi.status}

def create_issuing_cardholder(user: User) -> str:
    ch = stripe.issuing.Cardholder.create(type="individual", name=user.email or f"user-{user.id}")
    user.stripe_cardholder_id = ch.id; db.session.commit()
    return ch.id

def create_guardian_issuing_card(user: User) -> str:
    if not user.stripe_cardholder_id: create_issuing_cardholder(user)
    card = stripe.issuing.Card.create(cardholder=user.stripe_cardholder_id, currency="usd", type="virtual")
    user.guardian_card_id = card.id; db.session.commit()
    return card.id
