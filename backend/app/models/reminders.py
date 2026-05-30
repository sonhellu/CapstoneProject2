from sqlalchemy import Column, Integer, String, Date, Boolean, DateTime, ForeignKey
from sqlalchemy.sql import func
from app.db.base import Base

# Reminers Table
class Reminders(Base):
  __tablename__ = "reminders"

  id = Column(Integer, primary_key=True)
  user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"))
  category = Column(String(50))
  title = Column(String(255), nullable=False)
  due_date = Column(Date, nullable=False)
  is_completed = Column(Boolean, server_default="FALSE")
  created_at = Column(DateTime(timezone=True), server_default=func.now())