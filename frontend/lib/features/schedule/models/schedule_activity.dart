import 'package:flutter/material.dart';

/// One personal activity entry (title, time range, optional location/notes, accent color).
class ScheduleActivity {
  const ScheduleActivity({
    required this.id,
    required this.title,
    required this.emoji,
    required this.start,
    required this.end,
    this.location,
    this.notes,
    required this.categoryColor,
    required this.date,
  });

  final String id;
  final String title;
  final String emoji;
  final TimeOfDay start;
  final TimeOfDay end;

  /// Optional — null means no location set.
  final String? location;

  /// Optional free-form notes.
  final String? notes;

  final Color categoryColor;

  /// Calendar day only (local midnight).
  final DateTime date;

  int get startMinutes => start.hour * 60 + start.minute;
  int get endMinutes   => end.hour   * 60 + end.minute;

  /// Duration in minutes.
  int get durationMinutes => endMinutes - startMinutes;

  /// Human-readable duration string, e.g. "1h 30m" or "45m".
  String get durationLabel {
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  ScheduleActivity copyWith({
    String? id,
    String? title,
    String? emoji,
    TimeOfDay? start,
    TimeOfDay? end,
    String? location,
    bool clearLocation = false,
    String? notes,
    bool clearNotes = false,
    Color? categoryColor,
    DateTime? date,
  }) {
    return ScheduleActivity(
      id:            id            ?? this.id,
      title:         title         ?? this.title,
      emoji:         emoji         ?? this.emoji,
      start:         start         ?? this.start,
      end:           end           ?? this.end,
      location:      clearLocation ? null : (location ?? this.location),
      notes:         clearNotes    ? null : (notes    ?? this.notes),
      categoryColor: categoryColor ?? this.categoryColor,
      date:          date          ?? this.date,
    );
  }

  // ── JSON ──────────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'id':     id,
    'title':  title,
    'emoji':  emoji,
    'startH': start.hour,
    'startM': start.minute,
    'endH':   end.hour,
    'endM':   end.minute,
    if (location != null) 'location': location,
    if (notes    != null) 'notes':    notes,
    'color':  categoryColor.toARGB32(),
    'date':   date.millisecondsSinceEpoch,
  };

  factory ScheduleActivity.fromJson(Map<String, dynamic> j) => ScheduleActivity(
    id:            j['id']    as String,
    title:         j['title'] as String,
    emoji:         (j['emoji'] as String?) ?? '📌',
    start:         TimeOfDay(hour: j['startH'] as int, minute: j['startM'] as int),
    end:           TimeOfDay(hour: j['endH']   as int, minute: j['endM']   as int),
    location:      j['location'] as String?,
    notes:         j['notes']    as String?,
    categoryColor: Color(j['color'] as int),
    date:          DateTime.fromMillisecondsSinceEpoch(j['date'] as int),
  );
}
