Here’s a spec you can literally copy-paste into another LLM and say “implement this backend.”
I’ll write it as an instruction doc for the LLM.

---

### Prompt to give another LLM

You are implementing the backend of a **“Guardian Card”** system in **Python + Flask**.

High-level idea:

* Each user has a hidden **Guardian virtual card** (issued via Stripe Issuing or similar).
* Users link **funding sources** (cards/bank accounts) in the app.
* Every time a Guardian transaction happens, the backend:

  * Runs **budget / psychology rules** to decide if the purchase is safe.
  * Can **decline** and require an explicit **override**.
  * If approved, it **charges the chosen funding source** via Stripe.
* On iOS, the Guardian card also lives in **Apple Wallet**, so Stripe Issuing webhooks for authorizations will call into this backend.

You will build the **backend skeleton** with models, endpoints, and services, so it’s easy to extend later.

Implement everything below as production-ish, idiomatic Flask code.

---

## 1. Tech stack & structure

Use:

* Python 3.10+
* Flask
* Flask-SQLAlchemy
* Flask-Migrate
* Stripe Python SDK (for both Payments + Issuing)
* (Optional) `python-dotenv` for local config

Project structure (create these files/modules):

```text
guardian_backend/
  app.py                 # Flask app factory & entry
  config.py              # configuration class
  models.py              # SQLAlchemy models
  routes/
    __init__.py
    auth.py              # stubbed auth routes / helper, minimal
    funding.py           # funding sources (cards/banks)
    guardian.py          # guardian logic (authorize/override/charge)
    issuing_webhook.py   # Stripe Issuing webhook for real-time auth
  services/
    stripe_client.py     # wrapper helpers for Stripe
    guardian_engine.py   # risk, rules, override logic
  migrations/            # Alembic migrations
  requirements.txt
```

Use **blueprints** for each route file.

---

## 2. Configuration

Create `config.py` with a `Config` class:

* Read environment variables:

  * `DATABASE_URL`
  * `STRIPE_SECRET_KEY`
  * `STRIPE_WEBHOOK_SECRET` (for Issuing webhooks)
  * (Optional) `FLASK_ENV`, etc.

* Configure:

  ```python
  SQLALCHEMY_DATABASE_URI = os.environ["DATABASE_URL"]
  SQLALCHEMY_TRACK_MODIFICATIONS = False
  ```

`app.py`:

* Implement an `create_app()` factory.

* Initialize:

  * `SQLAlchemy()`
  * `Migrate()`
  * CORS (allow iOS app origin, or `*` for now).

* Register blueprints:

  ```python
  app.register_blueprint(auth_bp, url_prefix="/auth")
  app.register_blueprint(funding_bp, url_prefix="/funding")
  app.register_blueprint(guardian_bp, url_prefix="/guardian")
  app.register_blueprint(issuing_bp, url_prefix="/webhooks")
  ```

Expose `if __name__ == "__main__": app.run(...)` for local dev.

---

## 3. Data models (SQLAlchemy)

In `models.py`, define these models:

### 3.1. User

Fields:

* `id` (int, PK)
* `email` (string, unique, not null)
* `password_hash` (string, not null) – you can just create a helper to hash/verify but keep it simple.
* `stripe_customer_id` (string, nullable)
* `stripe_cardholder_id` (string, nullable) – Issuing cardholder ID.
* `guardian_card_id` (string, nullable) – Issuing card ID for Guardian card.

### 3.2. FundingSource

Funding sources represent **underlying cards/bank accounts** used to fund Guardian transactions.

Fields:

* `id` (int, PK)
* `user_id` (FK to User, not null)
* `type` (string, not null) – `"card"` or `"bank"`
* `provider` (string, not null) – e.g. `"stripe"` or `"plaid"`
* `external_id` (string, not null) – e.g. `pm_123` or bank account token
* `label` (string, optional) – “Main Visa”, “Checking account”
* `is_default` (bool, default False)
* `created_at` (datetime, default now)

### 3.3. GuardianRule

Per-user budget / control rules (keep simple, easy to extend later).

Fields:

* `id` (int, PK)
* `user_id` (FK to User, not null)
* `category` (string, nullable) – e.g. `"fun"`, `"groceries"`, `"uncategorized"`.
* `monthly_limit_cents` (int, nullable) – e.g., 20000 = $200.
* (Optionally add fields like `hard_block` bool later.)

### 3.4. PendingOverride

When Guardian blocks a transaction, we create a short-lived override token so the user can “Swipe to allow and re-try”.

Fields:

