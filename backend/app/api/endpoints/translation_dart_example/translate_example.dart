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
        print('ℹ️ [ML Kit] ${lang.bcpCode} 모델 다운로드 시작...');
        await modelManager.downloadModel(lang.bcpCode);
        print('✅ [ML Kit] ${lang.bcpCode} 모델 다운로드 완료!');
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

    // 1. 플랫폼별 설정 생성 (이 작업들은 동기식이므로 멈추지 않습니다)
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
            print('🌐 웹 페이지 로딩 완료: $url');
            // 페이지 로딩 완료 후 잠시 대기했다가 번역 추출 프로세스 시작
            await Future.delayed(const Duration(milliseconds: 1000));
            _runExtraction();
          },
        ),
      )
      ..loadRequest(Uri.parse('https://www.kmu.ac.kr/'));

    // ★ [핵심 수정] 웹뷰 세팅이 완벽히 끝나고 "화면이 1프레임 렌더링된 직후" 백그라운드에서 다운로드를 시작하게 만듭니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initTranslationModel();
    });
  }

  // 온디바이스 모델 체크 및 유저 알림
  Future<void> _initTranslationModel() async {
    // Scaffold가 확실히 안착한 후 스낵바를 안정적으로 띄웁니다.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('다국어 번역 리소스를 검사 중입니다... (최초 다운로드 시 몇 분 소요)'),
        duration: Duration(seconds: 3),
      ),
    );

    try {
      // 💡 await가 걸려도 이미 웹뷰 화면은 켜진 상태이므로 앱이 블로킹되지 않고 백그라운드에서 다운로드됩니다.
      await _translationManager.prepareModels();
      
      if (mounted) {
        setState(() {
          _isModelReady = true;
        });
        print('🎉 모든 온디바이스 번역 모델 준비 완료 (이제 20자 미만 로컬 번역 작동 가능)');
      }
    } catch (e) {
      print('❌ 모델 다운로드 중 에러 발생: $e');
    }
  }

  // JS를 실행하여 텍스트를 추출하고 하이브리드로 번역하는 함수
  Future<void> _runExtraction() async {
    try {
      print('🔍 본문 텍스트 추출 JavaScript 실행...');
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

      print('📊 추출된 총 텍스트 아이템 개수: ${extractedItems.length}개');
      if (extractedItems.isEmpty) return;

      const targetLang = TranslateLanguage.vietnamese;
      final onDeviceTranslator = OnDeviceTranslator(
        sourceLanguage: TranslateLanguage.korean,
        targetLanguage: targetLang,
      );

      List<dynamic> serverItems = []; 
      final datePattern = RegExp(r'^\d{2,4}[\.\-/]\d{1,2}[\.\-/]\d{1,2}$');

      for (var item in extractedItems) {
        String text = item['text'].toString().trim();

        if (datePattern.hasMatch(text) || RegExp(r'^[0-9\s\.\:\-]+$').hasMatch(text)) {
          continue; 
        }

        // 20자 미만이고 모델이 완벽히 준비 완료되었을 때만 로컬 번역 실행
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
        print('🚀 총 ${serverItems.length}개의 문장을 FastAPI 서버(http://10.0.2.2:8000)로 전송합니다.');

        try {
          final response = await http.post(
            Uri.parse('http://10.0.2.2:8000/api/translate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'items': serverItems, 
              'target_lang': 'vi',
            }),
          ).timeout(const Duration(seconds: 15));

          if (response.statusCode == 200) {
            var data = jsonDecode(response.body);
            await _applyTranslation(data['results']);
            print('✅ 서버 일괄 번역본 웹뷰 주입 완료!');
          } else {
            throw Exception('서버 응답 에러 코드: ${response.statusCode}');
          }
        } catch (e) {
          print('⚠️ 백엔드 호출 실패 -> 온디바이스 긴급 Fallback 모드 작동 시작: $e');
          
          List<dynamic> fallbackResults = [];
          for (var item in serverItems) {
            try {
              // 모델이 아직 다운로드 중일 수도 있으므로 방어 코드 작동
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
      print('❌ 전체 텍스트 추출 및 번역 흐름 오류: $e');
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
        appBar: AppBar(title: const Text('Hicampus Translator')),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}