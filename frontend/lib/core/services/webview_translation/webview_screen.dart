import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_client.dart';
import '../translation_service.dart';

class WebViewTranslationScreen extends StatefulWidget {
  const WebViewTranslationScreen({
    super.key,
    required this.url,
    required this.targetLangCode,
    this.title,
  });

  final String url;
  final String targetLangCode;
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

  // ── Debug: snapshot of page state. Korean range uses Unicode escape (가)
  // so the JS string is pure ASCII — no encoding issues on WKWebView.
  static const _debugJs = '''
    (function() {
      try {
        var body = document.body;
        var text  = body ? (body.innerText || '') : '';
        var sample = text.replace(/\\s+/g, ' ').trim().slice(0, 300);
        return JSON.stringify({
          href      : location.href,
          readyState: document.readyState,
          bodyLen   : text.length,
          sample    : sample,
          hasKorean : /[\\uAC00-\\uD7A3]/.test(text),
          iframes   : document.querySelectorAll('iframe').length
        });
      } catch(e) {
        return JSON.stringify({error: String(e), stack: e.stack || ''});
      }
    })();
  ''';

  // ── Lightweight Korean-presence check (pure-ASCII JS) ───────────────────
  static const _hasKoreanJs = '''
    (function() {
      try {
        var t = document.body ? (document.body.innerText || '') : '';
        return /[\\uAC00-\\uD7A3]/.test(t) ? 'yes' : 'no';
      } catch(e) { return 'error'; }
    })();
  ''';

  // ── TreeWalker extraction ─────────────────────────────────────────────────
  // Phase 1: walk + collect (no DOM mutation).
  // Phase 2: wrap collected nodes in <hi-tr>.
  // Skips nodes whose parent tag is in SKIP set (includes HI-TR for 2nd pass).
  // Returns JSON: {ok, count, items:[{id,text}]} or {ok:false, error, stack}.
  // NOTE: no Korean regex here — filtering is done in Dart where encoding is safe.
  static const _extractJs = '''
    (function() {
      try {
        window.__hiWrappers = window.__hiWrappers || [];
        var SKIP = {SCRIPT:1, STYLE:1, NOSCRIPT:1, HEAD:1, META:1, 'HI-TR':1};

        var walker = document.createTreeWalker(
          document.body,
          NodeFilter.SHOW_TEXT,
          {
            acceptNode: function(node) {
              var p = node.parentNode;
              if (!p) return NodeFilter.FILTER_REJECT;
              if (SKIP[p.tagName]) return NodeFilter.FILTER_REJECT;
              return (node.nodeValue || '').trim().length >= 2
                ? NodeFilter.FILTER_ACCEPT
                : NodeFilter.FILTER_SKIP;
            }
          }
        );

        // Phase 1: collect — walker must finish before we touch the DOM
        var collected = [];
        var node;
        while ((node = walker.nextNode())) {
          var text = (node.nodeValue || '').replace(/\\s+/g, ' ').trim();
          if (text.length >= 2) collected.push({node: node, text: text});
        }

        // Phase 2: wrap
        var items = [];
        for (var i = 0; i < collected.length; i++) {
          var entry = collected[i];
          if (!entry.node.parentNode) continue;
          var idx = window.__hiWrappers.length;
          var w = document.createElement('hi-tr');
          w.style.display = 'inline';
          w.setAttribute('data-hi-id', String(idx));
          entry.node.parentNode.insertBefore(w, entry.node);
          w.appendChild(entry.node);
          window.__hiWrappers.push(w);
          items.push({id: idx, text: entry.text});
        }

        return JSON.stringify({ok: true, count: items.length, items: items});
      } catch(e) {
        return JSON.stringify({ok: false, error: String(e), stack: e.stack || ''});
      }
    })();
  ''';

  // ── Log current page state to Flutter console ────────────────────────────
  Future<void> _debugPageState() async {
    final raw = await _webCtrl?.evaluateJavascript(source: _debugJs);
    if (raw == null) {
      debugPrint('[HiTr] debugPageState: null (JS returned nothing)');
      return;
    }
    String s = raw.toString();
    if (s.startsWith('"')) s = jsonDecode(s) as String;
    try {
      final m = jsonDecode(s) as Map<String, dynamic>;
      debugPrint('[HiTr] ── Page State ─────────────────────────');
      debugPrint('[HiTr] href       : ${m['href']}');
      debugPrint('[HiTr] readyState : ${m['readyState']}');
      debugPrint('[HiTr] bodyLen    : ${m['bodyLen']}');
      debugPrint('[HiTr] hasKorean  : ${m['hasKorean']}');
      debugPrint('[HiTr] iframes    : ${m['iframes']}');
      debugPrint('[HiTr] sample     : ${m['sample']}');
      if (m.containsKey('error')) {
        debugPrint('[HiTr] JS error   : ${m['error']}');
        debugPrint('[HiTr] stack      : ${m['stack']}');
      }
      debugPrint('[HiTr] ─────────────────────────────────────');
    } catch (_) {
      debugPrint('[HiTr] debugPageState raw: $s');
    }
  }

