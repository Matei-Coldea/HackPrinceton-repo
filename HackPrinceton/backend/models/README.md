# ML Models Directory

This directory stores trained machine learning models for the Guardian Card transaction scoring system.

## Models

### 1. `guardian_pipeline.pkl`

**Purpose:** Main transaction scoring model

**Type:** Scikit-learn Pipeline containing:
- Preprocessing (StandardScaler + OneHotEncoder)
- Logistic Regression classifier

**Input Features:**
- `amount`: Transaction amount (numeric)
- `hour_of_day`: Hour of transaction (0-23)
- `day_of_week`: Day of week (0-6)
- `saver_score`: User profile score (0-2)
- `base_category`: Transaction category (categorical)
- `micro_category`: Sub-category for groceries (categorical)
- `channel`: Transaction channel (online/offline)

**Output:**
- Probability that a transaction is "avoidable" (0-1)

**Training:**
To train this model, run:
```bash
cd backend
python model_training.py
```

### 2. `kmeans_groceries.pkl`

**Purpose:** Grocery transaction clustering

**Type:** KMeans clustering model (3 clusters)

**Input Features:**
- `amount`: Purchase amount
- `hour_of_day`: Hour of purchase
- `day_of_week`: Day of week

**Output:**
- Cluster ID (0, 1, or 2) representing micro-categories:
  - Small quick purchases (snacks, coffee)
  - Medium regular shopping
  - Large bulk shopping

**Usage:**
Used to create micro-categories for grocery purchases, helping distinguish between essential bulk shopping and impulse snack purchases.

## Training Data

Models are trained on synthetic data generated from `data/transactions.csv`.

**Required Columns in training data:**
- `timestamp`: Transaction timestamp
- `amount`: Amount in dollars
- `merchant_name`: Merchant name
- `mcc`: Merchant Category Code
- `user_id`: User identifier
- `base_category`: Main category
- `channel`: online/offline
- `saver_score`: User profile score
- `label_avoidable`: Training label (0 or 1)

## How to Train Models

### Prerequisites

1. Generate training data:
```bash
cd backend
python misc/data_gen.py  # If available
```

2. Ensure `data/transactions.csv` exists with proper structure

### Training Process

```bash
cd backend
python model_training.py
```

This will:
1. Load `data/transactions.csv`
2. Train KMeans on grocery transactions
3. Train logistic regression pipeline
4. Save both models to `models/` directory

### Expected Output

```
Loading data from /path/to/data/transactions.csv ...
Loaded 1000 rows
Fitting KMeans on 234 grocery rows ...
Saved /path/to/models/kmeans_groceries.pkl
Fitting logistic regression (guardian_pipeline) ...
Saved /path/to/models/guardian_pipeline.pkl
Done.
```

## Model Performance

The models use:
- **Balanced class weights** to handle imbalanced data
- **Pipeline architecture** for consistent preprocessing
- **Unknown category handling** for new merchants/categories

## Fallback Behavior

If models are not found:
- Transaction scoring still works but uses simpler rules
- `score_transaction` returns `p_ml = 0.5` as fallback
- Obligations planner and budget logic still apply

## Updating Models

To retrain with new data:

1. Append new transactions to `data/transactions.csv`
2. Run `python model_training.py`
3. Models are automatically reloaded on next API request

## File Size

- `guardian_pipeline.pkl`: ~50-100 KB
- `kmeans_groceries.pkl`: ~5-10 KB

## Git Ignore

These files should be in `.gitignore` as they:
- Are binary files
- Can be regenerated from training data
- May be large depending on model complexity

## Production Considerations

For production:
1. Train on real transaction data, not synthetic
2. Retrain periodically (monthly) with new data
3. Version models with timestamps
4. Monitor model performance metrics
5. Consider A/B testing before deploying new models

## Model Versioning

For production, consider:
```
models/
├── guardian_pipeline_v1.pkl
├── guardian_pipeline_v2.pkl
├── guardian_pipeline_current.pkl -> guardian_pipeline_v2.pkl
└── README.md
```

## Debugging

If models aren't loading:

```python
import joblib
from pathlib import Path

# Check if file exists
model_path = Path(__file__).parent / "guardian_pipeline.pkl"
print(f"Model exists: {model_path.exists()}")

# Try loading
try:
    model = joblib.load(model_path)
    print(f"Model loaded: {type(model)}")
except Exception as e:
    print(f"Error loading model: {e}")
```

## Dependencies

Required packages:
- `scikit-learn>=1.0.0`
- `joblib>=1.0.0`
- `pandas>=1.3.0`
- `numpy>=1.20.0`


