from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.sql import func
from app.db.base import Base

# Departments Table
class Departments(Base):
  __tablename__ = "departments"

  id = Column(Integer, primary_key=True, index=True)
  school_id = Column(Integer, ForeignKey("schools.id"))
  name = Column(String(255), nullable=False)