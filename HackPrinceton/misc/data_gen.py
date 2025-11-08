import os
import random
from datetime import datetime, timedelta
import numpy as np
import pandas as pd
from config import (
    CATEGORIES,
    MERCHANTS,
    CATEGORY_MCC,
    CATEGORY_BUDGET_RATIOS,
    PROFILE_CATEGORY_WEIGHTS,
    BASE_PROB_AVOIDABLE,
    PROFILE_MULTIPLIER_AVOID,
    SAVER_SCORE_MAP,
)

random.seed(42)
np.random.seed(42)

USERS = [
    {"user_id": "u1", "profile_type": "Saver", "monthly_income": 2000},
    {"user_id": "u2", "profile_type": "Average", "monthly_income": 3000},
    {"user_id": "u3", "profile_type": "Spender", "monthly_income": 4500},
]


def sample_category(profile_type: str) -> str:
    cats = list(CATEGORIES)
    weights = [PROFILE_CATEGORY_WEIGHTS[profile_type][c] for c in cats]
    return random.choices(cats, weights=weights, k=1)[0]


def sample_amount(cat: str) -> float:
    if cat == "RENT_BILLS":
        mu, sigma = 1200, 80
    elif cat == "GROCERIES":
        mu, sigma = 60, 25
    elif cat == "FAST_FOOD":
        mu, sigma = 15, 5
    elif cat == "ALCOHOL":
        mu, sigma = 25, 10
    elif cat == "CLOTHING":
        mu, sigma = 70, 30
    elif cat == "ELECTRONICS":
        mu, sigma = 200, 150
    elif cat == "PHARMACY_HEALTH":
        mu, sigma = 30, 15
    elif cat == "TRANSPORT":
        mu, sigma = 25, 15
    elif cat == "SUBSCRIPTION":
        mu, sigma = 20, 5
    else:
        mu, sigma = 40, 25
    amt = max(5, np.random.normal(mu, sigma))
    return round(float(amt), 2)


def main():
    os.makedirs("data", exist_ok=True)
    start_date = datetime(2025, 1, 1)
    days = 60
    rows = []
    for user in USERS:
        user_id = user["user_id"]
        profile_type = user["profile_type"]
        income = user["monthly_income"]
        saver_score = SAVER_SCORE_MAP[profile_type]
        for day_offset in range(days):
            date = start_date + timedelta(days=day_offset)
            num_tx = np.random.poisson(3)
            for _ in range(num_tx):
                cat = sample_category(profile_type)
                merchant = random.choice(MERCHANTS[cat])
                amount = sample_amount(cat)
                hour = random.randint(8, 22)
                minute = random.randint(0, 59)
                ts = date.replace(hour=hour, minute=minute, second=0, microsecond=0)
                channel = random.choice(["online", "offline"])
                mcc = CATEGORY_MCC[cat]
                base_p = BASE_PROB_AVOIDABLE[cat]
                p = min(0.95, base_p * PROFILE_MULTIPLIER_AVOID[profile_type])
                if cat in {"ELECTRONICS", "CLOTHING", "MISC_ONLINE"} and amount > 0.2 * income:
                    p = min(0.95, p + 0.25)
                label_avoidable = 1 if random.random() < p else 0
                rows.append(
                    {
                        "user_id": user_id,
                        "profile_type": profile_type,
                        "monthly_income": income,
                        "saver_score": saver_score,
                        "timestamp": ts.isoformat(),
                        "merchant_name": merchant,
                        "mcc": mcc,
                        "amount": amount,
                        "channel": channel,
                        "base_category": cat,
                        "label_avoidable": label_avoidable,
                    }
                )
    df = pd.DataFrame(rows)
    df["timestamp"] = pd.to_datetime(df["timestamp"])
    df.to_csv("data/transactions.csv", index=False)
    print("Wrote", len(df), "rows to data/transactions.csv")


if __name__ == "__main__":
    main()
