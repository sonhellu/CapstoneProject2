from fastapi import APIRouter
from pydantic import BaseModel
from deep_translator import GoogleTranslator, MyMemoryTranslator
from typing import List
import time

router = APIRouter(prefix="/translate", tags=["translate"])

# ---- Data Models ----
class TranslationItem(BaseModel):
    id: int    # Flutter에서 보낸 고유 ID
    text: str  # 원문

class TranslationRequest(BaseModel):
    items: List[TranslationItem] # 리스트 구조 변경
    target_lang: str = "en"

class TranslatedItem(BaseModel):
    id: int
    translated: str

class TranslationResponse(BaseModel):
    results: List[TranslatedItem]

def safe_translate(translator, text):
    try:
        time.sleep(0.1)
        result = translator.translate(text)
        return result if result else text
    except Exception as e:
        print(f'번역 실패: {text[:20]}... 에러: {e}')
        return text

def conduct_pivot_translation(text, target_lang):
    """한 -> 영 -> 타겟 중계 번역 함수"""
    try:
        # 1. 한국어 -> 영어
        en_text = GoogleTranslator(source='ko', target='en').translate(text)
        if not en_text: return text
        
        # 2. 영어 -> 타겟(vi)
        final_text = GoogleTranslator(source='en', target=target_lang).translate(en_text)
        return final_text if final_text else en_text
        
    except Exception as e:
        # 구글 에러 시 MyMemory로 2차 시도 (고유명사에 강함)
        try:
            return MyMemoryTranslator(source='ko', target=target_lang).translate(text)
        except:
            return text # 모든 번역 실패 시 원문 유지

def conduct_batch_translation(texts: List[str], target_lang: str):
    try:
        # 1. 한 번의 호출로 리스트 전체 번역 (GoogleTranslator 지원 기능)
        # source='auto'로 설정하면 한국어/영어 섞여 있어도 알아서 판단합니다.
        translated_list = GoogleTranslator(source='auto', target=target_lang).translate_batch(texts)
        return translated_list
    except Exception as e:
        print(f"Batch 번역 에러: {e}")
        # 실패 시 원문 그대로 반환
        return texts

# ---- Endpoint ----
'''
@router.post("", response_model=TranslationResponse)
async def translate_web_content(request: TranslationRequest):
    # 1. 번역할 텍스트만 리스트로 추출
    origin_texts = [item.text for item in request.items]
    
    # 2. 일괄 번역 실행 (API 호출 1번!)
    # 테스트 중이라면 아래 줄을 주석 처리하고 가짜 데이터를 만드세요.
    translated_texts = conduct_batch_translation(origin_texts, request.target_lang)
    
    # 3. 다시 ID와 매칭하여 결과 생성
    results = []
    for i, item in enumerate(request.items):
        results.append(TranslatedItem(
            id=item.id, 
            translated=translated_texts[i] if i < len(translated_texts) else item.text
        ))
    
    return TranslationResponse(results=results)
'''
# translate test
@router.post("", response_model=TranslationResponse)
async def translate_web_content(request: TranslationRequest):
    # 1. 번역할 텍스트만 리스트로 추출
    origin_texts = [item.text for item in request.items]
    
    # 2. [가짜 데이터 모드] 실제 API 대신 접두어만 붙여서 리스트 생성
    # 실제 운영 시에는 이 줄을 'translated_texts = conduct_batch_translation(...)'으로 교체
    translated_texts = [f"[TL_{request.target_lang}] {t}" for t in origin_texts]
    
    # 3. ID와 가짜 번역문을 매칭하여 결과 생성
    results = []
    for i, item in enumerate(request.items):
        results.append(TranslatedItem(
            id=item.id, 
            translated=translated_texts[i]
        ))
    
    # 4. 결과 반환
    return TranslationResponse(results=results)