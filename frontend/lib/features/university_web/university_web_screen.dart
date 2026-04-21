import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/translation_service.dart';
import '../../core/theme/theme_ext.dart';

// ─────────────────────────── Entry point ─────────────────────────────────────

void openUniversityWeb(BuildContext context, {required String url, String? title}) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => UniversityWebScreen(url: url, title: title),
  ));
}

// ─────────────────────────── Screen ──────────────────────────────────────────

class UniversityWebScreen extends StatefulWidget {
  const UniversityWebScreen({
    super.key,
    required this.url,
    this.title,
  });

  final String url;
  final String? title;

  @override
  State<UniversityWebScreen> createState() => _UniversityWebScreenState();
}

class _UniversityWebScreenState extends State<UniversityWebScreen> {
  InAppWebViewController? _webCtrl;

  double  _loadProgress  = 0;
  bool    _isTranslating = false;
  bool    _isTranslated  = false;
  String  _targetLang    = LangCode.en;
  String? _pageTitle;

  // Supported languages for translation (Papago supported)
  static const _langs = [
    (code: LangCode.en,   label: 'English'),
    (code: LangCode.vi,   label: 'Tiếng Việt'),
    (code: LangCode.ja,   label: '日本語'),
    (code: LangCode.zhCn, label: '中文'),
  ];

  // ── JS: extract all visible text nodes ────────────────────────────────────
  static const _jsExtract = r"""
    (function() {
      const results = [];
      let id = 0;

      function walk(node) {
        if (node.nodeType === Node.TEXT_NODE) {
          const text = node.textContent.trim();
          if (text.length < 2) return;
          // Skip already-translated nodes
          if (node.parentElement && node.parentElement.dataset.tid) return;
          // Skip script / style / noscript content
          const tag = node.parentElement?.tagName?.toLowerCase() ?? '';
          if (['script','style','noscript','code','pre','svg'].includes(tag)) return;

          node.parentElement.dataset.tid = 'n' + id;
          results.push({ id: 'n' + (id++), text: text });
        } else if (node.nodeType === Node.ELEMENT_NODE) {
          for (const child of node.childNodes) walk(child);
        }
      }

      walk(document.body);
      return JSON.stringify(results);
    })();
  """;

  // ── JS: replace text by tid map ────────────────────────────────────────────
  static String _jsReplace(Map<String, String> map) {
    final json = jsonEncode(map);
    return """
      (function() {
        const map = $json;
        document.querySelectorAll('[data-tid]').forEach(el => {
          const translated = map[el.dataset.tid];
          if (translated) el.textContent = translated;
        });
      })();
    """;
  }

  // ── JS: restore original text ─────────────────────────────────────────────
  static const _jsRestore = r"""
    (function() {
      document.querySelectorAll('[data-tid]').forEach(el => {
        const orig = el.dataset.original;
        if (orig) { el.textContent = orig; }
        delete el.dataset.tid;
      });
    })();
  """;

  // ── JS: save originals before first translate ─────────────────────────────
  static const _jsSaveOriginals = r"""
    (function() {
      document.querySelectorAll('[data-tid]').forEach(el => {
        if (!el.dataset.original) el.dataset.original = el.textContent.trim();
      });
    })();
  """;

  // ── Translate ──────────────────────────────────────────────────────────────

  Future<void> _translate() async {
    if (_webCtrl == null || _isTranslating) return;

    // If already translated → restore
    if (_isTranslated) {
      await _webCtrl!.evaluateJavascript(source: _jsRestore);
      setState(() => _isTranslated = false);
      return;
    }

    setState(() => _isTranslating = true);

    try {
      // 1. Extract text nodes
      final raw = await _webCtrl!.evaluateJavascript(source: _jsExtract);
      if (raw == null) return;

      final List<dynamic> nodes = jsonDecode(raw as String);
      if (nodes.isEmpty) return;

      // 2. Save originals
      await _webCtrl!.evaluateJavascript(source: _jsSaveOriginals);

      // 3. Batch translate — chunk by ~3000 chars to stay within Papago limit
      final Map<String, String> translated = {};
      final List<Map<String, String>> batch = [];
      int batchLen = 0;

      Future<void> flushBatch() async {
        if (batch.isEmpty) return;
        // Join with separator, translate as one call, split back
        const sep = '\n||||\n';
        final combined = batch.map((e) => e['text']!).join(sep);
        final result = await TranslationService.instance.translateText(
          combined,
          from: LangCode.ko,
          to: _targetLang,
        );
        final parts = result.split(sep);
        for (int i = 0; i < batch.length && i < parts.length; i++) {
          translated[batch[i]['id']!] = parts[i].trim();
        }
        batch.clear();
        batchLen = 0;
      }

      for (final node in nodes) {
        final id   = node['id']  as String;
        final text = node['text'] as String;
        if (batchLen + text.length > 2000) await flushBatch();
        batch.add({'id': id, 'text': text});
        batchLen += text.length;
      }
      await flushBatch();

      // 4. Inject translations
      await _webCtrl!.evaluateJavascript(source: _jsReplace(translated));
      setState(() => _isTranslated = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Translation failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final primary = context.primary;

    return Scaffold(
      backgroundColor: context.bg,
      appBar: _buildAppBar(primary),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri(widget.url),
            ),
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
                _isTranslated  = false;
              });
            },
            onProgressChanged: (_, progress) {
              setState(() => _loadProgress = progress / 100.0);
            },
            onLoadStop: (ctrl, url) {
              setState(() => _loadProgress = 1.0);
            },
            onTitleChanged: (_, title) {
              if (title != null && title.isNotEmpty) {
                setState(() => _pageTitle = title);
              }
            },
          ),

          // Loading bar
          if (_loadProgress < 1.0)
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

          // Translating overlay
          if (_isTranslating)
            Container(
              color: Colors.black.withValues(alpha: 0.35),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: context.cardFill,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Translating…',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 14,
                          color: context.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
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
        // Language picker
        _LangPicker(
          selected: _targetLang,
          langs: _langs,
          onChanged: (lang) {
            setState(() {
              _targetLang   = lang;
              _isTranslated = false;
            });
          },
        ),

        // Translate / Restore button
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton.icon(
            onPressed: _loadProgress < 1.0 ? null : _translate,
            icon: Icon(
              _isTranslated
                  ? Icons.undo_rounded
                  : Icons.translate_rounded,
              size: 16,
            ),
            label: Text(
              _isTranslated ? 'Original' : 'Translate',
              style: GoogleFonts.notoSansKr(fontSize: 12),
            ),
            style: TextButton.styleFrom(
              foregroundColor: primary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── Language Picker ─────────────────────────────────

class _LangPicker extends StatelessWidget {
  const _LangPicker({
    required this.selected,
    required this.langs,
    required this.onChanged,
  });

  final String selected;
  final List<({String code, String label})> langs;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    final current = langs.firstWhere(
      (l) => l.code == selected,
      orElse: () => langs.first,
    );
    return PopupMenuButton<String>(
      initialValue: selected,
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (_) => langs
          .map((l) => PopupMenuItem(
                value: l.code,
                child: Text(
                  l.label,
                  style: GoogleFonts.notoSansKr(fontSize: 13),
                ),
              ))
          .toList(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language_rounded,
                size: 16, color: context.onSurfaceVar),
            const SizedBox(width: 3),
            Text(
              current.label,
              style: GoogleFonts.notoSansKr(
                fontSize: 12,
                color: context.onSurfaceVar,
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded,
                size: 16, color: context.onSurfaceVar),
          ],
        ),
      ),
    );
  }
}
