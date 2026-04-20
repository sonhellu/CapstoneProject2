from pydantic import BaseModel
from typing import Optional, List

class ReviewCreate(BaseModel):
    rating: int
    content: str
    user_id: int

class PlaceCreate(BaseModel):
    api_id: str
    name_ko: str
    category: str
    address: str
    latitude: float
    longitude: float
    review: ReviewCreate  # 장소 저장 시 리뷰도 같이 포함