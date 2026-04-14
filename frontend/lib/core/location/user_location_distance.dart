import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';

import '../../l10n/app_localizations.dart';

/// Geodesic distance & formatting for "distance from you" map UI.
///
/// Prefer [geolocatorMeters] (WGS84) in app code; [haversineMeters] is kept for
/// parity checks / documentation of the Haversine formula.
abstract final class UserLocationDistance {
  static const double _earthRadiusM = 6371000.0;

  /// Great-circle distance (Haversine), meters. Earth modeled as sphere ~6371 km.
  static double haversineMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _earthRadiusM * c;
  }

  static double _degToRad(double d) => d * math.pi / 180.0;

  /// Recommended: platform geodesic distance in meters (matches typical map apps).
  static double geolocatorMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  /// Formats the km part for &lt; 10 km (one decimal when needed), else integer km.
  static String formatKilometersPart(double meters) {
    final km = meters / 1000.0;
    if (km >= 10) return km.round().toString();
    final roundedTenth = (km * 10).round() / 10.0;
    if ((roundedTenth - roundedTenth.round()).abs() < 1e-9) {
      return roundedTenth.round().toString();
    }
    return roundedTenth.toStringAsFixed(1);
  }

  /// Localized one-line caption: meters if &lt; 1000, else km.
  static String localizedCaption(BuildContext context, double meters) {
    final l = AppLocalizations.of(context)!;
    if (meters < 1000) {
      final m = meters.round().clamp(0, 999999999);
      return l.mapDistanceFromYouMeters(m);
    }
    return l.mapDistanceFromYouKilometers(formatKilometersPart(meters));
  }
}
