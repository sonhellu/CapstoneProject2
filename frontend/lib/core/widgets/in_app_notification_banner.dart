import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// iOS-style in-app notification banner that slides down from the top.
///
/// Usage:
/// ```dart
/// InAppNotificationBanner.show(
///   context: context,
///   title: 'Kim Minji',
///   subtitle: 'Wants to connect with you',
///   avatarInitial: 'K',
///   onTap: () { /* navigate */ },
/// );
/// ```
class InAppNotificationBanner {
  InAppNotificationBanner._();

  static OverlayEntry? _current;

  static void show({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String avatarInitial,
    required VoidCallback onTap,
    Duration duration = const Duration(seconds: 5),
  }) {
    // Dismiss any existing banner first
    _current?.remove();
    _current = null;

    late final OverlayEntry entry;

    void dismiss() {
      if (_current == entry) {
        _current?.remove();
        _current = null;
      }
    }

    entry = OverlayEntry(
      builder: (_) => _BannerWidget(
        title: title,
        subtitle: subtitle,
        avatarInitial: avatarInitial,
        duration: duration,
        onTap: () {
          dismiss();
          onTap();
        },
        onDismiss: dismiss,
      ),
    );

    _current = entry;
    Overlay.of(context).insert(entry);
  }
}

// ─────────────────────────── Banner Widget ────────────────────────────────
class _BannerWidget extends StatefulWidget {
  const _BannerWidget({
    required this.title,
    required this.subtitle,
    required this.avatarInitial,
    required this.duration,
    required this.onTap,
    required this.onDismiss,
  });

  final String title;
  final String subtitle;
  final String avatarInitial;
  final Duration duration;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  State<_BannerWidget> createState() => _BannerWidgetState();
}

class _BannerWidgetState extends State<_BannerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 260),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    _ctrl.forward();
    Future.delayed(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, topPadding + 8, 12, 0),
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: widget.onTap,
                onVerticalDragUpdate: (d) {
                  if (d.delta.dy < -4) _dismiss();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: cs.primary,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          widget.avatarInitial.toUpperCase(),
                          style: GoogleFonts.notoSansKr(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: cs.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // App name
                            Text(
                              'HiCampus',
                              style: GoogleFonts.notoSansKr(
                                fontSize: 10,
                                color: cs.primary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 1),
                            // Sender name
                            Text(
                              widget.title,
                              style: GoogleFonts.notoSansKr(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // Message
                            Text(
                              widget.subtitle,
                              style: GoogleFonts.notoSansKr(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Dismiss button
                      GestureDetector(
                        onTap: _dismiss,
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
