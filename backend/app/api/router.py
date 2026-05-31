from fastapi import APIRouter

from app.api.endpoints import auth, users, rent, translation
from app.api import posts

api_router = APIRouter()

api_router.include_router(auth.router)
api_router.include_router(posts.router)
api_router.include_router(users.router)
api_router.include_router(rent.router)
api_router.include_router(translation.router)
