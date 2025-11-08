# Data Flow & Model Explanation

## 🎯 Complete Data Flow

```
Transaction Request
       │
       ├─ user_id: "u1"
       ├─ amount: 100
       ├─ merchant_name: "Chipotle"
       ├─ timestamp: "2025-11-09T19:30:00"
       └─ channel: "offline"
       │
       ▼
┌──────────────────────────────────────────────────────────────┐
│                   TRANSACTION SCORER                          │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  STEP 1: Load User Profile                                   │
│  ────────────────────────────                                │
│  FROM: data/user_profiles.csv                                │
│  ┌────────────────────────────────────────┐                 │
│  │ user_id,profile_type,monthly_income     │                 │
│  │ u1,Saver,2000                           │                 │
│  └────────────────────────────────────────┘                 │
│  → profile_type = "Saver"                                    │
│  → monthly_income = 2000                                     │
│  → saver_score = 2 (from config.py)                         │
│  → threshold = 0.4 (Savers block at p_avoid >= 0.4)         │
│                                                               │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  STEP 2: Extract Features from Transaction                   │
│  ──────────────────────────────────────                      │
│  Parse timestamp: "2025-11-09T19:30:00"                      │
│    → hour_of_day = 19                                        │
│    → day_of_week = 6 (Saturday)                              │
│                                                               │
│  Map merchant to category: "Chipotle"                        │
│    → base_category = "FAST_FOOD"                             │
│    → category_type = "WANTS" (discretionary)                 │
│                                                               │
│  Apply KMeans for groceries (if applicable):                 │
│    → micro_category = "NONE" (not groceries)                 │
│                                                               │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  STEP 3: ML Model Prediction (UNCHANGED)                     │
│  ──────────────────────────────────────                      │
│  INPUT FEATURES:                                             │
│  ┌────────────────────────────────────────┐                 │
│  │ amount:         100                     │                 │
│  │ hour_of_day:    19                      │                 │
│  │ day_of_week:    6                       │                 │
│  │ saver_score:    2                       │                 │
│  │ base_category:  "FAST_FOOD"             │                 │
│  │ micro_category: "NONE"                  │                 │
│  │ channel:        "offline"               │                 │
│  └────────────────────────────────────────┘                 │
│                                                               │
│  MODEL: Logistic Regression (guardian_pipeline.pkl)          │
│  OUTPUT: p_ml = 0.78 (78% chance avoidable)                  │
│                                                               │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  STEP 4: Quantum Obligations Layer (NEW!)                    │
│  ─────────────────────────────────────                       │
│  Call: get_cached_obligations_summary()                      │
│                                                               │
│  ┌─────────────────────────────────────────────────┐        │
│  │  A. Load Obligations from CSV                    │        │
│  │  ────────────────────────────────                │        │
│  │  FROM: data/obligations.csv                      │        │
│  │                                                   │        │
│  │  Filter by:                                      │        │
│  │    - user_id = "u1"                              │        │
│  │    - due_date >= today (2025-11-08)             │        │
│  │    - due_date <= today + 30 days                │        │
│  │                                                   │        │
│  │  Result:                                         │        │
│  │  ┌───────────────────────────────────────────┐  │        │
│  │  │ e1: November Rent    $1200  mandatory    │  │        │
│  │  │ e4: Dental           $ 300  mandatory    │  │        │
│  │  │ e6: December Rent    $1200  mandatory    │  │        │
│  │  │ e2: Birthday Gift    $  80  optional     │  │        │
│  │  └───────────────────────────────────────────┘  │        │
│  └─────────────────────────────────────────────────┘        │
│                                                               │
│  ┌─────────────────────────────────────────────────┐        │
│  │  B. Split Mandatory vs Optional                  │        │
│  │  ───────────────────────────────                 │        │
│  │  Mandatory: e1 + e4 + e6 = $2,700               │        │
│  │  Optional:  e2 = $80                             │        │
│  └─────────────────────────────────────────────────┘        │
│                                                               │
│  ┌─────────────────────────────────────────────────┐        │
│  │  C. Calculate Budget for Optional                │        │
│  │  ────────────────────────────────                │        │
│  │  income_remaining = $2,000                       │        │
│  │  - mandatory_needed = $2,700                     │        │
│  │  - baseline_essentials = $600 (30% of income)   │        │
│  │  - savings_goal = $300 (15% of income)          │        │
│  │  - safety_buffer = $200 (10% of income)         │        │
│  │  ──────────────────────────────────              │        │
│  │  budget_for_optional = $2000 - $2700 - $600     │        │
│  │                        - $300 - $200             │        │
│  │                      = -$1,800 (NEGATIVE!)       │        │
│  │                      → Use $0                    │        │
│  └─────────────────────────────────────────────────┘        │
│                                                               │
│  ┌─────────────────────────────────────────────────┐        │
│  │  D. Quantum Knapsack Solver                      │        │
│  │  ───────────────────────────                     │        │
│  │  INPUT:                                          │        │
│  │    optional_events = [                           │        │
│  │      {id: "e2", amount: 80, importance: 3}      │        │
│  │    ]                                             │        │
│  │    budget = $0                                   │        │
│  │                                                   │        │
│  │  ALGORITHM: QAOA (or classical greedy fallback)  │        │
│  │                                                   │        │
│  │  Problem: maximize importance                    │        │
│  │           subject to: cost <= budget             │        │
│  │                                                   │        │
│  │  QUBO Form:                                      │        │
│  │    H = -Σ(importance_i * x_i)                   │        │
│  │        + λ(Σ(cost_i * x_i) - budget)²          │        │
│  │                                                   │        │
│  │  OUTPUT:                                         │        │
│  │    chosen_optional = [] (nothing fits budget)   │        │
│  │    optional_chosen_needed = $0                   │        │
│  └─────────────────────────────────────────────────┘        │
│                                                               │
│  ┌─────────────────────────────────────────────────┐        │
│  │  E. Calculate Free-to-Spend                      │        │
│  │  ──────────────────────────                      │        │
│  │  reserved_obligations = mandatory_needed         │        │
│  │                        + optional_chosen_needed  │        │
│  │                       = $2,700 + $0 = $2,700    │        │
│  │                                                   │        │
│  │  free_to_spend = income - reserved - essentials │        │
│  │                  - savings - buffer              │        │
│  │                = $2000 - $2700 - $600           │        │
│  │                  - $300 - $200                   │        │
│  │                = -$1,800 → Use $0                │        │
│  │                                                   │        │
│  │  discretionary_spent_so_far = $0 (from tracker) │        │
│  │                                                   │        │
│  │  safe_left = free_to_spend                       │        │
│  │              - discretionary_spent_so_far        │        │
│  │            = $0 - $0 = $0                        │        │
│  └─────────────────────────────────────────────────┘        │
│                                                               │
│  RESULT:                                                     │
│    obligations_reserved: $2,700                              │
│    free_to_spend: $0                                         │
│    safe_left: $0                                             │
│                                                               │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  STEP 5: Apply Obligations Rules                             │
│  ────────────────────────────                                │
│  Is this a WANTS category? YES (FAST_FOOD)                   │
│  Is safe_left <= 0? YES ($0 <= $0)                          │
│                                                               │
│  → TRIGGER OBLIGATIONS BLOCKING                              │
│  → Boost p_avoid from 0.78 to 0.98                          │
│  → Update reason with obligations info                       │
│                                                               │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  STEP 6: Apply Existing Budget Rules                         │
│  ─────────────────────────────                               │
│  (Only if obligations didn't trigger)                        │
│  - Check category budget ratio                               │
│  - Apply essential category exceptions                       │
│                                                               │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  STEP 7: Make Final Decision                                 │
│  ────────────────────────                                    │
│  p_avoid = 0.98                                              │
│  threshold = 0.4 (Saver)                                     │
│  0.98 >= 0.4? YES                                            │
│                                                               │
│  DECISION: BLOCK                                             │
│  REASON: "This purchase would use money reserved             │
│           for upcoming obligations ($2700 needed             │
│           for rent/trips/bills). You have $0                 │
│           safely available."                                 │
│                                                               │
└──────────────────────────────────────────────────────────────┘
       │
       ▼
API Response
{
  "decision": "BLOCK",
  "p_avoid": 0.98,
  "reason": "Money reserved for obligations...",
  "debug": {
    "p_ml": 0.78,
    "obligations_reserved": 2700.0,
    "obligations_free_to_spend": 0.0,
    "obligations_safe_left": 0.0,
    "obligations_triggered": true,
    "threshold": 0.4
  }
}
```

