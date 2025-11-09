from flask import Flask
from flask_migrate import Migrate
from flask_cors import CORS
from models import db
from config import Config


def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)
    CORS(app)
    db.init_app(app)
    Migrate(app, db)

    # Blueprints
    from routes.funding import funding_bp
    from routes.guardian import guardian_bp
    from routes.rules import rules_bp
    from routes.analytics import analytics_bp
    from routes.location import location_bp
    from routes.geofence import geofence_bp
    from routes.agentic import agentic_bp
    from routes.transaction_scoring import transaction_scoring_bp

    app.register_blueprint(agentic_bp, url_prefix="")
    app.register_blueprint(location_bp, url_prefix="")
    app.register_blueprint(geofence_bp, url_prefix="")
    app.register_blueprint(funding_bp, url_prefix="/funding")
    app.register_blueprint(guardian_bp, url_prefix="/guardian")
    app.register_blueprint(rules_bp)
    app.register_blueprint(analytics_bp, url_prefix="")
    app.register_blueprint(transaction_scoring_bp, url_prefix="")


    # debug token route already added earlier; keep /whoami too
    return app

app = create_app()