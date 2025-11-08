import time, requests
from flask import request, current_app, abort
from jose import jwt
from models import db, User

_cached = {"jwks": None, "exp": 0}

def _jwks():
    now = int(time.time())
    if _cached["jwks"] and now < _cached["exp"]:
        return _cached["jwks"]
    url = current_app.config["SUPABASE_JWKS_URL"] or (
        current_app.config["SUPABASE_PROJECT_URL"].rstrip("/") + "/auth/v1/.well-known/jwks.json"
    )
    r = requests.get(url, timeout=5); r.raise_for_status()
    _cached["jwks"] = r.json(); _cached["exp"] = now + 300
    return _cached["jwks"]

def get_current_user_id() -> int:
    auth = request.headers.get("Authorization","")
    if not auth.startswith("Bearer "):
        abort(401, description="missing bearer token")
    token = auth.split(" ",1)[1]
    jwks = _jwks()
    headers = jwt.get_unverified_header(token)
    key = next((k for k in jwks["keys"] if k["kid"] == headers.get("kid")), None)
    if not key: abort(401, description="invalid kid")
    claims = jwt.decode(
        token, key, algorithms=[key["alg"]],
        audience=current_app.config["SUPABASE_JWT_AUDIENCE"],
        issuer=current_app.config["SUPABASE_JWT_ISSUER"],
        options={"verify_exp": True}
    )
    sub = claims.get("sub")
    email = claims.get("email")
    user = User.query.filter_by(external_sub=sub).first()
    if not user:
        user = User(email=email or f"{sub}@supabase.local", external_sub=sub)
        db.session.add(user); db.session.commit()
    return user.id
