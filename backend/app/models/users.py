# app/models/user.py (또는 models.py)
from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, FetchedValue
from sqlalchemy.sql import func
from app.db.base import Base  # 팀의 Base 설정에 맞게 import

class Language(Base):
    __tablename__ = "language"
    
    code = Column(String(10), primary_key=True)
    name = Column(String(50), nullable=False)

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    nickname = Column(String(100), nullable=False)
    
    nationality_iso2 = Column(String(2), ForeignKey("country.iso2"), nullable=False)
    main_language = Column(String(10), ForeignKey("language.code"), nullable=False)
    
    school_id = Column(Integer, ForeignKey("schools.id"), nullable=True)
    department_id = Column(Integer, ForeignKey("departments.id"), nullable=True)
    
    # DB가 자동으로 계산하는 컬럼이므로 FetchedValue() 처리
    is_helper = Column(Boolean, server_default=FetchedValue())
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    last_login = Column(DateTime(timezone=True), nullable=True)