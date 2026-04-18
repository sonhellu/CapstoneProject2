import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:http/http.dart' as http;

import '../config/api_keys.dart';

// ─────────────────────────── Result model ────────────────────────────

/// Successful route data returned by [DirectionService.getRoute].
class RouteResult {
  const RouteResult({
    required this.path,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  /// Ordered list of coordinates forming the driving path.
  final List<NLatLng> path;

  /// Total route distance in metres.
  final int distanceMeters;

  /// Estimated travel time in seconds.
  final int durationSeconds;

  // ── Convenience formatters ──────────────────────────────────────

  /// "1.4 km"  or  "850 m"
  String get distanceLabel {
    if (distanceMeters >= 1000) {
      final km = distanceMeters / 1000.0;
      return '${km.toStringAsFixed(1)} km';
    }
    return '$distanceMeters m';
  }

  /// "12 min"  or  "1 hr 5 min"
  String get durationLabel {
    final minutes = (durationSeconds / 60).round();
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h hr' : '$h hr $m min';
  }
}

// ─────────────────────────── Typed error ─────────────────────────────

/// Represents a known failure from the Directions API.
class DirectionException implements Exception {
  const DirectionException(this.message);
  final String message;

  @override
  String toString() => 'DirectionException: $message';
}

// ─────────────────────────── Service ─────────────────────────────────

/// Fetches a driving route between two coordinates using the
/// Naver Directions 5 API and returns a strongly-typed [RouteResult].
///
/// Usage:
/// ```dart
/// try {
///   final result = await DirectionService.instance.getRoute(
///     start: NLatLng(35.8562, 128.4896),
///     goal:  NLatLng(35.8700, 128.6014),
///   );
///   print(result.distanceLabel);  // "14.2 km"
///   print(result.durationLabel);  // "22 min"
///   // Draw result.path on the map …
/// } on DirectionException catch (e) {
///   print(e.message);             // "No route found"
/// }
/// ```
class DirectionService {
  DirectionService._();
  static final instance = DirectionService._();

  static const _baseUrl =
      'https://maps.apigw.ntruss.com/map-direction/v1/driving';

  /// Returns a [RouteResult] containing the optimal driving path, distance,
  /// and duration between [start] and [goal].
  ///
  /// Throws [DirectionException] for API-level errors (no route, quota, etc.).
  /// Rethrows network / timeout exceptions as-is.
  Future<RouteResult> getRoute({
    required NLatLng start,
    required NLatLng goal,
  }) async {
    // Naver expects "longitude,latitude" (x,y) order for both start and goal.
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'start': '${start.longitude},${start.latitude}',
      'goal':  '${goal.longitude},${goal.latitude}',
      'option': 'traoptimal',          // optimal route
    });

    if (kDebugMode) {
      debugPrint('[DirectionService] GET $uri');
    }

    final response = await http.get(uri, headers: {
      'X-NCP-APIGW-API-KEY-ID': ApiKeys.naverMapClientId,
      'X-NCP-APIGW-API-KEY':    ApiKeys.naverMapClientSecret,
    }).timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      if (kDebugMode) {
        debugPrint('[DirectionService] HTTP ${response.statusCode}: ${response.body}');
      }
      throw DirectionException(
        'Server error ${response.statusCode}. Please try again.',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return _parse(json);
  }

  // ── JSON parsing ─────────────────────────────────────────────────

  RouteResult _parse(Map<String, dynamic> json) {
    // Top-level status code  (0 = OK)
    final code = json['code'] as int? ?? -1;
    if (code != 0) {
      final msg = json['message'] as String? ?? 'Unknown error';
      throw DirectionException(_friendlyError(code, msg));
    }

    // Navigate:  route → traoptimal → [0]
    final route    = json['route'] as Map<String, dynamic>?;
    final optimal  = route?['traoptimal'] as List<dynamic>?;
    if (optimal == null || optimal.isEmpty) {
      throw const DirectionException('No route found between the two points.');
    }

    final best = optimal.first as Map<String, dynamic>;

    // Summary fields
    final summary  = best['summary'] as Map<String, dynamic>? ?? {};
    final distance = (summary['distance'] as num?)?.toInt() ?? 0;   // metres
    final duration = (summary['duration'] as num?)?.toInt() ?? 0;   // ms → convert below

    // Path  →  list of [lng, lat] arrays
    final rawPath  = best['path'] as List<dynamic>? ?? [];
    final path = rawPath.map((point) {
      final p = point as List<dynamic>;
      // Naver returns [longitude, latitude]
      return NLatLng(
        (p[1] as num).toDouble(),  // latitude  — index 1
        (p[0] as num).toDouble(),  // longitude — index 0
      );
    }).toList();

    if (path.isEmpty) {
      throw const DirectionException('Route path is empty.');
    }

    return RouteResult(
      path: path,
      distanceMeters: distance,
      durationSeconds: duration ~/ 1000, // API returns milliseconds
    );
  }

  /// Maps Naver Directions API error codes to user-friendly messages.
  String _friendlyError(int code, String raw) {
    return switch (code) {
      1  => 'Departure and destination are the same.',
      2  => 'No route found — the two points may be too far apart or on separate road networks.',
      3  => 'Starting point is on a pedestrian-only road.',
      4  => 'Destination is on a pedestrian-only road.',
      5  => 'Driving route unavailable in this area.',
      _ => 'Directions unavailable (code $code): $raw',
    };
  }
}
