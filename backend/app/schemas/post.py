from typing import Optional, List
from pydantic import BaseModel
from datetime import datetime


class PostCreate(BaseModel):
    title: str
    content: str
    category: Optional[str] = None
    language_code: Optional[str] = None
    is_anonymous: bool = False
    author_name: Optional[str] = None
    author_avatar_initial: Optional[str] = None
    author_school: Optional[str] = None
    image_url: Optional[str] = None


class PostUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None


class PostResponse(BaseModel):
    id: int
    firebase_uid: str
    author_name: Optional[str] = None
    author_avatar_initial: Optional[str] = None
    author_school: Optional[str] = None
    title: str
    content: str
    category: Optional[str] = None
    language_code: Optional[str] = None
    is_anonymous: bool
    image_url: Optional[str] = None
    like_count: int
    view_count: int
    created_at: datetime

    class Config:
        from_attributes = True


class CommentCreate(BaseModel):
    content: str
    is_anonymous: bool = False
    author_name: Optional[str] = None
    author_avatar_initial: Optional[str] = None


class CommentResponse(BaseModel):
    id: int
    post_id: int
    firebase_uid: str
    author_name: Optional[str] = None
    author_avatar_initial: Optional[str] = None
    content: str
    is_anonymous: bool
    created_at: datetime

    class Config:
        from_attributes = True


class PostWithTranslationResponse(BaseModel):
    post: PostResponse
    translation: Optional[dict] = None
