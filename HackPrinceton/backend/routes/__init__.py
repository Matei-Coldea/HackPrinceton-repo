# routes/__init__.py
import time, requests
from jose import jwt, JWTError
from flask import request, abort, current_app
from models import db, User

_cache = {"jwks": None, "exp": 0}

def _jwks():
    now = int(time.time())
    if _cache["jwks"] and now < _cache["exp"]:
        return _cache["jwks"]
    project_url = current_app.config["SUPABASE_PROJECT_URL"].rstrip("/")
    url = current_app.config.get("SUPABASE_JWKS_URL") or f"{project_url}/auth/v1/.well-known/jwks.json"
    r = requests.get(url, timeout=5)
    r.raise_for_status()
    _cache["jwks"] = r.json()
    _cache["exp"] = now + 300
    return _cache["jwks"]  # <- return the cached object, not recursion

def get_current_user_id() -> int:
    auth = request.headers.get("Authorization", "")
    if not auth.startswith("Bearer "):
        abort(401, description="missing bearer token")
    token = auth.split(" ", 1)[1]

    issuer   = current_app.config["SUPABASE_JWT_ISSUER"]
    audience = current_app.config.get("SUPABASE_JWT_AUDIENCE", "authenticated")

    try:
        hdr = jwt.get_unverified_header(token)
        alg = hdr.get("alg", "HS256")

        if alg.startswith("RS"):
            jwks = _jwks()
            kid = hdr.get("kid")
            key = next((k for k in jwks.get("keys", []) if k.get("kid") == kid), None)
            if not key:
                abort(401, description="invalid kid")
            claims = jwt.decode(token, key, algorithms=[alg], audience=audience, issuer=issuer)
        else:
            secret = current_app.config.get("SUPABASE_JWT_SECRET")
            if not secret:
                abort(500, description="server missing SUPABASE_JWT_SECRET for HS256 tokens")
            claims = jwt.decode(token, secret, algorithms=["HS256"], audience=audience, issuer=issuer)

    except JWTError as e:
        abort(401, description=f"jwt error: {str(e)}")

    sub = claims["sub"]
    email = claims.get("email") or f"{sub}@supabase.local"

    user = User.query.filter_by(external_sub=sub).first()
    if not user:
        user = User(email=email, external_sub=sub)
        db.session.add(user)
        db.session.commit()

    return user.id
