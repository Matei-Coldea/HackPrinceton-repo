from flask import Blueprint, request, jsonify
import asyncio
from routes import get_current_user_id
from services.transaction_scorer import score_transaction
from services.geo_guardian import check_location as check_location_service

transaction_scoring_bp = Blueprint("transaction_scoring", __name__)


@transaction_scoring_bp.route("/score-transaction", methods=["POST"])
def score_transaction_endpoint():
    """
    Score a transaction using ML model and obligations planner.
    
    Request body:
    {
        "user_id": "string",  # optional, will use auth if not provided
        "amount": float,
        "merchant_name": "string",
        "mcc": int (optional),
        "timestamp": "ISO string" (optional),
        "channel": "string" (optional, default: "offline")
    }
    
    Response:
    {
        "decision": "ALLOW" | "BLOCK",
        "p_avoid": float,
        "reason": "string",
        "debug": {...}
    }
    """
    try:
        data = request.get_json(force=True)
        
        # Use authenticated user if no user_id provided
        user_id = data.get("user_id")
        if not user_id:
            try:
                user_id = str(get_current_user_id())
            except:
                # If no auth, use user_id from request or default
                user_id = data.get("user_id", "default_user")
        
        amount = data.get("amount")
        merchant_name = data.get("merchant_name")
        mcc = data.get("mcc", 0)
        timestamp = data.get("timestamp", "")
        channel = data.get("channel", "offline")
        
        if amount is None or merchant_name is None:
            return jsonify({"error": "amount and merchant_name are required"}), 400
        
        result = score_transaction(
            user_id=user_id,
            amount=float(amount),
            merchant_name=merchant_name,
            mcc=int(mcc),
            timestamp=timestamp,
            channel=channel
        )
        
        return jsonify(result), 200
        
    except ValueError as err:
        return jsonify({"error": "Validation error", "message": str(err)}), 400
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@transaction_scoring_bp.route("/location-check", methods=["GET", "POST"])
def location_check():
    """
    Check if user's location triggers geo-guardian alerts.
    
    Query params (GET) or body (POST):
    {
        "user_id": "string",  # optional, will use auth if not provided
        "lat": float,
        "lon": float
    }
    
    Response:
    {
        "decision": "ok" | "block",
        "stats": {...} (optional),
        "notifications": [...] (optional)
    }
    """
    try:
        if request.method == "GET":
            user_id = request.args.get("user_id")
            lat = request.args.get("lat", type=float)
            lon = request.args.get("lon", type=float)
        else:
            data = request.get_json(force=True)
            user_id = data.get("user_id")
            lat = data.get("lat")
            lon = data.get("lon")
        
        # Use authenticated user if no user_id provided
        if not user_id:
            try:
                user_id = str(get_current_user_id())
            except:
                user_id = request.args.get("user_id") if request.method == "GET" else data.get("user_id", "default_user")
        
        if lat is None:
            return jsonify({"error": "lat is required"}), 400
        if lon is None:
            return jsonify({"error": "lon is required"}), 400
        
        # Run async function
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        result = loop.run_until_complete(check_location_service(user_id, float(lat), float(lon)))
        loop.close()
        
        return jsonify(result), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@transaction_scoring_bp.route("/", methods=["GET"])
@transaction_scoring_bp.route("/health", methods=["GET"])
def health():
    """Health check endpoint"""
    return jsonify({
        "status": "ok",
        "message": "Guardian Card Transaction Scoring API is running",
        "endpoints": {
            "transaction_scoring": "/score-transaction",
            "location_check": "/location-check"
        }
    })


