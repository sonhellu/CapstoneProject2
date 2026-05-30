from typing import Any
import xml.etree.ElementTree as ET

import httpx
from fastapi import APIRouter, HTTPException

from app.core.config import settings

router = APIRouter(prefix="/rent", tags=["Rent"])

_RENT_API_URL = (
    "https://apis.data.go.kr/1613000/RTMSDataSvcRHRent/"
    "getRTMSDataSvcRHRent"
)


@router.get("")
async def get_rent_data(
    lawd_cd: str = "27290",
    deal_ymd: str = "202401",
) -> list[dict[str, Any]]:
    service_key = settings.PUBLIC_DATA_SERVICE_KEY
    if not service_key:
        raise HTTPException(
            status_code=503,
            detail="PUBLIC_DATA_SERVICE_KEY is not configured.",
        )

    async with httpx.AsyncClient(timeout=10) as client:
        response = await client.get(
            _RENT_API_URL,
            params={
                "serviceKey": service_key,
                "LAWD_CD": lawd_cd,
                "DEAL_YMD": deal_ymd,
            },
        )

    if response.status_code != 200:
        raise HTTPException(
            status_code=response.status_code,
            detail="Rent data provider request failed.",
        )

    root = ET.fromstring(response.content)
    result = []
    for item in root.iter("item"):
        result.append(
            {
                "deposit": item.findtext("deposit"),
                "monthlyRent": item.findtext("monthlyRent"),
                "exclusiveArea": item.findtext("excluUseAr"),
                "buildingName": (item.findtext("aptNm") or "").strip(),
                "district": (item.findtext("umdNm") or "").strip(),
                "floor": item.findtext("floor"),
                "buildYear": item.findtext("buildYear"),
                "dealYear": item.findtext("dealYear"),
                "dealMonth": item.findtext("dealMonth"),
                "dealDay": item.findtext("dealDay"),
            }
        )
    return result
