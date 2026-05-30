from sqlalchemy import Column, String
from app.db.base import Base

# Country Table
class Country(Base):
  __tablename__ = "country"

  iso2 = Column(String(2), primary_key=True, index=True)
  name = Column(String(100), nullable=False)