  // ── Poll until body has Korean text, then translate ──────────────────────
  // Checks every 800 ms, up to 12 attempts (~9.6 s).
  // Runs a second pass 3 s later to catch lazy-loaded content.
  Future<void> _waitForKoreanTextThenTranslate() async {
    const maxAttempts = 12;
    const interval = Duration(milliseconds: 800);

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      await Future.delayed(interval);
      if (!mounted || _webCtrl == null) return;

      final raw = await _webCtrl!.evaluateJavascript(source: _hasKoreanJs);
      final result = (raw?.toString() ?? 'error').replaceAll('"', '');
      debugPrint('[HiTr] poll #$attempt → hasKorean=$result');

      if (result == 'yes') {
        await _debugPageState();
        await _runTranslation();
        // Second pass for lazy-loaded content
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) await _runTranslation();
        return;
      }
    }

    // Gave up waiting — log state anyway for debugging
    debugPrint('[HiTr] polling timed out (${maxAttempts * 800} ms)');
    await _debugPageState();
  }

  // ── Extract → filter → translate → inject ───────────────────────────────
  Future<void> _runTranslation() async {
    if (_translating || _webCtrl == null) return;
    setState(() => _translating = true);

    try {
      // 1. Extract text nodes
      final raw = await _webCtrl!.evaluateJavascript(source: _extractJs);
      String s = raw?.toString() ?? '{"ok":false,"error":"evaluateJavascript returned null"}';
      if (s.startsWith('"')) s = jsonDecode(s) as String;
      final result = jsonDecode(s) as Map<String, dynamic>;

      if (result['ok'] != true) {
        debugPrint('[HiTr] extract failed: ${result['error']}\n${result['stack']}');
        return;
      }

      final allItems = (result['items'] as List).cast<Map<String, dynamic>>();
      debugPrint('[HiTr] extracted ${allItems.length} raw items');
      if (allItems.isEmpty) return;

      // 2. Filter — Korean only, skip pure dates/numbers
      // RegExp runs in Dart: no WKWebView encoding concern.
      final dateRe   = RegExp(r'^\d{2,4}[\.\-/]\d{1,2}[\.\-/]\d{1,2}$');
      final numRe    = RegExp(r'^[0-9\s\.\:\-]+$');
      final koreanRe = RegExp(r'[가-힣]'); // Hangul Syllables

      final shortItems   = <Map<String, dynamic>>[];
      final backendItems = <Map<String, dynamic>>[];

      for (final item in allItems) {
        final text = (item['text'] as String).trim();
        if (!koreanRe.hasMatch(text)) continue;
        if (dateRe.hasMatch(text) || numRe.hasMatch(text)) continue;
        if (text.length < 20) {
          shortItems.add(item);
        } else {
          backendItems.add(item);
        }
      }
      debugPrint('[HiTr] to translate — short=${shortItems.length} long=${backendItems.length}');
      // Combine and cap at 200 — backend processes in DOM order (top → bottom)
      final toTranslate = [...shortItems, ...backendItems];
      const maxItems = 200;
      final capped = toTranslate.length > maxItems
          ? toTranslate.sublist(0, maxItems)
          : toTranslate;
      debugPrint('[HiTr] sending ${capped.length} items to backend (capped from ${toTranslate.length})');
      if (capped.isEmpty) return;

      // All items → backend (parallelised on server side)
      try {
        final res = await _api.post('/api/translate', body: {
          'items': capped
              .map((e) => {'id': e['id'], 'text': e['text']})
              .toList(),
          'source_lang': LangCode.ko,
          'target_lang': widget.targetLangCode,
        });
        debugPrint('[HiTr] backend status: ${res.statusCode}');
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final results =
              (data['results'] as List).cast<Map<String, dynamic>>();
          debugPrint('[HiTr] injecting ${results.length} results');
          await _injectTranslations(results);
        }
      } catch (e) {
        debugPrint('[HiTr] backend error: $e');
      }
    } catch (e, st) {
      debugPrint('[HiTr] _runTranslation error: $e\n$st');
    } finally {
      if (mounted) setState(() => _translating = false);
    }
  }

  // ── Inject in batches of 20 via evaluateJavascript ───────────────────────
  // jsonEncode handles all string escaping (quotes, backslashes, newlines).
  // Uses window.__hiWrappers[id] with data-hi-id querySelector as fallback.
  Future<void> _injectTranslations(List<Map<String, dynamic>> results) async {
    if (results.isEmpty) return;

    const batchSize = 20;
    for (int i = 0; i < results.length; i += batchSize) {
      final batch = results.sublist(i, (i + batchSize).clamp(0, results.length));
      final sb = StringBuffer(
        '(function(){'
        'var w=window.__hiWrappers||[];',
      );
      for (final item in batch) {
        final id = item['id'];
        final t  = jsonEncode(item['translated'] ?? '');
        sb.write(
          'try{'
          'var el=w[$id]||document.querySelector(\'hi-tr[data-hi-id="$id"]\');'
          'if(el){el.innerText=$t;el.style.wordBreak="break-word";}'
          '}catch(_){}',
        );
      }
      sb.write('})();');
      await _webCtrl?.evaluateJavascript(source: sb.toString());
    }
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
            onConsoleMessage: (_, msg) =>
                debugPrint('[WebView] ${msg.messageLevel}: ${msg.message}'),
            onLoadStop: (_, _) async {
              setState(() => _progress = 1);
              await _waitForKoreanTextThenTranslate();
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
