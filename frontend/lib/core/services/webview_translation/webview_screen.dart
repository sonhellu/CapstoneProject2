import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WebViewScreen extends StatefulWidget {
  final String targetLangStr;         // 💡 예: "vi", "en", "zh" (FastAPI 전송용 문자열)
  final TranslateLanguage targetLanguage; // 💡 예: TranslateLanguage.vietnamese (ML Kit 매핑 객체)
  final String jwtToken;              // 인증이 필요한 경우 확장용 토큰

  const WebViewScreen({
    super.key, 
    required this.targetLangStr, 
    required this.targetLanguage,
    required this.jwtToken,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  
  // 💡 컨트롤러가 앞단에서 다운로드를 완료해 주었으므로 true로 시작합니다.
  final bool _isModelReady = true; 

  @override
  void initState() {
    super.initState();

    // 1. 플랫폼별 설정 생성
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params);

    // 2. 안드로이드 전용 설정
    if (_controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (_controller.platform as AndroidWebViewController).setMediaPlaybackRequiresUserGesture(false);
    }

    // 3. 컨트롤러 구성
    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent("Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36")
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) async {
            debugPrint('🌐 웹 페이지 로딩 완료: $url');
            // 페이지 로딩 완료 후 잠시 대기했다가 번역 추출 프로세스 시작
            await Future.delayed(const Duration(milliseconds: 1000));
            _runExtraction();
          },
        ),
      )
      ..loadRequest(Uri.parse('https://www.kmu.ac.kr/'));
  }

  // JS를 실행하여 텍스트를 추출하고 하이브리드로 번역하는 함수
  Future<void> _runExtraction() async {
    try {
      debugPrint('🔍 본문 텍스트 추출 JavaScript 실행...');
      final Object result = await _controller.runJavaScriptReturningResult('''
        (function() {
          var walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, {
            acceptNode: function(node) {
              var tag = node.parentNode.tagName;
              if (['SCRIPT', 'STYLE', 'NOSCRIPT', 'KMU-TR'].includes(tag)) return NodeFilter.FILTER_REJECT;
              return node.nodeValue.trim().length > 0 ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_REJECT;
            }
          });

          var textData = [];
          var id = 0;
          var nodesToReplace = [];
          var node;

          while (node = walker.nextNode()) {
            var cleanText = node.nodeValue.replace(/[\\x00-\\x1F\\x7F]/g, "").replace(/\\s+/g, " ").trim();
            if (cleanText.length > 1 && /[a-zA-Z가-힣]/.test(cleanText)) {
              nodesToReplace.push({node: node, text: cleanText});
            }
          }

          nodesToReplace.forEach(item => {
            var wrapper = document.createElement('kmu-tr');
            wrapper.setAttribute('data-kmu-id', id);
            wrapper.style.display = 'inline'; 
            
            item.node.parentNode.insertBefore(wrapper, item.node);
            wrapper.appendChild(item.node);
            
            textData.push({'id': id, 'text': item.text});
            id++;
          });

          return JSON.stringify(textData);
        })();
      ''');

      String rawJson = result.toString();
      if (rawJson.startsWith('"')) rawJson = jsonDecode(rawJson); 
      List<dynamic> extractedItems = jsonDecode(rawJson);

      debugPrint('📊 추출된 총 텍스트 아이템 개수: ${extractedItems.length}개');
      if (extractedItems.isEmpty) return;

      // 💡 주입받은 타겟 객체 언어로 동적 세팅
      final onDeviceTranslator = OnDeviceTranslator(
        sourceLanguage: TranslateLanguage.korean,
        targetLanguage: widget.targetLanguage, 
      );

      List<dynamic> serverItems = []; 
      final datePattern = RegExp(r'^\d{2,4}[\.\-/]\d{1,2}[\.\-/]\d{1,2}$');

      for (var item in extractedItems) {
        String text = item['text'].toString().trim();

        if (datePattern.hasMatch(text) || RegExp(r'^[0-9\s\.\:\-]+$').hasMatch(text)) {
          continue; 
        }

        // 20자 미만 로컬 번역 실행
        if (text.length < 20 && _isModelReady) {
          try {
            String localTranslated = await onDeviceTranslator.translateText(text);
            await _applyTranslation([{'id': item['id'], 'translated': localTranslated}]);
          } catch (e) {
            serverItems.add(item); 
          }
        } else {
          serverItems.add(item);
        }
      }

      // 4. 긴 문장들 백엔드(FastAPI) 서버 일괄 전송
      if (serverItems.isNotEmpty) {
        debugPrint('🚀 총 ${serverItems.length}개의 문장을 FastAPI 서버로 전송합니다. 타겟 언어: ${widget.targetLangStr}');

        try {
          final response = await http.post(
            Uri.parse('http://10.0.2.2:8000/api/translate'), // 팀의 엔드포인트에 맞게 조정 (앞단에 /api 가 붙어있다면 유지)
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'items': serverItems, 
              'target_lang': widget.targetLangStr, // 💡 동적 변수 주입
            }),
          ).timeout(const Duration(seconds: 15));

          if (response.statusCode == 200) {
            var data = jsonDecode(response.body);
            await _applyTranslation(data['results']);
            debugPrint('✅ 서버 일괄 번역본 웹뷰 주입 완료!');
          } else {
            throw Exception('서버 응답 에러 코드: ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('⚠️ 백엔드 호출 실패 -> 온디바이스 긴급 Fallback 모드 작동 시작: $e');
          
          List<dynamic> fallbackResults = [];
          for (var item in serverItems) {
            try {
              String fallbackText = _isModelReady 
                  ? await onDeviceTranslator.translateText(item['text'])
                  : item['text'];
              fallbackResults.add({'id': item['id'], 'translated': fallbackText});
            } catch (_) {
              fallbackResults.add({'id': item['id'], 'translated': item['text']});
            }
          }
          await _applyTranslation(fallbackResults);
        }
      }

      onDeviceTranslator.close();

    } catch (e) {
      debugPrint('❌ 전체 텍스트 추출 및 번역 흐름 오류: $e');
    }
  }

  // 웹뷰에 번역 데이터를 안전하게 주입하는 함수
  Future<void> _applyTranslation(List<dynamic> translatedData) async {
    String jsonStr = jsonEncode(translatedData);
    await _controller.runJavaScript('''
      (function() {
        var results = $jsonStr;
        results.forEach(item => {
          var el = document.querySelector('kmu-tr[data-kmu-id="' + item.id + '"]');
          if (el) {
            el.innerText = item.translated;
            el.style.wordBreak = 'break-word';
          }
        });
      })();
    ''');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (await _controller.canGoBack()) {
          await _controller.goBack();
        } else {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text('HiCampus Translator (${widget.targetLangStr.toUpperCase()})')),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}