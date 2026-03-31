import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:capstone_frontend/l10n/app_localizations.dart';
import '../locale/app_language_option.dart';
import '../locale/locale_controller.dart';

/// Nút góc phải: [Icons.language] mở bottom sheet chọn ngôn ngữ (flutter gen-l10n).
class LanguagePickerButton extends StatelessWidget {
  const LanguagePickerButton({super.key});

  static bool _localeEquals(Locale a, Locale b) =>
      a.languageCode == b.languageCode &&
      (a.countryCode ?? '') == (b.countryCode ?? '');

  Future<void> _openSheet(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = context.read<LocaleController>();
    final theme = Theme.of(context);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final current = controller.locale;
        final bottomInset = MediaQuery.paddingOf(sheetContext).bottom;
        final maxH = MediaQuery.sizeOf(sheetContext).height * 0.58;

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          builder: (context, t, child) {
            return Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, 10 * (1 - t)),
                child: child,
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset + 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 8, 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.language_rounded,
                        color: theme.colorScheme.primary,
                        size: 26,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.languageSheetTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close_rounded),
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxH),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: AppLanguageOption.all.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 2),
                    itemBuilder: (context, i) {
                      final opt = AppLanguageOption.all[i];
                      final selected = _localeEquals(opt.locale, current);
                      return _LanguageTile(
                        option: opt,
                        selected: selected,
                        onTap: () async {
                          HapticFeedback.selectionClick();
                          await controller.setLocale(opt.locale);
                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext);
                          }
                          HapticFeedback.lightImpact();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return IconButton(
      tooltip: l10n.languagePickerTooltip,
      onPressed: () => _openSheet(context),
      icon: Icon(
        Icons.language_rounded,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final AppLanguageOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Text(
                option.flagEmoji,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.nativeLabel,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: selected
                    ? Icon(
                        Icons.check_circle_rounded,
                        key: const ValueKey('on'),
                        color: theme.colorScheme.primary,
                        size: 24,
                      )
                    : SizedBox(
                        key: const ValueKey('off'),
                        width: 24,
                        height: 24,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
