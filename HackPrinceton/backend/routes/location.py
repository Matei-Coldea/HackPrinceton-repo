from flask import Blueprint, request, jsonify
from datetime import datetime
from models import db, UserLocationPing
from routes import get_current_user_id

location_bp = Blueprint("location", __name__)

@location_bp.post("/location/update")
def location_update():
    uid = get_current_user_id()
    data = request.get_json(force=True)
    lat = data.get("latitude")
    lon = data.get("longitude")
    acc = data.get("accuracy_m", None)
    if lat is None or lon is None:
        return jsonify({"error":"latitude and longitude required"}), 400

    ping = UserLocationPing(user_id=uid, latitude=float(lat), longitude=float(lon), accuracy_m=(float(acc) if acc is not None else None))
    db.session.add(ping)
    db.session.commit()

    return jsonify({"status":"ok","ts": ping.ts.isoformat()})