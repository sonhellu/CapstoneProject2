import json
import logging
import os

import firebase_admin
from firebase_admin import auth, credentials

logger = logging.getLogger(__name__)

_app = None


def _get_app() -> firebase_admin.App:
    global _app
    if _app is not None:
        return _app

    raw = os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON")
    if raw:
        try:
            parsed = json.loads(raw)
            logger.info("Firebase: loaded from env var, project_id=%s", parsed.get("project_id"))
            cred = credentials.Certificate(parsed)
        except Exception as e:
            logger.error("Firebase: failed to parse FIREBASE_SERVICE_ACCOUNT_JSON: %s", e)
            raise
    else:
        logger.info("Firebase: loading from local file")
        cred = credentials.Certificate("firebase-service-account.json")

    _app = firebase_admin.initialize_app(cred)
    logger.info("Firebase: app initialized OK")
    return _app


def verify_token(id_token: str) -> dict:
    """Verify Firebase ID token, return decoded claims (uid, email, ...)."""
    try:
        _get_app()
        return auth.verify_id_token(id_token)
    except Exception as e:
        logger.error("Firebase: verify_token failed: %s", e)
        raise
