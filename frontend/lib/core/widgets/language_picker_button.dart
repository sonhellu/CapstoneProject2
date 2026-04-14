import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../locale/language_model.dart';
import '../locale/locale_controller.dart';
import '../theme/theme_ext.dart';

// ─────────────────────────── Trigger Button ───────────────────────────

/// Icon button đặt ở AppBar hoặc Profile — mở [LanguageBottomSheet].
class LanguagePickerButton extends StatelessWidget {
  const LanguagePickerButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return IconButton(
      tooltip: l.languagePickerTooltip,
      onPressed: () => LanguageBottomSheet.show(context),
      icon: const Icon(Icons.language_rounded),
      color: Theme.of(context).colorScheme.onSurface,
    );
  }
}

// ─────────────────────────── Bottom Sheet ───────────────────────────

class LanguageBottomSheet extends StatefulWidget {
  const LanguageBottomSheet._();

  /// Mở bottom sheet chọn ngôn ngữ. Dùng hàm này thay vì tạo widget trực tiếp.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const LanguageBottomSheet._(),
    );
  }

  @override
  State<LanguageBottomSheet> createState() => _LanguageBottomSheetState();
}

class _LanguageBottomSheetState extends State<LanguageBottomSheet> {
  late LanguageModel _selected;

  @override
  void initState() {
    super.initState();
    final currentLocale = context.read<LocaleController>().locale;
    _selected = _findMatch(currentLocale);
  }

  /// Tìm LanguageModel khớp với locale hiện tại.
  LanguageModel _findMatch(Locale locale) {
    return LanguageModel.all.firstWhere(
      (m) => m.languageCode == locale.languageCode,
      orElse: () => LanguageModel.systemDefault,
    );
  }

  /// Áp dụng ngôn ngữ đã chọn và đóng sheet.
  Future<void> _confirm() async {
    HapticFeedback.mediumImpact();
    final controller = context.read<LocaleController>();

    if (_selected.isSystemDefault) {
      // Dùng locale thiết bị — lấy từ WidgetsBinding
      final deviceLocale =
          WidgetsBinding.instance.platformDispatcher.locale;
      await controller.setLocale(deviceLocale);
    } else {
      await controller.setLocale(_selected.locale);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset + safeBottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildTitle(context),
          Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context).dividerColor),
          _buildLanguageList(),
          _buildConfirmButton(context),
        ],
      ),
    );
  }

  // ─── Drag Handle ───
  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // ─── Title Row ───
  Widget _buildTitle(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final p = context.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: p.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.language_rounded,
              color: p,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.languageSheetTitle,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: context.onSurface,
                  ),
                ),
                Text(
                  l.languageSheetSubtitle,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12,
                    color: context.onSurfaceVar,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close_rounded, color: context.onSurfaceVar),
          ),
        ],
      ),
    );
  }

  // ─── Language List ───
  Widget _buildLanguageList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: LanguageModel.all.length,
      separatorBuilder: (context, i) => i == 0
          ? Divider(
              height: 1,
              thickness: 1,
              indent: 20,
              endIndent: 20,
              color: Theme.of(context).dividerColor,
            )
          : const SizedBox.shrink(),
      itemBuilder: (context, i) {
        final lang = LanguageModel.all[i];
        final isSelected = _selected.languageCode == lang.languageCode;
        return _LanguageTile(
          language: lang,
          isSelected: isSelected,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selected = lang);
          },
        );
      },
    );
  }

  // ─── Confirm Button ───
  Widget _buildConfirmButton(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _confirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(vertical: 15),
            elevation: 0,
          ),
          child: Text(
            l.btnConfirm,
            style: GoogleFonts.notoSansKr(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Language Tile ───────────────────────────

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  final LanguageModel language;
  final bool isSelected;
  final VoidCallback onTap;

  // Myanmar script requires a Unicode-compliant font; others use NotoSansKr.
  TextStyle _nativeLabelStyle(BuildContext context, bool isSelected) {
    final weight = isSelected ? FontWeight.w700 : FontWeight.w500;
    final color =
        isSelected ? context.primary : context.onSurface;
    if (language.languageCode == 'my') {
      return GoogleFonts.notoSansMyanmar(
          fontSize: 15, fontWeight: weight, color: color);
    }
    return GoogleFonts.notoSansKr(
        fontSize: 15, fontWeight: weight, color: color);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: isSelected ? p.withValues(alpha: 0.12) : context.cardFill,
        border: isSelected
            ? Border(
                left: BorderSide(color: p, width: 3),
              )
            : const Border(
                left: BorderSide(color: Colors.transparent, width: 3),
              ),
      ),
      child: InkWell(
        onTap: onTap,
        splashColor: p.withValues(alpha: 0.08),
        highlightColor: p.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          child: Row(
            children: [
              // ── Flag circle ──
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? p.withValues(alpha: 0.08)
                      : context.subtleFill,
                  border: isSelected
                      ? Border.all(color: p, width: 2)
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  language.flagEmoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(width: 14),
              // ── Labels ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language.nativeLabel,
                      style: _nativeLabelStyle(context, isSelected),
                    ),
                    if (!language.isSystemDefault) ...[
                      const SizedBox(height: 2),
                      Text(
                        language.languageName,
                        style: GoogleFonts.notoSansKr(
                          fontSize: 12,
                          color: context.onSurfaceVar,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // ── Check icon ──
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: child,
                ),
                child: isSelected
                    ? Container(
                        key: const ValueKey('checked'),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: p,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 15,
                        ),
                      )
                    : Container(
                        key: const ValueKey('unchecked'),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.outline.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
