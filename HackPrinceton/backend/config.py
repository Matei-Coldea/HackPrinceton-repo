import os
class Config:
    SQLALCHEMY_DATABASE_URI = os.environ.get("DATABASE_URL", "sqlite:///guardian.db")
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SUPABASE_PROJECT_URL = os.environ.get("SUPABASE_PROJECT_URL", "")
    SUPABASE_JWKS_URL = os.environ.get("SUPABASE_JWKS_URL", "")
    SUPABASE_JWT_AUDIENCE = os.environ.get("SUPABASE_JWT_AUDIENCE", "supabase")
    SUPABASE_JWT_ISSUER = os.environ.get("SUPABASE_JWT_ISSUER", "")
    SUPABASE_JWT_SECRET = os.environ.get("SUPABASE_JWT_SECRET")
    STRIPE_SECRET_KEY = os.environ.get("STRIPE_SECRET_KEY", "")
    PAYMENTS_PROVIDER = os.getenv("PAYMENTS_PROVIDER", "mock")
    #STRIPE_WEBHOOK_SECRET = os.environ.get("STRIPE_WEBHOOK_SECRET", "")
    CORS_ORIGINS = os.environ.get("CORS_ORIGINS", "*")
