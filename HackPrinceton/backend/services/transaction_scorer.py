"""
Transaction Scoring Service

Handles all logic for scoring transactions and determining if they should be blocked.
"""

from datetime import datetime
from typing import Dict
import csv
import joblib
import pandas as pd
from pathlib import Path
import sys

sys.path.append(str(Path(__file__).parent.parent.parent))
from config import (
    MERCHANTS,
    CATEGORY_MCC,
    CATEGORY_BUDGET_RATIOS,
    WANTS_CATEGORIES,
    ESSENTIAL_CATEGORIES,
    SAVER_SCORE_MAP,
    THRESHOLDS,
)
from ..models import TransactionIn, ScoreResponse


# ================================
#  LOAD MODELS
# ================================

base_dir = Path(__file__).parent.parent.parent
pipeline = joblib.load(base_dir / "models" / "guardian_pipeline.pkl")

try:
    kmeans_groc = joblib.load(base_dir / "models" / "kmeans_groceries.pkl")
except FileNotFoundError:
    kmeans_groc = None


# ================================
#  LOAD MOCK DATA FROM CSV
# ================================

def _load_user_profiles():
    """Load user profiles from CSV file"""
    profiles = {}
    csv_path = base_dir / "data" / "user_profiles.csv"
    
    if not csv_path.exists():
        # Return default profiles if CSV doesn't exist
        return {
            "u1": {"profile_type": "Saver", "monthly_income": 2000},
            "u2": {"profile_type": "Average", "monthly_income": 3000},
            "u3": {"profile_type": "Spender", "monthly_income": 4500},
        }
    
    with open(csv_path, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            profiles[row['user_id']] = {
                "profile_type": row['profile_type'],
                "monthly_income": float(row['monthly_income']),
            }
    return profiles


# ================================
#  STATE MANAGEMENT
# ================================

# Build merchant category map
MERCHANT_CATEGORY_MAP: Dict[str, str] = {}
for cat, merchants in MERCHANTS.items():
    for m in merchants:
        MERCHANT_CATEGORY_MAP[m] = cat

# Load user profiles from CSV
USER_PROFILES: Dict[str, Dict[str, float]] = _load_user_profiles()

USER_MONTHLY_SPEND: Dict[str, Dict[str, float]] = {
    uid: {} for uid in USER_PROFILES.keys()
}


# ================================
#  HELPER FUNCTIONS
# ================================

def get_base_category(merchant_name: str, mcc: int) -> str:
    """Determine the base category from merchant name or MCC code."""
    if merchant_name in MERCHANT_CATEGORY_MAP:
        return MERCHANT_CATEGORY_MAP[merchant_name]
    for cat, cmcc in CATEGORY_MCC.items():
        if cmcc == mcc:
            return cat
    return "MISC_ONLINE"


# ================================
#  MAIN SCORING FUNCTION
# ================================

def score_transaction(t: TransactionIn) -> ScoreResponse:
    """
    Score a transaction and determine if it should be blocked.
    
    Args:
        t: TransactionIn object with transaction details
        
    Returns:
        ScoreResponse with decision, probability, reason, and debug info
    """
    # Ensure user exists in profiles
    if t.user_id not in USER_PROFILES:
        USER_PROFILES[t.user_id] = {"profile_type": "Average", "monthly_income": 3000}
        USER_MONTHLY_SPEND[t.user_id] = {}
    
    # Get user profile
    profile = USER_PROFILES[t.user_id]
    profile_type = profile["profile_type"]
    income = profile["monthly_income"]
    saver_score = SAVER_SCORE_MAP.get(profile_type, 1)
    
    # Parse timestamp
    dt = datetime.fromisoformat(t.timestamp)
    hour = dt.hour
    day_of_week = dt.weekday()
    
    # Determine category
    base_category = get_base_category(t.merchant_name, t.mcc or 0)
    micro_category = "NONE"
    
    # Apply KMeans clustering for groceries
    if base_category == "GROCERIES" and kmeans_groc is not None:
        Xg = [[t.amount, hour, day_of_week]]
        cluster = kmeans_groc.predict(Xg)[0]
        micro_category = str(cluster)
    
    # Calculate budget ratios
    ratio = CATEGORY_BUDGET_RATIOS.get(base_category, 0.1)
    budget_cat = income * ratio
    user_spend = USER_MONTHLY_SPEND.setdefault(t.user_id, {})
    spend_before = user_spend.get(base_category, 0.0)
    spend_after = spend_before + t.amount
    over_budget_ratio = (spend_after / budget_cat) if budget_cat > 0 else 0.0
    
    # Prepare features for ML model
    row = {
        "amount": t.amount,
        "hour_of_day": hour,
        "day_of_week": day_of_week,
        "saver_score": saver_score,
        "base_category": base_category,
        "micro_category": micro_category,
        "channel": t.channel,
    }
    X = pd.DataFrame([row])
    
    # Get ML prediction
    p_ml = float(pipeline.predict_proba(X)[0, 1])
    p_avoid = p_ml
    reason = "Model thinks this might be avoidable."
    
    # Apply budget-based rules
    if over_budget_ratio > 1.0 and base_category in WANTS_CATEGORIES:
        p_avoid = max(p_avoid, min(0.9 + 0.1 * (over_budget_ratio - 1.0), 0.99))
        reason = (
            f"You've already spent {spend_before:.0f} in {base_category} this month. "
            f"This {t.amount:.0f} purchase will push you to "
            f"{over_budget_ratio * 100:.0f}% of your {base_category} budget."
        )
    
    # Exception for essential categories
    if base_category in ESSENTIAL_CATEGORIES and over_budget_ratio <= 1.3:
        p_avoid *= 0.5
        reason = "This looks like an essential recurring expense."
    
    # Make decision based on threshold
    threshold = THRESHOLDS.get(profile_type, 0.6)
    decision = "BLOCK" if p_avoid >= threshold else "ALLOW"
    
    # Update spending
    user_spend[base_category] = spend_after
    
    # Prepare debug info
    debug = {
        "p_ml": p_ml,
        "over_budget_ratio": over_budget_ratio,
        "threshold": threshold,
        "spend_before": spend_before,
        "spend_after": spend_after,
    }
    
    return ScoreResponse(
        decision=decision,
        p_avoid=p_avoid,
        reason=reason,
        debug=debug,
    )

