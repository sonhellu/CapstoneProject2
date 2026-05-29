from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List
import asyncio
import requests
import redis
import html

from app.core.config import settings

router = APIRouter(prefix="/translate", tags=["translate"])

# ---- Data Models ----
class TranslationItem(BaseModel):
    id: int    # Flutter에서 보낸 고유 ID
    text: str  # 원문

class TranslationRequest(BaseModel):
    items: List[TranslationItem] 
    target_lang: str = "en"  # 기본값 영어로 세팅

class TranslatedItem(BaseModel):
    id: int
    translated: str

class TranslationResponse(BaseModel):
    results: List[TranslatedItem]

GOOGLE_API_KEY = settings.GOOGLE_TRANSLATOR_API_KEY

# Redis 연결
r = redis.Redis(host='localhost', port=6379, decode_responses=True)

def conduct_pure_redis_translation(items: List[TranslationItem], target_lang: str) -> List[TranslatedItem]:
    if not items:
        return []

    final_results = []
    texts_to_api = []
    
    try:
        # ---- 1단계: Redis 캐시 일괄 조회 ----
        for item in items:
            clean_text = item.text.strip()
            redis_key = f"{target_lang}:{clean_text}"
            
            cached_text = r.get(redis_key)
            
            if cached_text:
                final_results.append(TranslatedItem(id=item.id, translated=cached_text))
            else:
                texts_to_api.append(clean_text)
                final_results.append(TranslatedItem(id=item.id, translated="")) # 우선 빈값으로 예약

        # ---- 2단계: 캐시 미스된 문장들만 모아서 구글 API 호출 ----
        if texts_to_api:
            print(f"ℹ️ [Redis Cache Miss] {len(texts_to_api)}개의 새로운 문장 구글 API 요청")
            
            url = f"https://translation.googleapis.com/language/translate/v2?key={GOOGLE_API_KEY}"
            payload = {"q": texts_to_api, "target": target_lang, "format": "text"}
            
            # 💡 보완: 구글 API가 죽더라도 기존 캐시 히트 데이터는 살리기 위해 try-except로 한 번 더 감싸기
            try:
                response = requests.post(url, json=payload, timeout=10)
                
                if response.status_code != 200:
                    print(f"❌ 구글 응답 에러 (안전장치 작동): {response.text}")
                    response.raise_for_status()
                
                data = response.json()
                # 💡 보완: html.unescape()를 적용하여 특수문자 문장 깨짐 현상 예방
                api_outputs = [
                    html.unescape(res['translatedText']) 
                    for res in data['data']['translations']
                ]
                
                # ---- 3단계: 신규 번역본 Redis에 저장 ----
                for orig, trans in zip(texts_to_api, api_outputs):
                    redis_key = f"{target_lang}:{orig}"
                    r.set(redis_key, trans, ex=2592000) 
                
                print(f"✅ 신규 번역 {len(texts_to_api)}건 Redis 캐시 기록 완료 (TTL: 30일)")
                
                # ---- 4단계: 비어있던 결과 배열 채우기 ----
                api_idx = 0
                for res in final_results:
                    if res.translated == "":
                        res.translated = api_outputs[api_idx]
                        api_idx += 1
                        
            except Exception as api_err:
                print(f"⚠️ 구글 API 통신 실패로 미스된 {len(texts_to_api)}건 원문 복구 처리: {api_err}")
                # 구글 API 내부가 터지면 미스된 문장들만 원래 한국어 텍스트로 복구 (웹뷰 렌더링 유지 방어벽)
                # 매핑 순서를 안전하게 맞추기 위해 원문 복구용 사전 준비
                orig_idx = 0
                for res in final_results:
                    if res.translated == "":
                        res.translated = texts_to_api[orig_idx]
                        orig_idx += 1

    except Exception as e:
        print(f"💥 Redis 파이프라인 전반부 치명적 에러: {e}")
        raise e

    return final_results

# ---- 엔드포인트 ----
@router.post("", response_model=TranslationResponse)
async def translate_web_content(request: TranslationRequest):
    if not request.items:
        return TranslationResponse(results=[])

    # 비동기 이벤트 루프 스레드풀에서 동기(requests, redis) 연산을 실행하여 대기 차단 방지
    loop = asyncio.get_event_loop()
    try:
        results = await loop.run_in_executor(
            None, conduct_pure_redis_translation, request.items, request.target_lang
        )
        return TranslationResponse(results=results)
    except Exception as e:
        # 구글 API 한도 초과(403)나 Redis 오류 시 500을 뱉어 Flutter가 온디바이스(ML Kit)로 롤백하게 만듦
        raise HTTPException(status_code=500, detail=str(e))