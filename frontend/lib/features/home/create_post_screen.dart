import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_ext.dart';
import '../../l10n/app_localizations.dart';
import '../auth/providers/auth_provider.dart';
import 'models/post.dart';
import 'providers/post_provider.dart';

const Color _kWarningOrange = Color(0xFFE65100);

// ──────────────────────────── Config ────────────────────────────
abstract final class _Cfg {
  static const titleMax = 100;
  static const contentMax = 2000;

  static const categories = [
    'International 🌏',
    'Campus 🇰🇷',
    'Scholarship 🎓',
    'Housing 🏠',
    'Academic 📚',
    'Lost & Found 🔍',
  ];

  static const languages = [
    'Korean',
    'Vietnamese',
    'English',
    'Japanese',
    'Chinese',
    'Myanmar',
  ];

  static const langFlags = {
    'Korean': '🇰🇷',
    'Vietnamese': '🇻🇳',
    'English': '🇺🇸',
    'Japanese': '🇯🇵',
    'Chinese': '🇨🇳',
    'Myanmar': '🇲🇲',
  };
}

// ──────────────────────────── Screen ────────────────────────────
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _titleFocus = FocusNode();
  final _contentFocus = FocusNode();

  String _category = _Cfg.categories[0];
  String _language = 'Vietnamese';
  bool _isPublishing = false;

  late final ValueNotifier<bool> _canPublish;

  @override
  void initState() {
    super.initState();
    _canPublish = ValueNotifier(false);
    _titleCtrl.addListener(_onTextChanged);
    _contentCtrl.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _titleFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _titleCtrl.removeListener(_onTextChanged);
    _contentCtrl.removeListener(_onTextChanged);
    _canPublish.dispose();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _canPublish.value =
        _titleCtrl.text.trim().isNotEmpty &&
        _contentCtrl.text.trim().isNotEmpty;
  }

  Future<void> _publish() async {
    if (!_canPublish.value || _isPublishing) return;
    HapticFeedback.mediumImpact();
    setState(() => _isPublishing = true);

    try {
      final auth = context.read<AuthProvider>();
      final uid = auth.uid;
      if (uid == null) {
        throw Exception('Please sign in before publishing.');
      }
      final authorName = auth.nickname;

      if (!mounted) return;

      final post = Post(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        author: PostAuthor(
          name: authorName,
          school: auth.school ?? 'Keimyung University',
          major: 'International Student',
          avatarInitial: authorName.characters.first.toUpperCase(),
        ),
        time: 'Just now',
        category: _normalizeCategory(_category),
        images: const [],
        language: _normalizeLanguage(_language),
        likes: 0,
        comments: 0,
        userId: uid,
      );

      await context.read<PostProvider>().addPost(post);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPublishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  String _normalizeCategory(String category) => switch (category) {
    'International 🌏' => 'International',
    'Campus 🇰🇷' => 'Campus',
    'Scholarship 🎓' => 'Scholarship',
    'Housing 🏠' => 'Housing',
    'Academic 📚' => 'Academic',
    'Lost & Found 🔍' => 'Campus',
    _ => 'Campus',
  };

  String _normalizeLanguage(String language) => switch (language) {
    'Korean' => 'KR',
    'Vietnamese' => 'VN',
    'English' => 'EN',
    'Japanese' => 'JA',
    'Chinese' => 'ZH',
    'Myanmar' => 'MY',
    _ => 'EN',
  };

  void _openLanguagePicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final l = AppLocalizations.of(ctx)!;
        final p = ctx.primary;
        final onS = ctx.onSurface;
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: ctx.outline.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l.createPostLanguage,
                style: GoogleFonts.notoSansKr(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: onS,
                ),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _Cfg.languages.length,
                itemBuilder: (_, i) {
                  final lang = _Cfg.languages[i];
                  final flag = _Cfg.langFlags[lang] ?? '🌐';
                  final isSel = lang == _language;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    leading: Text(flag, style: const TextStyle(fontSize: 22)),
                    title: Text(
                      lang,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 15,
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
                        color: isSel ? p : onS,
                      ),
                    ),
                    trailing: isSel
                        ? Icon(Icons.check_rounded, color: p)
                        : null,
                    onTap: () {
                      setState(() => _language = lang);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
          ),
        );
      },
    );
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.bg,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: context.cardFill,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: Icon(
            Icons.close_rounded,
            size: 22,
            color: context.onSurfaceVar,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppLocalizations.of(context)!.createPostNew,
          style: GoogleFonts.notoSansKr(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: context.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          // ── Category ──
          _Label(l.createPostCategory),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _Cfg.categories
                .map(
                  (cat) => _CategoryChip(
                    label: cat,
                    selected: _category == cat,
                    onTap: () => setState(() => _category = cat),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),

          // ── Title ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Label(l.createPostTitleLabel),
              _CharCounter(ctrl: _titleCtrl, max: _Cfg.titleMax),
            ],
          ),
          const SizedBox(height: 10),
          _FieldBox(
            child: TextField(
              controller: _titleCtrl,
              focusNode: _titleFocus,
              maxLength: _Cfg.titleMax,
              buildCounter:
                  (
                    _, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => null,
              inputFormatters: [
                LengthLimitingTextInputFormatter(_Cfg.titleMax),
              ],
              style: GoogleFonts.notoSansKr(
                fontSize: 15,
                color: context.onSurface,
                height: 1.4,
              ),
              textInputAction: TextInputAction.next,
              onEditingComplete: _contentFocus.requestFocus,
              decoration: InputDecoration.collapsed(
                hintText: l.createPostTitleHint,
                hintStyle: GoogleFonts.notoSansKr(
                  fontSize: 15,
                  color: context.hintColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Language ──
          _Label(l.createPostLanguage),
          const SizedBox(height: 10),
          _buildLanguageTile(),
          const SizedBox(height: 20),

          // ── Content ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Label(l.createPostContent),
              _CharCounter(ctrl: _contentCtrl, max: _Cfg.contentMax),
            ],
          ),
          const SizedBox(height: 10),
          _FieldBox(
            child: TextField(
              controller: _contentCtrl,
              focusNode: _contentFocus,
              maxLines: null,
              minLines: 7,
              maxLength: _Cfg.contentMax,
              buildCounter:
                  (
                    _, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => null,
              style: GoogleFonts.notoSansKr(
                fontSize: 14,
                color: context.onSurface,
                height: 1.75,
              ),
              decoration: InputDecoration.collapsed(
                hintText: l.createPostContentHint,
                hintStyle: GoogleFonts.notoSansKr(
                  fontSize: 14,
                  color: context.hintColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // ── Publish — only this widget rebuilds when typing ──
          ValueListenableBuilder<bool>(
            valueListenable: _canPublish,
            builder: (_, can, _) => _PublishButton(
              enabled: can && !_isPublishing,
              isPublishing: _isPublishing,
              onTap: _publish,
            ),
          ),
        ],
      ),
    );
  }

  // ── Builders ────────────────────────────────────────────────────────

  Widget _buildLanguageTile() {
    final flag = _Cfg.langFlags[_language] ?? '🌐';
    final p = context.primary;
    return ListTile(
      onTap: _openLanguagePicker,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      tileColor: context.cardFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.outline),
      ),
      leading: Icon(Icons.translate_rounded, color: p, size: 20),
      title: Text(
        '$flag  $_language',
        style: GoogleFonts.notoSansKr(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: context.onSurface,
        ),
      ),
      subtitle: Text(
        AppLocalizations.of(context)!.createPostLanguage,
        style: GoogleFonts.notoSansKr(fontSize: 11, color: p),
      ),
      trailing: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: context.onSurfaceVar,
      ),
    );
  }
}

// ──────────────────────────── _FieldBox ────────────────────────────
class _FieldBox extends StatelessWidget {
  const _FieldBox({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.cardFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.outline),
      ),
      child: child,
    );
  }
}

