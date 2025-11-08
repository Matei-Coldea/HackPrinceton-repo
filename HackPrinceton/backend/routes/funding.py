from flask import Blueprint, request, jsonify, abort
from routes import get_current_user_id
from models import db, User, FundingSource
from services import stripe_client

funding_bp = Blueprint("funding", __name__)

@funding_bp.post("/cards/intent")
def cards_intent():
    uid = get_current_user_id()
    user = User.query.get(uid)
    cust = stripe_client.get_or_create_customer(user)
    return jsonify(stripe_client.create_card_setup_intent(cust))

@funding_bp.post("/cards/confirm")
def cards_confirm():
    uid = get_current_user_id()
    data = request.get_json(force=True)
    pm = data.get("payment_method_id"); label = data.get("label","Main Visa")
    if not pm: abort(400, description="payment_method_id required")
    count = FundingSource.query.filter_by(user_id=uid).count()
    fs = FundingSource(user_id=uid, type="card", provider="stripe", external_id=pm, label=label, is_default=(count==0))
    db.session.add(fs); db.session.commit()
    return jsonify({"status":"ok","funding_source_id":fs.id})

@funding_bp.get("/sources")
def list_sources():
    uid = get_current_user_id()
    rows = FundingSource.query.filter_by(user_id=uid).all()
    return jsonify({"data":[{"id":r.id,"label":r.label,"provider":r.provider,"type":r.type,"is_default":r.is_default} for r in rows]})
