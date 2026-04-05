import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../locale/language_model.dart';
import '../locale/locale_controller.dart';

// ─────────────────────────── Design Tokens ───────────────────────────
abstract final class _T {
  static const primary = Color(0xFF003478);
  static const selectedBg = Color(0xFFE6EBF2);
  static const textDark = Color(0xFF1A1A1A);
  static const textGrey = Color(0xFF6B7280);
  static const divider = Color(0xFFF0F0F0);
}

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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset + safeBottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildTitle(context),
          const Divider(height: 1, thickness: 1, color: _T.divider),
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
          color: const Color(0xFFDDDDDD),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // ─── Title Row ───
  Widget _buildTitle(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _T.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.language_rounded,
              color: _T.primary,
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
                    color: _T.textDark,
                  ),
                ),
                Text(
                  l.languageSheetSubtitle,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12,
                    color: _T.textGrey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: _T.textGrey),
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
          ? const Divider(
              height: 1,
              thickness: 1,
              indent: 20,
              endIndent: 20,
              color: _T.divider,
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
            backgroundColor: _T.primary,
            foregroundColor: Colors.white,
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
  TextStyle _nativeLabelStyle(bool isSelected) {
    final weight = isSelected ? FontWeight.w700 : FontWeight.w500;
    final color = isSelected ? _T.primary : _T.textDark;
    if (language.languageCode == 'my') {
      return GoogleFonts.notoSansMyanmar(
          fontSize: 15, fontWeight: weight, color: color);
    }
    return GoogleFonts.notoSansKr(
        fontSize: 15, fontWeight: weight, color: color);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: isSelected ? _T.selectedBg : Colors.white,
        // #003478 left-edge accent bar when selected.
        border: isSelected
            ? const Border(
                left: BorderSide(color: _T.primary, width: 3),
              )
            : const Border(
                left: BorderSide(color: Colors.transparent, width: 3),
              ),
      ),
      child: InkWell(
        onTap: onTap,
        splashColor: _T.primary.withValues(alpha: 0.08),
        highlightColor: _T.primary.withValues(alpha: 0.04),
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
                      ? _T.primary.withValues(alpha: 0.08)
                      : const Color(0xFFF5F7FA),
                  border: isSelected
                      ? Border.all(color: _T.primary, width: 2)
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
                      style: _nativeLabelStyle(isSelected),
                    ),
                    if (!language.isSystemDefault) ...[
                      const SizedBox(height: 2),
                      Text(
                        language.languageName,
                        style: GoogleFonts.notoSansKr(
                          fontSize: 12,
                          color: _T.textGrey,
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
                        decoration: const BoxDecoration(
                          color: _T.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
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
                            color: const Color(0xFFDDE3EA),
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
