from fastapi import APIRouter, Depends
from pydantic import BaseModel

from app.api.deps import get_current_uid
from app.core.firebase import verify_token

router = APIRouter(prefix="/auth", tags=["Auth"])


class MeResponse(BaseModel):
    uid: str
    email: str | None
    name: str | None


@router.get("/me", response_model=MeResponse)
def get_me(uid: str = Depends(get_current_uid)):
    """Return basic info of the currently logged-in user."""
    return MeResponse(uid=uid, email=None, name=None)
