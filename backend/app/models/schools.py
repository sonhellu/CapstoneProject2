from sqlalchemy import Column, Integer, String, Text, Numeric
from app.db.base import Base

# Shcools Table
class Schools(Base):
  __tablename__ = "schools"

  id = Column(Integer, primary_key=True, index=True)
  name = Column(String(255), nullable=False)
  website_url = Column(Text)
  location_lat = Column(Numeric(10, 8))
  location_lng = Column(Numeric(11, 8))