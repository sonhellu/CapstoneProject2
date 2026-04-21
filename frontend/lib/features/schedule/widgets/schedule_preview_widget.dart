import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/theme_ext.dart';
import '../../../l10n/app_localizations.dart';
import '../models/schedule_activity.dart';
import '../providers/schedule_provider.dart';
import '../schedule_screen.dart';

/// Home tab preview: up to 3 activities for today + link to full schedule.
class SchedulePreviewWidget extends StatelessWidget {
  const SchedulePreviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final today = DateTime.now();
    final items = context.watch<ScheduleProvider>().upcomingForDay(today);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 8, 10),
          child: Row(
            children: [
              Text(
                l.scheduleTodayHeader,
                style: GoogleFonts.notoSansKr(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.primary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => openScheduleScreen(context),
                style: TextButton.styleFrom(
                  foregroundColor: context.onSurfaceVar,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text(
                  l.scheduleViewAll,
                  style: GoogleFonts.notoSansKr(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text(
              l.scheduleNoActivitiesToday,
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                color: context.onSurfaceVar,
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              children: items
                  .map(
                    (a) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PreviewRow(activity: a),
                    ),
                  )
                  .toList(),
            ),
          ),
        Divider(height: 1, thickness: 1, color: context.divider),
      ],
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.activity});

  final ScheduleActivity activity;

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${activity.start.format(context)} – ${activity.end.format(context)}';

    return Material(
      color: context.cardFill,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => openScheduleScreen(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: context.cardElevationShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left accent bar
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: activity.categoryColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                  ),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      child: Row(
                        children: [
                          Text(activity.emoji, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activity.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.notoSansKr(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: context.onSurface,
                                  ),
                                ),
                                Text(
                                  timeStr,
                                  style: GoogleFonts.notoSansKr(
                                    fontSize: 12,
                                    color: context.onSurfaceVar,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: context.onSurfaceVar.withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
