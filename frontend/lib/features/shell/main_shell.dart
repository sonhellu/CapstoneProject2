import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/widgets/language_picker_button.dart';
import '../chat/chat_tab_screen.dart';
import '../home/home_tab_screen.dart';
import '../maps/maps_tab_screen.dart';
import '../profile/profile_tab_screen.dart';
import 'theme/shell_theme.dart';
import 'widgets/floating_bottom_nav.dart';
import 'widgets/map_loading_overlay.dart';

/// Shell chính: 4 tab + bottom bar nổi + delay khi mở Maps.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const int _mapsIndex = 3;

  int _selectedIndex = 0;

  /// Trạng thái tải giả lập khi chọn tab Maps (theo yêu cầu).
  bool _isLoadingMap = false;

  final math.Random _random = math.Random();

  static const List<NavItemData> _navItems = [
    NavItemData(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    NavItemData(
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_rounded,
      label: 'Chat',
    ),
    NavItemData(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
    NavItemData(
      icon: Icons.map_outlined,
      activeIcon: Icons.map_rounded,
      label: 'Maps',
    ),
  ];

  List<Widget> get _pages => const [
        HomeTabScreen(),
        ChatTabScreen(),
        ProfileTabScreen(),
        MapsTabScreen(),
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

    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShellColors.background,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: KeyedSubtree(
              key: ValueKey<int>(_selectedIndex),
              child: _pages[_selectedIndex],
            ),
          ),
          Positioned(
            top: 0,
            right: 4,
            child: SafeArea(
              child: Material(
                color: Colors.transparent,
                child: const LanguagePickerButton(),
              ),
            ),
          ),
          if (_isLoadingMap)
            const Positioned.fill(
              child: MapLoadingOverlay(),
            ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          12 + MediaQuery.paddingOf(context).bottom,
        ),
        child: FloatingBottomNav(
          currentIndex: _selectedIndex,
          onTap: _onNavTap,
          items: _navItems,
          chatBadgeCount: 3,
        ),
      ),
    );
  }
}
