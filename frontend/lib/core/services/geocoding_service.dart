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

  bool get hasTranslation => localized.isNotEmpty && localized != korean;
}

// ──────────────────────────── Service (Singleton) ────────────────────────────

class GeocodingService {
  GeocodingService._();
  static final instance = GeocodingService._();

  static const _reverseGeoUrl =
      'https://naveropenapi.apigw.ntruss.com/map-reversegeocode/v2/gc';
  static const _nominatimUrl =
      'https://nominatim.openstreetmap.org/reverse';

  /// Resolves lat/lng → [LocalizedAddress].
  ///
  /// Strategy:
  /// 1. Naver (Korean address) → translate via Papago NMT to [targetLang].
  /// 2. Naver fails → Nominatim with [targetLang] directly (no translation needed).
  /// 3. Both fail → empty address.
  Future<LocalizedAddress> getLocalizedAddress(
    double lat,
    double lng,
    String targetLang,
  ) async {
    // ── 1. Try Naver (returns Korean) ──────────────────────────────────────
    final korean = await _reverseGeocodeNaver(lat, lng);
    if (korean.isNotEmpty) {
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

    // ── 2. Naver failed → Nominatim with target language directly ──────────
    // Nominatim accepts ISO 639-1 codes; zh-CN → zh.
    final nominatimLang = _toNominatimLang(targetLang);
    final localized = await _reverseGeocodeNominatim(lat, lng, lang: nominatimLang);
    if (localized.isNotEmpty) {
      return LocalizedAddress(localized: localized, korean: localized);
    }

    return const LocalizedAddress(localized: '', korean: '');
  }

  // ── Naver ─────────────────────────────────────────────────────────────────

  Future<String> _reverseGeocodeNaver(double lat, double lng) async {
    try {
      final uri = Uri.parse(_reverseGeoUrl).replace(queryParameters: {
        'coords': '$lng,$lat',
        'output': 'json',
        'orders': 'roadaddr,addr',
      });

      final response = await http.get(uri, headers: {
        'X-NCP-APIGW-API-KEY-ID': ApiKeys.naverMapClientId,
        'X-NCP-APIGW-API-KEY': ApiKeys.naverMapClientSecret,
      }).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return '';

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return _extractAddress(data);
    } catch (_) {
      return '';
    }
  }

  // ── Nominatim ─────────────────────────────────────────────────────────────

  Future<String> _reverseGeocodeNominatim(
    double lat,
    double lng, {
    String lang = 'en',
  }) async {
    try {
      final uri = Uri.parse(_nominatimUrl).replace(queryParameters: {
        'format': 'jsonv2',
        'lat': '$lat',
        'lon': '$lng',
        'accept-language': lang,
      });

      final response = await http.get(uri, headers: {
        'User-Agent': 'HiCampus/1.0',
      }).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        if (kDebugMode) {
          debugPrint('[Geocoding] Nominatim HTTP ${response.statusCode}');
        }
        return '';
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final displayName = data['display_name'] as String? ?? '';
      if (displayName.isEmpty) return '';

      // Drop the last segment (country name) for a shorter string.
      final parts = displayName.split(', ');
      return parts.length > 1
          ? parts.sublist(0, parts.length - 1).join(', ')
          : displayName;
    } catch (e) {
      if (kDebugMode) debugPrint('[Geocoding] Nominatim Error: $e');
      return '';
    }
  }

  // ── Naver address parser ──────────────────────────────────────────────────

  String _extractAddress(Map<String, dynamic> data) {
    final results = data['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) return '';

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

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Maps app lang codes → ISO 639-1 accepted by Nominatim.
  static String _toNominatimLang(String langCode) => switch (langCode) {
        'zh-CN' => 'zh',
        _ => langCode,
      };
}
