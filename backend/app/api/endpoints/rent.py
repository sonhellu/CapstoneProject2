from fastapi import FastAPI
import requests
import xml.etree.ElementTree as ET
app = FastAPI()
SERVICE_KEY = 
"10686e2e749080db9d9a55097f037a188071e5562de06124d3a839f645035df1"
@app.get("/rent")
def get_rent_data():
    url = 
"http://apis.data.go.kr/1613000/RTMSDataSvcRHRent/getRTMSDataSvcRHRent"
    params = {
        "serviceKey": SERVICE_KEY,
        "LAWD_CD": "27290",
        "DEAL_YMD": "202401"
    }
    response = requests.get(url, params=params)
    root = ET.fromstring(response.content)
    result = []
    for item in root.iter("item"):
        data = {
            "deposit": item.findtext("deposit"),
            "monthlyRent": item.findtext("monthlyRent")
        }
        result.append(data)
    return result
JSON 형태 데이터
from PublicDataReader import TransactionPrice
import pandas as pd
import json
#  1. API 키 입력 (Decoding 키)
SERVICE_KEY = 
"10686e2e749080db9d9a55097f037a188071e5562de06124d3a839f645035df1"
# 2. API 객체 생성
api = TransactionPrice(SERVICE_KEY)
# 3. 데이터 가져오기 (달서구 / 2023년 기준)
df = api.get_rent(
    row=1000,
    lawd_code="27290",   # 대구 달서구
    deal_ymd="202301"    # 2023년 1월 (작년 기준)
)
#  데이터 없을 경우 대비
if df.empty:
    print("데이터가 없습니다.")
else:
    # 4. 필요한 컬럼만 선택
    df = df[["보증금", "월세", "전용면적"]]
    # 5. 숫자 변환
    df["보증금"] = df["보증금"].astype(int)
    df["월세"] = df["월세"].astype(int)
    # 6. 평균값 계산
    avg_deposit = int(df["보증금"].mean())
    avg_monthly = int(df["월세"].mean())
    # 7. JSON 구조 생성 (캡스톤용)
    result = {
        "region": "대구 달서구",
        "year": 2023,
        "avg_deposit": avg_deposit,
        "avg_monthly": avg_monthly,
        "data": df.to_dict(orient="records")[:5]  # 샘플 5개만
    }
# 8. JSON 출력
print(json.dumps(result, ensure_ascii=False, indent=2)