// ──────────────────────────── _Label ────────────────────────────
class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.notoSansKr(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: context.onSurfaceVar,
        letterSpacing: 0.4,
      ),
    );
  }
}

// ──────────────────────────── _CharCounter ────────────────────────────
class _CharCounter extends StatelessWidget {
  const _CharCounter({required this.ctrl, required this.max});
  final TextEditingController ctrl;
  final int max;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: ctrl,
      builder: (_, val, _) {
        final len = val.text.length;
        final ratio = len / max;
        final color = ratio >= 0.95
            ? Theme.of(context).colorScheme.error
            : ratio >= 0.80
            ? _kWarningOrange
            : context.hintColor;
        return Text(
          '$len / $max',
          style: GoogleFonts.notoSansKr(fontSize: 11, color: color),
        );
      },
    );
  }
}

// ──────────────────────────── _PublishButton ────────────────────────────
class _PublishButton extends StatelessWidget {
  const _PublishButton({
    required this.enabled,
    required this.isPublishing,
    required this.onTap,
  });
  final bool enabled;
  final bool isPublishing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.primary,
          disabledBackgroundColor: context.primary.withValues(alpha: 0.45),
          foregroundColor: cs.onPrimary,
          shape: const StadiumBorder(),
          elevation: 0,
        ),
        child: isPublishing
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(cs.onPrimary),
                ),
              )
            : Text(
                AppLocalizations.of(context)!.createPostPublish,
                style: GoogleFonts.notoSansKr(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

// ──────────────────────────── _CategoryChip ────────────────────────────
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? context.primary : context.cardFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? context.primary : context.outline,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.notoSansKr(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? cs.onPrimary : context.onSurfaceVar,
          ),
        ),
      ),
    );
  }
}