* `id` (int, PK)
* `user_id` (FK to User, not null)
* `merchant` (string, not null)
* `amount_cents` (int, not null)
* `expires_at` (datetime, not null)

---

## 4. Auth stub

You don’t need full auth; just enough to make the code usable.

In `routes/auth.py`:

* Implement minimal endpoints like:

  * `POST /auth/signup` → create user, hash password.
  * `POST /auth/login` → return a dummy token and `user_id`.

* Also implement a helper function (doesn’t need full JWT):

  ```python
  def get_current_user_id():
      """
      For now, read user_id from a header like X-User-Id.
      In real life, this will be replaced by proper auth/JWT.
      """
  ```

For all core endpoints, assume you can get `user_id` from this helper.

---

## 5. Stripe service wrapper

In `services/stripe_client.py`:

* Initialize Stripe SDK with `STRIPE_SECRET_KEY`.
* Implement helper functions:

  ### 5.1. Customer & PaymentMethods

  * `get_or_create_customer(user: User) -> str`

    * If `user.stripe_customer_id` is None:

      * Create Stripe Customer.
      * Store `customer.id` on user.
    * Return `customer_id`.

  * `create_card_setup_intent(customer_id: str) -> SetupIntent`

    * Use Stripe’s SetupIntent (payment_method_types=["card"]) to set up saved cards.

  ### 5.2. Charge funding source (cards)

  * `charge_card(customer_id: str, payment_method_id: str, amount_cents: int, currency: str) -> PaymentIntent`

    * Create and confirm an off_session PaymentIntent.

  ### 5.3. Issuing: cardholder & card

  * `create_issuing_cardholder(user: User) -> str`

    * Create Stripe Issuing Cardholder, store ID on `user.stripe_cardholder_id`.

  * `create_guardian_issuing_card(user: User) -> str`

    * Create an Issuing Card with `type="virtual"`, store ID on `user.guardian_card_id`.

  *(We don’t need full Apple Wallet provisioning implementation here, just ensure the card exists and has an ID.)*

---

## 6. Guardian engine (business logic)

In `services/guardian_engine.py`, implement functions:

### 6.1. Risk logic

```python
def is_risky(user_id: int, amount_cents: int, merchant: str, category: str | None) -> bool:
    """
    Very simple first version:
    - Look up GuardianRule for this user & category.
    - If no rule exists -> not risky.
    - If amount_cents > (monthly_limit_cents / 2) -> risky.
    - (In future, you can extend to sum monthly spending, etc.)
    """
```

### 6.2. Override management

```python
def has_valid_override(user_id: int, merchant: str, amount_cents: int) -> bool:
    """
    Return True if there is a PendingOverride for this user + merchant + amount
    whose expires_at is still in the future. If so, delete that override (one-time use).
    """

def create_pending_override(user_id: int, merchant: str, amount_cents: int, ttl_minutes: int = 5) -> None:
    """
    Create a PendingOverride that expires in ttl_minutes.
    """
```

### 6.3. Main decision function

```python
from typing import Tuple

def apply_guardian_logic(user_id: int, amount_cents: int, merchant: str, category: str | None) -> Tuple[str, str]:
    """
    Returns: (decision, reason)
    decision: "APPROVE" or "DECLINE"
    reason: short string like "safe", "override", "risky"

    Steps:
    1. If has_valid_override(...) -> APPROVE, "override".
    2. Else, check is_risky(...).
       - If not risky -> APPROVE, "safe".
       - If risky -> create_pending_override(...), DECLINE, "risky".
    """
```

---

## 7. Funding routes (`routes/funding.py`)

Implement endpoints:

### 7.1. `POST /funding/cards/intent`

Purpose: prepare a Stripe SetupIntent so the iOS app (Swift) can collect card details and attach a PaymentMethod to the customer.

Input (JSON):

* No body needed; `user_id` comes from `get_current_user_id()`.

Steps:

1. Get `user_id`.
2. Get or create Stripe customer for this user.
3. Create SetupIntent with `payment_method_types=["card"]`.
4. Return JSON:

```json
{
  "clientSecret": "<setup_intent_client_secret>"
}
```

### 7.2. `POST /funding/cards/confirm`

After the Swift app finishes the Stripe SetupIntent on the client, it will get a `payment_method_id`.

Input (JSON):

* `payment_method_id`: string
* `label`: optional string

Steps:

1. Get `user_id`.

2. Create a `FundingSource` row:

   * `type="card"`
   * `provider="stripe"`
   * `external_id=payment_method_id`
   * `label=provided_or_default`
   * `is_default=True` if it’s the first funding source, or keep logic simple.

