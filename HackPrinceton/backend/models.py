# models.py
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime, timedelta
from sqlalchemy import Index

db = SQLAlchemy()

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(255), unique=True)
    external_sub = db.Column(db.String(255), unique=True)  # from JWT
    # optional stripe fields if you add later
    stripe_customer_id = db.Column(db.String(64))
    stripe_cardholder_id = db.Column(db.String(64))
    guardian_card_id = db.Column(db.String(64))

class FundingSource(db.Model):
    __tablename__ = "funding_sources"
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=False)
    type = db.Column(db.String(16), nullable=False)       # "card" | "bank"
    provider = db.Column(db.String(16), nullable=False)   # "mock" | "stripe"
    external_id = db.Column(db.String(128), nullable=False)  # pm_123, bank token, or mock id
    label = db.Column(db.String(64))
    is_default = db.Column(db.Boolean, default=False, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

class GuardianRule(db.Model):
    __tablename__ = "guardian_rules"
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=False)
    category = db.Column(db.String(32))                   # e.g., "fun","groceries", or None
    monthly_limit_cents = db.Column(db.Integer)           # e.g., 20000 = $200

class PendingOverride(db.Model):
    __tablename__ = "pending_overrides"
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=False)
    merchant = db.Column(db.String(128), nullable=False)
    amount_cents = db.Column(db.Integer, nullable=False)
    expires_at = db.Column(db.DateTime, nullable=False)

    @staticmethod
    def expires_in(minutes: int = 5):
        return datetime.utcnow() + timedelta(minutes=minutes)
    

class Transaction(db.Model):
    __tablename__ = "transactions"
    id = db.Column(db.Integer, primary_key=True)

    # CHANGE users.id -> user.id
    user_id = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=False)

    ts = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    event_type = db.Column(db.String(20), nullable=False)
    decision = db.Column(db.String(20))
    reason   = db.Column(db.String(20))
    provider = db.Column(db.String(20))
    processor_status = db.Column(db.String(40))
    payment_intent_id = db.Column(db.String(64))
    amount_cents = db.Column(db.Integer, nullable=False, default=0)
    currency     = db.Column(db.String(10), default="usd")
    merchant     = db.Column(db.String(120))
    category     = db.Column(db.String(50))

Index("ix_tx_user_ts", Transaction.user_id, Transaction.ts)
Index("ix_tx_user_cat_ts", Transaction.user_id, Transaction.category, Transaction.ts)
