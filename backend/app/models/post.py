from sqlalchemy import Column, Integer, String, Text, ForeignKey, Boolean, DateTime
from sqlalchemy.sql import func
from app.db.base import Base

class Post(Base):
    __tablename__ = "posts"

    id = Column(Integer, primary_key=True, index=True)
    firebase_uid = Column(String(128), nullable=False, index=True)
    author_name = Column(String(100))
    author_avatar_initial = Column(String(5))
    author_school = Column(String(255))
    title = Column(String(255), nullable=False)
    content = Column(Text, nullable=False)
    category = Column(String(50))
    language_code = Column(String(10))
    is_anonymous = Column(Boolean, default=False)
    image_url = Column(String(1024), nullable=True)
    like_count = Column(Integer, default=0)
    view_count = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class PostTranslation(Base):
    __tablename__ = "post_translations"

    id = Column(Integer, primary_key=True, index=True)
    post_id = Column(Integer, ForeignKey("posts.id", ondelete="CASCADE"))
    language_code = Column(String(10))
    translated_title = Column(String(255))
    translated_content = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class Comment(Base):
    __tablename__ = "comments"

    id = Column(Integer, primary_key=True, index=True)
    post_id = Column(Integer, ForeignKey("posts.id", ondelete="CASCADE"))
    firebase_uid = Column(String(128), nullable=False)
    author_name = Column(String(100))
    author_avatar_initial = Column(String(5))
    content = Column(Text, nullable=False)
    is_anonymous = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
