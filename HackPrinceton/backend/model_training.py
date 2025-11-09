import os
from pathlib import Path
import joblib
import pandas as pd
from sklearn.cluster import KMeans
from sklearn.compose import ColumnTransformer
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler


def main():
    base_dir = Path(__file__).resolve().parent
    data_path = base_dir / "data" / "transactions.csv"
    models_dir = base_dir / "models"
    models_dir.mkdir(parents=True, exist_ok=True)
    if not data_path.exists():
        raise FileNotFoundError(
            f"transactions.csv not found at {data_path}. "
            f"Run data_gen.py first from the project root."
        )
    print(f"Loading data from {data_path} ...")
    df = pd.read_csv(data_path, parse_dates=["timestamp"])
    print(f"Loaded {len(df)} rows")
    df["hour_of_day"] = df["timestamp"].dt.hour
    df["day_of_week"] = df["timestamp"].dt.dayofweek
    mask_g = df["base_category"] == "GROCERIES"
    groc_rows = df.loc[mask_g, ["amount", "hour_of_day", "day_of_week"]]
    kmeans = None
    if len(groc_rows) >= 3:
        print(f"Fitting KMeans on {len(groc_rows)} grocery rows ...")
        kmeans = KMeans(n_clusters=3, random_state=42)
        kmeans.fit(groc_rows)
        kmeans_path = models_dir / "kmeans_groceries.pkl"
        joblib.dump(kmeans, kmeans_path)
        print(f"Saved {kmeans_path}")
    else:
        print("Not enough grocery rows for KMeans; skipping micro-basket model.")
    df["micro_category"] = "NONE"
    if kmeans is not None:
        micro = kmeans.predict(df.loc[mask_g, ["amount", "hour_of_day", "day_of_week"]])
        df.loc[mask_g, "micro_category"] = micro.astype(str)
    feature_cols_num = ["amount", "hour_of_day", "day_of_week", "saver_score"]
    feature_cols_cat = ["base_category", "micro_category", "channel"]
    missing_cols = [c for c in feature_cols_num + feature_cols_cat if c not in df.columns]
    if missing_cols:
        raise ValueError(f"Missing expected columns in df: {missing_cols}")
    X = df[feature_cols_num + feature_cols_cat]
    if "label_avoidable" not in df.columns:
        raise ValueError("Column 'label_avoidable' not found in data.")
    y = df["label_avoidable"]
    print("Fitting logistic regression (guardian_pipeline) ...")
    numeric_transformer = StandardScaler()
    categorical_transformer = OneHotEncoder(handle_unknown="ignore")
    preprocess = ColumnTransformer(
        transformers=[
            ("num", numeric_transformer, feature_cols_num),
            ("cat", categorical_transformer, feature_cols_cat),
        ]
    )
    clf = LogisticRegression(max_iter=1000, class_weight="balanced")
    pipe = Pipeline(steps=[("preprocess", preprocess), ("model", clf)])
    pipe.fit(X, y)
    pipeline_path = models_dir / "guardian_pipeline.pkl"
    joblib.dump(pipe, pipeline_path)
    print(f"Saved {pipeline_path}")
    print("Done.")


if __name__ == "__main__":
    main()


