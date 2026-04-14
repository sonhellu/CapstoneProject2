import 'package:flutter_naver_map/flutter_naver_map.dart';

import '../models/user_pin_model.dart';

/// In-memory mock "database" for pinned locations.
///
/// Replace the body of [saveMockPost] and the [_db] seed data with real
/// HTTP calls when the FastAPI backend is ready.
///
/// Swap guide:
///   - [checkIsPinned]   → GET /pins/nearby?lat=…&lng=…
///   - [findNearbyPin]   → GET /pins/nearby?lat=…&lng=…  (returns full pin)
///   - [saveMockPost]    → POST /pins
///   - [allPins]         → GET /pins
class MockPinService {
  MockPinService._();
  static final MockPinService instance = MockPinService._();

  // ── Proximity threshold ─────────────────────────────────────────────
  // 0.0002° ≈ 22 m — generous enough for a finger tap, tight enough to
  // avoid false positives across different buildings.
  static const double _kThreshold = 0.0002;

  /// Exposed for map / POI proximity checks against in-memory [_pins].
  static const double nearbyThresholdDegrees = _kThreshold;

  // ── Seed data (Keimyung University area) ────────────────────────────
  // Each entry mirrors the shape of a backend POST /pins body:
  //   id, lat, lng, title, content, type
  final List<Map<String, dynamic>> _db = [
    {
      'id': 'km_001',
      'lat': 35.8562,
      'lng': 128.4896,
      'title': '계명대학교 정문',
      'content': '메인 게이트 — 버스 정류장 바로 앞',
      'type': 'utility',
    },
    {
      'id': 'km_002',
      'lat': 35.8571,
      'lng': 128.4882,
      'title': '학생회관 편의점',
      'content': '캠퍼스 내 CU 편의점, 24시간 운영',
      'type': 'restaurant',
    },
    {
      'id': 'km_003',
      'lat': 35.8548,
      'lng': 128.4912,
      'title': '정문 약국',
      'content': '정문 바로 앞, 학생 할인 적용',
      'type': 'pharmacy',
    },
    {
      'id': 'km_004',
      'lat': 35.8583,
      'lng': 128.4870,
      'title': '국제학생 기숙사',
      'content': '유학생 전용 기숙사 — 신청은 학생처',
      'type': 'realEstate',
    },
    {
      'id': 'km_005',
      'lat': 35.8558,
      'lng': 128.4905,
      'title': '캠퍼스 ATM (하나은행)',
      'content': '외국 카드 사용 가능, Visa/Mastercard OK',
      'type': 'utility',
    },
  ];

  // ── Public API ──────────────────────────────────────────────────────

  /// Returns true if any saved pin is within [_kThreshold] degrees of
  /// ([lat], [lng]).
  bool checkIsPinned(double lat, double lng) =>
      findNearbyPin(lat, lng) != null;

  /// Returns the raw DB entry nearest to ([lat], [lng]), or null if none
  /// is within [_kThreshold].
  Map<String, dynamic>? findNearbyPin(double lat, double lng) {
    for (final entry in _db) {
      if (_isNear(lat, lng, entry['lat'] as double, entry['lng'] as double)) {
        return entry;
      }
    }
    return null;
  }

  /// Converts the nearest raw entry to a [UserPinModel], or null.
  UserPinModel? findNearbyPinModel(double lat, double lng) {
    final entry = findNearbyPin(lat, lng);
    return entry == null ? null : _toModel(entry);
  }

  /// Simulates POST /pins — adds the new pin to the in-memory DB and
  /// returns the saved [UserPinModel].
  ///
  /// Replace with:
  /// ```dart
  /// final res = await http.post(Uri.parse('$baseUrl/pins'),
  ///   headers: {'Content-Type': 'application/json'},
  ///   body: jsonEncode({'lat': lat, 'lng': lng, 'title': name, ...}));
  /// return UserPinModel.fromJson(jsonDecode(res.body));
  /// ```
  Future<UserPinModel> saveMockPost(
    double lat,
    double lng, {
    String name = '',
    PinType type = PinType.utility,
  }) async {
    // Simulate network latency.
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final id = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final title = name.isNotEmpty
        ? name
        : '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';

    final entry = <String, dynamic>{
      'id': id,
      'lat': lat,
      'lng': lng,
      'title': title,
      'content': '',
      'type': type.name,
    };

    _db.add(entry);
    return _toModel(entry);
  }

  /// All saved pins as [UserPinModel] — use to seed the map on startup.
  List<UserPinModel> get allPins => _db.map(_toModel).toList();

  // ── Helpers ─────────────────────────────────────────────────────────

  bool _isNear(double lat1, double lng1, double lat2, double lng2) =>
      (lat1 - lat2).abs() < _kThreshold &&
      (lng1 - lng2).abs() < _kThreshold;

  static PinType _typeFromString(String t) => switch (t) {
        'restaurant' => PinType.restaurant,
        'realEstate' => PinType.realEstate,
        'pharmacy'   => PinType.pharmacy,
        _            => PinType.utility,
      };

  static UserPinModel _toModel(Map<String, dynamic> m) => UserPinModel(
        id: m['id'] as String,
        latLng: NLatLng(m['lat'] as double, m['lng'] as double),
        name: m['title'] as String,
        notes: m['content'] as String,
        type: _typeFromString(m['type'] as String),
        isPublic: true,
        rating: 4,
        createdAt: DateTime(2025, 1, 1),
        authorName: 'hicampus',
        isVerified: true,
      );
}
