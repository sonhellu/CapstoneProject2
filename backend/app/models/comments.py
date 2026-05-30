from sqlalchemy import Column, Integer, Boolean, ForeignKey, DateTime, Text
from sqlalchemy.sql import func
from app.db.base import Base

# Comments Table
class Comments(Base):
  __tablename__ = "comments"

  id = Column(Integer, primary_key=True)
  post_id = Column(Integer, ForeignKey("posts.id", ondelete="CASCADE"))
  author_id = Column(Integer, ForeignKey("users.id"))
  content = Column(Text, nullable=False)
  is_anonymous = Column(Boolean, server_default="FALSE")
  created_at = Column(DateTime(timezone=True), server_default=func.now())