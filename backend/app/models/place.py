from sqlalchemy import Column, Integer, String, Numeric, Text, ForeignKey, Boolean, DateTime, SmallInteger
from sqlalchemy.sql import func
from app.db.base import Base


class Place(Base):
    __tablename__ = "places"

    place_id = Column(Integer, primary_key=True, index=True)
    api_id = Column(String(100), unique=True)
    school_id = Column(Integer, nullable=True)
    name_ko = Column(String(255), nullable=False)
    name_en = Column(String(255))
    category = Column(String(50), nullable=False)
    address = Column(Text)
    latitude = Column(Numeric(10, 8), nullable=False)
    longitude = Column(Numeric(11, 8), nullable=False)
    is_official = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class Review(Base):
    __tablename__ = "reviews"

    review_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    place_id = Column(Integer, ForeignKey("places.place_id", ondelete="CASCADE"), nullable=False)
    rating = Column(SmallInteger, nullable=False)
    content = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
