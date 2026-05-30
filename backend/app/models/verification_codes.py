from sqlalchemy import Column, Integer, String, DateTime
from app.db.base import Base

# Email Verification Table
class VerificationCodes(Base):
  __tablename__ = "verification_codes"

  id = Column(Integer, primary_key=True)
  email = Column(String(255), nullable=False)
  code = Column(String(6), nullable=False)
  expiry_time = Column(DateTime(timezone=True), nullable=False)