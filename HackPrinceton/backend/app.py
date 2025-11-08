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
    app.register_blueprint(funding_bp, url_prefix="/funding")
    app.register_blueprint(guardian_bp, url_prefix="/guardian")
    app.register_blueprint(rules_bp)
    app.register_blueprint(analytics_bp, url_prefix="")


    # debug token route already added earlier; keep /whoami too
    return app

app = create_app()