import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

import '../api_client.dart';
import '../translation_service.dart';

class WebViewTranslationScreen extends StatefulWidget {
  const WebViewTranslationScreen({
    super.key,
    required this.url,
    required this.targetLangCode,
    required this.targetLanguage,
    this.title,
  });

  final String url;
  final String targetLangCode;
  final TranslateLanguage targetLanguage;
  final String? title;

  @override
  State<WebViewTranslationScreen> createState() =>
      _WebViewTranslationScreenState();
}

class _WebViewTranslationScreenState extends State<WebViewTranslationScreen> {
  InAppWebViewController? _webCtrl;
  bool _translating = false;
  double _progress = 0;

  final _api = ApiClient();

  // JS: DOM traversal → collect text nodes with IDs
  static const _extractJs = '''
    (function() {
      var walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, {
        acceptNode: function(node) {
          var tag = node.parentNode ? node.parentNode.tagName : '';
          if (['SCRIPT','STYLE','NOSCRIPT','HI-TR'].includes(tag)) return NodeFilter.FILTER_REJECT;
          return node.nodeValue.trim().length > 1 ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_REJECT;
        }
      });
      var items = [];
      var id = 0;
      var node;
      while ((node = walker.nextNode())) {
        var clean = node.nodeValue.replace(/[\\x00-\\x1F\\x7F]/g,'').replace(/\\s+/g,' ').trim();
        if (clean.length > 1 && /[a-zA-Z가-힣]/.test(clean)) {
          var wrapper = document.createElement('hi-tr');
          wrapper.setAttribute('data-id', id);
          wrapper.style.display = 'inline';
          node.parentNode.insertBefore(wrapper, node);
          wrapper.appendChild(node);
          items.push({id: id, text: clean});
          id++;
        }
      }
      return JSON.stringify(items);
    })();
  ''';

  Future<void> _runTranslation() async {
    if (_translating || _webCtrl == null) return;
    setState(() => _translating = true);

    try {
      // 1. Extract text nodes
      final raw = await _webCtrl!.evaluateJavascript(source: _extractJs);
      String jsonStr = raw?.toString() ?? '[]';
      if (jsonStr.startsWith('"')) jsonStr = jsonDecode(jsonStr);
      final items = (jsonDecode(jsonStr) as List).cast<Map<String, dynamic>>();
      if (items.isEmpty) return;

      final dateRe = RegExp(r'^\d{2,4}[\.\-/]\d{1,2}[\.\-/]\d{1,2}$');
      final numRe  = RegExp(r'^[0-9\s\.\:\-]+$');

      final shortItems = <Map<String, dynamic>>[];
      final longItems  = <Map<String, dynamic>>[];

      for (final item in items) {
        final text = (item['text'] as String).trim();
        if (dateRe.hasMatch(text) || numRe.hasMatch(text)) continue;
        if (text.length < 20) {
          shortItems.add(item);
        } else {
          longItems.add(item);
        }
      }

      // 2. Short texts → ML Kit on-device
      if (shortItems.isNotEmpty) {
        final translator = OnDeviceTranslator(
          sourceLanguage: TranslateLanguage.korean,
          targetLanguage: widget.targetLanguage,
        );
        final results = <Map<String, dynamic>>[];
        for (final item in shortItems) {
          try {
            final translated =
                await translator.translateText(item['text'] as String);
            results.add({'id': item['id'], 'translated': translated});
          } catch (_) {
            results.add({'id': item['id'], 'translated': item['text']});
          }
        }
        translator.close();
        await _inject(results);
      }

      // 3. Long texts → backend
      if (longItems.isNotEmpty) {
        try {
          final res = await _api.post('/api/translate', body: {
            'items': longItems
                .map((e) => {'id': e['id'], 'text': e['text']})
                .toList(),
            'source_lang': LangCode.ko,
            'target_lang': widget.targetLangCode,
          });
          if (res.statusCode == 200) {
            final data = jsonDecode(res.body) as Map<String, dynamic>;
            final results = (data['results'] as List).cast<Map<String, dynamic>>();
            await _inject(results);
          }
        } catch (_) {
          // fallback: ML Kit for long texts too
          final translator = OnDeviceTranslator(
            sourceLanguage: TranslateLanguage.korean,
            targetLanguage: widget.targetLanguage,
          );
          final results = <Map<String, dynamic>>[];
          for (final item in longItems) {
            try {
              final t = await translator.translateText(item['text'] as String);
              results.add({'id': item['id'], 'translated': t});
            } catch (_) {
              results.add({'id': item['id'], 'translated': item['text']});
            }
          }
          translator.close();
          await _inject(results);
        }
      }
    } catch (e) {
      debugPrint('[WebViewTranslation] error: $e');
    } finally {
      if (mounted) setState(() => _translating = false);
    }
  }

  Future<void> _inject(List<Map<String, dynamic>> results) async {
    final js = '''
      (function() {
        var results = ${jsonEncode(results)};
        results.forEach(function(item) {
          var el = document.querySelector('hi-tr[data-id="' + item.id + '"]');
          if (el) {
            el.innerText = item.translated;
            el.style.wordBreak = 'break-word';
          }
        });
      })();
    ''';
    await _webCtrl?.evaluateJavascript(source: js);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        title: Text(
          widget.title ?? widget.url,
          style: GoogleFonts.notoSansKr(fontSize: 15),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_translating)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.translate_rounded),
              tooltip: '번역',
              onPressed: _runTranslation,
            ),
        ],
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.url)),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              userAgent:
                  'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 '
                  '(KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36',
            ),
            onWebViewCreated: (ctrl) => _webCtrl = ctrl,
            onProgressChanged: (_, progress) =>
                setState(() => _progress = progress / 100),
            onLoadStop: (_, _) async {
              setState(() => _progress = 1);
              await Future.delayed(const Duration(milliseconds: 800));
              await _runTranslation();
            },
          ),
          if (_progress < 1)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: _progress,
                color: cs.primary,
                backgroundColor: cs.primary.withValues(alpha: 0.2),
                minHeight: 3,
              ),
            ),
        ],
      ),
    );
  }
}
