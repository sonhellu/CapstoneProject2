import requests

def translate_text(text: str, source: str = "ko", target: str = "en"):
    # 실제 API 키는 .env 파일에서 불러와야 안전합니다.
    client_id = "YOUR_CLIENT_ID"
    client_secret = "YOUR_CLIENT_SECRET"
    url = "https://openapi.naver.com/v1/papago/n2mt"
    
    headers = {
        "X-Naver-Client-Id": client_id,
        "X-Naver-Client-Secret": client_secret
    }
    data = {"source": source, "target": target, "text": text}
    
    response = requests.post(url, headers=headers, data=data)
    return response.json()['message']['result']['translatedText']