import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';
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
  bool _hasShownTranslationError = false;
  bool _showTranslationPanel = false;
  bool _translationHadError = false;
  int _translationTotal = 0;
  int _translationProcessed = 0;
  int _translationApplied = 0;
  int _translationRunId = 0;
  double _progress = 0;
  Timer? _lazyTranslationTimer;
  Timer? _hidePanelTimer;

  final _api = ApiClient();

  static const _translationChunkSize = 12;
  static const _translationTimeout = Duration(seconds: 35);

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
        var visitedDocs = [];
        function hasKorean(doc) {
          if (!doc || !doc.body || visitedDocs.indexOf(doc) >= 0) return false;
          visitedDocs.push(doc);
          var t = doc.body.innerText || '';
          if (/[\\uAC00-\\uD7A3]/.test(t)) return true;
          var frames = doc.querySelectorAll('iframe');
          for (var i = 0; i < frames.length; i++) {
            try {
              var childDoc = frames[i].contentDocument ||
                  (frames[i].contentWindow && frames[i].contentWindow.document);
              if (hasKorean(childDoc)) return true;
            } catch (_) {}
          }
          return false;
        }
        return hasKorean(document) ? 'yes' : 'no';
      } catch(e) { return 'error'; }
    })();
  ''';

  // ── TreeWalker extraction ─────────────────────────────────────────────────
  // Phase 1: walk + collect (no DOM mutation).
  // Phase 2: wrap collected nodes in <hi-tr>.
  // Reuses existing HI-TR wrappers so a failed/timeout attempt can be retried.
  // Returns JSON: {ok, count, items:[{id,text}]} or {ok:false, error, stack}.
  // NOTE: no Korean regex here — filtering is done in Dart where encoding is safe.
  static const _extractJs = '''
    (function() {
      try {
        window.__hiWrappers = window.__hiWrappers || [];
        var SKIP = {SCRIPT:1, STYLE:1, NOSCRIPT:1, HEAD:1, META:1, TITLE:1};
        var items = [];
        var visitedDocs = [];

        function rememberWrapper(w) {
          var id = w.getAttribute('data-hi-id');
          if (id === null || id === '') {
            id = String(window.__hiWrappers.length);
            w.setAttribute('data-hi-id', id);
            window.__hiWrappers.push(w);
          } else {
            var n = parseInt(id, 10);
            if (!window.__hiWrappers[n]) window.__hiWrappers[n] = w;
          }
          return parseInt(id, 10);
        }

        function collectFrom(doc) {
          if (!doc || !doc.body || visitedDocs.indexOf(doc) >= 0) return;
          visitedDocs.push(doc);

          var walker = doc.createTreeWalker(
            doc.body,
            NodeFilter.SHOW_TEXT,
            {
              acceptNode: function(node) {
                var p = node.parentNode;
                if (!p) return NodeFilter.FILTER_REJECT;
                if (p.tagName && SKIP[p.tagName]) return NodeFilter.FILTER_REJECT;
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
            if (text.length >= 2) collected.push({doc: doc, node: node, text: text});
          }

          // Phase 2: wrap new nodes, reuse old wrappers
          for (var i = 0; i < collected.length; i++) {
            var entry = collected[i];
            var parent = entry.node.parentNode;
            if (!parent) continue;

            var wrapper = parent.tagName === 'HI-TR'
              ? parent
              : entry.doc.createElement('hi-tr');

            if (parent.tagName !== 'HI-TR') {
              wrapper.style.display = 'inline';
              parent.insertBefore(wrapper, entry.node);
              wrapper.appendChild(entry.node);
            }

            items.push({id: rememberWrapper(wrapper), text: entry.text});
          }

          var frames = doc.querySelectorAll('iframe');
          for (var f = 0; f < frames.length; f++) {
            try {
              var childDoc = frames[f].contentDocument ||
                  (frames[f].contentWindow && frames[f].contentWindow.document);
              collectFrom(childDoc);
            } catch (_) {}
          }
        }

        collectFrom(document);
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
  Future<void> _runTranslation({bool showWhenEmpty = true}) async {
    if (_translating || _webCtrl == null) return;
    final targetLang = LangCode.normalize(widget.targetLangCode);
    debugPrint(
      '[HiTr] runTranslation target=$targetLang raw=${widget.targetLangCode}',
    );
    if (!LangCode.isSupported(targetLang)) {
      debugPrint('[HiTr] skip: unsupported target language $targetLang');
      return;
    }

    final runId = ++_translationRunId;
    _hidePanelTimer?.cancel();
    setState(() {
      _translating = true;
      _showTranslationPanel = showWhenEmpty;
      _translationHadError = false;
      _translationTotal = 0;
      _translationProcessed = 0;
      _translationApplied = 0;
    });

    try {
      // 1. Extract text nodes
      final raw = await _webCtrl!.evaluateJavascript(source: _extractJs);
      if (!_isActiveRun(runId)) return;
      String s =
          raw?.toString() ??
          '{"ok":false,"error":"evaluateJavascript returned null"}';
      if (s.startsWith('"')) s = jsonDecode(s) as String;
      final result = jsonDecode(s) as Map<String, dynamic>;

      if (result['ok'] != true) {
        debugPrint(
          '[HiTr] extract failed: ${result['error']}\n${result['stack']}',
        );
        return;
      }

      final allItems = (result['items'] as List).cast<Map<String, dynamic>>();
      debugPrint('[HiTr] extracted ${allItems.length} raw items');
      if (allItems.isEmpty) {
        if (showWhenEmpty) _showTranslationError();
        return;
      }

      // 2. Filter — translate meaningful visible text, skip pure dates/numbers
      // RegExp runs in Dart: no WKWebView encoding concern.
      final dateRe = RegExp(r'^\d{2,4}[\.\-/]\d{1,2}[\.\-/]\d{1,2}$');
      final numRe = RegExp(r'^[0-9\s\.\:\-]+$');
      final letterRe = RegExp(r'[A-Za-z가-힣一-龥ぁ-ゟ゠-ヿက-႟]');

      final idsByText = <String, List<int>>{};
      final representativeItems = <Map<String, dynamic>>[];
      final idsByRepresentativeId = <int, List<int>>{};
      for (final item in allItems) {
        final text = _normalizeWebText(item['text'] as String);
        if (!letterRe.hasMatch(text)) continue;
        if (dateRe.hasMatch(text) || numRe.hasMatch(text)) continue;
        final id = _asInt(item['id']);
        if (id < 0) continue;

        final ids = idsByText.putIfAbsent(text, () {
          final group = <int>[];
          representativeItems.add({'id': id, 'text': text});
          idsByRepresentativeId[id] = group;
          return group;
        });
        ids.add(id);
      }
      debugPrint(
        '[HiTr] to translate nodes=${_countExpandedNodes(representativeItems, idsByRepresentativeId)} unique=${representativeItems.length}',
      );
      if (representativeItems.isEmpty) {
        if (showWhenEmpty) _showTranslationError();
        return;
      }

      final sourceById = {
        for (final item in representativeItems)
          item['id'] as int: item['text'] as String,
      };
      var translatedCount = 0;
      var processedCount = 0;

      if (_isActiveRun(runId)) {
        setState(() {
          _showTranslationPanel = true;
          _translationTotal = _countExpandedNodes(
            representativeItems,
            idsByRepresentativeId,
          );
        });
      }

      for (
        var i = 0;
        i < representativeItems.length;
        i += _translationChunkSize
      ) {
        if (!_isActiveRun(runId)) return;
        final chunk = representativeItems.sublist(
          i,
          (i + _translationChunkSize).clamp(0, representativeItems.length),
        );
        final chunkNodeCount = _countExpandedNodes(
          chunk,
          idsByRepresentativeId,
        );

        try {
          translatedCount += await _translateChunk(
            chunk,
            runId: runId,
            sourceById: sourceById,
            idsByRepresentativeId: idsByRepresentativeId,
            targetLang: targetLang,
          );
        } catch (e) {
          debugPrint('[HiTr] backend chunk error: $e');
          _translationHadError = true;
        } finally {
          processedCount += chunkNodeCount;
          if (_isActiveRun(runId)) {
            setState(() {
              _translationProcessed = processedCount
                  .clamp(0, _translationTotal)
                  .toInt();
              _translationApplied = translatedCount;
            });
          }
        }
      }

      if (!_isActiveRun(runId)) return;
      if (translatedCount == 0) {
        _showTranslationError();
      } else {
        _hideTranslationPanelSoon();
      }
    } catch (e, st) {
      debugPrint('[HiTr] _runTranslation error: $e\n$st');
      if (_isActiveRun(runId)) _showTranslationError();
    } finally {
      if (mounted && runId == _translationRunId) {
        setState(() => _translating = false);
      }
    }
  }

  Future<int> _translateChunk(
    List<Map<String, dynamic>> chunk, {
    required int runId,
    required Map<int, String> sourceById,
    required Map<int, List<int>> idsByRepresentativeId,
    required String targetLang,
  }) async {
    final res = await _api.post(
      '/api/translate',
      body: {
        'items': chunk.map((e) => {'id': e['id'], 'text': e['text']}).toList(),
        'source_lang': 'auto',
        'target_lang': targetLang,
      },
      timeout: _translationTimeout,
    );
    if (!_isActiveRun(runId)) return 0;

    debugPrint('[HiTr] backend status: ${res.statusCode}');
    if (res.statusCode != 200) {
      throw Exception('translation backend returned ${res.statusCode}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final rawResults = (data['results'] as List? ?? const []);
    final results = <Map<String, dynamic>>[];

    for (final raw in rawResults) {
      if (raw is! Map<String, dynamic>) continue;
      final id = _asInt(raw['id']);
      if (id < 0) continue;

      final translated = (raw['translated'] as String? ?? '').trim();
      final source = (sourceById[id] ?? '').trim();
      if (translated.isEmpty || translated == source) continue;

      final targetIds = idsByRepresentativeId[id] ?? [id];
      for (final targetId in targetIds) {
        results.add({'id': targetId, 'translated': translated});
      }
    }

    debugPrint('[HiTr] injecting ${results.length} results');
    await _injectTranslations(results);
    if (results.isNotEmpty) _hasShownTranslationError = false;
    return results.length;
  }

  String _normalizeWebText(String text) =>
      text.replaceAll(RegExp(r'\s+'), ' ').trim();

  int _countExpandedNodes(
    List<Map<String, dynamic>> items,
    Map<int, List<int>> idsByRepresentativeId,
  ) {
    var count = 0;
    for (final item in items) {
      final id = _asInt(item['id']);
      count += idsByRepresentativeId[id]?.length ?? 1;
    }
    return count;
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? -1;
  }

  bool _isActiveRun(int runId) =>
      mounted && runId == _translationRunId && _webCtrl != null;

  void _showTranslationError() {
    if (!mounted || _hasShownTranslationError) return;
    _hasShownTranslationError = true;
    setState(() {
      _translationHadError = true;
      _showTranslationPanel = true;
    });
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.uniWebTranslateUnavailableTitle),
        action: SnackBarAction(
          label: l.alertTryAgain,
          onPressed: () => _runTranslation(),
        ),
      ),
    );
  }

  void _hideTranslationPanelSoon() {
    _hidePanelTimer?.cancel();
    _hidePanelTimer = Timer(const Duration(milliseconds: 1600), () {
      if (!mounted || _translating || _translationHadError) return;
      setState(() => _showTranslationPanel = false);
    });
  }

  void _scheduleLazyTranslation() {
    if (_translating || _webCtrl == null) return;
    _lazyTranslationTimer?.cancel();
    _lazyTranslationTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted && !_translating) _runLazyTranslationIfNeeded();
    });
  }

  Future<void> _runLazyTranslationIfNeeded() async {
    if (_translating || _webCtrl == null) return;
    final raw = await _webCtrl!.evaluateJavascript(source: _hasKoreanJs);
    if (!mounted || _translating) return;
    final result = (raw?.toString() ?? 'error').replaceAll('"', '');
    if (result == 'yes') await _runTranslation(showWhenEmpty: false);
  }

  void _resetTranslationStateForNewPage() {
    _translationRunId++;
    _lazyTranslationTimer?.cancel();
    _hidePanelTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _translating = false;
      _hasShownTranslationError = false;
      _showTranslationPanel = false;
      _translationHadError = false;
      _translationTotal = 0;
      _translationProcessed = 0;
      _translationApplied = 0;
    });
  }

  @override
  void dispose() {
    _lazyTranslationTimer?.cancel();
    _hidePanelTimer?.cancel();
    super.dispose();
  }

  // ── Inject in batches of 20 via evaluateJavascript ───────────────────────
  // jsonEncode handles all string escaping (quotes, backslashes, newlines).
  // Uses window.__hiWrappers[id] with data-hi-id querySelector as fallback.
  Future<void> _injectTranslations(List<Map<String, dynamic>> results) async {
    if (results.isEmpty) return;

    const batchSize = 20;
    for (int i = 0; i < results.length; i += batchSize) {
      final batch = results.sublist(
        i,
        (i + batchSize).clamp(0, results.length),
      );
      final sb = StringBuffer(
        '(function(){'
        'var w=window.__hiWrappers||[];',
      );
      for (final item in batch) {
        final id = item['id'];
        final t = jsonEncode(item['translated'] ?? '');
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
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.translate_rounded),
              tooltip: '번역',
              onPressed: () => _runTranslation(),
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
            onLoadStart: (_, _) => _resetTranslationStateForNewPage(),
            onProgressChanged: (_, progress) =>
                setState(() => _progress = progress / 100),
            onConsoleMessage: (_, msg) =>
                debugPrint('[WebView] ${msg.messageLevel}: ${msg.message}'),
            onLoadStop: (_, _) async {
              setState(() => _progress = 1);
              await _waitForKoreanTextThenTranslate();
            },
            onScrollChanged: (_, _, _) => _scheduleLazyTranslation(),
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
          if (_showTranslationPanel)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: SafeArea(
                child: _TranslationStatusPill(
                  translating: _translating,
                  hadError: _translationHadError,
                  processed: _translationProcessed,
                  total: _translationTotal,
                  applied: _translationApplied,
                  onRetry: () => _runTranslation(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TranslationStatusPill extends StatelessWidget {
  const _TranslationStatusPill({
    required this.translating,
    required this.hadError,
    required this.processed,
    required this.total,
    required this.applied,
    required this.onRetry,
  });

  final bool translating;
  final bool hadError;
  final int processed;
  final int total;
  final int applied;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final value = total > 0
        ? (processed / total).clamp(0.0, 1.0).toDouble()
        : null;
    final countText = total > 0 ? '$applied/$total' : '';
    final statusText = hadError
        ? l.uniWebTranslateUnavailableTitle
        : translating
        ? l.postTranslating
        : countText.isNotEmpty
        ? countText
        : l.postTranslate;

    final icon = hadError
        ? Icons.error_outline_rounded
        : translating
        ? Icons.translate_rounded
        : Icons.check_circle_rounded;

    return Material(
      color: cs.surface,
      elevation: 6,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, color: hadError ? cs.error : cs.primary, size: 19),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                if (translating && countText.isNotEmpty)
                  Text(
                    countText,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  )
                else if (hadError)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: l.alertTryAgain,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    onPressed: onRetry,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 3,
                color: hadError ? cs.error : cs.primary,
                backgroundColor: cs.surfaceContainerHighest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
