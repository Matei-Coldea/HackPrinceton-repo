"""
Geo-Guardian Location Monitoring Service

Handles all logic for location tracking, restaurant detection, and behavioral monitoring.
"""

import math
import os
import csv
from datetime import datetime, timedelta
from typing import List, Optional, Tuple
from pathlib import Path
import httpx
from dotenv import load_dotenv

from ..models import Stats, Notification, LocationCheckResponse

# Load environment variables from .env file
env_path = Path(__file__).parent.parent.parent / ".env"
load_dotenv(dotenv_path=env_path)

# Data directory
DATA_DIR = Path(__file__).parent.parent.parent / "data"


# ================================
#  CONFIGURATION
# ================================

def _get_required_env(var_name: str, var_type=str, default=None):
    """
    Get environment variable with type conversion and validation.
    
    Args:
        var_name: Name of environment variable
        var_type: Type to convert to (str, int, float, bool)
        default: Default value if not set (None means required)
    
    Returns:
        Converted value
        
    Raises:
        ValueError: If required variable is not set
    """
    value = os.getenv(var_name)
    
    if value is None:
        if default is not None:
            return default
        raise ValueError(
            f"Required environment variable '{var_name}' is not set. "
            f"Please add it to your .env file. See env.example for reference."
        )
    
    if var_type == bool:
        return value.lower() in ('true', '1', 'yes', 'on')
    elif var_type == int:
        return int(value)
    elif var_type == float:
        return float(value)
    else:
        return value


# Load configuration from environment variables
# All values now come from .env file
USE_GOOGLE_PLACES = _get_required_env("USE_GOOGLE_PLACES", bool, default=False)
GOOGLE_API_KEY = _get_required_env("GOOGLE_API_KEY", str, default="")

# Behaviour thresholds - required in .env
DEFAULT_BLOCK_PING_THRESHOLD = _get_required_env("DEFAULT_BLOCK_PING_THRESHOLD", int)
DEFAULT_DWELL_WINDOW_MINUTES = _get_required_env("DEFAULT_DWELL_WINDOW_MINUTES", int)
STATIONARY_SPEED_MPS = _get_required_env("STATIONARY_SPEED_MPS", float)
MAX_STATIONARY_GAP_SECONDS = _get_required_env("MAX_STATIONARY_GAP_SECONDS", int)

# Types we treat as "restaurant-like"
RESTAURANT_TYPES = {
    "restaurant",
    "cafe",
    "bar",
    "meal_takeaway",
    "meal_delivery",
    "bakery",
    "night_club",
}


# ================================
#  LOAD MOCK DATA FROM CSV FILES
# ================================

