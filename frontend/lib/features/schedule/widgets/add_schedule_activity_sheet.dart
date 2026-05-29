import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/theme_ext.dart';
import '../../../l10n/app_localizations.dart';
import '../models/schedule_activity.dart';

// ─────────────────────────── Palette ─────────────────────────────────────────

const List<Color> kScheduleColorPalette = [
  Color(0xFF5C6BC0),
  Color(0xFF26A69A),
  Color(0xFFFF8F00),
  Color(0xFFAB47BC),
  Color(0xFFEF5350),
  Color(0xFF42A5F5),
  Color(0xFF7E57C2),
  Color(0xFF78909C),
];

const List<String> kEmojiChoices = [
  '📚', '⚽', '💻', '☕', '🎵', '🧘', '📌', '🍜',
  '🏋️', '🎯', '🛒', '🏃', '📖', '🎨', '🍳', '💊',
  '📝', '🤝', '🎬', '🚗', '😴', '🏊', '🎮', '✈️',
];

// ─────────────────────────── Result type ─────────────────────────────────────

typedef SheetResult = ({ScheduleActivity? activity, bool deleted});

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

// ─────────────────────────── Public API ──────────────────────────────────────

Future<SheetResult?> showScheduleActivitySheet(
  BuildContext context, {
  ScheduleActivity? existing,
  required DateTime forDate,
}) {
  return showModalBottomSheet<SheetResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AddScheduleActivitySheet(
      existing: existing,
      forDate: _dateOnly(forDate),
    ),
  );
}

// ─────────────────────────── Sheet widget ────────────────────────────────────

class _AddScheduleActivitySheet extends StatefulWidget {
  const _AddScheduleActivitySheet({
    this.existing,
    required this.forDate,
  });

  final ScheduleActivity? existing;
  final DateTime forDate;

  @override
  State<_AddScheduleActivitySheet> createState() =>
      _AddScheduleActivitySheetState();
}

