from datetime import datetime, timedelta
from typing import Dict, Any, List, Optional
import pandas as pd
from pathlib import Path
import sys

config_path = Path(__file__).parent.parent.parent
sys.path.insert(0, str(config_path))
from config import (
    SAFETY_BUFFER_RATIO,
    SAVINGS_GOAL_RATIO,
    BASELINE_ESSENTIALS_RATIO,
)

from .obligations_quantum import quantum_select_optional_events

DATA_DIR = Path(__file__).parent.parent.parent / "data"


def load_obligations_for_user(user_id: str, 
                              start_date: datetime,
                              end_date: datetime) -> pd.DataFrame:
    csv_path = DATA_DIR / "obligations.csv"
    
    if not csv_path.exists():
        return pd.DataFrame()
    
    df = pd.read_csv(
        csv_path,
        parse_dates=["due_date", "min_pay_date", "max_pay_date"]
    )
    
    df = df[df["user_id"] == user_id]
    df = df[(df["due_date"] >= start_date) & (df["due_date"] <= end_date)]
    
    return df


def split_mandatory_optional(obligations_df: pd.DataFrame) -> tuple:
    mandatory = obligations_df[obligations_df["mandatory"] == 1]
    optional = obligations_df[obligations_df["mandatory"] == 0]
    return mandatory, optional


def compute_obligations_summary(
    user_id: str,
    today: datetime,
    income_remaining: float,
    baseline_essentials: float,
    savings_goal: float,
    safety_buffer: float,
    horizon_days: int = 30,
) -> Dict[str, Any]:
    horizon_end = today + timedelta(days=horizon_days)
    obligations_df = load_obligations_for_user(user_id, today, horizon_end)
    
    if obligations_df.empty:
        return {
            "mandatory_needed": 0.0,
            "optional_chosen_needed": 0.0,
            "reserved_obligations": 0.0,
            "free_to_spend": max(
                0.0,
                income_remaining - baseline_essentials - savings_goal - safety_buffer
            ),
            "chosen_optional_ids": [],
            "all_obligations": [],
        }
    
    mandatory_df, optional_df = split_mandatory_optional(obligations_df)
    mandatory_needed = float(mandatory_df["amount"].sum())
    
    budget_for_optional = max(
        0.0,
        income_remaining - mandatory_needed - baseline_essentials - savings_goal - safety_buffer
    )
    
    optional_events = []
    for _, row in optional_df.iterrows():
        optional_events.append({
            "event_id": row["event_id"],
            "name": row["name"],
            "amount": float(row["amount"]),
            "importance": float(row["importance"]),
            "due_date": row["due_date"],
        })
    
    chosen_optional = quantum_select_optional_events(optional_events, budget_for_optional)
    optional_chosen_needed = sum(ev["amount"] for ev in chosen_optional)
    reserved_obligations = mandatory_needed + optional_chosen_needed
    
    free_to_spend = max(
        0.0,
        income_remaining - reserved_obligations - baseline_essentials - savings_goal - safety_buffer
    )
    
    all_obligations = []
    for _, row in obligations_df.iterrows():
        all_obligations.append({
            "event_id": row["event_id"],
            "name": row["name"],
            "category": row["category"],
            "amount": float(row["amount"]),
            "due_date": row["due_date"].isoformat() if pd.notna(row["due_date"]) else None,
            "mandatory": bool(row["mandatory"]),
            "importance": float(row["importance"]),
            "selected": row["event_id"] in [ev["event_id"] for ev in chosen_optional] or bool(row["mandatory"]),
        })
    
    return {
        "mandatory_needed": mandatory_needed,
        "optional_chosen_needed": optional_chosen_needed,
        "reserved_obligations": reserved_obligations,
        "free_to_spend": free_to_spend,
        "chosen_optional_ids": [ev["event_id"] for ev in chosen_optional],
        "all_obligations": all_obligations,
    }


def compute_obligations_for_transaction_scoring(
    user_id: str,
    monthly_income: float,
    discretionary_spent_so_far: float,
) -> Dict[str, Any]:
    today = datetime.utcnow()
    
    baseline_essentials = monthly_income * BASELINE_ESSENTIALS_RATIO
    savings_goal = monthly_income * SAVINGS_GOAL_RATIO
    safety_buffer = monthly_income * SAFETY_BUFFER_RATIO
    income_remaining = monthly_income
    
    summary = compute_obligations_summary(
        user_id=user_id,
        today=today,
        income_remaining=income_remaining,
        baseline_essentials=baseline_essentials,
        savings_goal=savings_goal,
        safety_buffer=safety_buffer,
    )
    
    safe_left = summary["free_to_spend"] - discretionary_spent_so_far
    summary["safe_left"] = max(0.0, safe_left)
    
    return summary


_obligations_cache: Dict[str, tuple] = {}


def get_cached_obligations_summary(
    user_id: str,
    monthly_income: float,
    discretionary_spent_so_far: float,
) -> Dict[str, Any]:
    today = datetime.utcnow().date()
    
    if user_id in _obligations_cache:
        cached_date, cached_summary = _obligations_cache[user_id]
        if cached_date == today:
            cached_summary["safe_left"] = max(
                0.0,
                cached_summary["free_to_spend"] - discretionary_spent_so_far
            )
            return cached_summary
    
    summary = compute_obligations_for_transaction_scoring(
        user_id, monthly_income, discretionary_spent_so_far
    )
    
    _obligations_cache[user_id] = (today, summary)
    
    return summary

