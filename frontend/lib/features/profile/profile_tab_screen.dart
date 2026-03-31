import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../shell/theme/shell_theme.dart';

class ProfileTabScreen extends StatelessWidget {
  const ProfileTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShellColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: ShellColors.primaryBlue.withValues(alpha: 0.15),
                child: Icon(
                  Icons.person_rounded,
                  size: 56,
                  color: ShellColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Hồ sơ',
                style: GoogleFonts.notoSansKr(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: ShellColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Thông tin du học sinh (placeholder)',
                style: GoogleFonts.notoSansKr(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
