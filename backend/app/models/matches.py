from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, CheckConstraint
from sqlalchemy.sql import func
from app.db.base import Base

# Matches Table
class Matches(Base):
    __tablename__ = "matches"
    __table_args__ = (
        CheckConstraint(
            "student_id <> helper_id", 
            name="chk_different_user"
        ),
    )

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    helper_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    status = Column(String(20), server_default="active")
    created_at = Column(DateTime(timezone=True), server_default=func.now())