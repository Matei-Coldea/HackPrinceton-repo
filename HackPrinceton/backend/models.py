# models.py
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime, timedelta
from sqlalchemy import Index
from math import radians, cos, sin, asin, sqrt

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

class GeoFenceRule(db.Model):
    __tablename__ = "geofence_rules"
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=False)

    name = db.Column(db.String(64), nullable=False)          # "Mall", "Bar row", etc.
    latitude = db.Column(db.Float, nullable=False)
    longitude = db.Column(db.Float, nullable=False)
    radius_m = db.Column(db.Integer, nullable=False)         # radius in meters

    # Optional targeting: only apply to a category (e.g., "fun"), or null = any
    category = db.Column(db.String(32))                      # same normalization as GuardianRule

    # policy: "block" (decline unless override) or "warn" (approve but mark reason)
    policy = db.Column(db.String(8), nullable=False, default="block")

    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

class UserLocationPing(db.Model):
    __tablename__ = "user_location_pings"
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=False)
    latitude = db.Column(db.Float, nullable=False)
    longitude = db.Column(db.Float, nullable=False)
    accuracy_m = db.Column(db.Float)                         # optional GPS accuracy
    ts = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

from dataclasses import dataclass
from typing import Dict, Optional, List
from marshmallow import Schema, fields, post_load


@dataclass
class TransactionIn:
    user_id: str
    amount: float
    merchant_name: str
    mcc: int = 0
    timestamp: str = ""
    channel: str = "offline"


@dataclass
class ScoreResponse:
    decision: str
    p_avoid: float
    reason: str
    debug: Dict[str, float]


@dataclass
class Stats:
    recent_stationary_pings_near_restaurants: int
    window_minutes: int


@dataclass
class Notification:
    type: str
    code: str
    severity: str


@dataclass
class LocationCheckResponse:
    decision: str
    stats: Optional[Stats] = None
    notifications: Optional[List[Notification]] = None


class TransactionInSchema(Schema):
    user_id = fields.Str(required=True)
    amount = fields.Float(required=True)
    merchant_name = fields.Str(required=True)
    mcc = fields.Int(missing=0)
    timestamp = fields.Str(required=True)
    channel = fields.Str(missing="offline")
    
    @post_load
    def make_transaction(self, data, **kwargs):
        return data


class ScoreResponseSchema(Schema):
    decision = fields.Str(required=True)
    p_avoid = fields.Float(required=True)
    reason = fields.Str(required=True)
    debug = fields.Dict(keys=fields.Str(), values=fields.Float(), required=True)


class StatsSchema(Schema):
    recent_stationary_pings_near_restaurants = fields.Int(required=True)
    window_minutes = fields.Int(required=True)


class NotificationSchema(Schema):
    type = fields.Str(required=True)
    code = fields.Str(required=True)
    severity = fields.Str(required=True)


class LocationCheckResponseSchema(Schema):
    decision = fields.Str(required=True)
    stats = fields.Nested(StatsSchema, allow_none=True)
    notifications = fields.List(fields.Nested(NotificationSchema), allow_none=True)


