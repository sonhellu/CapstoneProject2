// lib/controllers/web_translation_controller.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'webview_screen.dart';

class WebTranslationController {
  // 언어 코드 문자열("vi")을 ML Kit 객체로 매핑
  TranslateLanguage _mapLanguage(String code) {
    switch (code.trim().toLowerCase()) {
      case 'vi': return TranslateLanguage.vietnamese;
      case 'en': return TranslateLanguage.english;
      case 'zh': return TranslateLanguage.chinese;
      default: return TranslateLanguage.english;
    }
  }

  // 배너 클릭 시 실행할 메인 함수
  Future<void> handleBannerClick(BuildContext context, String jwtToken) async {
    _showLoadingDialog(context); // 로딩창 켜기

    try {
      // 1. FastAPI 유저 프로필에서 언어 코드 가져오기
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/users/me'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 7));

      if (!context.mounted) return;

      if (response.statusCode != 200) throw Exception('프로필 로드 실패');
      
      final userData = jsonDecode(response.body);
      String userLangCode = userData['main_language'] ?? 'en'; 
      
      // 2. ML Kit 모델 로컬 다운로드 체크 및 실행
      final targetLanguage = _mapLanguage(userLangCode);
      final modelManager = OnDeviceTranslatorModelManager();
      final isDownloaded = await modelManager.isModelDownloaded(targetLanguage.bcpCode);
      
      if (!isDownloaded) {
        debugPrint('ℹ️ [ML Kit] 유저 맞춤 언어팩($userLangCode) 다운로드 시작...');
        await modelManager.downloadModel(targetLanguage.bcpCode);
      }

      if (!context.mounted) return;

      Navigator.pop(context); // 로딩창 끄기
      
      // 3. ⭐️ 받아온 언어 설정을 2번 파일(WebViewScreen)로 넘겨주며 화면 이동!
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WebViewScreen(
            targetLangStr: userLangCode,
            targetLanguage: targetLanguage, 
            jwtToken: jwtToken
          ),
        ),
      );

    } catch (e) {
      if (!context.mounted) return;

      Navigator.pop(context); // 에러 시 로딩창 끄기
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('초기화 실패: $e')),
      );
    }
  }

  // 기존 오타 수정 완료된 로딩 다이얼로그
  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 15),
                Text('번역 엔진 및 언어 팩 로딩 중...', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}