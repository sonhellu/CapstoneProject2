from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.core.firebase import verify_token
from app.models.users import User

router = APIRouter(prefix="/users", tags=["Users"])
bearer_scheme = HTTPBearer()


@router.get("/me")
def get_user_profile(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    db: Session = Depends(get_db),
):
    try:
        decoded = verify_token(credentials.credentials)
        user_email = decoded.get("email")
        if not user_email:
            raise HTTPException(status_code=400, detail="Token does not contain an email address")
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        )

    user = db.query(User).filter(User.email == user_email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    return {
        "id": user.id,
        "email": user.email,
        "nickname": user.nickname,
        "nationality_iso2": user.nationality_iso2,
        "main_language": user.main_language,
        "is_helper": user.is_helper,
    }
