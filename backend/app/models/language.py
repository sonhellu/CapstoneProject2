from sqlalchemy import Column, String
from sqlalchemy.sql import func
from app.db.base import Base

class Language(Base):
    __tablename__ = "language"
    
    code = Column(String(10), primary_key=True)
    name = Column(String(50), nullable=False)