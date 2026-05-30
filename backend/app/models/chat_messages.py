from sqlalchemy import Column, Integer, DateTime, ForeignKey, Boolean, Text
from sqlalchemy.sql import func
from app.db.base import Base

# Chat Messages Table
class ChatMessages(Base):
    __tablename__ = "chat_messages"

    id = Column(Integer, primary_key=True, index=True)
    room_id = Column(Integer, ForeignKey("chat_rooms.id", ondelete="CASCADE"))
    sender_id = Column(Integer, ForeignKey("users.id"))
    message_content = Column(Text, nullable=False)
    is_read = Column(Boolean, server_default="FALSE")
    created_at = Column(DateTime(timezone=True), server_default=func.now())