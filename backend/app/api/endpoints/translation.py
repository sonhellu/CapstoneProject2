from typing import List, Optional

from fastapi import APIRouter
from pydantic import BaseModel
import httpx

router = APIRouter(prefix="/translate", tags=["Translation"])

_MYMEMORY_URL = "https://api.mymemory.translated.net/get"


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

async def _translate_one(text: str, source: str, target: str) -> str:
    """Translate a single text via MyMemory API. Returns original on failure."""
    if not text.strip() or source == target:
        return text
    langpair = f"{source}|{target}"
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            res = await client.get(
                _MYMEMORY_URL,
                params={"q": text, "langpair": langpair},
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


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.post("", response_model=TranslationResponse)
async def translate(request: TranslationRequest):
    """Batch translate items via MyMemory (free, no API key required)."""
    results = []
    for item in request.items:
        source = request.source_lang if request.source_lang != "auto" else "ko"
        translated = await _translate_one(item.text, source, request.target_lang)
        results.append(TranslatedItem(id=item.id, translated=translated))
    return TranslationResponse(results=results)


@router.post("/detect", response_model=DetectResponse)
async def detect_language(request: DetectRequest):
    """Detect the language of a text using langdetect."""
    if not request.text.strip():
        return DetectResponse(lang=None)
    try:
        from langdetect import detect
        lang = detect(request.text)
        return DetectResponse(lang=lang)
    except Exception:
        return DetectResponse(lang=None)
