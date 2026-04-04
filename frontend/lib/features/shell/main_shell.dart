import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../chat/chat_tab_screen.dart';
import '../home/home_tab_screen.dart';
import '../maps/maps_tab_screen.dart';
import '../profile/profile_tab_screen.dart';
import 'theme/shell_theme.dart';
import 'widgets/floating_bottom_nav.dart';
import 'widgets/map_loading_overlay.dart';

/// Shell chính: 4 tab + bottom bar nổi + delay khi mở Maps.
class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    this.homeCarouselAutoPlay = true,
  });

  /// Passed to [HomeTabScreen]; set to `false` in widget tests.
  final bool homeCarouselAutoPlay;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const int _mapsIndex = 2;

  int _selectedIndex = 0;

  /// Trạng thái tải giả lập khi chọn tab Maps (theo yêu cầu).
  bool _isLoadingMap = false;

  bool _isTabFading = false;

  final math.Random _random = math.Random();


  late final List<Widget> _pages = [
    HomeTabScreen(bannerCarouselAutoPlay: widget.homeCarouselAutoPlay),
    const ChatTabScreen(),
    const MapsTabScreen(),
    const ProfileTabScreen(),
  ];

  Future<void> _onNavTap(int index) async {
    if (index == _mapsIndex) {
      if (_selectedIndex == _mapsIndex) return;

      setState(() => _isLoadingMap = true);

      final delayMs = 800 + _random.nextInt(401);
      await Future<void>.delayed(Duration(milliseconds: delayMs));

      if (!mounted) return;
      setState(() {
        _selectedIndex = _mapsIndex;
        _isLoadingMap = false;
      });
      return;
    }

    setState(() {
      _selectedIndex = index;
      _isTabFading = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    setState(() => _isTabFading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final navItems = [
      NavItemData(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: l.navHome,
      ),
      NavItemData(
        icon: Icons.chat_bubble_outline_rounded,
        activeIcon: Icons.chat_rounded,
        label: l.navCommunity,
      ),
      NavItemData(
        icon: Icons.map_outlined,
        activeIcon: Icons.map_rounded,
        label: l.navMap,
      ),
      NavItemData(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: l.navMyPage,
      ),
    ];

    return Scaffold(
      backgroundColor: ShellColors.background,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _isTabFading ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: Container(
                color: Colors.black.withValues(alpha: 0.06),
              ),
            ),
          ),
          if (_isLoadingMap)
            const Positioned.fill(
              child: MapLoadingOverlay(),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thin divider — separates content from nav bar (Instagram style)
            const Divider(height: 1, thickness: 0.5, color: Color(0xFFE0E0E0)),
            SafeArea(
              top: false,
              child: FloatingBottomNav(
                currentIndex: _selectedIndex,
                onTap: _onNavTap,
                items: navItems,
                chatBadgeCount: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
