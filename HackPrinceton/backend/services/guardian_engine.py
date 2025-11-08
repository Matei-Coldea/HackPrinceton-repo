from typing import Tuple, Optional
from datetime import datetime
from models import db, GuardianRule, PendingOverride

def is_risky(user_id: int, amount_cents: int, merchant: str, category: Optional[str]) -> bool:
    # Very simple v1 rule:
    # If there is a rule matching the category and amount > half the monthly limit -> risky
    if not category:
        return False
    rule = GuardianRule.query.filter_by(user_id=user_id, category=category).first()
    if not rule or not rule.monthly_limit_cents:
        return False
    return amount_cents > (rule.monthly_limit_cents // 2)

def has_valid_override(user_id: int, merchant: str, amount_cents: int) -> bool:
    now = datetime.utcnow()
    ov = PendingOverride.query.filter_by(
        user_id=user_id, merchant=merchant, amount_cents=amount_cents
    ).filter(PendingOverride.expires_at > now).first()
    if ov:
        db.session.delete(ov)  # one-time use
        db.session.commit()
        return True
    return False

def create_pending_override(user_id: int, merchant: str, amount_cents: int, ttl_minutes: int = 5) -> None:
    ov = PendingOverride(
        user_id=user_id,
        merchant=merchant,
        amount_cents=amount_cents,
        expires_at=PendingOverride.expires_in(ttl_minutes),
    )
    db.session.add(ov)
    db.session.commit()

def apply_guardian_logic(user_id: int, amount_cents: int, merchant: str, category: Optional[str]) -> Tuple[str, str]:
    # 1) Check override
    if has_valid_override(user_id, merchant, amount_cents):
        return "APPROVE", "override"
    # 2) Risk
    if is_risky(user_id, amount_cents, merchant, category):
        create_pending_override(user_id, merchant, amount_cents)
        return "DECLINE", "risky"
    # 3) Safe
    return "APPROVE", "safe"
