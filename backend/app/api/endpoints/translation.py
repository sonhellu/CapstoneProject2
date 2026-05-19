from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List
import asyncio
import requests
import os
from dotenv import load_dotenv

router = APIRouter(prefix="/translate", tags=["translate"])

# ---- Data Models ----
class TranslationItem(BaseModel):
    id: int    # Flutter에서 보낸 고유 ID
    text: str  # 원문

class TranslationRequest(BaseModel):
    items: List[TranslationItem] 
    target_lang: str = "vi"  # 기본값 베트남어로 세팅

class TranslatedItem(BaseModel):
    id: int
    translated: str

class TranslationResponse(BaseModel):
    results: List[TranslatedItem]

GOOGLE_API_KEY = os.getenv("GOOGLE_TRANSLATOR_API_KEY")

def conduct_google_api_translation(texts: List[str], target_lang: str) -> List[str]:
    # 1. 빈 문자열 및 양끝 공백 제거, 완전 빈 값은 구글로 안 보내고 필터링
    cleaned_texts = [t.strip() for t in texts if t and t.strip()]
    
    if not cleaned_texts:
        return []

    url = f"https://translation.googleapis.com/language/translate/v2?key={GOOGLE_API_KEY}"
    translated_results = []
    
    # 2. 400 에러(용량/개수 초과) 방지를 위해 안전하게 50개 단위로 쪼개서 구글에 요청
    safe_chunk_size = 50
    for i in range(0, len(cleaned_texts), safe_chunk_size):
        chunk = cleaned_texts[i:i + safe_chunk_size]
        
        payload = {
            "q": chunk,
            "target": target_lang,
            "format": "text"
        }
        
        try:
            response = requests.post(url, json=payload, timeout=10)
            
            # 만약 여기서 또 400이 나면 어떤 문장 때문에 에러가 났는지 로그를 찍어 확인
            if response.status_code != 200:
                print(f"❌ 구글 응답 에러 원인 파악용 로그: {response.text}")
                
            response.raise_for_status()
            
            data = response.json()
            chunk_translated = [res['translatedText'] for res in data['data']['translations']]
            translated_results.extend(chunk_translated)
            
        except Exception as e:
            print(f"❌ Google API 하위 청크 통신 실패: {e}")
            if 'response' in locals() and response is not None:
                print(f"🚨 구글이 보낸 진짜 차단 메시지: {response.text}")
            raise e

    # 3. 만약 원문 중 공백이 필터링되어 개수가 안 맞을 것을 대비한 안전 매칭 로직
    # (일단은 원본 texts와 인덱스를 맞추기 위해 변환 성공한 리스트를 반환)
    return translated_results

# ---- 엔드포인트 ----
@router.post("", response_model=TranslationResponse)
async def translate_web_content(request: TranslationRequest):
    origin_texts = [item.text for item in request.items]
    
    if not origin_texts:
        return TranslationResponse(results=[])

    # 비동기 실행으로 동기 requests 라이브러리로 인한 서버 Hang(멈춤) 현상 방지
    loop = asyncio.get_event_loop()
    try:
        translated_texts = await loop.run_in_executor(
            None, conduct_google_api_translation, origin_texts, request.target_lang
        )
    except Exception as e:
        # 구글 API 에러 발생 시 최후의 보루로 원문 배열을 대입하여 대응
        raise HTTPException(status_code=500, detail=f"Google API Error: {str(e)}")

    # 원래 요청받은 고유 ID와 번역된 텍스트 1:1 매칭
    results = [
        TranslatedItem(
            id=item.id, 
            translated=translated_texts[i] if i < len(translated_texts) else item.text
        )
        for i, item in enumerate(request.items)
    ]
    
    return TranslationResponse(results=results)