def _load_mock_restaurants():
    """Load mock restaurants from CSV file"""
    places = []
    csv_path = DATA_DIR / "mock_restaurants.csv"
    
    if not csv_path.exists():
        return []
    
    with open(csv_path, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            places.append({
                "id": row['id'],
                "name": row['name'],
                "types": [row['types']],  # CSV stores as single value
                "lat": float(row['lat']),
                "lon": float(row['lon']),
            })
    return places


def _load_geo_user_config():
    """Load geo user configurations from CSV file"""
    config = {}
    csv_path = DATA_DIR / "geo_user_config.csv"
    
    if not csv_path.exists():
        return {}
    
    with open(csv_path, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            config[row['user_id']] = {
                "block_ping_threshold": int(row['block_ping_threshold']),
                "dwell_window_minutes": int(row['dwell_window_minutes']),
            }
    return config


def _load_notification_templates():
    """Load notification templates from CSV file"""
    templates = {}
    csv_path = DATA_DIR / "notification_templates.csv"
    
    if not csv_path.exists():
        return {}
    
    with open(csv_path, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            templates[row['code']] = {
                "type": row['type'],
                "severity": row['severity'],
            }
    return templates


# Load mock data from CSV files
HARDCODED_PLACES = _load_mock_restaurants()
GEO_USER_CONFIG = _load_geo_user_config()
NOTIFICATION_TEMPLATES = _load_notification_templates()


# ================================
#  IN-MEMORY STATE (MVP ONLY)
# ================================

# per user: last location + timestamp
USER_STATE = {}       # user_id -> {"last_lat": float, "last_lon": float, "last_ts": datetime}

# per user: timestamps when user was stationary near restaurant-like places
RESTAURANT_PINGS = {}  # user_id -> [datetime, ...]


# ================================
#  HELPER FUNCTIONS
# ================================

def haversine_m(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Calculate distance in meters between two lat/lon points using Haversine formula.
    
    Args:
        lat1, lon1: First point coordinates
        lat2, lon2: Second point coordinates
        
    Returns:
        Distance in meters
    """
    R = 6371000  # Earth radius in meters
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)

    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c


async def get_nearby_places(lat: float, lon: float, radius_m: int = 50) -> List[dict]:
    """
    Get nearby places either from hardcoded list or Google Places API.
    
    ⚠️  WARNING: For production use with real user locations, you MUST enable Google Places API
    by setting USE_GOOGLE_PLACES=true and GOOGLE_API_KEY in your .env file.
    
    Hardcoded mode is only for testing/demos with predefined coordinates.
    
    Args:
        lat, lon: Location coordinates
        radius_m: Search radius in meters
        
    Returns:
        List of place dictionaries
    """
    if USE_GOOGLE_PLACES and GOOGLE_API_KEY:
        # ---- Real Google Places path ----
        url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
        params = {
            "location": f"{lat},{lon}",
            "radius": radius_m,
            "key": GOOGLE_API_KEY,
        }
        async with httpx.AsyncClient() as client:
            r = await client.get(url, params=params, timeout=5.0)
            r.raise_for_status()
            data = r.json()

        if data.get("status") != "OK":
            return []

        results = data.get("results", [])
        # Normalize shape slightly to what we expect
        norm = []
        for p in results:
            loc = p.get("geometry", {}).get("location", {})
            norm.append({
                "id": p.get("place_id"),
                "name": p.get("name"),
                "types": p.get("types", []),
                "lat": loc.get("lat"),
                "lon": loc.get("lng"),
            })
        return norm

    # ---- Hardcoded MVP path ----
    # ⚠️  WARNING: Using hardcoded places - not suitable for real user locations!
    import warnings
    warnings.warn(
        "Using hardcoded restaurant locations. For production with real user GPS data, "
        "set USE_GOOGLE_PLACES=true and GOOGLE_API_KEY in your .env file.",
        UserWarning
    )
    
    nearby = []
    for p in HARDCODED_PLACES:
        d = haversine_m(lat, lon, p["lat"], p["lon"])
        if d <= radius_m:
            nearby.append(p)
    return nearby


def is_restaurant_like(place: dict) -> bool:
    """
    Check if a place is restaurant-like based on its types.
    
    Args:
        place: Place dictionary with 'types' field
        
    Returns:
        True if restaurant-like, False otherwise
    """
    types = set(place.get("types", []))
    return bool(types & RESTAURANT_TYPES)


def get_nearest_restaurant(places: List[dict], lat: float, lon: float, 
                          max_dist_m: float = 20.0) -> Optional[Tuple[dict, float]]:
    """
    Find the nearest restaurant-like place within max distance.
    
    Args:
        places: List of places to search
        lat, lon: User location
        max_dist_m: Maximum distance in meters
        
    Returns:
        Tuple of (place, distance) or None if no restaurant found
    """
    nearest = None
    best_d = None
    for p in places:
        plat, plon = p.get("lat"), p.get("lon")
        if plat is None or plon is None:
            continue
        d = haversine_m(lat, lon, plat, plon)
        if d <= max_dist_m and is_restaurant_like(p):
            if best_d is None or d < best_d:
                best_d = d
                nearest = (p, d)
    return nearest


def get_geo_user_config(user_id: str) -> dict:
    """
    Get geo-guardian configuration for a user.
    
    Args:
        user_id: User identifier
        
    Returns:
        Dictionary with block_ping_threshold and dwell_window_minutes
    """
    cfg = GEO_USER_CONFIG.get(user_id, {})
    return {
        "block_ping_threshold": cfg.get("block_ping_threshold", DEFAULT_BLOCK_PING_THRESHOLD),
        "dwell_window_minutes": cfg.get("dwell_window_minutes", DEFAULT_DWELL_WINDOW_MINUTES),
    }


def update_user_state_and_stationary(user_id: str, lat: float, lon: float, 
                                    now: datetime) -> Tuple[bool, Optional[float]]:
    """
    Update user's last position and determine if they are stationary.
    
    Args:
        user_id: User identifier
        lat, lon: Current location
        now: Current timestamp
        
    Returns:
        Tuple of (is_stationary, dt_seconds)
    """
    last = USER_STATE.get(user_id)
    USER_STATE[user_id] = {"last_lat": lat, "last_lon": lon, "last_ts": now}

    if not last:
        return False, None

    dt = (now - last["last_ts"]).total_seconds()
    if dt <= 0:
        return False, dt

    dist = haversine_m(lat, lon, last["last_lat"], last["last_lon"])
    speed = dist / dt  # m/s

    is_stationary = speed < STATIONARY_SPEED_MPS and dt <= MAX_STATIONARY_GAP_SECONDS
    return is_stationary, dt


def record_restaurant_ping(user_id: str, now: datetime, window_minutes: int) -> List[datetime]:
    """
    Record a stationary ping near a restaurant and trim old pings.
    
    Args:
        user_id: User identifier
        now: Current timestamp
        window_minutes: Time window for keeping pings
        
    Returns:
        List of timestamps within the window
    """
    lst = RESTAURANT_PINGS.get(user_id, [])
    cutoff = now - timedelta(minutes=window_minutes)
    lst = [t for t in lst if t >= cutoff]
    lst.append(now)
    RESTAURANT_PINGS[user_id] = lst
    return lst


def build_notification(code: str) -> Notification:
    """
    Build a notification object from a notification code.
    
    Args:
        code: Notification code (e.g., "RESTAURANT_STATIONARY_TOO_LONG")
        
    Returns:
        Notification object
    """
    tmpl = NOTIFICATION_TEMPLATES.get(code, {})
    return Notification(
        type=tmpl.get("type", "generic"),
        severity=tmpl.get("severity", "info"),
        code=code,
    )


def send_notification(user_id: str, notification: Notification) -> None:
    """
    Send a notification to the user.
    MVP: just print. Replace with FCM/APNs/email/sockets later.
    
    Args:
        user_id: User identifier
        notification: Notification object to send
    """
    print(f"[NOTIFY] user={user_id} code={notification.code} severity={notification.severity}")


# ================================
#  MAIN CHECK FUNCTION
# ================================

async def check_location(user_id: str, lat: float, lon: float) -> LocationCheckResponse:
    """
    Check user location and determine if card should be blocked.
    
    Args:
        user_id: User identifier
        lat, lon: User's current location
        
    Returns:
        LocationCheckResponse with decision and optional stats/notifications
    """
    from datetime import timezone
    now = datetime.now(timezone.utc)

    # 1) Movement / stationary check
    is_stationary, _ = update_user_state_and_stationary(user_id, lat, lon, now)

    # 2) Nearby places (hardcoded or Google)
    places = await get_nearby_places(lat, lon, radius_m=100)

    nearest = get_nearest_restaurant(places, lat, lon, max_dist_m=50.0)
    if not nearest:
        # Not near any restaurant-like place
        return LocationCheckResponse(decision="ok")

    if not is_stationary:
        # Near restaurant but moving → don't count yet
        return LocationCheckResponse(decision="ok")

    # 3) Stationary near restaurant → update dwell stats
    user_cfg = get_geo_user_config(user_id)
    dwell_window = user_cfg["dwell_window_minutes"]
    block_threshold = user_cfg["block_ping_threshold"]

    recent_pings = record_restaurant_ping(user_id, now, window_minutes=dwell_window)
    num_pings = len(recent_pings)

    if num_pings >= block_threshold:
        notif = build_notification("RESTAURANT_STATIONARY_TOO_LONG")
        send_notification(user_id, notif)

        return LocationCheckResponse(
            decision="block",
            stats=Stats(
                recent_stationary_pings_near_restaurants=num_pings,
                window_minutes=dwell_window,
            ),
            notifications=[notif],
        )

    # Not over threshold yet → still ok
    return LocationCheckResponse(decision="ok")

