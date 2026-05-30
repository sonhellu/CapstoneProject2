from typing import Optional, List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.api.deps import get_current_uid
from app.db.session import get_db
from app.models.post import Post, PostTranslation, Comment
from app.schemas.post import (
    PostCreate, PostUpdate, PostResponse,
    CommentCreate, CommentResponse,
    PostWithTranslationResponse,
)

router = APIRouter(prefix="/posts", tags=["Posts"])


def _post_payload(post: Post, comments_count: int = 0) -> dict:
    return {
        "id": post.id,
        "firebase_uid": post.firebase_uid,
        "author_name": post.author_name,
        "author_avatar_initial": post.author_avatar_initial,
        "author_school": post.author_school,
        "title": post.title,
        "content": post.content,
        "category": post.category,
        "language_code": post.language_code,
        "is_anonymous": post.is_anonymous,
        "image_url": post.image_url,
        "like_count": post.like_count or 0,
        "comments_count": comments_count,
        "view_count": post.view_count or 0,
        "created_at": post.created_at,
    }


def _translation_payload(translation: PostTranslation | None) -> dict | None:
    if translation is None:
        return None
    return {
        "id": translation.id,
        "post_id": translation.post_id,
        "language_code": translation.language_code,
        "translated_title": translation.translated_title,
        "translated_content": translation.translated_content,
        "created_at": translation.created_at,
    }


def _get_post_or_404(post_id: int, db: Session) -> Post:
    post = db.query(Post).filter(Post.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    return post


@router.get("/", response_model=List[PostWithTranslationResponse])
def read_posts(
    category: Optional[str] = None,
    last_id: Optional[int] = None,
    size: int = 20,
    lang: str = "en",
    db: Session = Depends(get_db),
):
    size = max(1, min(size, 50))
    query = (
        db.query(Post, func.count(Comment.id).label("comments_count"))
        .outerjoin(Comment, Comment.post_id == Post.id)
        .group_by(Post.id)
        .order_by(Post.id.desc())
    )
    if category:
        query = query.filter(Post.category == category)
    if last_id:
        query = query.filter(Post.id < last_id)

    rows = query.limit(size).all()

    result = []
    for post, comments_count in rows:
        translation = db.query(PostTranslation).filter(
            PostTranslation.post_id == post.id,
            PostTranslation.language_code == lang,
        ).first()
        result.append({
            "post": _post_payload(post, comments_count),
            "translation": _translation_payload(translation),
        })

    return result


@router.post("/", response_model=PostResponse, status_code=status.HTTP_201_CREATED)
def create_post(
    data: PostCreate,
    uid: str = Depends(get_current_uid),
    db: Session = Depends(get_db),
):
    post = Post(
        firebase_uid=uid,
        title=data.title,
        content=data.content,
        category=data.category,
        language_code=data.language_code,
        is_anonymous=data.is_anonymous,
        author_name=None if data.is_anonymous else data.author_name,
        author_avatar_initial=None if data.is_anonymous else data.author_avatar_initial,
        author_school=None if data.is_anonymous else data.author_school,
        image_url=data.image_url,
    )
    db.add(post)
    db.commit()
    db.refresh(post)
    return _post_payload(post)


@router.patch("/{post_id}", response_model=PostResponse)
def update_post(
    post_id: int,
    data: PostUpdate,
    uid: str = Depends(get_current_uid),
    db: Session = Depends(get_db),
):
    post = _get_post_or_404(post_id, db)
    if post.firebase_uid != uid:
        raise HTTPException(status_code=403, detail="Not your post")

    if data.title is not None:
        post.title = data.title
    if data.content is not None:
        post.content = data.content

    db.commit()
    db.refresh(post)
    comments_count = db.query(func.count(Comment.id)).filter(
        Comment.post_id == post.id
    ).scalar() or 0
    return _post_payload(post, comments_count)


@router.delete("/{post_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_post(
    post_id: int,
    uid: str = Depends(get_current_uid),
    db: Session = Depends(get_db),
):
    post = _get_post_or_404(post_id, db)
    if post.firebase_uid != uid:
        raise HTTPException(status_code=403, detail="Not your post")

    db.delete(post)
    db.commit()


@router.get("/{post_id}/comments", response_model=List[CommentResponse])
def get_comments(
    post_id: int,
    db: Session = Depends(get_db),
):
    _get_post_or_404(post_id, db)
    return db.query(Comment).filter(
        Comment.post_id == post_id
    ).order_by(Comment.created_at.desc()).all()


@router.post("/{post_id}/comments", response_model=CommentResponse, status_code=status.HTTP_201_CREATED)
def add_comment(
    post_id: int,
    data: CommentCreate,
    uid: str = Depends(get_current_uid),
    db: Session = Depends(get_db),
):
    _get_post_or_404(post_id, db)

    comment = Comment(
        post_id=post_id,
        firebase_uid=uid,
        content=data.content,
        is_anonymous=data.is_anonymous,
        author_name=None if data.is_anonymous else data.author_name,
        author_avatar_initial=None if data.is_anonymous else data.author_avatar_initial,
    )
    db.add(comment)
    db.commit()
    db.refresh(comment)
    return comment


@router.post("/{post_id}/like", response_model=PostResponse)
def like_post(
    post_id: int,
    uid: str = Depends(get_current_uid),
    db: Session = Depends(get_db),
):
    del uid
    post = _get_post_or_404(post_id, db)
    post.like_count = (post.like_count or 0) + 1
    db.commit()
    db.refresh(post)
    comments_count = db.query(func.count(Comment.id)).filter(
        Comment.post_id == post.id
    ).scalar() or 0
    return _post_payload(post, comments_count)
