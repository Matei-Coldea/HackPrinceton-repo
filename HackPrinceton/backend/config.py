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


# Transaction Scoring Configuration
CATEGORIES = [
    "RENT_BILLS",
    "GROCERIES",
    "FAST_FOOD",
    "ALCOHOL",
    "CLOTHING",
    "ELECTRONICS",
    "PHARMACY_HEALTH",
    "TRANSPORT",
    "SUBSCRIPTION",
    "MISC_ONLINE",
]

MERCHANTS = {
    "RENT_BILLS": ["LandlordCo", "UtilityBills", "PropManagement"],
    "GROCERIES": ["Whole Foods", "Trader Joe's", "Safeway", "Walmart", "Target"],
    "FAST_FOOD": ["McDonald's", "Starbucks", "Chipotle", "Subway", "Taco Bell", "Panera"],
    "ALCOHOL": ["Total Wine", "BevMo", "Local Liquor", "Wine Shop", "Bar & Grill"],
    "CLOTHING": ["Zara", "H&M", "Nike", "Adidas", "Gap", "Uniqlo", "Macy's"],
    "ELECTRONICS": ["Apple Store", "Best Buy", "Amazon Electronics", "Newegg", "B&H Photo"],
    "PHARMACY_HEALTH": ["CVS", "Walgreens", "Rite Aid", "GNC", "Vitamin Shoppe"],
    "TRANSPORT": ["Uber", "Lyft", "Gas Station", "Shell", "Chevron", "Metro Card"],
    "SUBSCRIPTION": ["Netflix", "Spotify", "Disney+", "Hulu", "YouTube Premium", "Amazon Prime"],
    "MISC_ONLINE": ["Amazon", "eBay", "Etsy", "AliExpress", "Shein"],
}

CATEGORY_MCC = {
    "RENT_BILLS": 6513,
    "GROCERIES": 5411,
    "FAST_FOOD": 5814,
    "ALCOHOL": 5921,
    "CLOTHING": 5651,
    "ELECTRONICS": 5732,
    "PHARMACY_HEALTH": 5912,
    "TRANSPORT": 4121,
    "SUBSCRIPTION": 4899,
    "MISC_ONLINE": 5999,
}

CATEGORY_BUDGET_RATIOS = {
    "RENT_BILLS": 0.30,
    "GROCERIES": 0.15,
    "FAST_FOOD": 0.05,
    "ALCOHOL": 0.03,
    "CLOTHING": 0.05,
    "ELECTRONICS": 0.08,
    "PHARMACY_HEALTH": 0.05,
    "TRANSPORT": 0.10,
    "SUBSCRIPTION": 0.03,
    "MISC_ONLINE": 0.05,
}

ESSENTIAL_CATEGORIES = {"RENT_BILLS", "GROCERIES", "PHARMACY_HEALTH", "TRANSPORT"}
WANTS_CATEGORIES = {"FAST_FOOD", "ALCOHOL", "CLOTHING", "ELECTRONICS", "MISC_ONLINE"}

SAVER_SCORE_MAP = {
    "Saver": 2,
    "Average": 1,
    "Spender": 0,
}

THRESHOLDS = {
    "Saver": 0.4,
    "Average": 0.6,
    "Spender": 0.75,
}

PROFILE_CATEGORY_WEIGHTS = {
    "Saver": {
        "RENT_BILLS": 0.25,
        "GROCERIES": 0.30,
        "FAST_FOOD": 0.05,
        "ALCOHOL": 0.02,
        "CLOTHING": 0.05,
        "ELECTRONICS": 0.03,
        "PHARMACY_HEALTH": 0.10,
        "TRANSPORT": 0.10,
        "SUBSCRIPTION": 0.05,
        "MISC_ONLINE": 0.05,
    },
    "Average": {
        "RENT_BILLS": 0.20,
        "GROCERIES": 0.20,
        "FAST_FOOD": 0.10,
        "ALCOHOL": 0.05,
        "CLOTHING": 0.10,
        "ELECTRONICS": 0.08,
        "PHARMACY_HEALTH": 0.07,
        "TRANSPORT": 0.10,
        "SUBSCRIPTION": 0.05,
        "MISC_ONLINE": 0.05,
    },
    "Spender": {
        "RENT_BILLS": 0.15,
        "GROCERIES": 0.15,
        "FAST_FOOD": 0.15,
        "ALCOHOL": 0.10,
        "CLOTHING": 0.15,
        "ELECTRONICS": 0.10,
        "PHARMACY_HEALTH": 0.03,
        "TRANSPORT": 0.07,
        "SUBSCRIPTION": 0.05,
        "MISC_ONLINE": 0.05,
    },
}

BASE_PROB_AVOIDABLE = {
    "RENT_BILLS": 0.05,
    "GROCERIES": 0.15,
    "FAST_FOOD": 0.75,
    "ALCOHOL": 0.80,
    "CLOTHING": 0.60,
    "ELECTRONICS": 0.70,
    "PHARMACY_HEALTH": 0.20,
    "TRANSPORT": 0.30,
    "SUBSCRIPTION": 0.40,
    "MISC_ONLINE": 0.65,
}

PROFILE_MULTIPLIER_AVOID = {
    "Saver": 0.7,
    "Average": 1.0,
    "Spender": 1.3,
}

OBLIGATION_CATEGORIES = {
    "RENT_BILLS": "mandatory",
    "HEALTH": "mandatory",
    "TRIP": "optional",
    "CLOTHING": "optional",
    "ENTERTAINMENT": "optional",
    "GIFT": "optional",
}

SAFETY_BUFFER_RATIO = 0.10
SAVINGS_GOAL_RATIO = 0.15
BASELINE_ESSENTIALS_RATIO = 0.30
