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
  bool _googleTranslating = false;
  bool _googleActive = false;
  bool _googleFailed = false;
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
  static const _googleTranslateElementTimeoutAttempts = 40;

  @override
  void initState() {
    super.initState();
    if (!_shouldTranslateWeb(_webTargetLang)) {
      unawaited(_clearPersistedGoogleTranslateState(evaluateInPage: false));
    }
  }

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

  static const _removeGoogleTranslateElementJs = '''
    (function() {
      try {
        function hiCampusGoogleTranslateDomains() {
          var host = location.hostname || '';
          var domains = [''];
          if (host) {
            domains.push(host);
            var parts = host.split('.');
            for (var i = 1; i < parts.length - 1; i++) {
              domains.push('.' + parts.slice(i).join('.'));
            }
          }
          return domains;
        }
        function clearHiCampusGoogleTranslateCookie() {
          var domains = hiCampusGoogleTranslateDomains();
          for (var i = 0; i < domains.length; i++) {
            var domain = domains[i] ? ';domain=' + domains[i] : '';
            document.cookie =
              'googtrans=;path=/;expires=Thu, 01 Jan 1970 00:00:00 GMT;max-age=0;SameSite=Lax' +
              domain;
          }
        }
        clearHiCampusGoogleTranslateCookie();
        var bar = document.getElementById('__hi_gt_injected');
        if (bar && bar.parentNode) bar.parentNode.removeChild(bar);
        var style = document.getElementById('__hi_gt_hide_style');
        if (style && style.parentNode) style.parentNode.removeChild(style);
        var script = document.getElementById('__hi_gt_script');
        if (script && script.parentNode) script.parentNode.removeChild(script);
        var banners = document.querySelectorAll(
          'iframe.goog-te-banner-frame,.goog-te-banner-frame,body > .skiptranslate'
        );
        for (var i = 0; i < banners.length; i++) {
          if (banners[i].parentNode) banners[i].parentNode.removeChild(banners[i]);
        }
        if (document.body && window.__hiGtOriginalPaddingTop !== undefined) {
          document.body.style.paddingTop = window.__hiGtOriginalPaddingTop || '';
        }
        if (document.body && window.__hiGtOriginalTop !== undefined) {
          document.body.style.top = window.__hiGtOriginalTop || '';
        }
      } catch (_) {}
    })();
  ''';

  static const _clearGoogleTranslateCookieJs = '''
    (function() {
      try {
        var host = location.hostname || '';
        var domains = [''];
        if (host) {
          domains.push(host);
          var parts = host.split('.');
          for (var i = 1; i < parts.length - 1; i++) {
            domains.push('.' + parts.slice(i).join('.'));
          }
        }
        for (var j = 0; j < domains.length; j++) {
          var domain = domains[j] ? ';domain=' + domains[j] : '';
          document.cookie =
            'googtrans=;path=/;expires=Thu, 01 Jan 1970 00:00:00 GMT;max-age=0;SameSite=Lax' +
            domain;
        }
      } catch (_) {}
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
                if (p.closest && p.closest('#__hi_gt_injected,.skiptranslate')) {
                  return NodeFilter.FILTER_REJECT;
                }
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
  // Google Translate Element is the primary path; HiCampus DOM translation is
  // kept as the explicit fallback when Google fails.
  Future<void> _waitForKoreanTextThenTranslate() async {
    final targetLang = _webTargetLang;
    if (!_shouldTranslateWeb(targetLang)) {
      debugPrint('[HiTr] skip auto translation for target=$targetLang');
      await _clearPersistedGoogleTranslateState();
      return;
    }

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
        await _runGoogleTranslate();
        return;
      }
    }

    // Gave up waiting — log state anyway for debugging
    debugPrint('[HiTr] polling timed out (${maxAttempts * 800} ms)');
    await _debugPageState();
    await _runGoogleTranslate();
  }

  Future<void> _runGoogleTranslate() async {
    if (_googleTranslating ||
        _googleActive ||
        _translating ||
        _webCtrl == null) {
      return;
    }

    final targetLang = _webTargetLang;
    debugPrint(
      '[HiTr] runGoogleTranslate target=$targetLang raw=${widget.targetLangCode} device=${WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag()}',
    );
    if (!_shouldTranslateWeb(targetLang)) {
      debugPrint('[HiTr] Google skip for target=$targetLang');
      return;
    }

    setState(() {
      _googleTranslating = true;
      _googleFailed = false;
      _showTranslationPanel = false;
      _translationHadError = false;
    });

    try {
      await _prepareGoogleTranslateCookie(targetLang);
      if (!mounted || _webCtrl == null) return;
      await _webCtrl!.evaluateJavascript(
        source: _googleTranslateElementJs(targetLang),
      );
    } catch (e) {
      debugPrint('[HiTr] Google Translate Element inject error: $e');
      _handleGoogleTranslateFailed();
    }
  }

  Future<void> _prepareGoogleTranslateCookie(String targetLang) async {
    final cookieValue = '/auto/$targetLang';
    try {
      await CookieManager.instance().setCookie(
        url: WebUri(widget.url),
        name: 'googtrans',
        value: cookieValue,
        path: '/',
        isSecure: widget.url.startsWith('https://'),
      );
    } catch (e) {
      debugPrint('[HiTr] set googtrans cookie skipped: $e');
    }

    final ctrl = _webCtrl;
    if (ctrl == null) return;
    try {
      await ctrl.evaluateJavascript(
        source: _setGoogleTranslateCookieJs(targetLang),
      );
    } catch (e) {
      debugPrint('[HiTr] set page googtrans cookie skipped: $e');
    }
  }

  Future<void> _clearPersistedGoogleTranslateState({
    bool evaluateInPage = true,
  }) async {
    try {
      final cookieManager = CookieManager.instance();
      await cookieManager.deleteCookie(
        url: WebUri(widget.url),
        name: 'googtrans',
      );
      await cookieManager.deleteCookie(
        url: WebUri('https://translate.google.com'),
        name: 'googtrans',
      );
    } catch (e) {
      debugPrint('[HiTr] clear googtrans cookie skipped: $e');
    }

    final ctrl = _webCtrl;
    if (!evaluateInPage || ctrl == null) return;
    try {
      await ctrl.evaluateJavascript(source: _clearGoogleTranslateCookieJs);
    } catch (e) {
      debugPrint('[HiTr] clear page googtrans cookie skipped: $e');
    }
  }

  String _setGoogleTranslateCookieJs(String targetLang) {
    final cookieValue = jsonEncode('/auto/$targetLang');
    return '''
      (function() {
        try {
          var value = $cookieValue;
          var expires = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toUTCString();
          var host = location.hostname || '';
          var domains = [''];
          if (host) {
            domains.push(host);
            var parts = host.split('.');
            for (var i = 1; i < parts.length - 1; i++) {
              domains.push('.' + parts.slice(i).join('.'));
            }
          }
          for (var j = 0; j < domains.length; j++) {
            var domain = domains[j] ? ';domain=' + domains[j] : '';
            document.cookie =
              'googtrans=' + value + ';path=/;expires=' + expires + ';SameSite=Lax' +
              domain;
          }
        } catch (_) {}
      })();
    ''';
  }

  String _googleTranslateElementJs(String targetLang) {
    final target = jsonEncode(targetLang);
    const includedLanguages = 'ko,en,vi,ja,zh-CN,my';
    return '''
      (function() {
        try {
          var targetLang = $target;
          var attempts = 0;
          var maxAttempts = $_googleTranslateElementTimeoutAttempts;
          var scriptId = '__hi_gt_script';

          function hiCampusGoogleTranslateDomains() {
            var host = location.hostname || '';
            var domains = [''];
            if (host) {
              domains.push(host);
              var parts = host.split('.');
              for (var i = 1; i < parts.length - 1; i++) {
                domains.push('.' + parts.slice(i).join('.'));
              }
            }
            return domains;
          }

          function setHiCampusGoogleTranslateCookie(lang) {
            var domains = hiCampusGoogleTranslateDomains();
            var value = '/auto/' + lang;
            var expires = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toUTCString();
            for (var i = 0; i < domains.length; i++) {
              var domain = domains[i] ? ';domain=' + domains[i] : '';
              document.cookie =
                'googtrans=' + value + ';path=/;expires=' + expires + ';SameSite=Lax' +
                domain;
            }
          }

          function callFlutter(name) {
            try {
              window.flutter_inappwebview.callHandler(name);
            } catch (_) {}
          }

          function selectTargetLanguage() {
            var sel = document.querySelector('.goog-te-combo');
            if (!sel) return false;
            sel.value = targetLang;
            sel.dispatchEvent(new Event('change', { bubbles: true }));
            sel.dispatchEvent(new Event('input', { bubbles: true }));
            return true;
          }

          function widgetReady() {
            var el = document.getElementById('__hi_gt_injected');
            if (!el) return false;
            var text = (el.innerText || el.textContent || '').replace(/\\s+/g, ' ').trim();
            return text.length > 0 || !!el.querySelector('select,iframe');
          }

          var pageLang = (document.documentElement.lang ||
            (document.querySelector('meta[http-equiv="content-language"]') || {}).content ||
            'ko').split('-')[0].toLowerCase();
          if (!['ko','en','vi','ja','zh','my'].includes(pageLang)) pageLang = 'ko';
          setHiCampusGoogleTranslateCookie(targetLang);

          var hideStyle = document.getElementById('__hi_gt_hide_style');
          if (!hideStyle) {
            hideStyle = document.createElement('style');
            hideStyle.id = '__hi_gt_hide_style';
            document.documentElement.appendChild(hideStyle);
          }
          hideStyle.textContent = [
            '#__hi_gt_injected{position:absolute!important;left:-10000px!important;top:-10000px!important;width:1px!important;height:1px!important;overflow:hidden!important;opacity:0!important;pointer-events:none!important;}',
            'iframe.goog-te-banner-frame,.goog-te-banner-frame,body > .skiptranslate{display:none!important;}',
            'body{top:0!important;}'
          ].join('\\n');

          var bar = document.getElementById('__hi_gt_injected');
          if (!bar) {
            bar = document.createElement('div');
            bar.id = '__hi_gt_injected';
            bar.style.cssText = [
              'position:absolute',
              'top:-10000px',
              'left:-10000px',
              'width:1px',
              'height:1px',
              'overflow:hidden',
              'opacity:0',
              'pointer-events:none'
            ].join(';');
            document.body.appendChild(bar);
          }
          if (window.__hiGtOriginalPaddingTop === undefined) {
            window.__hiGtOriginalPaddingTop = document.body.style.paddingTop || '';
          }
          if (window.__hiGtOriginalTop === undefined) {
            window.__hiGtOriginalTop = document.body.style.top || '';
          }
          document.body.style.paddingTop = window.__hiGtOriginalPaddingTop || '';
          document.body.style.top = '0px';

          window.googleTranslateElementInit = function() {
            new google.translate.TranslateElement({
              pageLanguage: pageLang,
              includedLanguages: '$includedLanguages',
              autoDisplay: true,
              layout: google.translate.TranslateElement.InlineLayout.SIMPLE
            }, '__hi_gt_injected');
          };

          if (window.google && window.google.translate && window.google.translate.TranslateElement) {
            window.googleTranslateElementInit();
          } else {
            var oldScript = document.getElementById(scriptId);
            if (oldScript && oldScript.parentNode) {
              oldScript.parentNode.removeChild(oldScript);
            }
            var script = document.createElement('script');
            script.id = scriptId;
            script.src = 'https://translate.google.com/translate_a/element.js?cb=googleTranslateElementInit';
            script.onerror = function() {
              callFlutter('onHiCampusGoogleTranslateFailed');
            };
            document.body.appendChild(script);
          }

          var poll = setInterval(function() {
            if (selectTargetLanguage()) {
              clearInterval(poll);
              callFlutter('onHiCampusGoogleTranslateSuccess');
            } else if (attempts > 12 && widgetReady()) {
              clearInterval(poll);
              callFlutter('onHiCampusGoogleTranslateSuccess');
            } else if (++attempts > maxAttempts) {
              clearInterval(poll);
              callFlutter('onHiCampusGoogleTranslateFailed');
            }
          }, 300);
        } catch (e) {
          try {
            window.flutter_inappwebview.callHandler('onHiCampusGoogleTranslateFailed', String(e));
          } catch (_) {}
        }
      })();
    ''';
  }

  void _handleGoogleTranslateSuccess() {
    if (!mounted) return;
    debugPrint('[HiTr] Google Translate Element success');
    setState(() {
      _googleTranslating = false;
      _googleActive = true;
      _googleFailed = false;
    });
  }

  void _handleGoogleTranslateFailed() {
    if (!mounted) return;
    if (_googleActive) {
      debugPrint('[HiTr] Google Translate Element late failure ignored');
      return;
    }
    debugPrint('[HiTr] Google Translate Element failed');
    setState(() {
      _googleTranslating = false;
      _googleActive = false;
      _googleFailed = true;
      _showTranslationPanel = false;
    });
  }

  // ── Extract → filter → translate → inject ───────────────────────────────
  Future<void> _runTranslation({bool showWhenEmpty = true}) async {
    if (_translating || _webCtrl == null) return;
    final targetLang = _webTargetLang;
    debugPrint(
      '[HiTr] runTranslation target=$targetLang raw=${widget.targetLangCode} device=${WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag()}',
    );
    if (!_shouldTranslateWeb(targetLang)) {
      debugPrint('[HiTr] HiCampus skip for target=$targetLang');
      return;
    }

    final runId = ++_translationRunId;
    _hidePanelTimer?.cancel();
    setState(() {
      _googleTranslating = false;
      _googleActive = false;
      _googleFailed = false;
      _translating = true;
      _showTranslationPanel = showWhenEmpty;
      _translationHadError = false;
      _translationTotal = 0;
      _translationProcessed = 0;
      _translationApplied = 0;
    });

    try {
      try {
        await _webCtrl!.evaluateJavascript(
          source: _removeGoogleTranslateElementJs,
        );
      } catch (e) {
        debugPrint('[HiTr] Google Translate cleanup skipped: $e');
      }
      if (!_isActiveRun(runId)) return;

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

  String get _webTargetLang => LangCode.normalize(widget.targetLangCode);

  bool _shouldTranslateWeb(String targetLang) =>
      targetLang != LangCode.ko && LangCode.isSupported(targetLang);

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
    if (!_shouldTranslateWeb(_webTargetLang)) return;
    if (_googleActive ||
        _googleTranslating ||
        _googleFailed ||
        _translating ||
        _webCtrl == null) {
      return;
    }
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
      _googleTranslating = false;
      _googleActive = false;
      _googleFailed = false;
      _progress = 0;
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
    final canTranslateWeb = _shouldTranslateWeb(_webTargetLang);

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
          if (canTranslateWeb) ...[
            if (_translating || _googleTranslating)
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
                tooltip: 'Google Translate',
                onPressed: () => _runGoogleTranslate(),
              ),
            IconButton(
              icon: const Icon(Icons.auto_fix_high_rounded),
              tooltip: 'HiCampus',
              onPressed: () => _runTranslation(),
            ),
          ],
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
            onWebViewCreated: (ctrl) {
              _webCtrl = ctrl;
              ctrl.addJavaScriptHandler(
                handlerName: 'onHiCampusGoogleTranslateSuccess',
                callback: (_) {
                  _handleGoogleTranslateSuccess();
                  return null;
                },
              );
              ctrl.addJavaScriptHandler(
                handlerName: 'onHiCampusGoogleTranslateFailed',
                callback: (_) {
                  _handleGoogleTranslateFailed();
                  return null;
                },
              );
            },
            onLoadStart: (_, _) {
              _resetTranslationStateForNewPage();
              if (!_shouldTranslateWeb(_webTargetLang)) {
                unawaited(
                  _clearPersistedGoogleTranslateState(evaluateInPage: false),
                );
              }
            },
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
            Positioned.fill(child: _WebPageLoadingOverlay(progress: _progress)),
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
          if (!_showTranslationPanel && (_googleTranslating || _googleFailed))
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: SafeArea(
                child: _GoogleTranslationStatusPill(
                  translating: _googleTranslating,
                  failed: _googleFailed,
                  onRetryGoogle: _runGoogleTranslate,
                  onFallback: () => _runTranslation(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WebPageLoadingOverlay extends StatelessWidget {
  const _WebPageLoadingOverlay({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final value = progress > 0 && progress < 1 ? progress : null;
    final percent = (progress * 100).clamp(0, 99).round();

    return DecoratedBox(
      decoration: BoxDecoration(color: cs.surface.withValues(alpha: 0.92)),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 3,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _webLoadingMessage(context),
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansKr(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$percent%',
              style: GoogleFonts.notoSansKr(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _webLoadingMessage(BuildContext context) {
    return switch (Localizations.localeOf(context).languageCode) {
      'ko' => '웹 페이지 불러오는 중…',
      'en' => 'Loading webpage…',
      'ja' => 'Webページを読み込み中…',
      'zh' => '正在加载网页…',
      'my' => 'ဝဘ်စာမျက်နှာ ဖွင့်နေသည်…',
      _ => 'Đang tải trang web…',
    };
  }
}

class _GoogleTranslationStatusPill extends StatelessWidget {
  const _GoogleTranslationStatusPill({
    required this.translating,
    required this.failed,
    required this.onRetryGoogle,
    required this.onFallback,
  });

  final bool translating;
  final bool failed;
  final VoidCallback onRetryGoogle;
  final VoidCallback onFallback;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    final title = failed
        ? l.uniWebTranslateUnavailableTitle
        : l.postTranslating;

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
                Icon(
                  failed
                      ? Icons.error_outline_rounded
                      : Icons.translate_rounded,
                  color: failed ? cs.error : cs.primary,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                if (failed)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: l.alertTryAgain,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    onPressed: onRetryGoogle,
                  )
                else
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (failed)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onFallback,
                  icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                  label: const Text('HiCampus'),
                ),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  color: cs.primary,
                  backgroundColor: cs.surfaceContainerHighest,
                ),
              ),
          ],
        ),
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
