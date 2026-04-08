import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_keys.dart';
import 'translation_service.dart';

// ──────────────────────────── Model ────────────────────────────

class LocalizedAddress {
  /// Translated address in the user's language (e.g. "Nhà thi đấu Đại học Keimyung").
  final String localized;

  /// Original Korean road address (e.g. "대구 달서구 달구벌대로 1095").
  final String korean;

  const LocalizedAddress({required this.localized, required this.korean});

  /// Returns [localized] if different from [korean], else just [korean].
  bool get hasTranslation =>
      localized.isNotEmpty && localized != korean;
}

// ──────────────────────────── Service (Singleton) ────────────────────────────

/// Converts lat/lng → Korean address (Naver Reverse Geocoding NCP)
/// then translates the result to the user's current app language (MyMemory).
///
/// Usage — inside a Widget with BuildContext:
/// ```dart
/// final address = await GeocodingService.instance
///     .getLocalizedAddress(lat, lng, context);
/// Text(address.localized);        // "Phòng tập thể dục ĐH Keimyung"
/// Text(address.korean);           // "계명대학교 체육관"
/// ```
class GeocodingService {
  GeocodingService._();
  static final instance = GeocodingService._();

  static const _reverseGeoUrl =
      'https://naveropenapi.apigw.ntruss.com/map-reversegeocode/v2/gc';

  /// Resolves lat/lng to a [LocalizedAddress].
  ///
  /// 1. Calls Naver Reverse Geocoding → Korean address.
  /// 2. Resolves [targetLang] from [LangCode.fromTag] on the app's locale.
  /// 3. Translates via [TranslationService] if [targetLang] ≠ Korean.
  /// 4. Falls back gracefully — never throws.
  Future<LocalizedAddress> getLocalizedAddress(
    double lat,
    double lng,
    String targetLang,
  ) async {
    final korean = await _reverseGeocode(lat, lng);
    if (korean.isEmpty) {
      return const LocalizedAddress(localized: '', korean: '');
    }

    if (targetLang == LangCode.ko) {
      return LocalizedAddress(localized: korean, korean: korean);
    }

    final localized = await TranslationService.instance.translateText(
      korean,
      from: LangCode.ko,
      to: targetLang,
    );

    return LocalizedAddress(localized: localized, korean: korean);
  }

  // ── Private: Naver Reverse Geocoding ────────────────────────────────────

  Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse(_reverseGeoUrl).replace(queryParameters: {
        'coords': '$lng,$lat',           // Naver uses lng,lat order
        'output': 'json',
        'orders': 'roadaddr,addr',       // prefer road address
      });

      final response = await http.get(uri, headers: {
        'X-NCP-APIGW-API-KEY-ID': ApiKeys.naverMapClientId,
        'X-NCP-APIGW-API-KEY': ApiKeys.naverMapClientSecret,
      }).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        if (kDebugMode) {
          debugPrint('[Geocoding] HTTP ${response.statusCode}: ${response.body}');
        }
        return '';
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return _extractAddress(data);
    } catch (e) {
      if (kDebugMode) debugPrint('[Geocoding] Error: $e');
      return '';
    }
  }

  /// Parses Naver reverse geocoding JSON → readable Korean address string.
  String _extractAddress(Map<String, dynamic> data) {
    final results = data['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) return '';

    // Prefer roadaddr over addr
    for (final result in results) {
      final r = result as Map<String, dynamic>;
      final name = r['name'] as String? ?? '';
      final region = r['region'] as Map<String, dynamic>?;
      final land = r['land'] as Map<String, dynamic>?;

      if (land == null || region == null) continue;

      final area1 = region['area1']?['name'] ?? '';
      final area2 = region['area2']?['name'] ?? '';
      final area3 = region['area3']?['name'] ?? '';
      final number1 = land['number1'] ?? '';
      final number2 = land['number2'] ?? '';
      final addition0 = land['addition0']?['value'] ?? '';

      String address = '$area1 $area2 ';

      if (name == 'roadaddr') {
        final roadName = land['name'] ?? '';
        address += '$roadName $number1';
        if (number2.isNotEmpty) address += '-$number2';
        if (addition0.isNotEmpty) address += ' $addition0';
      } else {
        address += '$area3 $number1';
        if (number2.isNotEmpty) address += '-$number2';
      }

      return address.trim();
    }

    return '';
  }
}
