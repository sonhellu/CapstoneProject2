from fastapi import APIRouter, Depends
from pydantic import BaseModel

from app.api.deps import get_current_user

router = APIRouter(prefix="/auth", tags=["Auth"])


class MeResponse(BaseModel):
    uid: str
    email: str | None = None
    name: str | None = None


@router.get("/me", response_model=MeResponse)
def get_me(user: dict = Depends(get_current_user)):
    """Return uid, email, name of the currently authenticated user."""
    return MeResponse(
        uid=user["uid"],
        email=user.get("email"),
        name=user.get("name"),
    )
