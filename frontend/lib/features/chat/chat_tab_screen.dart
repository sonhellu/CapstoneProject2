import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../shell/theme/shell_theme.dart';

class ChatTabScreen extends StatelessWidget {
  const ChatTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShellColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 64,
                  color: ShellColors.primaryBlue.withValues(alpha: 0.35),
                ),
                const SizedBox(height: 16),
                Text(
                  'Chat',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: ShellColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tin nhắn & nhóm lớp (placeholder)',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
