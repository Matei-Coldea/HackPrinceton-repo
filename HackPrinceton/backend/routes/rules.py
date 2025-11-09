from flask import Blueprint, request, jsonify
from routes import get_current_user_id
from models import db, GuardianRule

rules_bp = Blueprint("rules", __name__)

@rules_bp.get("/rules")
def list_rules():
    uid = get_current_user_id()
    rows = GuardianRule.query.filter_by(user_id=uid).all()
    return jsonify([{"id": r.id, "category": r.category, "monthly_limit_cents": r.monthly_limit_cents} for r in rows])

@rules_bp.post("/rules")
def upsert_rule():
    uid = get_current_user_id()
    data = request.get_json(force=True)
    category = (data.get("category") or "").strip().lower()
    limit = int(data.get("monthly_limit_cents", 0))
    if not category or limit < 0:
        return jsonify({"error": "category and positive monthly_limit_cents required"}), 400
    r = GuardianRule.query.filter_by(user_id=uid, category=category).first()
    if r:
        r.monthly_limit_cents = limit
    else:
        r = GuardianRule(user_id=uid, category=category, monthly_limit_cents=limit)
        db.session.add(r)
    db.session.commit()
    return jsonify({"id": r.id, "category": r.category, "monthly_limit_cents": r.monthly_limit_cents})