---

## 📋 Data Sources

### 1. Transaction Data (Your Input)
**What you provide in each API call:**
- `user_id` - Which user is making the transaction
- `amount` - How much they want to spend
- `merchant_name` - Where they're spending
- `timestamp` - When they're spending
- `channel` - Online or offline
- `mcc` - (optional) Merchant category code

### 2. User Profiles (CSV)
**File:** `data/user_profiles.csv`
```csv
user_id,profile_type,monthly_income
u1,Saver,2000
u2,Average,3000
u3,Spender,4500
```

**What it provides:**
- Profile type (Saver/Average/Spender)
- Monthly income (for budget calculations)

### 3. Obligations Data (CSV) 
**File:** `data/obligations.csv`
```csv
user_id,event_id,name,category,amount,due_date,mandatory,importance
u1,e1,November Rent,RENT_BILLS,1200,2025-11-15,1,5
u1,e2,Birthday Gift,CLOTHING,80,2025-11-20,0,3
```

**What it provides:**
- Upcoming financial obligations
- Mandatory vs optional classification
- Importance scores for quantum optimization

### 4. ML Models (Pre-trained)
**Files:** 
- `models/guardian_pipeline.pkl` - Logistic regression
- `models/kmeans_groceries.pkl` - Grocery clustering

**What they do:**
- Predict probability transaction is avoidable
- Cluster grocery purchases into micro-categories

