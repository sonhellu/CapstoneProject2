from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import Optional

from app.models.post import Post, PostTranslation
from app.db.session import get_db

router = APIRouter(prefix="/posts", tags=["posts"])

@router.get("/")
def read_posts(
    board_id: int,
    last_id: Optional[int] = None,
    size: int = 10,
    lang: str = "en", # 사용자가 보고 싶은 언어
    db: Session = Depends(get_db)
):
    # 기본 게시글 쿼리
    query = db.query(Post).filter(Post.board_id == board_id).order_by(Post.id.desc())
    
    if last_id:
        query = query.filter(Post.id < last_id)
    
    posts = query.limit(size).all()
    
    # 각 게시글에 대해 요청한 언어의 번역본이 있는지 확인하여 합쳐서 반환
    result = []
    for post in posts:
        translation = db.query(PostTranslation).filter(
            PostTranslation.post_id == post.id,
            PostTranslation.language_code == lang
        ).first()
        
        result.append({
            "post": post,
            "translation": translation # 번역본이 없으면 null
        })
        
    return result
