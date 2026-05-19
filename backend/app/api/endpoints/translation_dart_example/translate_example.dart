// 필요 dependencies
// webview_flutter, webview_flutter_android
// webview_flutter_wkwebview, http
// google_mlkit_translation
import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// MLKit 관리 클래스
class TranslationManager {
  // 다운 받아야 할 언어 리스트(현재: 영어, 베트남어)
  // 실제 앱에선 사용자 언어를 자동으로 다운받게 해야할 듯 함
  final List<TranslateLanguage> _requiredLanguages = [
    TranslateLanguage.vietnamese,
    TranslateLanguage.english,
  ];

  // 모델이 모두 준비되었는지 확인하는 함수
  Future<bool> prepareModels() async {
    final modelManager = OnDeviceTranslatorModelManager();
    bool isAllDownloaded = true;

    for (var lang in _requiredLanguages) {
      final bool isDownloaded = await modelManager.isModelDownloaded(lang.bcpCode);
      if (!isDownloaded) {
        isAllDownloaded = false;
        print('${lang.bcpCode} 모델 다운로드 시작...');
        await modelManager.downloadModel(lang.bcpCode);
      }
    }
    return isAllDownloaded;
  }
}

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
  final TranslationManager _translationManager = TranslationManager();
  bool _isModelReady = false;

  @override
  void initState() {
    super.initState();

    // 앱 실행 후 온디바이스 번역 모델 준비 트리거
    _initTranslationModel();

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
            // 페이지 로딩 완료 후 잠시 대기했다가 번역 추출 프로세스 시작
            await Future.delayed(const Duration(milliseconds: 500));
            _runExtraction();
          },
        ),
      )
      ..loadRequest(Uri.parse('https://www.kmu.ac.kr/'));
  }

  // 온디바이스 모델 체크 및 유저 알림
  Future<void> _initTranslationModel() async {
    // 최초 다운로드 시 유저가 인지할 수 있도록 스낵바 제공 (플레이스토어 검수 및 UX 가점 요소)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('다국어 번역 리소스를 준비 중입니다... (최초 시 몇 분 소요)'),
          duration: Duration(seconds: 3),
        ),
      );
    });

    try {
      await _translationManager.prepareModels();
      setState(() {
        _isModelReady = true;
      });
      print('모든 온디바이스 번역 모델 준비 완료');
    } catch (e) {
      print('모델 다운로드 중 에러 발생: $e');
    }
  }

  // JS를 실행하여 텍스트를 추출하고 하이브리드로 번역하는 함수
  Future<void> _runExtraction() async {
    try {
      // 1. JS로 {id, text} 리스트 추출 및 독립 태그(<kmu-tr>) 격리 작업 동시 진행
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

          // 탐색 노드 먼저 수집
          while (node = walker.nextNode()) {
            var cleanText = node.nodeValue.replace(/[\\x00-\\x1F\\x7F]/g, "").replace(/\\s+/g, " ").trim();
            if (cleanText.length > 1 && /[a-zA-Z가-힣]/.test(cleanText)) {
              nodesToReplace.push({node: node, text: cleanText});
            }
          }

          // 부모 스타일 오염 및 겹침 방지를 위해 <kmu-tr>로 텍스트 각각을 감싸기
          nodesToReplace.forEach(item => {
            var wrapper = document.createElement('kmu-tr');
            wrapper.setAttribute('data-kmu-id', id);
            wrapper.style.display = 'inline'; // 레이아웃 파괴 방지
            
            item.node.parentNode.insertBefore(wrapper, item.node);
            wrapper.appendChild(item.node);
            
            textData.push({'id': id, 'text': item.text});
            id++;
          });

          return JSON.stringify(textData);
        })();
      ''');

      // 2. 데이터 파싱
      String rawJson = result.toString();
      if (rawJson.startsWith('"')) rawJson = jsonDecode(rawJson); 
      List<dynamic> extractedItems = jsonDecode(rawJson);

      if (extractedItems.isEmpty) return;

      // 타겟 언어 설정 (베트남어)
      const targetLang = TranslateLanguage.vietnamese;
      final onDeviceTranslator = OnDeviceTranslator(
        sourceLanguage: TranslateLanguage.korean,
        targetLanguage: targetLang,
      );

      List<dynamic> serverItems = []; // 백엔드로 일괄 전송할 긴 문장들 리스트

      // 3. 데이터 엄격 분류 (날짜 필터링 + 글자 수 분기)
      final datePattern = RegExp(r'^\d{2,4}[\.\-/]\d{1,2}[\.\-/]\d{1,2}$');

      for (var item in extractedItems) {
        String text = item['text'].toString().trim();

        // [필터 1] 날짜, 시간, 순수 숫자 기호는 토큰 아까우니 제외 (원문 유지)
        if (datePattern.hasMatch(text) || RegExp(r'^[0-9\s\.\:\-]+$').hasMatch(text)) {
          continue; 
        }

        // [필터 2] 20자 미만은 기기 내부(ML Kit)에서 무료로 즉시 소화
        if (text.length < 20 && _isModelReady) {
          try {
            String localTranslated = await onDeviceTranslator.translateText(text);
            await _applyTranslation([{'id': item['id'], 'translated': localTranslated}]);
          } catch (e) {
            print('온디바이스 단어 번역 실패로 서버 이관: $e');
            serverItems.add(item); 
          }
        } else {
          // [필터 3] 20자 이상의 긴 문장만 서버 전송 대상으로 축축
          serverItems.add(item);
        }
      }

      // 4. [★ 핵심 개선 ★] 긴 문장들만 모아서 단 한 번의 HTTP POST로 서버에 일괄 요청
      if (serverItems.isNotEmpty) {
        print('🚀 총 ${serverItems.length}개의 본문 문장을 서버로 일괄 전송합니다.');

        try {
          final response = await http.post(
            Uri.parse('http://10.0.2.2:8000/api/translate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'items': serverItems, // 청크로 쪼개지 않고 통째로 배열 전송
              'target_lang': 'vi',
            }),
          ).timeout(const Duration(seconds: 25)); // 통 데이터이므로 타임아웃을 넉넉히 설정

          if (response.statusCode == 200) {
            var data = jsonDecode(response.body);
            // 전체 번역 데이터 화면에 한 번에 주입
            await _applyTranslation(data['results']);
            print('✅ 서버 일괄 번역 및 반영 완료');
          } else {
            throw Exception('서버 응답 오류: ${response.statusCode}');
          }
        } catch (e) {
          // 5. 서버 API 초과 또는 장애 발생 시 -> 온디바이스(ML Kit) 긴급 Fallback 작동
          print('⚠️ 유료 API 차단 또는 서버 장애 감지! 온디바이스 Fallback 긴급 기동: $e');
          
          List<dynamic> fallbackResults = [];
          for (var item in serverItems) {
            try {
              String fallbackText = await onDeviceTranslator.translateText(item['text']);
              fallbackResults.add({'id': item['id'], 'translated': fallbackText});
            } catch (_) {
              // ML Kit 마저 안될 때의 최후의 안전장치: 원문 유지
              fallbackResults.add({'id': item['id'], 'translated': item['text']});
            }
          }
          // 원문 혹은 복구된 데이터 주입
          await _applyTranslation(fallbackResults);
        }
      }

      // 번역기 리소스 닫기
      onDeviceTranslator.close();

    } catch (e) {
      print('전체 텍스트 추출 및 번역 흐름 오류: $e');
    }
  }

  // 웹뷰에 번역 데이터를 안전하게 주입하는 함수
  Future<void> _applyTranslation(List<dynamic> translatedData) async {
    String jsonStr = jsonEncode(translatedData);
    
    await _controller.runJavaScript('''
      (function() {
        var results = $jsonStr;
        results.forEach(item => {
          // 부모가 아닌 격리된 커스텀 태그 <kmu-tr>만 정확히 타겟팅
          var el = document.querySelector('kmu-tr[data-kmu-id="' + item.id + '"]');
          if (el) {
            el.innerText = item.translated;
            // 부모의 스타일 레이아웃 영역을 해치지 않고 텍스트를 줄바꿈 처리
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
        appBar: AppBar(title: const Text('Hicampus Translator')),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}