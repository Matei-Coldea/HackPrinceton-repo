from flask import Flask, request, jsonify
from flask_cors import CORS
from marshmallow import ValidationError
from dataclasses import asdict
import asyncio

from .models import (
    TransactionInSchema,
    ScoreResponseSchema,
    LocationCheckResponseSchema,
    TransactionIn,
)

from .services.transaction_scorer import score_transaction as score_transaction_service
from .services.geo_guardian import check_location as check_location_service

app = Flask(__name__)
CORS(app)

transaction_in_schema = TransactionInSchema()
score_response_schema = ScoreResponseSchema()
location_check_response_schema = LocationCheckResponseSchema()


@app.route("/score-transaction", methods=["POST"])
def score_transaction():
    try:
        transaction_data = transaction_in_schema.load(request.json)
        transaction = TransactionIn(**transaction_data)
        result = score_transaction_service(transaction)
        response_data = asdict(result)
        return jsonify(response_data), 200
        
    except ValidationError as err:
        return jsonify({"error": "Validation error", "messages": err.messages}), 400
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/location-check", methods=["GET"])
def location_check():
    try:
        user_id = request.args.get("user_id")
        lat = request.args.get("lat", type=float)
        lon = request.args.get("lon", type=float)
        
        if not user_id:
            return jsonify({"error": "user_id is required"}), 400
        if lat is None:
            return jsonify({"error": "lat is required"}), 400
        if lon is None:
            return jsonify({"error": "lon is required"}), 400
            
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        result = loop.run_until_complete(check_location_service(user_id, lat, lon))
        loop.close()
        
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


@app.route("/", methods=["GET"])
def root():
    return jsonify({
        "message": "Guardian Card API is running",
        "endpoints": {
            "transaction_scoring": "/score-transaction",
            "location_check": "/location-check"
        }
    })
