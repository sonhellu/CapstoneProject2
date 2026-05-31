import asyncio
import html
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

async def _translate_via_google(
    client: httpx.AsyncClient,
    text: str,
    source: str,
    target: str,
) -> Optional[str]:
    """Google Cloud Translation API. Returns None when key absent or on failure."""
    key = settings.GOOGLE_TRANSLATOR_API_KEY
    if not key:
        return None
    try:
        payload = {"q": text, "target": target, "format": "text"}
        if source != "auto":
            payload["source"] = source
        res = await client.post(
            _GOOGLE_URL,
            params={"key": key},
            json=payload,
        )
        if res.status_code != 200:
            return None
        data = res.json()
        translations = data.get("data", {}).get("translations", [])
        translated = translations[0].get("translatedText", "") if translations else ""
        return html.unescape(translated) if translated else None
    except Exception:
        return None


async def _translate_batch_via_google(
    client: httpx.AsyncClient,
    texts: list[str],
    source: str,
    target: str,
) -> Optional[list[str]]:
    """Batch Google Cloud Translation API request. Returns None on failure."""
    key = settings.GOOGLE_TRANSLATOR_API_KEY
    if not key or not texts:
        return None
    try:
        payload = {"q": texts, "target": target, "format": "text"}
        if source != "auto":
            payload["source"] = source
        res = await client.post(
            _GOOGLE_URL,
            params={"key": key},
            json=payload,
        )
        if res.status_code != 200:
            return None
        data = res.json()
        translations = data.get("data", {}).get("translations", [])
        if len(translations) != len(texts):
            return None
        return [
            html.unescape(item.get("translatedText", "")) or original
            for item, original in zip(translations, texts)
        ]
    except Exception:
        return None


async def _translate_via_mymemory(
    client: httpx.AsyncClient,
    text: str,
    source: str,
    target: str,
) -> str:
    """MyMemory free API fallback. Returns original on failure."""
    try:
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
        return html.unescape(translated)
    except Exception:
        return text


async def _detect_lang(text: str) -> Optional[str]:
    try:
        from langdetect import detect
        return detect(text)
    except Exception:
        return None


async def _translate_one(
    client: httpx.AsyncClient,
    text: str,
    source: str,
    target: str,
) -> str:
    if not text.strip() or source == target:
        return text
    effective_source = source
    if source == "auto":
        effective_source = (await _detect_lang(text)) or "ko"
    if effective_source == target:
        return text
    result = await _translate_via_google(client, text, effective_source, target)
    return result if result is not None else await _translate_via_mymemory(
        client,
        text,
        effective_source,
        target,
    )


async def _translate_batch(
    client: httpx.AsyncClient,
    batch: list[TranslationItem],
    source: str,
    target: str,
) -> list[str]:
    texts = [item.text for item in batch]
    if source == target:
        return texts
    translated = await _translate_batch_via_google(client, texts, source, target)
    if translated is not None:
        return translated
    return await asyncio.gather(*[
        _translate_one(
            client,
            item.text,
            source,
            target,
        )
        for item in batch
    ])


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.post("", response_model=TranslationResponse)
async def translate(request: TranslationRequest):
    _BATCH = 8  # keep fallback providers responsive on large WebView pages
    items = request.items[:200]  # hard cap
    results: list[TranslatedItem] = []
    async with httpx.AsyncClient(timeout=10) as client:
        for i in range(0, len(items), _BATCH):
            batch = items[i:i + _BATCH]
            translations = await _translate_batch(
                client,
                batch,
                request.source_lang,
                request.target_lang,
            )
            for item, translated in zip(batch, translations):
                results.append(TranslatedItem(id=item.id, translated=translated))
    return TranslationResponse(results=results)


@router.post("/detect", response_model=DetectResponse)
async def detect_language(request: DetectRequest):
    if not request.text.strip():
        return DetectResponse(lang=None)
    lang = await _detect_lang(request.text)
    return DetectResponse(lang=lang)
