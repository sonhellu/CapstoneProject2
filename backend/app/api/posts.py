from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from typing import List, Optional

# 우리가 앞으로 만들 모델과 스키마를 불러옵니다
from app.models.post import Post
from app.schemas.post import PostResponse
from app.db.session import get_db # DB 연결용 함수 (팀 프로젝트 설정에 따라 확인 필요)

router = APIRouter()

@router.get("/", response_model=List[PostResponse])
def read_posts(
    last_id: Optional[int] = Query(None, description="마지막으로 본 게시글 ID"),
    size: int = Query(10, ge=1, le=50, description="한 번에 가져올 게시글 수"),
    db: Session = Depends(get_db)
):
    """
    에브리타임 스타일의 무한 스크롤(커서 기반 페이지네이션) API
    """
    # 1. 기본 쿼리: 최신순(ID 내림차순)으로 정렬
    query = db.query(Post).order_by(Post.id.desc())
    
    # 2. 커서 로직: last_id가 있으면 그보다 작은(이전에 작성된) 글들만 필터링
    if last_id:
        query = query.filter(Post.id < last_id)
    
    # 3. 개수 제한 후 반환
    posts = query.limit(size).all()
    return posts
