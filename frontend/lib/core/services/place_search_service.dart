import 'dart:convert';
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
    // mapx / mapy are longitude / latitude × 1e7
    final mapx = int.tryParse(json['mapx']?.toString() ?? '') ?? 0;
    final mapy = int.tryParse(json['mapy']?.toString() ?? '') ?? 0;

    // Strip HTML tags (e.g. <b>keyword</b>) from title
    final rawTitle = json['title']?.toString() ?? '';
    final cleanTitle = rawTitle.replaceAll(RegExp(r'<[^>]+>'), '');

    return NaverPlace(
      id: json['link']?.toString() ?? rawTitle,
      name: cleanTitle,
      category: json['category']?.toString() ?? '',
      address: json['roadAddress']?.toString().isNotEmpty == true
          ? json['roadAddress'].toString()
          : json['address']?.toString() ?? '',
      lat: mapy / 1e7,
      lng: mapx / 1e7,
    );
  }
}

// ──────────────────────────── Service ────────────────────────────

class PlaceSearchService {
  static const _baseUrl =
      'https://openapi.naver.com/v1/search/local.json';

  static const _headers = {
    'X-Naver-Client-Id': ApiKeys.naverMapClientId,
    'X-Naver-Client-Secret': ApiKeys.naverMapClientSecret,
  };

  /// Searches Naver's place database for [query].
  /// Returns an empty list on any error (network, auth, etc.).
  static Future<List<NaverPlace>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    try {
      final uri = Uri.parse(
        '$_baseUrl?query=${Uri.encodeComponent(trimmed)}&display=5&sort=random',
      );
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>?;
      if (items == null) return [];

      return items
          .cast<Map<String, dynamic>>()
          .map(NaverPlace.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }
}
