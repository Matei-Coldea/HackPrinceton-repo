from typing import Optional, Tuple
from datetime import datetime, timedelta
from models import db, GuardianRule, PendingOverride

def is_risky(user_id: int, amount_cents: int, merchant: str, category: Optional[str]) -> bool:
    rule = GuardianRule.query.filter_by(user_id=user_id, category=category).first()
    if not rule or not rule.monthly_limit_cents: return False
    return amount_cents > (rule.monthly_limit_cents // 2)

def has_valid_override(user_id: int, merchant: str, amount_cents: int) -> bool:
    now = datetime.utcnow()
    ov = PendingOverride.query.filter_by(user_id=user_id, merchant=merchant, amount_cents=amount_cents)\
        .filter(PendingOverride.expires_at > now).first()
    if ov:
        db.session.delete(ov); db.session.commit()
        return True
    return False

def create_pending_override(user_id: int, merchant: str, amount_cents: int, ttl_minutes: int=5) -> None:
    exp = datetime.utcnow() + timedelta(minutes=ttl_minutes)
    db.session.add(PendingOverride(user_id=user_id, merchant=merchant, amount_cents=amount_cents, expires_at=exp))
    db.session.commit()

def apply_guardian_logic(user_id: int, amount_cents: int, merchant: str, category: Optional[str]) -> Tuple[str,str]:
    if has_valid_override(user_id, merchant, amount_cents): return ("APPROVE","override")
    if not is_risky(user_id, amount_cents, merchant, category): return ("APPROVE","safe")
    create_pending_override(user_id, merchant, amount_cents)
    return ("DECLINE","risky")
