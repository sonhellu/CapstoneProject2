import 'package:flutter_naver_map/flutter_naver_map.dart';

import '../../../l10n/app_localizations.dart';

// ──────────────────────────── Pin Type ────────────────────────────

enum PinType {
  restaurant('🍜'),
  realEstate('🏠'),
  utility('📍'),
  pharmacy('💊');

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
      case PinType.pharmacy:
        return l.pinTypePharmacy;
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
    this.authorId = '',
    this.authorName = '',
    this.isVerified = false,
    this.reviewCount = 0,
    this.addressKorean = '',
    this.addressLocalized = '',
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

  /// Who created this pin.
  final String authorId;
  final String authorName;

  /// Senior student or admin — shows a verified badge.
  final bool isVerified;

  /// Number of people who rated/reviewed this pin.
  final int reviewCount;

  /// Original Korean address from Naver Reverse Geocoding.
  final String addressKorean;

  /// Address translated to the user's current app language.
  final String addressLocalized;

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
    String? authorId,
    String? authorName,
    bool? isVerified,
    int? reviewCount,
    String? addressKorean,
    String? addressLocalized,
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
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      isVerified: isVerified ?? this.isVerified,
      reviewCount: reviewCount ?? this.reviewCount,
      addressKorean: addressKorean ?? this.addressKorean,
      addressLocalized: addressLocalized ?? this.addressLocalized,
    );
  }
}
