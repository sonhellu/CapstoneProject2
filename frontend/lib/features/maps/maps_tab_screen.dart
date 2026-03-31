import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../shell/theme/shell_theme.dart';

/// Màn Maps — tính năng trọng tâm (nội dung placeholder).
class MapsTabScreen extends StatelessWidget {
  const MapsTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShellColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ShellColors.primaryBlue.withValues(alpha: 0.15),
                    ShellColors.accentRed.withValues(alpha: 0.08),
                  ],
                ),
                border: Border.all(
                  color: ShellColors.primaryBlue.withValues(alpha: 0.2),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map_rounded,
                      size: 72,
                      color: ShellColors.primaryBlue,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Bản đồ',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: ShellColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Campus, nhà thuê, tuyến metro — sẽ tích hợp SDK sau.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSansKr(
                          fontSize: 14,
                          height: 1.45,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
