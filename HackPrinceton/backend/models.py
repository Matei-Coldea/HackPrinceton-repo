"""
Data models and marshmallow schemas for API requests and responses
"""

from dataclasses import dataclass
from typing import Dict, Optional, List
from marshmallow import Schema, fields, post_load


# ================================
#  DATACLASSES (for internal use)
# ================================

@dataclass
class TransactionIn:
    """Transaction input data"""
    user_id: str
    amount: float
    merchant_name: str
    mcc: int = 0
    timestamp: str = ""
    channel: str = "offline"


@dataclass
class ScoreResponse:
    """Transaction scoring response"""
    decision: str
    p_avoid: float
    reason: str
    debug: Dict[str, float]


@dataclass
class Stats:
    """Geo-guardian statistics"""
    recent_stationary_pings_near_restaurants: int
    window_minutes: int


@dataclass
class Notification:
    """Notification data"""
    type: str           # e.g. "behavior"
    code: str           # e.g. "RESTAURANT_STATIONARY_TOO_LONG"
    severity: str       # e.g. "warning"


@dataclass
class LocationCheckResponse:
    """Location check response"""
    decision: str                      # "ok" or "block"
    stats: Optional[Stats] = None
    notifications: Optional[List[Notification]] = None


# ================================
#  MARSHMALLOW SCHEMAS (for API serialization)
# ================================

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
    type = fields.Str(required=True)      # e.g. "behavior"
    code = fields.Str(required=True)      # e.g. "RESTAURANT_STATIONARY_TOO_LONG"
    severity = fields.Str(required=True)  # e.g. "warning"


class LocationCheckResponseSchema(Schema):
    decision = fields.Str(required=True)  # "ok" or "block"
    stats = fields.Nested(StatsSchema, allow_none=True)
    notifications = fields.List(fields.Nested(NotificationSchema), allow_none=True)

