import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/app_transitions.dart';
import '../../core/theme/theme_ext.dart';
import '../../l10n/app_localizations.dart';
import 'models/schedule_activity.dart';
import 'providers/schedule_provider.dart';
import 'widgets/add_schedule_activity_sheet.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime _mondayOfWeek(DateTime d) {
  final day = _dateOnly(d);
  return day.subtract(Duration(days: day.weekday - 1));
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _dateOnly(DateTime.now());
  }

  // ── Week helpers ────────────────────────────────────────────────────────

  List<DateTime> get _weekDays {
    final mon = _mondayOfWeek(_selectedDay);
    return List.generate(7, (i) => mon.add(Duration(days: i)));
  }

  bool get _isCurrentWeek =>
      _isSameDay(_mondayOfWeek(_selectedDay), _mondayOfWeek(DateTime.now()));

  void _prevWeek() =>
      setState(() => _selectedDay = _selectedDay.subtract(const Duration(days: 7)));

  void _nextWeek() =>
      setState(() => _selectedDay = _selectedDay.add(const Duration(days: 7)));

  void _goToToday() =>
      setState(() => _selectedDay = _dateOnly(DateTime.now()));

  // ── Sheet ───────────────────────────────────────────────────────────────

  Future<void> _openSheet({ScheduleActivity? existing}) async {
    final prov   = context.read<ScheduleProvider>();
    final result = await showScheduleActivitySheet(
      context,
      existing: existing,
      forDate:  _selectedDay,
    );
    if (!mounted || result == null) return;

    if (result.deleted) {
      if (existing != null) prov.remove(existing.id);
      return;
    }
    if (result.activity != null) {
      existing != null
          ? prov.update(result.activity!)
          : prov.add(result.activity!);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l      = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final dayFmt = DateFormat.E(locale);
    final numFmt = DateFormat.d(locale);
    final today  = _dateOnly(DateTime.now());
    final primary = Theme.of(context).colorScheme.primary;
    final prov   = context.watch<ScheduleProvider>();

    final days      = _weekDays;
    final weekLabel = '${DateFormat('MMM d').format(days.first)} – ${DateFormat('d, yyyy').format(days.last)}';

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        title: Text(
          l.scheduleScreenTitle,
          style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700),
        ),
        backgroundColor: context.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          // "Today" button — only visible when not on current week
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isCurrentWeek
                ? const SizedBox.shrink()
                : TextButton(
                    key: const ValueKey('today-btn'),
                    onPressed: _goToToday,
                    child: Text(
                      l.scheduleGoToToday,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openSheet(),
        backgroundColor: primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 2,
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Week strip ──────────────────────────────────────────────────
          Container(
            color: context.bg,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _prevWeek,
                        icon: const Icon(Icons.chevron_left_rounded, size: 22),
                        color: context.onSurfaceVar,
                        visualDensity: VisualDensity.compact,
                      ),
                      Text(
                        weekLabel,
                        style: GoogleFonts.notoSansKr(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: context.onSurfaceVar,
                        ),
                      ),
                      IconButton(
                        onPressed: _nextWeek,
                        icon: const Icon(Icons.chevron_right_rounded, size: 22),
                        color: context.onSurfaceVar,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Row(
                    children: List.generate(7, (i) {
                      final d        = days[i];
                      final selected = _isSameDay(d, _selectedDay);
                      final isToday  = _isSameDay(d, today);
                      final hasItems = prov.activitiesFor(d).isNotEmpty;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedDay = d),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  dayFmt.format(d),
                                  style: GoogleFonts.notoSansKr(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: selected
                                        ? primary
                                        : context.onSurfaceVar,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  numFmt.format(d),
                                  style: GoogleFonts.notoSansKr(
                                    fontSize: 16,
                                    fontWeight: selected
                                        ? FontWeight.w800
                                        : FontWeight.w400,
                                    color: selected
                                        ? primary
                                        : isToday
                                            ? context.onSurface
                                            : context.onSurfaceVar,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                // Activity dot
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: hasItems
                                        ? (selected
                                            ? primary
                                            : primary.withValues(alpha: 0.4))
                                        : Colors.transparent,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Selected underline
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: selected ? 20 : (isToday ? 4 : 0),
                                  height: 2,
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? primary
                                        : context.onSurfaceVar
                                            .withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                Divider(height: 1, thickness: 1, color: context.divider),
              ],
            ),
          ),

          // ── Activity list ───────────────────────────────────────────────
          Expanded(
            child: Consumer<ScheduleProvider>(
              builder: (context, prov, _) {
                final items = prov.activitiesFor(_selectedDay);
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_available_outlined,
                          size: 40,
                          color: context.onSurfaceVar.withValues(alpha: 0.35),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l.scheduleNoActivities,
                          style: GoogleFonts.notoSansKr(
                            fontSize: 14,
                            color: context.onSurfaceVar,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => _openSheet(),
                          child: Text(l.scheduleAddActivity),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final a = items[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Dismissible(
                        key: ValueKey(a.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) async {
                          final l = AppLocalizations.of(context)!;
                          return await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(
                                l.scheduleDeleteConfirmTitle,
                                style: GoogleFonts.notoSansKr(
                                    fontWeight: FontWeight.w700),
                              ),
                              content: Text(
                                l.scheduleDeleteConfirmMessage,
                                style: GoogleFonts.notoSansKr(),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, false),
                                  child: Text(l.scheduleDeleteCancel,
                                      style: GoogleFonts.notoSansKr()),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, true),
                                  style: TextButton.styleFrom(
                                    foregroundColor:
                                        Theme.of(context).colorScheme.error,
                                  ),
                                  child: Text(l.scheduleDelete,
                                      style: GoogleFonts.notoSansKr(
                                          fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (_) {
                          HapticFeedback.mediumImpact();
                          context.read<ScheduleProvider>().remove(a.id);
                        },
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 0),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        child: _ActivityCard(
                          activity: a,
                          onTap: () => _openSheet(existing: a),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Activity Card ───────────────────────────────────

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity, required this.onTap});

  final ScheduleActivity activity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final timeStr = '${activity.start.format(context)} – ${activity.end.format(context)}';

    return Material(
      color: context.cardFill,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
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
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(activity.emoji,
                              style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activity.title,
                                  style: GoogleFonts.notoSansKr(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: context.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                // Time + duration
                                Row(
                                  children: [
                                    Text(
                                      timeStr,
                                      style: GoogleFonts.notoSansKr(
                                        fontSize: 12,
                                        color: context.onSurfaceVar,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: activity.categoryColor
                                            .withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        activity.durationLabel,
                                        style: GoogleFonts.notoSansKr(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: activity.categoryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (activity.location?.isNotEmpty == true) ...[
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on_outlined,
                                          size: 13,
                                          color: context.onSurfaceVar),
                                      const SizedBox(width: 3),
                                      Expanded(
                                        child: Text(
                                          activity.location!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.notoSansKr(
                                            fontSize: 12,
                                            color: context.onSurfaceVar,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (activity.notes?.isNotEmpty == true) ...[
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Icon(Icons.notes_rounded,
                                          size: 13,
                                          color: context.onSurfaceVar),
                                      const SizedBox(width: 3),
                                      Expanded(
                                        child: Text(
                                          activity.notes!,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.notoSansKr(
                                            fontSize: 12,
                                            color: context.onSurfaceVar,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color:
                                context.onSurfaceVar.withValues(alpha: 0.4),
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

// ─────────────────────────── Navigation helper ───────────────────────────────

void openScheduleScreen(BuildContext context) {
  Navigator.of(context).push(
    AppTransitions.fadeSlide(const ScheduleScreen()),
  );
}
