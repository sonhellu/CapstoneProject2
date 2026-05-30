import logging
import os
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

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

    # Eagerly init Firebase so startup fails fast if credentials are wrong
    raw = os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON")
    logger.info("FIREBASE_SERVICE_ACCOUNT_JSON present: %s (len=%d)", bool(raw), len(raw or ""))
    try:
        from app.core.firebase import _get_app
        _get_app()
        logger.info("Firebase initialized OK")
    except Exception as e:
        logger.error("Firebase init FAILED: %s", e)

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
