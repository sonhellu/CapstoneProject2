import logging
import os
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from app.api.router import api_router
from app.core.config import settings
from app.db.session import engine
from app.db.base import Base

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    logger.info("DB tables created OK")

    # Eagerly init Firebase so Railway does not report a healthy app while
    # authenticated endpoints are guaranteed to fail.
    raw = os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON")
    logger.info("FIREBASE_SERVICE_ACCOUNT_JSON present: %s", bool(raw))
    try:
        from app.core.firebase import _get_app
        _get_app()
        logger.info("Firebase initialized OK")
    except Exception as e:
        logger.exception("Firebase init FAILED")
        raise RuntimeError("Firebase initialization failed") from e

    yield
    engine.dispose()


app = FastAPI(
    title="hicampus API",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix="/api")


@app.get("/", tags=["Health"])
def health_check():
    return {"status": "ok", "app": "hicampus"}


@app.get("/ready", tags=["Health"])
def readiness_check():
    from app.core.firebase import _get_app

    with engine.connect() as conn:
        conn.execute(text("SELECT 1"))
    _get_app()
    return {"status": "ready", "database": "ok", "firebase": "ok"}
