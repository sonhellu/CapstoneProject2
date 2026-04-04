import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ──────────────────────────── Design Tokens ────────────────────────────
abstract final class _T {
  static const primary    = Color(0xFF003478);
  static const background = Color(0xFFF5F7FA);
  static const surface    = Colors.white;
  static const textDark   = Color(0xFF1A1A1A);
  static const textGrey   = Color(0xFF6A6A6A);
  static const textLight  = Color(0xFFADB5BD);
  static const warning    = Color(0xFFE65100);
  static const danger     = Color(0xFFD32F2F);
  static const border     = Color(0xFFE4E8EF);
  static const divider    = Color(0xFFF0F2F5);
}

// ──────────────────────────── Config ────────────────────────────
abstract final class _Cfg {
  static const titleMax   = 100;
  static const contentMax = 2000;
  static const maxPhotos  = 5;

  static const categories = ['International 🌏', 'Campus 🇰🇷'];

  static const languages = [
    'Korean', 'Vietnamese', 'English', 'Japanese', 'Chinese', 'Myanmar',
  ];

  static const langFlags = {
    'Korean':     '🇰🇷',
    'Vietnamese': '🇻🇳',
    'English':    '🇺🇸',
    'Japanese':   '🇯🇵',
    'Chinese':    '🇨🇳',
    'Myanmar':    '🇲🇲',
  };
}

// ──────────────────────────── Screen ────────────────────────────
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleCtrl    = TextEditingController();
  final _contentCtrl  = TextEditingController();
  final _titleFocus   = FocusNode();
  final _contentFocus = FocusNode();

  String _category     = _Cfg.categories[0];
  String _language     = 'Vietnamese';
  bool   _isPublishing = false;
  int    _photoCount   = 0;

  // Only the Publish button + CharCounter rebuild on text change.
  late final ValueNotifier<bool> _canPublish;

  @override
  void initState() {
    super.initState();
    _canPublish = ValueNotifier(false);
    _titleCtrl.addListener(_onTextChanged);
    _contentCtrl.addListener(_onTextChanged);
    // Auto-focus title after first frame.
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
    if (!_canPublish.value) return;
    HapticFeedback.mediumImpact();
    setState(() => _isPublishing = true);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _isPublishing = false);
    Navigator.of(context).pop();
  }

  void _addPhoto() {
    if (_photoCount >= _Cfg.maxPhotos) return;
    HapticFeedback.lightImpact();
    setState(() => _photoCount++);
  }

  void _removePhoto() {
    if (_photoCount <= 0) return;
    HapticFeedback.lightImpact();
    setState(() => _photoCount--);
  }

  void _openLanguagePicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _T.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDE3EA),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Post Language',
              style: GoogleFonts.notoSansKr(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _T.textDark,
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _Cfg.languages.length,
              itemBuilder: (_, i) {
                final lang  = _Cfg.languages[i];
                final flag  = _Cfg.langFlags[lang] ?? '🌐';
                final isSel = lang == _language;
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20),
                  leading: Text(flag,
                      style: const TextStyle(fontSize: 22)),
                  title: Text(
                    lang,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 15,
                      fontWeight:
                          isSel ? FontWeight.w700 : FontWeight.w400,
                      color: isSel ? _T.primary : _T.textDark,
                    ),
                  ),
                  trailing: isSel
                      ? const Icon(Icons.check_rounded, color: _T.primary)
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
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: _T.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 22, color: _T.textGrey),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'New Post',
          style: GoogleFonts.notoSansKr(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _T.textDark,
          ),
        ),
        centerTitle: true,
      ),
      // bottomNavigationBar is automatically pushed above the keyboard
      // when resizeToAvoidBottomInset: true — no custom animation needed.
      bottomNavigationBar: _BottomBar(
        canAddPhoto: _photoCount < _Cfg.maxPhotos,
        onGallery: _addPhoto,
        onCamera: _addPhoto,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          // ── Category ──
          const _Label('Category'),
          const SizedBox(height: 10),
          Row(
            children: _Cfg.categories.map((cat) => Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _CategoryChip(
                label: cat,
                selected: _category == cat,
                onTap: () => setState(() => _category = cat),
              ),
            )).toList(),
          ),
          const SizedBox(height: 24),

          // ── Title ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _Label('Title'),
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
                  (_, {required currentLength, required isFocused, maxLength}) =>
                      null,
              inputFormatters: [
                LengthLimitingTextInputFormatter(_Cfg.titleMax),
              ],
              style: GoogleFonts.notoSansKr(
                  fontSize: 15, color: _T.textDark, height: 1.4),
              textInputAction: TextInputAction.next,
              onEditingComplete: _contentFocus.requestFocus,
              decoration: InputDecoration.collapsed(
                hintText: 'Enter a clear, concise title…',
                hintStyle: GoogleFonts.notoSansKr(
                    fontSize: 15, color: _T.textLight),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Language ──
          const _Label('Post Language'),
          const SizedBox(height: 10),
          _buildLanguageTile(),
          const SizedBox(height: 20),

          // ── Content ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _Label('Content'),
              _CharCounter(ctrl: _contentCtrl, max: _Cfg.contentMax),
            ],
          ),
          const SizedBox(height: 10),
          _FieldBox(
            child: TextField(
              controller: _contentCtrl,
              focusNode: _contentFocus,
              // maxLines: null avoids internal scrolling — outer ListView scrolls.
              maxLines: null,
              minLines: 7,
              maxLength: _Cfg.contentMax,
              buildCounter:
                  (_, {required currentLength, required isFocused, maxLength}) =>
                      null,
              style: GoogleFonts.notoSansKr(
                  fontSize: 14, color: _T.textDark, height: 1.75),
              decoration: InputDecoration.collapsed(
                hintText: 'Write your post here…',
                hintStyle: GoogleFonts.notoSansKr(
                    fontSize: 14, color: _T.textLight),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Photos ──
          _Label('Photos  ($_photoCount/${_Cfg.maxPhotos})'),
          const SizedBox(height: 10),
          _buildPhotoWrap(),
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
    return ListTile(
      onTap: _openLanguagePicker,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      tileColor: _T.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _T.border),
      ),
      leading:
          const Icon(Icons.translate_rounded, color: _T.primary, size: 20),
      title: Text(
        '$flag  $_language',
        style: GoogleFonts.notoSansKr(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: _T.textDark,
        ),
      ),
      subtitle: Text(
        'Post language',
        style: GoogleFonts.notoSansKr(fontSize: 11, color: _T.primary),
      ),
      trailing: const Icon(Icons.keyboard_arrow_down_rounded,
          color: _T.textGrey),
    );
  }

  Widget _buildPhotoWrap() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        if (_photoCount < _Cfg.maxPhotos)
          GestureDetector(
            onTap: _addPhoto,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _T.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _T.primary.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      color: _T.primary, size: 26),
                  const SizedBox(height: 4),
                  Text(
                    'Add',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 10,
                      color: _T.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ...List.generate(
          _photoCount,
          (_) => Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _T.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: _T.primary.withValues(alpha: 0.15)),
                ),
                child: Icon(
                  Icons.image_rounded,
                  color: _T.primary.withValues(alpha: 0.4),
                  size: 32,
                ),
              ),
              Positioned(
                top: -6,
                right: -6,
                child: GestureDetector(
                  onTap: _removePhoto,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: _T.danger,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 13, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────── _FieldBox ────────────────────────────
/// White card wrapper for collapsed TextField — provides the visible border.
class _FieldBox extends StatelessWidget {
  const _FieldBox({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _T.border),
      ),
      child: child,
    );
  }
}

