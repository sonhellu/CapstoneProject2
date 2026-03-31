import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../shell/theme/shell_theme.dart';

class HomeTabScreen extends StatelessWidget {
  const HomeTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShellColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Trang chủ',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: ShellColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Chào mừng du học sinh tại Hàn Quốc',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
