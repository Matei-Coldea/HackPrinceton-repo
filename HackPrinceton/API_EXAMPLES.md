# API Testing Examples

## Start the API First

```bash
./run_api.sh
```

Wait until you see: `Uvicorn running on http://0.0.0.0:8000`

Then open a NEW terminal and run these examples:

---

## 📍 1. Health Check (Easiest Test)

### Browser
Just open: http://localhost:8000

### Terminal
```bash
curl http://localhost:8000
```

**Expected Response:**
```json
{
  "message": "Guardian Card API is running",
  "endpoints": {
    "transaction_scoring": "/score-transaction",
    "location_check": "/location-check",
    "documentation": "/docs"
  }
}
```

---

## 💳 2. Transaction Scoring Tests

### Example 1: Small Purchase (Coffee)
```bash
curl -X POST "http://localhost:8000/score-transaction" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "u1",
    "amount": 15.00,
    "merchant_name": "Starbucks",
    "mcc": 5814,
    "timestamp": "2025-01-15T09:30:00",
    "channel": "offline"
  }'
```

**What to expect:** Likely BLOCKED (u1 is a Saver with strict threshold)

---

### Example 2: Large Purchase (Electronics)
```bash
curl -X POST "http://localhost:8000/score-transaction" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "u3",
    "amount": 350.00,
    "merchant_name": "Best Buy",
    "mcc": 5732,
    "timestamp": "2025-01-15T16:00:00",
    "channel": "offline"
  }'
```

**What to expect:** Possibly ALLOWED (u3 is a Spender with relaxed threshold)

---

### Example 3: Essential Purchase (Groceries)
```bash
curl -X POST "http://localhost:8000/score-transaction" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "u2",
    "amount": 120.00,
    "merchant_name": "Whole Foods",
    "mcc": 5411,
    "timestamp": "2025-01-15T18:00:00",
    "channel": "offline"
  }'
```

**What to expect:** ALLOWED (groceries are essential)

---

### Example 4: Late Night Fast Food
```bash
curl -X POST "http://localhost:8000/score-transaction" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "u2",
    "amount": 25.00,
    "merchant_name": "McDonalds",
    "mcc": 5814,
    "timestamp": "2025-01-15T23:00:00",
    "channel": "offline"
  }'
```

**What to expect:** Likely BLOCKED (late night + fast food = suspicious)

---

## 📍 3. Geo-Guardian Location Tests

### Example 1: Far from Restaurants (Should be OK)
```bash
curl "http://localhost:8000/location-check?user_id=test_user&lat=40.713000&lon=-74.007000"
```

**Expected Response:**
```json
{
  "decision": "ok"
}
```

---

### Example 2: Near Demo Burger (First Time)
```bash
curl "http://localhost:8000/location-check?user_id=walker&lat=40.712800&lon=-74.006000"
```

**Expected:** OK (first ping, not stationary yet)

---

### Example 3: Simulate Loitering (Run Multiple Times)

**First ping:**
```bash
curl "http://localhost:8000/location-check?user_id=loiterer&lat=40.712800&lon=-74.006000"
```

**Wait 2 seconds, then second ping:**
```bash
sleep 2 && curl "http://localhost:8000/location-check?user_id=loiterer&lat=40.712801&lon=-74.006001"
```

**Keep running (change coordinates slightly to simulate standing still):**
```bash
# Ping 1 (not counted - establishes baseline)
curl "http://localhost:8000/location-check?user_id=loiterer&lat=40.712802&lon=-74.006002"
sleep 2

# Ping 2 (counted - 1st stationary ping)
curl "http://localhost:8000/location-check?user_id=loiterer&lat=40.712803&lon=-74.006003"
sleep 2

# Ping 3 (counted - 2nd stationary ping)
curl "http://localhost:8000/location-check?user_id=loiterer&lat=40.712804&lon=-74.006004"
sleep 2

# Ping 4 (counted - 3rd stationary ping)
curl "http://localhost:8000/location-check?user_id=loiterer&lat=40.712805&lon=-74.006005"
sleep 2

# Ping 5 (counted - 4th stationary ping)
curl "http://localhost:8000/location-check?user_id=loiterer&lat=40.712806&lon=-74.006006"
sleep 2

# Ping 6 (counted - 5th stationary ping) → BLOCKED! 🚫
curl "http://localhost:8000/location-check?user_id=loiterer&lat=40.712807&lon=-74.006007"
```

**After ping 6:** Should get BLOCKED! (threshold = 5 stationary pings)

**Expected Response (after threshold):**
```json
{
  "decision": "block",
  "stats": {
    "recent_stationary_pings_near_restaurants": 5,
    "window_minutes": 15
  },
  "notifications": [
    {
      "type": "behavior",
      "code": "RESTAURANT_STATIONARY_TOO_LONG",
      "severity": "warning"
    }
  ]
}
```

---