// ──────────────────────────── _BottomBar ────────────────────────────
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.canAddPhoto,
    required this.onGallery,
    required this.onCamera,
  });
  final bool canAddPhoto;
  final VoidCallback onGallery;
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _T.surface,
        border: Border(top: BorderSide(color: _T.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              _BarBtn(
                icon: Icons.photo_library_outlined,
                label: 'Gallery',
                onTap: canAddPhoto ? onGallery : null,
              ),
              const SizedBox(width: 20),
              _BarBtn(
                icon: Icons.camera_alt_outlined,
                label: 'Camera',
                onTap: canAddPhoto ? onCamera : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarBtn extends StatelessWidget {
  const _BarBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap != null ? 1.0 : 0.35,
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: _T.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _T.primary,
              ),
            ),
          ],
        ),
      ),
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
        color: _T.textGrey,
        letterSpacing: 0.4,
      ),
    );
  }
}

// ──────────────────────────── _CharCounter ────────────────────────────
/// Uses ValueListenableBuilder — only this Text rebuilds on every keystroke.
class _CharCounter extends StatelessWidget {
  const _CharCounter({required this.ctrl, required this.max});
  final TextEditingController ctrl;
  final int max;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: ctrl,
      builder: (_, val, _) {
        final len   = val.text.length;
        final ratio = len / max;
        final color = ratio >= 0.95
            ? _T.danger
            : ratio >= 0.80
                ? _T.warning
                : _T.textLight;
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
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _T.primary,
          disabledBackgroundColor: _T.primary.withValues(alpha: 0.45),
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          elevation: 0,
        ),
        child: isPublishing
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Publish Post',
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _T.primary : _T.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _T.primary : _T.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.notoSansKr(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : _T.textGrey,
          ),
        ),
      ),
    );
  }
}
