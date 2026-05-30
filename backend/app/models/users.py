from sqlalchemy import Column, Integer, String, Boolean, DateTime
from sqlalchemy.sql import func
from app.db.base import Base


class Language(Base):
    __tablename__ = "language"

    code = Column(String(10), primary_key=True)
    name = Column(String(50), nullable=False)


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, nullable=False)
    password_hash = Column(String(255), nullable=True)
    nickname = Column(String(100), nullable=False)

    nationality_iso2 = Column(String(2), nullable=True)
    main_language = Column(String(10), nullable=True)

    school_id = Column(Integer, nullable=True)
    department_id = Column(Integer, nullable=True)

    is_helper = Column(Boolean, server_default="false")

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    last_login = Column(DateTime(timezone=True), nullable=True)
