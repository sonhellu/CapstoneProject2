from sqlalchemy import Column, Integer, DateTime, Text, String
from sqlalchemy.sql import func
from app.db.base import Base

# Attachments Table
class Attachments(Base):
  __tablename__ = "attachments"

  id = Column(Integer, primary_key=True)
  owner_id = Column(Integer, nullable=False)
  owner_type = Column(String(50), nullable=False)
  file_path = Column(Text, nullable=False)
  file_size = Column(Integer)
  created_at = Column(DateTime(timezone=True), server_default=func.now())