from typing import Optional, List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_uid
from app.db.session import get_db
from app.models.post import Post, PostTranslation, Comment
from app.schemas.post import (
    PostCreate, PostUpdate, PostResponse,
    CommentCreate, CommentResponse,
)

router = APIRouter(prefix="/posts", tags=["Posts"])


@router.get("/")
def read_posts(
    category: Optional[str] = None,
    last_id: Optional[int] = None,
    size: int = 20,
    lang: str = "en",
    db: Session = Depends(get_db),
):
    query = db.query(Post).order_by(Post.id.desc())
    if category:
        query = query.filter(Post.category == category)
    if last_id:
        query = query.filter(Post.id < last_id)

    posts = query.limit(size).all()

    result = []
    for post in posts:
        translation = db.query(PostTranslation).filter(
            PostTranslation.post_id == post.id,
            PostTranslation.language_code == lang,
        ).first()
        result.append({"post": post, "translation": translation})

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
    return post


@router.patch("/{post_id}", response_model=PostResponse)
def update_post(
    post_id: int,
    data: PostUpdate,
    uid: str = Depends(get_current_uid),
    db: Session = Depends(get_db),
):
    post = db.query(Post).filter(Post.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    if post.firebase_uid != uid:
        raise HTTPException(status_code=403, detail="Not your post")

    if data.title is not None:
        post.title = data.title
    if data.content is not None:
        post.content = data.content

    db.commit()
    db.refresh(post)
    return post


@router.delete("/{post_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_post(
    post_id: int,
    uid: str = Depends(get_current_uid),
    db: Session = Depends(get_db),
):
    post = db.query(Post).filter(Post.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    if post.firebase_uid != uid:
        raise HTTPException(status_code=403, detail="Not your post")

    db.delete(post)
    db.commit()


@router.get("/{post_id}/comments", response_model=List[CommentResponse])
def get_comments(
    post_id: int,
    db: Session = Depends(get_db),
):
    if not db.query(Post).filter(Post.id == post_id).first():
        raise HTTPException(status_code=404, detail="Post not found")
    return db.query(Comment).filter(
        Comment.post_id == post_id
    ).order_by(Comment.created_at).all()


@router.post("/{post_id}/comments", response_model=CommentResponse, status_code=status.HTTP_201_CREATED)
def add_comment(
    post_id: int,
    data: CommentCreate,
    uid: str = Depends(get_current_uid),
    db: Session = Depends(get_db),
):
    if not db.query(Post).filter(Post.id == post_id).first():
        raise HTTPException(status_code=404, detail="Post not found")

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