3. Return `{ "status": "ok" }`.

*(You can optionally add endpoints for listing funding sources and setting default.)*

---

## 8. Guardian routes (`routes/guardian.py`)

Implement three main endpoints:

### 8.1. `POST /guardian/authorize`

Used in:

* v1: your own checkout flow inside the app (before calling `/guardian/charge`).
* Later: also used conceptually by Stripe Issuing webhook.

Input (JSON):

* `amount_cents`: int
* `merchant`: string
* `category`: string (optional, like "fun", "groceries")

Steps:

1. Get `user_id`.

2. Call `apply_guardian_logic(user_id, amount_cents, merchant, category)`.

3. If decision is `"APPROVE"`:

   ```json
   { "decision": "APPROVE", "reason": "<reason>" }
   ```

4. If `"DECLINE"`:

   ```json
   {
     "decision": "DECLINE",
     "reason": "risky",
     "message": "This looks like a bad idea based on your budget."
   }
   ```

*(Message can be generic for now.)*

### 8.2. `POST /guardian/override`

Called when the user swipes up in the app to “allow this once”.

Input (JSON):

* `amount_cents`: int
* `merchant`: string

Steps:

1. Get `user_id`.
2. Call `create_pending_override(user_id, merchant, amount_cents)`.
3. Return `{ "status": "ok" }`.

### 8.3. `POST /guardian/charge`

Called **after** `/guardian/authorize` returns `"APPROVE"` to actually charge the underlying funding source.

Input (JSON):

* `amount_cents`: int
* `currency`: string (default `"usd"`)
* `funding_source_id`: optional int (if not provided, use default funding source)

Steps:

1. Get `user_id`.
2. Look up `FundingSource` for this `user_id`:

   * If `funding_source_id` provided → that one.
   * Else → default one.
3. If not found → 400 error.
4. If provider/type is `"stripe"`/`"card"`:

   * Fetch user object (to get `stripe_customer_id`).
   * Use `stripe_client.charge_card(...)`.
5. Return JSON like:

```json
{
  "status": "charged",
  "provider": "stripe",
  "payment_intent_id": "<pi_...>"
}
```

---

## 9. Stripe Issuing webhook (`routes/issuing_webhook.py`)

Implement a webhook endpoint for Stripe Issuing authorization requests:

### 9.1. `POST /webhooks/issuing`

Use Stripe’s webhook signature verification with `STRIPE_WEBHOOK_SECRET`.

Steps:

1. Construct Stripe event from request body & headers.

2. If `event["type"] == "issuing_authorization.request"`:

   * Extract `auth = event["data"]["object"]`.

   * Get:

     * `card_id = auth["card"]`
     * `amount_cents = auth["amount"]`
     * `merchant_name = auth["merchant_data"]["name"]`
     * `mcc = auth["merchant_data"]["category"]` (optional)

   * Map `card_id` → `user_id` by looking up `User.guardian_card_id`.

   * Call `apply_guardian_logic(user_id, amount_cents, merchant_name, category=None or from mcc)`.

   * If decision `"APPROVE"`:

     * Call `stripe.issuing.Authorization.approve(auth["id"])`.

   * If `"DECLINE"`:

     * Call `stripe.issuing.Authorization.decline(auth["id"])`.
     * Also, you may want to create a PendingOverride entry and/or send a notification (just leave TODO comments).

3. Return HTTP 200.

This webhook is what makes the **Guardian card** act like a smart firewall at POS when used via Apple Pay.

---

## 10. Make the code easy to extend

* Use **type hints** throughout functions and models where reasonable.
* Add clear `TODO:` comments where real logic or integrations will be enhanced later (e.g., Plaid for bank accounts, full monthly spending tracking, notification system).
* Keep responses always JSON with a clear structure: `{ "status": ..., "data": ..., "error": ... }` pattern when helpful.
* Don’t implement iOS or Apple Wallet code; just ensure the Guardian Issuing card exists and webhook logic is in place.

---

## Final expectation

Produce:

* All Python files with the structure above.
* Fully wired Flask app with:

  * Working database models and migrations.
  * Endpoints described, with clear docstrings.
  * Stripe integration scaffolded (assume valid keys exist).
  * Guardian logic working with a simple risk rule + override.

The code should be runnable locally (with dummy Stripe keys and a local Postgres or SQLite), and easy for another developer to add:

* Plaid integration for bank accounts.
* Full Apple Wallet push provisioning on the iOS side.
* More advanced Guardian rules.

---

You can now take this entire description and feed it to an LLM as:
“Implement this backend exactly as described.”
