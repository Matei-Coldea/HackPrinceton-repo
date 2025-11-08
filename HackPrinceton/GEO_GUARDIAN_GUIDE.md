# Geo-Guardian Location Monitoring System

## Overview

Geo-Guardian is a location-based behavioral monitoring system that helps prevent impulse dining expenses by tracking user proximity to restaurants and detecting when users spend excessive time near them.

## How It Works

### Core Concept

The system monitors:
1. **User location** via GPS coordinates (latitude/longitude)
2. **Movement patterns** to detect stationary behavior
3. **Proximity to restaurants** within a configurable radius
4. **Time spent near restaurants** using a rolling window approach

When a user remains stationary near a restaurant for too long, the system can block transactions to prevent impulse purchases.

### Technical Implementation

#### 1. Location Tracking
- Accepts GPS coordinates (lat, lon) via API endpoint
- Calculates distance traveled using Haversine formula
- Determines movement speed (meters per second)
- Classifies user as "stationary" if speed < 0.5 m/s

#### 2. Restaurant Detection

**MVP Mode (Default):**
- Uses hardcoded restaurant locations for testing
- Fast, no external API dependencies
- Perfect for demos and development

**Production Mode:**
- Integrates with Google Places API
- Real-time restaurant discovery
- Configurable search radius

#### 3. Stationary Ping System

```
User Location Update → Calculate Speed → Near Restaurant? → Stationary?
                                              ↓                    ↓
                                            No: Allow           Yes: Record Ping
                                                                     ↓
                                                              Count Recent Pings
                                                                     ↓
                                                              Threshold Exceeded?
                                                                     ↓
                                                          Yes: BLOCK | No: Allow
```

#### 4. Rolling Window Algorithm

- Maintains a list of timestamps for each user
- Each stationary ping near a restaurant adds current timestamp
- Old pings outside the time window are automatically removed
- Only pings within the window count toward the threshold

**Example:**
```
Window: 15 minutes
Threshold: 5 pings

Time    Action                  Ping Count   Decision
------  ----------------------  -----------  ---------
12:00   User arrives            1            Allow
12:03   Still there             2            Allow
12:06   Still there             3            Allow
12:09   Still there             4            Allow
12:12   Still there             5            BLOCK!
12:20   Ping from 12:00 expires 4            Allow
```

## API Usage

### Endpoint

```
GET /location-check
```

### Parameters

| Parameter | Type  | Required | Description                |
|-----------|-------|----------|----------------------------|
| user_id   | str   | Yes      | Unique user identifier     |
| lat       | float | Yes      | Latitude (-90 to 90)       |
| lon       | float | Yes      | Longitude (-180 to 180)    |

### Response Schema

```typescript
{
  decision: "ok" | "block",
  stats?: {
    recent_stationary_pings_near_restaurants: number,
    window_minutes: number
  },
  notifications?: [
    {
      type: string,
      code: string,
      severity: string
    }
  ]
}
```

### Example Requests

**User far from restaurants:**
```bash
curl "http://localhost:8000/location-check?user_id=user123&lat=40.713000&lon=-74.007000"

# Response:
{
  "decision": "ok"
}
```

**User stationary near restaurant (below threshold):**
```bash
curl "http://localhost:8000/location-check?user_id=user123&lat=40.712800&lon=-74.006000"

# Response:
{
  "decision": "ok"
}
```

**User exceeded threshold:**
```bash
curl "http://localhost:8000/location-check?user_id=user123&lat=40.712800&lon=-74.006000"

# Response:
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

## Configuration

### User Profiles

Define per-user sensitivity levels:

```python
GEO_USER_CONFIG = {
    "demo_user_strict": {
        "block_ping_threshold": 3,      # Block after 3 pings
        "dwell_window_minutes": 10,     # Look back 10 minutes
    },
    "demo_user_default": {
        "block_ping_threshold": 5,
        "dwell_window_minutes": 15,
    },
    "demo_user_relaxed": {
        "block_ping_threshold": 8,
        "dwell_window_minutes": 20,
    },
}
```

### Global Parameters

```python
# Detection thresholds
DEFAULT_BLOCK_PING_THRESHOLD = 5       # Default pings before block
DEFAULT_DWELL_WINDOW_MINUTES = 15     # Default time window
STATIONARY_SPEED_MPS = 0.5            # Speed threshold (m/s)
MAX_STATIONARY_GAP_SECONDS = 300      # Max time between pings

