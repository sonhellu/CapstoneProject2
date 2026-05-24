from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text

from app.db.session import get_db

router = APIRouter(prefix="/nearby", tags=["nearby"])

@router.get("/nearby")
def get_nearby_places(
    school_id: int, 
    lat: float, 
    lng: float, 
    radius: float = 1.0, 
    db: Session = Depends(get_db)
):
    # school_id로 1차 필터링 후, 거리 계산 쿼리 실행
    query = text("""
        SELECT *, (6371 * acos(cos(radians(:lat)) * cos(radians(latitude)) 
        * cos(radians(longitude) - radians(:lng)) + sin(radians(:lat)) 
        * sin(radians(latitude)))) AS distance 
        FROM places 
        WHERE school_id = :school_id
        HAVING distance < :radius 
        ORDER BY distance
    """)
    
    return db.execute(query, {"lat": lat, "lng": lng, "school_id": school_id, "radius": radius}).fetchall()
