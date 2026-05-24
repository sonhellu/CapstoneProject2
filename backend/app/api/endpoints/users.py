# TODO: User profile endpoints
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.core.firebase import verify_token  # 💡 파이어베이스 토큰 해독기 가져오기
from app.models import users          # 유저 SQL 모델

router = APIRouter(prefix="/users", tags=["Users"])
bearer_scheme = HTTPBearer()

@router.get("/me")
def get_user_profile(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    db: Session = Depends(get_db)
):
    """
    현재 로그인한 유저의 프로필(DB 정보 + 메인 언어)을 가져오는 API
    """
    try:
        # 1. Flutter가 보낸 Bearer 토큰을 해독합니다.
        decoded = verify_token(credentials.credentials)
        
        # 2. 파이어베이스 토큰 안에 들어있는 유저의 이메일을 쏙 빼냅니다.
        # 인증 방식이 이메일인지 확인 필요
        user_email = decoded.get("email")
        
        if not user_email:
            raise HTTPException(status_code=400, detail="Token does not contain an email address")
            
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        )

    # 3. ⭐️ 핵심: 파이어베이스 이메일을 가지고 우리 PostgreSQL DB에서 유저를 찾습니다!
    user = db.query(users).filter(users.email == user_email).first()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found in PostgreSQL Database")
        
    # 4. 정보를 이쁘게 담아서 리턴합니다.
    return {
        "id": user.id,
        "email": user.email,
        "nickname": user.nickname,
        "nationality_iso2": user.nationality_iso2,
        "main_language": user.main_language,
        "is_helper": user.is_helper
    }