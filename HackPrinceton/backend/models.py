from flask_sqlalchemy import SQLAlchemy
db = SQLAlchemy()

class User(db.Model):
    __tablename__="users"
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(255), unique=True, nullable=False, index=True)
    password_hash = db.Column(db.String(255), nullable=False, default="!")  # unused with Supabase
    external_sub = db.Column(db.String(64), unique=True, index=True)        # Supabase 'sub'
    stripe_customer_id = db.Column(db.String(64))
    stripe_cardholder_id = db.Column(db.String(64))
    guardian_card_id = db.Column(db.String(64))
    created_at = db.Column(db.DateTime, server_default=db.func.now(), nullable=False)

class FundingSource(db.Model):
    __tablename__="funding_sources"
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False, index=True)
    type = db.Column(db.String(16), nullable=False)       # "card" | "bank"
    provider = db.Column(db.String(32), nullable=False)   # "stripe" | "plaid"
    external_id = db.Column(db.String(128), nullable=False)
    label = db.Column(db.String(128))
    is_default = db.Column(db.Boolean, default=False, nullable=False)
    created_at = db.Column(db.DateTime, server_default=db.func.now(), nullable=False)
    __table_args__ = (db.UniqueConstraint("user_id","external_id",name="uq_user_ext"),)

class GuardianRule(db.Model):
    __tablename__="guardian_rules"
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False, index=True)
    category = db.Column(db.String(64))
    monthly_limit_cents = db.Column(db.Integer)
    created_at = db.Column(db.DateTime, server_default=db.func.now(), nullable=False)

class PendingOverride(db.Model):
    __tablename__="pending_overrides"
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False, index=True)
    merchant = db.Column(db.String(255), nullable=False)
    amount_cents = db.Column(db.Integer, nullable=False)
    expires_at = db.Column(db.DateTime, nullable=False, index=True)
    __table_args__ = (db.Index("ix_override_match","user_id","merchant","amount_cents"),)
