# Mock Data Files

This directory contains CSV files with mock/test data used by the Guardian Card API.

## Purpose

Instead of hardcoding mock data in the implementation files, we store it in CSV files for:
- ✅ **Easy modification** - Edit CSV files without touching code
- ✅ **Version control** - Track changes to test data
- ✅ **Separation of concerns** - Data separate from logic
- ✅ **Testing** - Easy to swap different datasets

## Files

### 1. `mock_restaurants.csv`

Mock restaurant locations for geo-guardian testing (when `USE_GOOGLE_PLACES=false`).

**Columns:**
- `id`: Unique identifier for the restaurant
- `name`: Restaurant name
- `types`: Type of place (restaurant, cafe, bar, etc.)
- `lat`: Latitude coordinate
- `lon`: Longitude coordinate

**Example:**
```csv
id,name,types,lat,lon
place_1,Demo Burger,restaurant,40.712800,-74.006000
place_2,Campus Coffee,cafe,40.712820,-74.006020
```

**Usage:** These locations are used when testing geo-guardian without Google Places API.

**To Add More:**
```csv
place_4,Pizza Palace,restaurant,40.712900,-74.006100
place_5,Juice Bar,cafe,40.712750,-74.005900
```

### 2. `geo_user_config.csv`

Geo-guardian user configuration profiles (sensitivity settings).

**Columns:**
- `user_id`: User identifier
- `block_ping_threshold`: Number of stationary pings before blocking
- `dwell_window_minutes`: Time window for counting pings
- `description`: Human-readable description

**Example:**
```csv
user_id,block_ping_threshold,dwell_window_minutes,description
demo_user_strict,3,10,Very sensitive – gets blocked quickly
demo_user_default,5,15,Default behaviour
demo_user_relaxed,8,20,More relaxed
```

**Usage:** Different users can have different sensitivity levels for location monitoring.

**To Add More:**
```csv
demo_user_paranoid,2,5,Extremely strict
demo_user_lenient,10,30,Very relaxed
```

### 3. `user_profiles.csv`

User profiles for transaction scoring.

**Columns:**
- `user_id`: User identifier
- `profile_type`: Saver, Average, or Spender
- `monthly_income`: User's monthly income

**Example:**
```csv
user_id,profile_type,monthly_income
u1,Saver,2000
u2,Average,3000
u3,Spender,4500
```

**Usage:** Determines blocking thresholds and budget calculations.

**Profile Types:**
- **Saver**: Blocks at 40% probability (strict)
- **Average**: Blocks at 60% probability (moderate)
- **Spender**: Blocks at 75% probability (relaxed)

**To Add More:**
```csv
u4,Saver,1800
test_user,Average,2500
demo_user,Spender,5000
```

### 4. `notification_templates.csv`

Notification templates for different alert types.

**Columns:**
- `code`: Unique notification code
- `type`: Type of notification (behavior, transaction, etc.)
- `severity`: Severity level (info, warning, error)
- `description`: Human-readable description

**Example:**
```csv
code,type,severity,description
RESTAURANT_STATIONARY_TOO_LONG,behavior,warning,User stationary near restaurant too long
```

**Usage:** Defines what notifications can be sent to users.

**To Add More:**
```csv
BUDGET_EXCEEDED,transaction,warning,Monthly budget exceeded
SUSPICIOUS_ACTIVITY,behavior,error,Unusual spending pattern detected
```

### 5. `transactions.csv`

Generated transaction data for model training (created by `data_gen.py`).

**Not a mock file** - This is generated training data for the ML model.

## How to Modify

### Adding New Mock Restaurants

1. Edit `mock_restaurants.csv`
2. Add a new row with real coordinates
3. Restart the API

```csv
place_4,Taco Stand,restaurant,34.0522,-118.2437
```

### Creating New User Profiles

1. Edit `user_profiles.csv`
2. Add new user with profile type and income
3. Restart the API

```csv
new_user,Saver,2500
```

### Adjusting Geo-Guardian Sensitivity

1. Edit `geo_user_config.csv`
2. Modify thresholds or add new users
3. Restart the API

## Production vs Development

### Development (Current)
- Uses CSV files for mock data
- `USE_GOOGLE_PLACES=false`
- Fast, no API costs

### Production
- Should use real database
- `USE_GOOGLE_PLACES=true` with API key
- Replace CSV loading with database queries

## Migration to Database

When moving to production, replace CSV loading with database queries:

```python
# Instead of:
profiles = _load_user_profiles()

# Use:
profiles = db.query(UserProfile).all()
```

The CSV structure maps directly to database tables:
- `mock_restaurants.csv` → `restaurants` table
- `user_profiles.csv` → `users` table
- `geo_user_config.csv` → `user_settings` table
- `notification_templates.csv` → `notifications` table

## Testing with Different Data

Create alternative CSV files for testing:

```bash
# Backup originals
cp user_profiles.csv user_profiles.backup.csv

# Create test dataset
cat > user_profiles.csv << EOF
user_id,profile_type,monthly_income
test1,Saver,1000
test2,Spender,10000
EOF

# Run tests
python test_transactions.py

# Restore originals
mv user_profiles.backup.csv user_profiles.csv
```

## File Locations

```
data/
├── README.md (this file)
├── mock_restaurants.csv      # Geo-guardian test locations
├── geo_user_config.csv        # Geo-guardian user settings
├── user_profiles.csv          # Transaction scoring user profiles
├── notification_templates.csv # Alert templates
└── transactions.csv           # Generated training data
```

## Summary

✅ All mock data is now in CSV files
✅ Easy to edit without touching code
✅ Works exactly as before
✅ Ready for production database migration

**To modify test data**: Just edit the CSV files and restart the API!

