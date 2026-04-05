import 'package:flutter_naver_map/flutter_naver_map.dart';

import '../../../l10n/app_localizations.dart';

// ──────────────────────────── Pin Type ────────────────────────────

enum PinType {
  restaurant('🍜'),
  realEstate('🏠'),
  utility('📍');

  const PinType(this.emoji);
  final String emoji;
}

extension PinTypeLocalization on PinType {
  String localizedLabel(AppLocalizations l) {
    switch (this) {
      case PinType.restaurant:
        return l.pinTypeRestaurant;
      case PinType.realEstate:
        return l.pinTypeRealEstate;
      case PinType.utility:
        return l.pinTypeUtility;
    }
  }
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
