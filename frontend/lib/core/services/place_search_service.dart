import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_keys.dart';

// ──────────────────────────── Model ────────────────────────────

class NaverPlace {
  final String id;
  final String name;
  final String category;
  final String address;
  final double lat;
  final double lng;

  const NaverPlace({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.lat,
    required this.lng,
  });

  factory NaverPlace.fromJson(Map<String, dynamic> json) {
    // mapx / mapy are longitude / latitude × 1e7 (WGS84)
    final mapx = int.tryParse(json['mapx']?.toString() ?? '') ?? 0;
    final mapy = int.tryParse(json['mapy']?.toString() ?? '') ?? 0;

    return NaverPlace(
      id: json['link']?.toString() ?? json['title']?.toString() ?? '',
      name: _clean(json['title']?.toString() ?? ''),
      category: _clean(json['category']?.toString() ?? ''),
      address: _clean(
        json['roadAddress']?.toString().isNotEmpty == true
            ? json['roadAddress'].toString()
            : json['address']?.toString() ?? '',
      ),
      lat: mapy / 1e7,
      lng: mapx / 1e7,
    );
  }

  /// Strips HTML tags and decodes common HTML entities.
  static String _clean(String raw) {
    return raw
        .replaceAll(RegExp(r'<[^>]+>'), '')   // <b>, </b> …
        .replaceAll('&amp;',  '&')
        .replaceAll('&lt;',   '<')
        .replaceAll('&gt;',   '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;',  "'")
        .trim();
  }
}

// ──────────────────────────── Service ────────────────────────────

class PlaceSearchService {
  static const _baseUrl = 'https://openapi.naver.com/v1/search/local.json';

  static final _headers = {
    'X-Naver-Client-Id':     ApiKeys.naverLocalSearchClientId,
    'X-Naver-Client-Secret': ApiKeys.naverLocalSearchClientSecret,
  };

  /// Searches Naver's place database for [query].
  ///
  /// If [centerLat]/[centerLng] are provided, results are sorted
  /// nearest-first. Pass user position or campus centre as fallback.
  ///
  /// Returns an empty list on any error.
  static Future<List<NaverPlace>> search(
    String query, {
    double? centerLat,
    double? centerLng,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'query':   trimmed,
        'display': '15',      // fetch more so filtering still leaves enough
        'sort':    'comment', // sort by review count (most relevant first)
      });

      if (kDebugMode) debugPrint('[PlaceSearch] GET $uri');

      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        if (kDebugMode) {
          debugPrint('[PlaceSearch] HTTP ${response.statusCode}: ${response.body}');
        }
        return [];
      }

      final data  = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];

      var places = items
          .cast<Map<String, dynamic>>()
          .map(NaverPlace.fromJson)
          .where((p) => p.lat != 0 && p.lng != 0)
          .toList();

      // ── Sort by distance ─────────────────────────────────────────────────
      // No radius filter — search covers all of Korea.
      // If a centre point is provided, sort nearest-first so the most
      // relevant results appear at the top of the dropdown.
      if (centerLat != null && centerLng != null) {
        places.sort((a, b) =>
            _distanceKm(centerLat, centerLng, a.lat, a.lng)
                .compareTo(_distanceKm(centerLat, centerLng, b.lat, b.lng)));

        if (kDebugMode) {
          for (final p in places) {
            final d = _distanceKm(centerLat, centerLng, p.lat, p.lng);
            debugPrint('[PlaceSearch] ${p.name} — ${d.toStringAsFixed(1)} km');
          }
        }
      }

      return places;
    } catch (e) {
      if (kDebugMode) debugPrint('[PlaceSearch] Error: $e');
      return [];
    }
  }

  /// Haversine distance in kilometres between two WGS84 coordinates.
  static double _distanceKm(
    double lat1, double lng1,
    double lat2, double lng2,
  ) {
    const r = 6371.0; // Earth radius km
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _rad(double deg) => deg * math.pi / 180;
}