class _AddScheduleActivitySheetState extends State<_AddScheduleActivitySheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _notesCtrl;
  late String    _emoji;
  late TimeOfDay _start;
  late TimeOfDay _end;
  late Color     _color;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl    = TextEditingController(text: e?.title    ?? '');
    _locationCtrl = TextEditingController(text: e?.location ?? '');
    _notesCtrl    = TextEditingController(text: e?.notes    ?? '');
    _emoji = e?.emoji         ?? kEmojiChoices.first;
    _start = e?.start         ?? const TimeOfDay(hour: 9,  minute: 0);
    _end   = e?.end           ?? const TimeOfDay(hour: 10, minute: 0);
    _color = e?.categoryColor ?? kScheduleColorPalette.first;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _start : _end;
    final t = await showTimePicker(context: context, initialTime: initial);
    if (t == null || !mounted) return;
    setState(() {
      if (isStart) {
        _start = t;
        if (t.hour * 60 + t.minute >= _end.hour * 60 + _end.minute) {
          final total = t.hour * 60 + t.minute + 60;
          _end = TimeOfDay(hour: (total ~/ 60) % 24, minute: total % 60);
        }
      } else {
        _end = t;
      }
    });
  }

  void _save() {
    final l     = AppLocalizations.of(context)!;
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.scheduleTitleRequired)),
      );
      return;
    }
    if (_end.hour * 60 + _end.minute <= _start.hour * 60 + _start.minute) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.scheduleEndAfterStart)),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    final loc   = _locationCtrl.text.trim();
    final notes = _notesCtrl.text.trim();
    Navigator.pop<SheetResult>(
      context,
      (
        activity: ScheduleActivity(
          id:            widget.existing?.id ?? 'act_${DateTime.now().microsecondsSinceEpoch}',
          title:         title,
          emoji:         _emoji,
          start:         _start,
          end:           _end,
          location:      loc.isEmpty   ? null : loc,
          notes:         notes.isEmpty ? null : notes,
          categoryColor: _color,
          date:          widget.forDate,
        ),
        deleted: false,
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l.scheduleDeleteConfirmTitle,
          style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700),
        ),
        content: Text(
          l.scheduleDeleteConfirmMessage,
          style: GoogleFonts.notoSansKr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              l.scheduleDeleteCancel,
              style: GoogleFonts.notoSansKr(),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(
              l.scheduleDelete,
              style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    HapticFeedback.mediumImpact();
    Navigator.pop<SheetResult>(
      context,
      (activity: null, deleted: true),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l      = AppLocalizations.of(context)!;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final dateStr = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    ).format(widget.forDate);

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: context.cardFill,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Handle bar ──
              Center(
                child: Container(
                  width: 36,
                  height: 3,
                  decoration: BoxDecoration(
                    color: context.outline.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Header row ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEdit ? l.scheduleEditActivity : l.scheduleAddActivity,
                          style: GoogleFonts.notoSansKr(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: context.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateStr,
                          style: GoogleFonts.notoSansKr(
                            fontSize: 13,
                            color: context.onSurfaceVar,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isEdit)
                    TextButton.icon(
                      onPressed: _confirmDelete,
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      label: Text(
                        l.scheduleDelete,
                        style: GoogleFonts.notoSansKr(fontSize: 13),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Title ──
              TextField(
                controller: _titleCtrl,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.notoSansKr(fontSize: 15),
                decoration: InputDecoration(
                  labelText: l.scheduleTitleLabel,
                  labelStyle: GoogleFonts.notoSansKr(
                    fontSize: 14,
                    color: context.onSurfaceVar,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: context.outline),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Emoji ──
              Text(
                l.scheduleEmojiLabel,
                style: GoogleFonts.notoSansKr(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.onSurfaceVar,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: kEmojiChoices.map((e) {
                  final sel = e == _emoji;
                  return GestureDetector(
                    onTap: () => setState(() => _emoji = e),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: sel
                            ? context.primary.withValues(alpha: 0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel
                              ? context.primary
                              : context.outline.withValues(alpha: 0.4),
                          width: sel ? 1.5 : 1,
                        ),
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 22)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // ── Time ──
              Row(
                children: [
                  Expanded(
                    child: _TimeButton(
                      label: l.scheduleStartTime,
                      time: _start.format(context),
                      onTap: () => _pickTime(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TimeButton(
                      label: l.scheduleEndTime,
                      time: _end.format(context),
                      onTap: () => _pickTime(isStart: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Location ──
              TextField(
                controller: _locationCtrl,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.notoSansKr(fontSize: 15),
                decoration: InputDecoration(
                  labelText: l.scheduleLocationLabel,
                  labelStyle: GoogleFonts.notoSansKr(
                    fontSize: 14,
                    color: context.onSurfaceVar,
                  ),
                  prefixIcon: Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: context.onSurfaceVar,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: context.outline),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Notes ──
              TextField(
                controller: _notesCtrl,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.notoSansKr(fontSize: 15),
                maxLines: 3,
                minLines: 1,
                decoration: InputDecoration(
                  labelText: l.scheduleNotesLabel,
                  labelStyle: GoogleFonts.notoSansKr(
                    fontSize: 14,
                    color: context.onSurfaceVar,
                  ),
                  prefixIcon: Icon(
                    Icons.notes_rounded,
                    size: 18,
                    color: context.onSurfaceVar,
                  ),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: context.outline),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Color ──
              Text(
                l.scheduleColorLabel,
                style: GoogleFonts.notoSansKr(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.onSurfaceVar,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: kScheduleColorPalette.map((c) {
                  final sel = c == _color;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => setState(() => _color = c),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: sel
                              ? Border.all(
                                  color: context.cardFill,
                                  width: 2.5,
                                  strokeAlign: BorderSide.strokeAlignOutside,
                                )
                              : null,
                        ),
                        child: sel
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 16)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              // ── Save button ──
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  l.scheduleSave,
                  style: GoogleFonts.notoSansKr(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Time Button ─────────────────────────────────────

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.label,
    required this.time,
    required this.onTap,
  });

  final String label;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          border: Border.all(
            color: context.outline.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule_outlined, size: 15, color: context.onSurfaceVar),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 10,
                    color: context.onSurfaceVar,
                  ),
                ),
                Text(
                  time,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
