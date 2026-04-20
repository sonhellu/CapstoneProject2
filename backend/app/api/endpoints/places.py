from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.schemas.place import PlaceCreate
from app.models.place import Place, Review
from app.services.translation import translate_text
# DB 세션 연결용 함수 필요 (예: get_db)

router = APIRouter()

@router.post("/")
async def create_place(data: PlaceCreate, db: Session = Depends(get_db)):
    # 1. 이름 번역
    translated_name = translate_text(data.name_ko)
    
    # 2. 장소 정보 저장
    db_place = Place(
        api_id=data.api_id,
        name_ko=data.name_ko,
        name_en=translated_name,
        category=data.category,
        latitude=data.latitude,
        longitude=data.longitude
    )
    db.add(db_place)
    db.commit()
    db.refresh(db_place)

    # 3. 함께 온 리뷰 저장
    db_review = Review(
        place_id=db_place.id,
        user_id=data.review.user_id,
        rating=data.review.rating,
        content=data.review.content
    )
    db.add(db_review)
    db.commit()
    
    return {"status": "success", "place_id": db_place.id}