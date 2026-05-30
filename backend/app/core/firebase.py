import json
import os

import firebase_admin
from firebase_admin import auth, credentials

_app = None


def _get_app() -> firebase_admin.App:
    global _app
    if _app is not None:
        return _app

    # 1. Prefer JSON string injected as env var (Railway / prod)
    raw = os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON")
    if raw:
        cred = credentials.Certificate(json.loads(raw))
    else:
        # 2. Fall back to local file (local dev)
        cred = credentials.Certificate("firebase-service-account.json")

    _app = firebase_admin.initialize_app(cred)
    return _app


def verify_token(id_token: str) -> dict:
    """Verify Firebase ID token, return decoded claims (uid, email, ...)."""
    _get_app()
    return auth.verify_id_token(id_token)
