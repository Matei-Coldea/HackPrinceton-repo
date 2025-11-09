# routes/geofence.py
from flask import Blueprint, request, jsonify
from models import db, GeoFenceRule
from routes import get_current_user_id

geofence_bp = Blueprint("geofence", __name__)

@geofence_bp.post("/rules/geofence")
def create_geofence():
    uid = get_current_user_id()
    data = request.get_json(force=True)
    name = (data.get("name") or "Geofence").strip()
    lat = data.get("latitude"); lon = data.get("longitude")
    radius_m = data.get("radius_m"); category = data.get("category")
    policy = (data.get("policy") or "block").lower()  # "block" or "warn"

    if None in (lat, lon, radius_m):
        return jsonify({"error":"latitude, longitude, radius_m required"}), 400
    if policy not in ("block","warn"):
        return jsonify({"error":"policy must be 'block' or 'warn'"}), 400

    gf = GeoFenceRule(
        user_id=uid,
        name=name,
        latitude=float(lat),
        longitude=float(lon),
        radius_m=int(radius_m),
        category=(category.lower() if category else None),
        policy=policy
    )
    db.session.add(gf)
    db.session.commit()
    return jsonify({"id": gf.id, "status":"created"})

@geofence_bp.get("/rules/geofence")
def list_geofences():
    uid = get_current_user_id()
    rows = GeoFenceRule.query.filter_by(user_id=uid).order_by(GeoFenceRule.id.desc()).all()
    return jsonify([{
        "id": r.id,
        "name": r.name,
        "latitude": r.latitude,
        "longitude": r.longitude,
        "radius_m": r.radius_m,
        "category": r.category,
        "policy": r.policy
    } for r in rows])

@geofence_bp.delete("/rules/geofence/<int:gid>")
def delete_geofence(gid: int):
    uid = get_current_user_id()
    r = GeoFenceRule.query.filter_by(id=gid, user_id=uid).first()
    if not r:
        return jsonify({"error":"not found"}), 404
    db.session.delete(r)
    db.session.commit()
    return jsonify({"status":"deleted"})
