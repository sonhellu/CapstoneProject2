import 'package:flutter/foundation.dart';

import '../chat/models/chat_models.dart';

/// Singleton controller that lets any screen request the map tab
/// to fly its camera to a specific location.
///
/// Usage:
///   // Trigger focus from anywhere (e.g. chat location bubble tap):
///   MapFocusController.instance.focus(myLocationData);
///
///   // In MapScreen — consume + act:
///   MapFocusController.instance.addListener(_onFocusRequest);
///   void _onFocusRequest() {
///     final loc = MapFocusController.instance.consume();
///     if (loc != null) _flyToPosition(NLatLng(loc.lat, loc.lng));
///   }
class MapFocusController extends ChangeNotifier {
  MapFocusController._();
  static final instance = MapFocusController._();

  LocationData? _pending;

  /// The location waiting to be shown on the map, or null if none.
  LocationData? get pending => _pending;

  /// Request the map to focus on [location].
  /// Notifies all listeners.
  void focus(LocationData location) {
    _pending = location;
    notifyListeners();
  }

  /// Takes and clears the pending location.
  /// Returns null if nothing is pending.
  LocationData? consume() {
    final loc = _pending;
    _pending = null;
    return loc;
  }
}
