from typing import Tuple, Optional
from datetime import datetime
from models import db, GuardianRule, PendingOverride
from models import db, GeoFenceRule, UserLocationPing
from services.geo import haversine_m

def is_risky(user_id: int, amount_cents: int, merchant: str, category: Optional[str]) -> bool:
    # Very simple v1 rule:
    # If there is a rule matching the category and amount > half the monthly limit -> risky
    if not category:
        return False
    
    cat = category.strip().lower()
    rule = GuardianRule.query.filter_by(user_id=user_id, category=cat).first()
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

def apply_guardian_logic(user_id: int, amount_cents: int, merchant: str, category: str | None):
    gf = geofence_effect(user_id, category)
    if gf:
        policy, gf_name = gf
        if policy == "block":
            # Create pending override & decline
            create_pending_override(user_id, merchant, amount_cents)
            return ("DECLINE", "location_block")
        elif policy == "warn":
            # Allow but tag the reason
            # (You can still continue with budget checks; we short-circuit here for clarity.)
            return ("APPROVE", "location_warn")

    # 1) Override?
    if has_valid_override(user_id, merchant, amount_cents):
        return ("APPROVE", "override")

    print(user_id, amount_cents, merchant, category)
    print(is_risky(user_id, amount_cents, merchant, category))
    # 2) Budget risk?
    if is_risky(user_id, amount_cents, merchant, category):
        create_pending_override(user_id, merchant, amount_cents)
        return ("DECLINE", "risky")

    # 3) Safe
    return ("APPROVE", "safe")


def _latest_ping_for_user(user_id: int):
    return (UserLocationPing.query
            .filter_by(user_id=user_id)
            .order_by(UserLocationPing.ts.desc())
            .first())

def geofence_effect(user_id: int, category: Optional[str]) -> Optional[Tuple[str, str]]:
    """
    Returns (policy, name) if current location is within a geofence that applies.
    policy in {"block","warn"}; name is geofence label.
    """
    ping = _latest_ping_for_user(user_id)
    if not ping:
        return None

    fences = GeoFenceRule.query.filter_by(user_id=user_id).all()
    cat = (category.lower() if category else None)

    for f in fences:
        if f.category and cat and f.category != cat:
            continue  # category-specific fence doesn't match
        d = haversine_m(ping.latitude, ping.longitude, f.latitude, f.longitude)
        if d <= float(f.radius_m):
            return (f.policy, f.name)
    return None

