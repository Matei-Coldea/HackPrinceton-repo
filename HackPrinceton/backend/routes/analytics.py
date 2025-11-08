# routes/analytics.py
from flask import Blueprint, request, jsonify
from sqlalchemy import func, case
from datetime import datetime, timedelta, timezone
from models import db, Transaction, GuardianRule
from routes import get_current_user_id

analytics_bp = Blueprint("analytics", __name__)

def _range_bounds(range_str: str):
    now = datetime.now(timezone.utc)
    r = (range_str or "30d").lower()
    if r == "7d":   start = now - timedelta(days=7)
    elif r == "mtd":
        start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    elif r == "90d": start = now - timedelta(days=90)
    else:            start = now - timedelta(days=30)  # default 30d
    return start, now

# 1) Summary: totals, counts, risky/override rates (last 30d by default)
@analytics_bp.get("/analytics/summary")
def analytics_summary():
    uid = get_current_user_id()
    start, end = _range_bounds(request.args.get("range"))

    # Charges only for spend
    q_charges = (db.session.query(
        func.coalesce(func.sum(Transaction.amount_cents), 0),
        func.count()
    ).filter(
        Transaction.user_id == uid,
        Transaction.event_type == "charge",
        Transaction.ts >= start, Transaction.ts < end,
        Transaction.processor_status == "succeeded"
    ))

    spend_cents, charge_count = q_charges.first()

    # Authorize/decline rates
    q_auth = (db.session.query(
        func.count().label("total"),
        func.sum(case((Transaction.reason=="risky", 1), else_=0)).label("risky_count"),
        func.sum(case((Transaction.reason=="override",1), else_=0)).label("override_count")
    ).filter(
        Transaction.user_id == uid,
        Transaction.event_type.in_(["authorize","decline"]),
        Transaction.ts >= start, Transaction.ts < end
    ))
    total_auth, risky_ct, override_ct = q_auth.first() or (0,0,0)

    return jsonify({
        "range": {"start": start.isoformat(), "end": end.isoformat()},
        "spend_cents": int(spend_cents or 0),
        "charge_count": int(charge_count or 0),
        "auth_events": int(total_auth or 0),
        "risky_rate": (risky_ct / total_auth) if total_auth else 0.0,
        "override_rate": (override_ct / total_auth) if total_auth else 0.0,
    })

# 2) Spend by category
@analytics_bp.get("/analytics/by-category")
def analytics_by_category():
    uid = get_current_user_id()
    start, end = _range_bounds(request.args.get("range"))

    rows = (db.session.query(
        Transaction.category,
        func.coalesce(func.sum(Transaction.amount_cents), 0).label("spend_cents"),
        func.count().label("count")
    ).filter(
        Transaction.user_id == uid,
        Transaction.event_type == "charge",
        Transaction.processor_status == "succeeded",
        Transaction.ts >= start, Transaction.ts < end
    ).group_by(Transaction.category)
     .order_by(func.coalesce(func.sum(Transaction.amount_cents), 0).desc())
    ).all()

    return jsonify([
        {"category": c or "uncategorized", "spend_cents": int(s), "count": int(n)}
        for c, s, n in rows
    ])

# 3) Time series spend (daily)
@analytics_bp.get("/analytics/timeseries")
def analytics_timeseries():
    uid = get_current_user_id()
    start, end = _range_bounds(request.args.get("range"))

    # Postgres date_trunc
    date_trunc = func.date_trunc('day', Transaction.ts)
    rows = (db.session.query(
        date_trunc.label("day"),
        func.coalesce(func.sum(Transaction.amount_cents), 0).label("spend_cents")
    ).filter(
        Transaction.user_id == uid,
        Transaction.event_type == "charge",
        Transaction.processor_status == "succeeded",
        Transaction.ts >= start, Transaction.ts < end
    ).group_by(date_trunc).order_by(date_trunc)).all()

    return jsonify([
        {"day": d.isoformat(), "spend_cents": int(s)} for d, s in rows
    ])

# 4) Top merchants
@analytics_bp.get("/analytics/merchants")
def analytics_merchants():
    uid = get_current_user_id()
    start, end = _range_bounds(request.args.get("range"))
    rows = (db.session.query(
        Transaction.merchant,
        func.coalesce(func.sum(Transaction.amount_cents), 0).label("spend_cents"),
        func.count().label("count")
    ).filter(
        Transaction.user_id == uid,
        Transaction.event_type == "charge",
        Transaction.processor_status == "succeeded",
        Transaction.ts >= start, Transaction.ts < end
    ).group_by(Transaction.merchant)
     .order_by(func.coalesce(func.sum(Transaction.amount_cents), 0).desc())
     .limit(10)).all()

    return jsonify([
        {"merchant": m or "unknown", "spend_cents": int(s), "count": int(n)} for m, s, n in rows
    ])

# 5) Rule progress (MTD): remaining vs limit per category
@analytics_bp.get("/analytics/rules-progress")
def analytics_rules_progress():
    uid = get_current_user_id()
    # month start
    now = datetime.utcnow()
    start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)

    rules = GuardianRule.query.filter_by(user_id=uid).all()
    out = []
    for r in rules:
        spent = (db.session.query(func.coalesce(func.sum(Transaction.amount_cents), 0))
                 .filter(
                     Transaction.user_id == uid,
                     Transaction.event_type == "charge",
                     Transaction.processor_status == "succeeded",
                     Transaction.category == r.category,
                     Transaction.ts >= start
                 ).scalar() or 0)
        limit = r.monthly_limit_cents or 0
        out.append({
            "category": r.category,
            "limit_cents": int(limit),
            "spent_mtd_cents": int(spent),
            "remaining_cents": int(max(0, (limit - spent))) if limit else None,
            "utilization": (spent/limit) if limit else None
        })
    return jsonify(out)

# 6) Recent overrides
@analytics_bp.get("/analytics/overrides")
def analytics_overrides():
    uid = get_current_user_id()
    start, end = _range_bounds(request.args.get("range"))
    rows = (db.session.query(Transaction)
            .filter(
                Transaction.user_id == uid,
                Transaction.event_type == "override",
                Transaction.ts >= start, Transaction.ts < end
            ).order_by(Transaction.ts.desc()).limit(50).all())
    return jsonify([
        {
            "ts": t.ts.isoformat(),
            "merchant": t.merchant,
            "amount_cents": t.amount_cents
        } for t in rows
    ])
