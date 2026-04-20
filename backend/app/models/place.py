from sqlalchemy import Column, Integer, String, Float, Text, ForeignKey, DateTime
from sqlalchemy.sql import func
from app.db.base_class import Base # 팀 프로젝트의 공통 Base 클래스 경로 확인 필요

class Place(Base):
    __tablename__ = "places"

    id = Column(Integer, primary_key=True, index=True)
    api_id = Column(String(100), unique=True)
    name_ko = Column(String(255), nullable=False)
    name_en = Column(String(255))
    category = Column(String(50))
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    created_at = Column(DateTime, server_default=func.now())

class Review(Base):
    __tablename__ = "reviews"

    id = Column(Integer, primary_key=True, index=True)
    place_id = Column(Integer, ForeignKey("places.id"))
    user_id = Column(Integer) # 실제 구현 시 users.id와 연결
    rating = Column(Integer)
    content = Column(Text)
    created_at = Column(DateTime, server_default=func.now())