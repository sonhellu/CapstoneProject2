import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/translation_service.dart';
import '../../../l10n/app_localizations.dart';

// ─────────────────────────── State enum ───────────────────────────

enum _TxState { idle, loading, done }

// ─────────────────────────── Widget ───────────────────────────────

/// Wraps any post text widget and adds an inline translate/show-original button.
///
/// Handles its own state completely — each instance is independent, so placing
/// multiple [PostTranslator] widgets in a ListView does not cause cross-post
/// interference. Translation results are cached inside the widget instance for
/// the lifetime of the widget (i.e. while it remains in the tree).
///
/// The button is hidden entirely when [postLangTag] maps to the same ISO code
/// as [deviceLangCode] (no translation needed).
///
/// Usage:
/// ```dart
/// PostTranslator(
///   text: post.content,
///   postLangTag: post.language,         // e.g. "KR"
///   deviceLangCode: deviceLocale,       // e.g. "vi"
///   textBuilder: (displayText) => Text(displayText, ...),
/// )
/// ```
class PostTranslator extends StatefulWidget {
  const PostTranslator({
    super.key,
    required this.text,
    required this.postLangTag,
    required this.deviceLangCode,
    required this.textBuilder,
  });

  /// Original post text.
  final String text;

  /// Post's language display tag (e.g. "KR", "VN", "EN").
  final String postLangTag;

  /// Device / app locale ISO code (e.g. "vi", "ko", "en").
  final String deviceLangCode;

  /// Builds the visible text widget. Called with either the original or the
  /// translated string depending on the current toggle state.
  final Widget Function(String text) textBuilder;

  @override
  State<PostTranslator> createState() => _PostTranslatorState();
}

class _PostTranslatorState extends State<PostTranslator>
    with SingleTickerProviderStateMixin {
  _TxState _state = _TxState.idle;
  String? _translated;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  String get _fromIso => LangCode.fromTag(widget.postLangTag);
  bool get _canTranslate => _fromIso != widget.deviceLangCode;
  bool get _isTranslated => _state == _TxState.done;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..value = 1.0;
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    if (_state == _TxState.loading) return;

    if (_isTranslated) {
      // Revert to original
      await _fadeCtrl.reverse();
      if (!mounted) return;
      setState(() => _state = _TxState.idle);
      _fadeCtrl.forward();
      return;
    }

    // If we already have a cached translation just show it.
    if (_translated != null) {
      await _fadeCtrl.reverse();
      if (!mounted) return;
      setState(() => _state = _TxState.done);
      _fadeCtrl.forward();
      return;
    }

    setState(() => _state = _TxState.loading);

    final result = await TranslationService.instance.translateText(
      widget.text,
      from: _fromIso,
      to: widget.deviceLangCode,
    );

    if (!mounted) return;

    await _fadeCtrl.reverse();
    if (!mounted) return;
    setState(() {
      _translated = result;
      _state = _TxState.done;
    });
    _fadeCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final displayText =
        _isTranslated ? (_translated ?? widget.text) : widget.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Text (fades between original and translated) ──
        FadeTransition(
          opacity: _fadeAnim,
          child: widget.textBuilder(displayText),
        ),

        // ── Translate button (hidden if same language) ──
        if (_canTranslate) ...[
          const SizedBox(height: 14),
          _TranslateChip(
            state: _state,
            isTranslated: _isTranslated,
            fromLangName: LangCode.displayName(_fromIso),
            onTap: _onTap,
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────── Chip widget ──────────────────────────

class _TranslateChip extends StatelessWidget {
  const _TranslateChip({
    required this.state,
    required this.isTranslated,
    required this.fromLangName,
    required this.onTap,
  });

  final _TxState state;
  final bool isTranslated;
  final String fromLangName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isLoading = state == _TxState.loading;

    final chipColor = isTranslated
        ? cs.surfaceContainerHighest
        : cs.primary.withValues(alpha: 0.07);
    final borderColor = isTranslated
        ? cs.outline.withValues(alpha: 0.55)
        : cs.primary.withValues(alpha: 0.35);
    final contentColor =
        isTranslated ? cs.onSurfaceVariant : cs.primary;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding:
            const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: chipColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon or spinner
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isLoading
                  ? SizedBox(
                      key: const ValueKey('spinner'),
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: cs.primary,
                      ),
                    )
                  : Icon(
                      Icons.translate_rounded,
                      key: const ValueKey('icon'),
                      size: 13,
                      color: contentColor,
                    ),
            ),
            const SizedBox(width: 5),
            // Label
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                key: ValueKey(state),
                isLoading
                    ? l.postTranslating
                    : isTranslated
                        ? l.postShowOriginal
                        : l.postTranslate,
                style: GoogleFonts.notoSansKr(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: contentColor,
                ),
              ),
            ),
            // "· OriginalLang" shown when translated
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: isTranslated
                  ? Row(
                      children: [
                        const SizedBox(width: 4),
                        Text(
                          '· $fromLangName',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
