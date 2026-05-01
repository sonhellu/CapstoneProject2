// 필요 dependencies
// webview_flutter, webview_flutter_android
// webview_flutter_wkwebview, http

// 테스트용이므로 일부만 사용
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MaterialApp(
    home: WebViewTestScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

class WebViewTestScreen extends StatefulWidget {
  const WebViewTestScreen({super.key});

  @override
  State<WebViewTestScreen> createState() => _WebViewTestScreenState();
}

class _WebViewTestScreenState extends State<WebViewTestScreen> {
  late final WebViewController _controller;

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

    // 2. 안드로이드 전용: 서드 파티 쿠키 허용 설정
    // 로그인 시 sso.kmu.ac.kr 같은 다른 도메인을 거칠 때 세션이 끊기는 걸 방지합니다.
    if (_controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      // 이 부분이 핵심입니다 (안드로이드 전용 API 접근)
      (_controller.platform as AndroidWebViewController).setMediaPlaybackRequiresUserGesture(false);
    }

    // 3. 컨트롤러 구성
    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // 중요: PC 브라우저나 최신 모바일 브라우저인 것처럼 속여야 로그인이 잘 안 풀립니다.
      ..setUserAgent("Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36")
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) async {
            // 페이지 로드 후 쿠키 동기화 강제 시도 (필요 시)
            // WebViewCookieManager().setAcceptCookie(true);

            await Future.delayed(const Duration(microseconds: 500));

            _runExtraction();
          },
        ),
      )
      ..loadRequest(Uri.parse('https://www.kmu.ac.kr/'));
  }

  // JS를 실행하여 텍스트를 추출하는 함수
  Future<void> _runExtraction() async {
    try {
      // 1. JS로 {id, text} 리스트 추출
      final Object result = await _controller.runJavaScriptReturningResult('''
        (function() {
          var walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, {
            acceptNode: function(node) {
              var tag = node.parentNode.tagName;
              if (['SCRIPT', 'STYLE', 'NOSCRIPT'].includes(tag)) return NodeFilter.FILTER_REJECT;
              return node.nodeValue.trim().length > 0 ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_REJECT;
            }
          });

          var textData = [];
          var id = 0;
          var node;

          while (node = walker.nextNode()) {
            node.parentNode.setAttribute('data-kmu-id', id); 

            var cleanText = node.nodeValue
              .replace(/[\\x00-\\x1F\\x7F]/g, "")
              .replace(/\\s+/g, " ")
              .trim();
            
            if (cleanText.length > 0) {
              textData.push({'id': id, 'text': cleanText});
              id++;
            }
          }
          return JSON.stringify(textData);
        })();
      ''');

      // 2. 파싱 및 전송 데이터 준비
      String rawJson = result.toString();
      if (rawJson.startsWith('"')) rawJson = jsonDecode(rawJson); 
      List<dynamic> extractedItems = jsonDecode(rawJson);

      // 3. FastAPI 호출 (서버 모델에 맞춤)
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/translate'), // router prefix와 main include 확인
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'items': extractedItems,
          'target_lang': 'vi', // 예: 베트남어
        }),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        // 4. 번역 결과(results)만 추출하여 적용
        await _applyTranslation(data['results']);
      }
    } catch (e) {
      print('오류: $e');
    }
  }

  // Flutter에서 번역 데이터를 받은 후 실행
  Future<void> _applyTranslation(List<dynamic> translatedData) async {
    String jsonStr = jsonEncode(translatedData);
    
    await _controller.runJavaScript('''
      (function() {
        var results = $jsonStr;
        results.forEach(item => {
          // 아까 부여한 data-kmu-id로 엘리먼트를 찾음
          var el = document.querySelector('[data-kmu-id="' + item.id + '"]');
          if (el) {
            // 엘리먼트 내의 텍스트 노드만 교체 (자식 노드가 여럿일 경우 주의 필요)
            el.innerText = item.translated; 
          }
        });
      })();
    ''');
  }

  @override
  Widget build(BuildContext context) {
    // PopScope는 뒤로가기 이벤트를 가로챕니다.
    return PopScope(
      canPop: false, // 기본 뒤로가기 동작(앱 종료/이동)을 막음
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // 웹뷰가 뒤로 갈 수 있는지 확인
        if (await _controller.canGoBack()) {
          await _controller.goBack(); // 웹뷰 내에서 뒤로가기
        } else {
          // 더 이상 뒤로 갈 곳이 없다면 앱 종료 허용 (혹은 다이얼로그 표시)
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Hicampus Translator')),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}