### Example 4: Strict User (Gets Blocked Faster)
```bash
# Ping 1
curl "http://localhost:8000/location-check?user_id=demo_user_strict&lat=40.712820&lon=-74.006020"

# Ping 2 (wait 2 seconds)
sleep 2 && curl "http://localhost:8000/location-check?user_id=demo_user_strict&lat=40.712821&lon=-74.006021"

# Ping 3 (wait 2 seconds)
sleep 2 && curl "http://localhost:8000/location-check?user_id=demo_user_strict&lat=40.712822&lon=-74.006022"

# Ping 4 (wait 2 seconds) - Should BLOCK here!
sleep 2 && curl "http://localhost:8000/location-check?user_id=demo_user_strict&lat=40.712823&lon=-74.006023"
```

**Expected:** Blocked after 4 pings (threshold is 3)

---

### Example 5: Test Real World Coordinates (Will Find Nothing)
```bash
# Los Angeles coordinates
curl "http://localhost:8000/location-check?user_id=test&lat=34.0522&lon=-118.2437"

# London coordinates  
curl "http://localhost:8000/location-check?user_id=test&lat=51.5074&lon=-0.1278"
```

**Expected:** Both return `"decision": "ok"` (no restaurants found - they're hardcoded near NYC)

---

## 🧪 4. Combined Test Script

Run all tests at once:

```bash
#!/bin/bash

echo "Testing Transaction Scoring..."
echo "1. Saver user - small purchase:"
curl -s -X POST "http://localhost:8000/score-transaction" \
  -H "Content-Type: application/json" \
  -d '{"user_id":"u1","amount":15.00,"merchant_name":"Starbucks","mcc":5814,"timestamp":"2025-01-15T09:30:00","channel":"offline"}' | python3 -m json.tool

echo -e "\n2. Spender user - large purchase:"
curl -s -X POST "http://localhost:8000/score-transaction" \
  -H "Content-Type: application/json" \
  -d '{"user_id":"u3","amount":350.00,"merchant_name":"Best Buy","mcc":5732,"timestamp":"2025-01-15T16:00:00","channel":"offline"}' | python3 -m json.tool

echo -e "\nTesting Geo-Guardian..."
echo "3. Far from restaurants:"
curl -s "http://localhost:8000/location-check?user_id=test&lat=40.713000&lon=-74.007000" | python3 -m json.tool

echo -e "\n4. Near Demo Burger:"
curl -s "http://localhost:8000/location-check?user_id=test2&lat=40.712800&lon=-74.006000" | python3 -m json.tool
```

---

## 🌐 5. Interactive Testing (Easiest!)

### Option A: Swagger UI (Recommended)
1. Start the API: `./run_api.sh`
2. Open in browser: http://localhost:8000/docs
3. Click on any endpoint
4. Click "Try it out"
5. Fill in parameters
6. Click "Execute"
7. See the response!

### Option B: ReDoc
- Open: http://localhost:8000/redoc
- Great for viewing API documentation

---

## 🔍 Understanding Responses

### Transaction Scoring Response
```json
{
  "decision": "BLOCK",           // ALLOW or BLOCK
  "p_avoid": 0.87,               // 87% likely to be avoidable
  "reason": "You've already spent...",
  "debug": {
    "p_ml": 0.75,                // ML model prediction
    "over_budget_ratio": 1.5,    // 150% of budget
    "threshold": 0.40,           // User's threshold (Saver=40%, Average=60%, Spender=75%)
    "spend_before": 100,         // Already spent in category
    "spend_after": 250           // Will be after this transaction
  }
}
```

### Location Check Response (OK)
```json
{
  "decision": "ok"
}
```

### Location Check Response (BLOCKED)
```json
{
  "decision": "block",
  "stats": {
    "recent_stationary_pings_near_restaurants": 5,
    "window_minutes": 15
  },
  "notifications": [
    {
      "type": "behavior",
      "code": "RESTAURANT_STATIONARY_TOO_LONG",
      "severity": "warning"
    }
  ]
}
```

---

## 🎯 Quick Test Checklist

- [ ] API starts without errors: `./run_api.sh`
- [ ] Health check works: `curl http://localhost:8000`
- [ ] Transaction scoring works: Try Examples 1-4
- [ ] Saver blocks more than Spender
- [ ] Essential purchases (groceries) allowed
- [ ] Location check works: Try geo examples
- [ ] Stationary detection works: Run loitering test
- [ ] Interactive docs work: http://localhost:8000/docs

---

## 🐛 Troubleshooting

### API won't start
```bash
# Kill any existing processes
pkill -f uvicorn

# Try again
./run_api.sh
```

### Connection refused
- Make sure API is running
- Check port 8000 is not in use: `lsof -i :8000`

### Want formatted JSON output?
Add `| python3 -m json.tool` or `| jq` to curl commands:
```bash
curl http://localhost:8000 | python3 -m json.tool
```

---

## 📝 Notes

- **User IDs in CSV**: u1 (Saver), u2 (Average), u3 (Spender)
- **Geo User IDs in CSV**: demo_user_strict, demo_user_default, demo_user_relaxed
- **Hardcoded Restaurants**: Near coordinates (40.7128, -74.006) in NYC
- **Time between pings**: Wait 2+ seconds for stationary detection to work

---

Enjoy testing! 🚀

