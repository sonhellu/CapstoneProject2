import firebase_admin
from firebase_admin import auth, credentials

_app = None


def _get_app() -> firebase_admin.App:
    global _app
    if _app is None:
        cred = credentials.Certificate("firebase-service-account.json")
        _app = firebase_admin.initialize_app(cred)
    return _app


def verify_token(id_token: str) -> dict:
    """Verify Firebase ID token, return decoded claims (uid, email, ...)."""
    _get_app()
    return auth.verify_id_token(id_token)
