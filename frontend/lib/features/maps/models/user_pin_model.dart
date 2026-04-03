import 'package:flutter_naver_map/flutter_naver_map.dart';

// ──────────────────────────── Pin Type ────────────────────────────

enum PinType {
  restaurant('Quán ăn ngon', '🍜'),
  realEstate('Bất động sản tốt', '🏠'),
  utility('Tiện ích khác', '📍');

  const PinType(this.label, this.emoji);
  final String label;
  final String emoji;
}

// ──────────────────────────── UserPinModel ────────────────────────────

class UserPinModel {
  const UserPinModel({
    required this.id,
    required this.latLng,
    required this.name,
    required this.notes,
    required this.type,
    required this.isPublic,
    required this.rating,
    required this.createdAt,
  });

  final String id;
  final NLatLng latLng;
  final String name;
  final String notes;
  final PinType type;

  /// true = visible to all students, false = private to owner only.
  final bool isPublic;

  /// 1–5 stars.
  final int rating;

  final DateTime createdAt;

  /// Human-readable label shown on the marker caption.
  String get markerCaption => '${type.emoji} $name';

  UserPinModel copyWith({
    String? id,
    NLatLng? latLng,
    String? name,
    String? notes,
    PinType? type,
    bool? isPublic,
    int? rating,
    DateTime? createdAt,
  }) {
    return UserPinModel(
      id: id ?? this.id,
      latLng: latLng ?? this.latLng,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      type: type ?? this.type,
      isPublic: isPublic ?? this.isPublic,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
