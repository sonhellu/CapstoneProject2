import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/theme_ext.dart';
import '../../l10n/app_localizations.dart';

// ─────────────────────────── Entry point ─────────────────────────────────────

void openUniversityWeb(
  BuildContext context, {
  required String url,
  String? title,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => UniversityWebScreen(url: url, title: title),
    ),
  );
}

// ─────────────────────────── State enum ──────────────────────────────────────

enum _TxState { idle, loading, active }

// ─────────────────────────── Screen ──────────────────────────────────────────

class UniversityWebScreen extends StatefulWidget {
  const UniversityWebScreen({super.key, required this.url, this.title});

  final String url;
  final String? title;

  @override
  State<UniversityWebScreen> createState() => _UniversityWebScreenState();
}

class _UniversityWebScreenState extends State<UniversityWebScreen> {
  InAppWebViewController? _webCtrl;
  final _safariBrowser = ChromeSafariBrowser();

  double _loadProgress = 0;
  String? _pageTitle;
  _TxState _txState = _TxState.idle;

  static const _gtLangMap = {
    'ko': 'ko',
    'en': 'en',
    'vi': 'vi',
    'ja': 'ja',
    'zh': 'zh-CN',
    'my': 'my',
  };

  static const _allLangs = 'ko,en,vi,ja,zh-CN,my';

  bool get _pageLoaded => _loadProgress >= 1.0;

  void _openInBrowser() {
    _safariBrowser.open(
      url: WebUri(widget.url),
      settings: ChromeSafariBrowserSettings(
        shareState: CustomTabsShareState.SHARE_STATE_OFF,
        showTitle: true,
      ),
    );
  }

  void _showFallbackSnackbar() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.uniWebTranslateUnavailableTitle,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.uniWebTranslateUnavailableBody,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        action: SnackBarAction(
          label: l10n.uniWebOpenInBrowser,
          onPressed: _openInBrowser,
        ),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  Future<void> _toggleTranslate() async {
    final ctrl = _webCtrl;
    if (ctrl == null || _txState == _TxState.loading) return;

    if (_txState == _TxState.active) {
      await ctrl.reload();
      setState(() => _txState = _TxState.idle);
      return;
    }

    setState(() => _txState = _TxState.loading);

    final localeLang = Localizations.localeOf(context).languageCode;
    final targetLang = _gtLangMap[localeLang] ?? 'en';

    ctrl.addJavaScriptHandler(
      handlerName: 'onGtSuccess',
      callback: (_) {
        if (mounted) setState(() => _txState = _TxState.active);
      },
    );
    ctrl.addJavaScriptHandler(
      handlerName: 'onGtFailed',
      callback: (_) {
        if (mounted) setState(() => _txState = _TxState.idle);
        _showFallbackSnackbar();
      },
    );

    // Detect page language from HTML lang attribute or meta tag, fallback 'ko'.
    await ctrl.evaluateJavascript(source: '''
      (function() {
        if (document.getElementById('__gt_injected')) return;

        var pageLang = (document.documentElement.lang ||
          (document.querySelector('meta[http-equiv="content-language"]') || {}).content ||
          'ko').split('-')[0].toLowerCase();
        if (!['ko','en','vi','ja','zh','my'].includes(pageLang)) pageLang = 'ko';

        var bar = document.createElement('div');
        bar.id = '__gt_injected';
        bar.style.cssText = 'position:fixed;top:0;left:0;right:0;z-index:999999;background:#fff;padding:4px 8px;box-shadow:0 2px 6px rgba(0,0,0,.3);';
        document.body.insertBefore(bar, document.body.firstChild);
        document.body.style.marginTop = '40px';

        window.googleTranslateElementInit = function() {
          new google.translate.TranslateElement({
            pageLanguage: pageLang,
            includedLanguages: '$_allLangs',
            autoDisplay: true,
            layout: google.translate.TranslateElement.InlineLayout.SIMPLE
          }, '__gt_injected');
        };

        var s = document.createElement('script');
        s.src = 'https://translate.google.com/translate_a/element.js?cb=googleTranslateElementInit';
        document.body.appendChild(s);

        var attempts = 0;
        var poll = setInterval(function() {
          var sel = document.querySelector('.goog-te-combo');
          if (sel) {
            sel.value = '$targetLang';
            sel.dispatchEvent(new Event('change'));
            clearInterval(poll);
            window.flutter_inappwebview.callHandler('onGtSuccess');
          } else if (++attempts > 40) {
            clearInterval(poll);
            window.flutter_inappwebview.callHandler('onGtFailed');
          }
        }, 300);
      })();
    ''');
  }

  @override
  Widget build(BuildContext context) {
    final primary = context.primary;

    return Scaffold(
      backgroundColor: context.bg,
      appBar: _buildAppBar(primary),
      body: Stack(
        children: [
          RepaintBoundary(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.url)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                userAgent:
                    'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
                    '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
              ),
              onWebViewCreated: (ctrl) => _webCtrl = ctrl,
              onLoadStart: (ctrl, url) {
                setState(() {
                  _loadProgress = 0;
                  _txState = _TxState.idle;
                });
              },
              onProgressChanged: (_, progress) {
                setState(() => _loadProgress = progress / 100.0);
              },
              onLoadStop: (ctrl, url) {
                setState(() => _loadProgress = 1.0);
              },
              onReceivedError: (ctrl, request, error) {
                if (request.isForMainFrame == true && mounted) {
                  _showFallbackSnackbar();
                }
              },
              onTitleChanged: (_, title) {
                if (title != null && title.isNotEmpty) {
                  setState(() => _pageTitle = title);
                }
              },
            ),
          ),
          if (!_pageLoaded)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: _loadProgress,
                minHeight: 2,
                backgroundColor: Colors.transparent,
                color: primary,
              ),
            ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(Color primary) {
    return AppBar(
      backgroundColor: context.cardFill,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title ?? _pageTitle ?? 'University',
            style: GoogleFonts.notoSansKr(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            widget.url,
            style: GoogleFonts.notoSansKr(
              fontSize: 10,
              color: context.onSurfaceVar,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      actions: [
        if (_txState == _TxState.loading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: primary,
              ),
            ),
          )
        else
          IconButton(
            tooltip: _txState == _TxState.active ? 'Show original' : 'Translate',
            onPressed: _pageLoaded ? _toggleTranslate : null,
            icon: Icon(
              Icons.translate_rounded,
              color: !_pageLoaded
                  ? context.onSurfaceVar.withValues(alpha: 0.3)
                  : _txState == _TxState.active
                      ? primary
                      : context.onSurfaceVar,
            ),
          ),
        IconButton(
          tooltip: 'Open in browser',
          onPressed: _openInBrowser,
          icon: Icon(Icons.open_in_browser_rounded, color: context.onSurfaceVar),
        ),
        IconButton(
          tooltip: 'Reload',
          onPressed: () => _webCtrl?.reload(),
          icon: Icon(Icons.refresh_rounded, color: primary),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