### 5. Configuration (Python)
**File:** `config.py`
```python
CATEGORY_BUDGET_RATIOS = {
    "FAST_FOOD": 0.05,  # 5% of income
    "GROCERIES": 0.15,  # 15% of income
    # ...
}

THRESHOLDS = {
    "Saver": 0.4,      # Block if p_avoid >= 0.4
    "Average": 0.6,
    "Spender": 0.75
}
```

---

## 🧠 What Each Model Does

### Model 1: Logistic Regression (Existing, Unchanged)
**Input:** Transaction features
```python
{
  "amount": 100,
  "hour_of_day": 19,
  "day_of_week": 6,
  "saver_score": 2,
  "base_category": "FAST_FOOD",
  "micro_category": "NONE",
  "channel": "offline"
}
```

**Output:** Probability this transaction is avoidable
```python
p_ml = 0.78  # 78% likely to be avoidable impulse purchase
```

**How it was trained:** On historical transaction data with labels indicating which transactions were avoidable

---

### Model 2: KMeans Clustering (Existing, Unchanged)
**Only for groceries!**

**Input:** Grocery transaction details
```python
[amount, hour_of_day, day_of_week]
[60, 18, 5]  # $60 at 6pm on Friday
```

**Output:** Cluster ID (micro-category)
```python
micro_category = "2"  # Could mean "weekend bulk shopping"
```

**Purpose:** Helps distinguish between:
- Quick essential runs
- Bulk shopping trips
- Impulse snack purchases

---

### Model 3: Quantum Knapsack Solver (NEW!)
**Input:** Optional obligations and budget
```python
optional_events = [
    {"event_id": "e2", "amount": 80, "importance": 3},
    {"event_id": "e3", "amount": 400, "importance": 4},
    {"event_id": "e5", "amount": 150, "importance": 3}
]
budget = 500
```

**Algorithm:** QAOA (Quantum Approximate Optimization Algorithm)
- Formulates as QUBO (Quadratic Unconstrained Binary Optimization)
- Solves: Which obligations to fund to maximize importance while staying within budget
- Uses classical greedy fallback if Qiskit not installed

**Output:** Selected obligations
```python
chosen = [
    {"event_id": "e3", "amount": 400, "importance": 4},  # Ski trip
    {"event_id": "e2", "amount": 80, "importance": 3}    # Gift
]
# Total: $480 ≤ $500 budget ✓
# Total importance: 7 (maximized)
```

---

## 🔄 Integration: How Models Work Together

### Without Quantum (Old Way)
```
Transaction → ML Model → p_avoid → Compare to threshold → BLOCK/ALLOW
```

### With Quantum (New Way)
```
Transaction → ML Model → p_avoid (base)
              ↓
         Quantum Optimizer
         (obligations planning)
              ↓
         If obligations at risk:
           Boost p_avoid to 0.98
              ↓
         Compare to threshold → BLOCK/ALLOW
```

**Key Point:** Quantum doesn't replace ML—it **enhances** it by adding obligation-awareness!

---

## 💡 Example Scenarios

### Scenario 1: User with Tight Obligations
```
Input Transaction: $100 fast food
User u1: Income $2000, Obligations $2700

Flow:
1. ML predicts: 78% avoidable
2. Quantum finds: $0 safe to spend (obligations = $2700)
3. Obligations triggered: Boost to 98% avoidable
4. Decision: BLOCK
5. Reason: "Money reserved for rent/dental"
```

### Scenario 2: User with Budget Room
```
Input Transaction: $100 fast food
User u3: Income $4500, Obligations $2500

Flow:
1. ML predicts: 50% avoidable
2. Quantum finds: $725 safe to spend
3. Transaction $100 < 50% of $725 → OK
4. No obligations boost needed
5. Decision: ALLOW (50% < 75% spender threshold)
```

### Scenario 3: Essential Purchase
```
Input Transaction: $50 groceries
User u1: Income $2000, Obligations $2700

Flow:
1. ML predicts: 30% avoidable
2. Category = ESSENTIAL → Reduce to 15%
3. Even with obligations, essentials allowed
4. Decision: ALLOW
5. Reason: "Essential recurring expense"
```

---

## 🎯 Summary: What You Need to Know

### Data You Input (API Call)
✅ Transaction details (user, amount, merchant, time)

### Data Already in System
✅ User profiles (CSV)
✅ Obligations (CSV)
✅ ML models (pre-trained .pkl files)
✅ Configuration (config.py)

### What Models Do
1. **Logistic Regression:** Predicts avoidability from transaction features
2. **KMeans:** Clusters grocery purchases into micro-categories
3. **Quantum Knapsack:** Optimally selects which obligations to fund

### How They Work Together
- ML gives base prediction
- Quantum adds obligation-awareness
- Combined decision considers both
- User gets clear explanation

### The Magic
🌟 **Quantum solver runs automatically behind the scenes**
🌟 **No extra input needed from you**
🌟 **Just send transaction, get smart decision**
🌟 **System knows about upcoming rent, trips, bills**

---

Does this clarify how the data flows and what each model does? The beauty is that you just send a simple transaction request, and the system automatically:
1. Loads the user's profile
2. Runs ML prediction
3. Checks their obligations
4. Uses quantum optimization to plan their budget
5. Makes an intelligent BLOCK/ALLOW decision

