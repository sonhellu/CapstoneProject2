import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/shell_theme.dart';

class NavItemData {
  const NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Bottom bar phẳng kiểu Instagram/Facebook — edge-to-edge, không bo góc.
class FloatingBottomNav extends StatelessWidget {
  const FloatingBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.chatBadgeCount,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavItemData> items;

  /// null = không hiện badge.
  final int? chatBadgeCount;

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.notoSansKr(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
    );

    return Material(
      color: ShellColors.surface,
      child: SizedBox(
        height: 55,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (i) {
            final selected = i == currentIndex;
            final item = items[i];
            final isChat = i == 1;

            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTap(i);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            selected ? item.activeIcon : item.icon,
                            size: 26,
                            color: selected
                                ? ShellColors.primaryBlue
                                : ShellColors.navInactive,
                          ),
                          if (isChat && (chatBadgeCount ?? 0) > 0)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: ShellColors.accentRed,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: ShellColors.surface,
                                    width: 1.5,
                                  ),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  chatBadgeCount! > 9
                                      ? '9+'
                                      : '$chatBadgeCount',
                                  style: GoogleFonts.notoSansKr(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: textStyle.copyWith(
                          color: selected
                              ? ShellColors.primaryBlue
                              : ShellColors.navInactive,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