# Restaurant detection
RESTAURANT_TYPES = {
    "restaurant", "cafe", "bar",
    "meal_takeaway", "meal_delivery",
    "bakery", "night_club"
}
```

### Hardcoded Places (MVP)

```python
HARDCODED_PLACES = [
    {
        "id": "place_1",
        "name": "Demo Burger",
        "types": ["restaurant"],
        "lat": 40.712800,
        "lon": -74.006000,
    },
    # Add more locations as needed
]
```

### Google Places Integration

1. Get API key from [Google Cloud Console](https://console.cloud.google.com/)
2. Enable Places API
3. Update configuration:

```python
USE_GOOGLE_PLACES = True
GOOGLE_API_KEY = "your-api-key-here"
```

4. Restart API server

## Testing

### Automated Test Suite

Run the comprehensive test suite:

```bash
./test_location.sh
```

Or manually:

```bash
source venv/bin/activate
python test_location.py
```

### Test Scenarios

The test script covers:

1. **Baseline**: User far from restaurants → Allow
2. **Near but moving**: User passing by → Allow
3. **Stationary buildup**: Multiple pings → Eventually block
4. **Strict profile**: Lower threshold → Block sooner
5. **Relaxed profile**: Higher threshold → Block later

### Manual Testing

Test individual locations:

```bash
# Test 1: Not near restaurant
curl "http://localhost:8000/location-check?user_id=test1&lat=40.713000&lon=-74.007000"

# Test 2: Near Demo Burger (first visit)
curl "http://localhost:8000/location-check?user_id=test1&lat=40.712800&lon=-74.006000"

# Test 3: Still there (repeat several times with 1-2 second delays)
curl "http://localhost:8000/location-check?user_id=test1&lat=40.712800&lon=-74.006000"
```

## Integration Patterns

### Mobile App Integration

```typescript
// Periodic location monitoring
setInterval(async () => {
  const position = await getCurrentPosition();
  
  const response = await fetch(
    `${API_BASE}/location-check?` +
    `user_id=${userId}&` +
    `lat=${position.latitude}&` +
    `lon=${position.longitude}`
  );
  
  const result = await response.json();
  
  if (result.decision === 'block') {
    // Disable payment card
    disableCard();
    
    // Show notification
    showAlert(result.notifications[0]);
  }
}, 60000); // Check every minute
```

### Card Transaction Flow

```python
# Before processing payment
location_result = check_user_location(user_id, lat, lon)

if location_result['decision'] == 'block':
    return {
        'status': 'declined',
        'reason': 'Spending protection activated',
        'details': location_result['stats']
    }

# Proceed with transaction
process_payment(transaction)
```

### Webhook Notifications

```python
def send_notification(user_id: str, notification: Notification):
    # Email
    send_email(
        to=get_user_email(user_id),
        subject=f"Guardian Alert: {notification.code}",
        body=build_email_template(notification)
    )
    
    # Push notification
    send_fcm_notification(
        device_token=get_device_token(user_id),
        title="Spending Protection Active",
        body="Your card has been temporarily blocked"
    )
    
    # SMS
    send_sms(
        phone=get_user_phone(user_id),
        message="Guardian: Too much time near restaurants. Card blocked."
    )
```

## Architecture

### State Management

```python
# In-memory state (MVP)
USER_STATE = {}          # Last location per user
RESTAURANT_PINGS = {}    # Timestamp lists per user

# Production: Use Redis or database
redis.hset(f"user:{user_id}:state", mapping={
    "last_lat": lat,
    "last_lon": lon,
    "last_ts": timestamp
})

redis.zadd(
    f"user:{user_id}:pings",
    {timestamp: timestamp}
)
```

### Scalability Considerations

1. **State Storage**: Move to Redis for multi-instance deployment
2. **Places Cache**: Cache Google Places results to reduce API calls
3. **Rate Limiting**: Limit location updates per user
4. **Batch Processing**: Process multiple users concurrently
5. **Geospatial Index**: Use PostGIS for efficient location queries

## Troubleshooting

### User blocked unexpectedly

Check recent pings:
```python
print(RESTAURANT_PINGS.get(user_id))
# Shows list of timestamps
```

Verify user config:
```python
print(get_geo_user_config(user_id))
# Shows threshold and window
```

### Location not detected

Verify coordinates:
```python
nearby = await get_nearby_places(lat, lon, radius_m=50)
print(f"Found {len(nearby)} places")
```

Check distance calculation:
```python
d = haversine_m(user_lat, user_lon, restaurant_lat, restaurant_lon)
print(f"Distance: {d:.2f}m")
```

### Google Places not working

1. Verify API key is valid
2. Check Places API is enabled
3. Verify billing is set up
4. Check API quotas

```python
# Test API directly
import httpx
async with httpx.AsyncClient() as client:
    r = await client.get(
        "https://maps.googleapis.com/maps/api/place/nearbysearch/json",
        params={
            "location": "40.7128,-74.0060",
            "radius": 10,
            "key": GOOGLE_API_KEY
        }
    )
    print(r.json())
```

## Future Enhancements

- [ ] Machine learning to predict restaurant visits
- [ ] Customizable notification templates
- [ ] Integration with calendar (allow restaurant visits during planned meals)
- [ ] Time-of-day rules (different thresholds for lunch vs. dinner)
- [ ] Spending limits per restaurant type
- [ ] Geofencing for approved locations
- [ ] Historical analytics and reports
- [ ] Multi-device synchronization
- [ ] Family/group account support

## Security & Privacy

- Location data stored temporarily in-memory (MVP)
- No persistent location history
- Timestamps automatically expire
- User can configure their own sensitivity
- Location data never shared with third parties
- Optional: Full location history deletion on request

## License & Credits

Part of the Guardian Card Hackathon Project

