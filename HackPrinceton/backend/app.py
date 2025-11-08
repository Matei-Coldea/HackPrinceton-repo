"""
Guardian Card API - Main Application

This module contains only the API routing logic.
Business logic is separated into service modules.
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
from marshmallow import ValidationError
from dataclasses import asdict
import asyncio

# Import schemas and models (relative imports)
from .models import (
    TransactionInSchema,
    ScoreResponseSchema,
    LocationCheckResponseSchema,
    TransactionIn,
)

# Import service functions (relative imports)
from .services.transaction_scorer import score_transaction as score_transaction_service
from .services.geo_guardian import check_location as check_location_service


# ================================
#  FLASK APPLICATION
# ================================

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Initialize schemas
transaction_in_schema = TransactionInSchema()
score_response_schema = ScoreResponseSchema()
location_check_response_schema = LocationCheckResponseSchema()


# ================================
#  TRANSACTION SCORING ENDPOINT
# ================================

@app.route("/score-transaction", methods=["POST"])
def score_transaction():
    """
    Score a transaction to determine if it should be blocked.
    
    This endpoint uses ML models and budget rules to predict whether a transaction
    is an avoidable expense and should be blocked based on the user's profile.
    
    Request Body:
        JSON with: user_id, amount, merchant_name, mcc (optional), timestamp, channel (optional)
        
    Returns:
        JSON with decision (ALLOW/BLOCK), probability, reason, and debug info
    """
    try:
        # Validate and deserialize input
        transaction_data = transaction_in_schema.load(request.json)
        
        # Create TransactionIn dataclass
        transaction = TransactionIn(**transaction_data)
        
        # Call service function
        result = score_transaction_service(transaction)
        
        # Convert dataclass to dict and serialize
        response_data = asdict(result)
        return jsonify(response_data), 200
        
    except ValidationError as err:
        return jsonify({"error": "Validation error", "messages": err.messages}), 400
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ================================
#  GEO-GUARDIAN LOCATION ENDPOINT
# ================================

@app.route("/location-check", methods=["GET"])
def location_check():
    """
    Check user location and determine if card should be blocked.
    
    This endpoint monitors user location to detect stationary behavior near
    restaurants and prevents impulse dining expenses.
    
    Query Parameters:
        user_id: Unique user identifier (required)
        lat: Latitude coordinate -90 to 90 (required)
        lon: Longitude coordinate -180 to 180 (required)
        
    Returns:
        JSON with decision (ok/block) and optional stats/notifications
    """
    try:
        # Get query parameters
        user_id = request.args.get("user_id")
        lat = request.args.get("lat", type=float)
        lon = request.args.get("lon", type=float)
        
        # Validate required parameters
        if not user_id:
            return jsonify({"error": "user_id is required"}), 400
        if lat is None:
            return jsonify({"error": "lat is required"}), 400
        if lon is None:
            return jsonify({"error": "lon is required"}), 400
            
        # Call async service function (run in event loop)
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        result = loop.run_until_complete(check_location_service(user_id, lat, lon))
        loop.close()
        
        # Convert dataclass to dict (handles nested dataclasses)
        def dataclass_to_dict(obj):
            if hasattr(obj, '__dataclass_fields__'):
                result = {}
                for field_name in obj.__dataclass_fields__:
                    value = getattr(obj, field_name)
                    if value is None:
                        result[field_name] = None
                    elif hasattr(value, '__dataclass_fields__'):
                        result[field_name] = dataclass_to_dict(value)
                    elif isinstance(value, list):
                        result[field_name] = [dataclass_to_dict(item) if hasattr(item, '__dataclass_fields__') else item for item in value]
                    else:
                        result[field_name] = value
                return result
            return obj
        
        response_data = dataclass_to_dict(result)
        return jsonify(response_data), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ================================
#  HEALTH CHECK ENDPOINT
# ================================

@app.route("/", methods=["GET"])
def root():
    """
    Health check endpoint.
    
    Returns:
        Simple message indicating the API is running
    """
    return jsonify({
        "message": "Guardian Card API is running",
        "endpoints": {
            "transaction_scoring": "/score-transaction",
            "location_check": "/location-check"
        }
    })
