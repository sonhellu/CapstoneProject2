from fastapi import APIRouter

from app.api.endpoints import auth, pins, posts, users, chat

api_router = APIRouter()

api_router.include_router(auth.router)
api_router.include_router(pins.router)
api_router.include_router(posts.router)
api_router.include_router(users.router)
api_router.include_router(chat.router)
