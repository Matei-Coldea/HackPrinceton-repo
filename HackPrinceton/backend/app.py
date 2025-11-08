import os
from flask import Flask
from flask_cors import CORS
from flask_migrate import Migrate
from models import db
from config import Config

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)
    CORS(app, resources={r"/*": {"origins": app.config["CORS_ORIGINS"]}})
    db.init_app(app)
    Migrate(app, db)

    from routes.auth import auth_bp
    from routes.funding import funding_bp
    from routes.guardian import guardian_bp
    from routes.issuing_webhook import issuing_bp
    app.register_blueprint(auth_bp, url_prefix="/auth")
    app.register_blueprint(funding_bp, url_prefix="/funding")
    app.register_blueprint(guardian_bp, url_prefix="/guardian")
    app.register_blueprint(issuing_bp, url_prefix="/webhooks")
    return app

app = create_app()

if __name__ == "__main__":
    app.run(port=8080, debug=True)
