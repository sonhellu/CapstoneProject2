from sqlalchemy import Column, Integer, String, Text
from app.db.base import Base

# Boards Table
class Boards(Base):
  __tablename__ = "boards"

  id = Column(Integer, primary_key=True)
  name = Column(String(100), nullable=False)
  desciption = Column(Text)