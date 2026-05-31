import asyncio
from typing import List, Optional

from fastapi import APIRouter
from pydantic import BaseModel
import httpx

from app.core.config import settings

router = APIRouter(prefix="/translate", tags=["Translation"])

_MYMEMORY_URL = "https://api.mymemory.translated.net/get"
_GOOGLE_URL = "https://translation.googleapis.com/language/translate/v2"


# ── Schemas ───────────────────────────────────────────────────────────────────

class TranslationItem(BaseModel):
    id: int
    text: str

class TranslationRequest(BaseModel):
    items: List[TranslationItem]
    target_lang: str = "en"
    source_lang: str = "auto"

class TranslatedItem(BaseModel):
    id: int
    translated: str

class TranslationResponse(BaseModel):
    results: List[TranslatedItem]

class DetectRequest(BaseModel):
    text: str

class DetectResponse(BaseModel):
    lang: Optional[str] = None


# ── Helpers ───────────────────────────────────────────────────────────────────

async def _translate_via_google(text: str, source: str, target: str) -> Optional[str]:
    """Google Cloud Translation API. Returns None when key absent or on failure."""
    key = settings.GOOGLE_TRANSLATOR_API_KEY
    if not key:
        return None
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            res = await client.post(
                _GOOGLE_URL,
                params={"key": key},
                json={"q": text, "source": source, "target": target, "format": "text"},
            )
        if res.status_code != 200:
            return None
        data = res.json()
        translations = data.get("data", {}).get("translations", [])
        translated = translations[0].get("translatedText", "") if translations else ""
        return translated or None
    except Exception:
        return None


async def _translate_via_mymemory(text: str, source: str, target: str) -> str:
    """MyMemory free API fallback. Returns original on failure."""
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            res = await client.get(
                _MYMEMORY_URL,
                params={"q": text, "langpair": f"{source}|{target}"},
            )
        if res.status_code != 200:
            return text
        data = res.json()
        translated = data.get("responseData", {}).get("translatedText", "")
        if not translated or translated.upper().startswith("MYMEMORY"):
            return text
        return translated
    except Exception:
        return text


async def _detect_lang(text: str) -> Optional[str]:
    try:
        from langdetect import detect
        return detect(text)
    except Exception:
        return None


async def _translate_one(text: str, source: str, target: str) -> str:
    if not text.strip() or source == target:
        return text
    effective_source = source
    if source == "auto":
        effective_source = (await _detect_lang(text)) or "ko"
    if effective_source == target:
        return text
    result = await _translate_via_google(text, effective_source, target)
    return result if result is not None else await _translate_via_mymemory(text, effective_source, target)


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.post("", response_model=TranslationResponse)
async def translate(request: TranslationRequest):
    _BATCH = 20  # concurrent requests per batch — avoids rate-limit spikes
    items = request.items[:200]  # hard cap
    results: list[TranslatedItem] = []
    for i in range(0, len(items), _BATCH):
        batch = items[i:i + _BATCH]
        translations = await asyncio.gather(*[
            _translate_one(item.text, request.source_lang, request.target_lang)
            for item in batch
        ])
        for item, translated in zip(batch, translations):
            results.append(TranslatedItem(id=item.id, translated=translated))
    return TranslationResponse(results=results)


@router.post("/detect", response_model=DetectResponse)
async def detect_language(request: DetectRequest):
    if not request.text.strip():
        return DetectResponse(lang=None)
    lang = await _detect_lang(request.text)
    return DetectResponse(lang=lang)
