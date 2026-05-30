from sqlalchemy import Column, Integer, DateTime, ForeignKey
from sqlalchemy.sql import func
from app.db.base import Base

# Chat Rooms Table
class ChatRooms(Base):
    __tablename__ = "chat_rooms"

    id = Column(Integer, primary_key=True, index=True)
    match_id = Column(Integer, ForeignKey("matches.id", ondelete="CASCADE"))
    created_at = Column(DateTime(timezone=True), server_default=func.now())