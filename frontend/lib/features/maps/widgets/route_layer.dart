import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/direction_service.dart';

// ─────────────────────────── Constants ───────────────────────────────

const _kRouteOverlayId   = '__route_path__';
const _kStartMarkerId    = '__route_start__';
const _kGoalMarkerId     = '__route_goal__';

/// Aligns with [ColorScheme.primary] in app theme.
const _kRouteColor       = Color(0xFF2563EB);
const _kRouteWidth       = 8.0;
const _kRouteOutlineWidth = 2.0;

// ─────────────────────────── Route state ─────────────────────────────

enum RouteStatus { idle, loading, success, error }

class RouteState {
  const RouteState._({
    required this.status,
    this.result,
    this.errorMessage,
  });

  const RouteState.idle()
      : this._(status: RouteStatus.idle);

  const RouteState.loading()
      : this._(status: RouteStatus.loading);

  RouteState.success(RouteResult result)
      : this._(status: RouteStatus.success, result: result);

  RouteState.error(String msg)
      : this._(status: RouteStatus.error, errorMessage: msg);

  final RouteStatus status;
  final RouteResult? result;
  final String? errorMessage;

  bool get isIdle    => status == RouteStatus.idle;
  bool get isLoading => status == RouteStatus.loading;
  bool get isSuccess => status == RouteStatus.success;
  bool get isError   => status == RouteStatus.error;
}

// ─────────────────────────── Controller ──────────────────────────────

/// Manages route fetching and communicates draw commands back to [MapScreen].
///
/// [MapScreen] owns the [NaverMapController] and calls [onDraw]/[onClear]
/// to update the map.  [RouteController] only does the API call and
/// notifies listeners about state — zero platform-channel coupling.
///
/// Usage:
/// ```dart
/// final _routeCtrl = RouteController();
///
/// @override
/// void initState() {
///   super.initState();
///   _routeCtrl.addListener(_onRouteStateChanged);
/// }
///
/// void _onRouteStateChanged() {
///   final state = _routeCtrl.state;
///   if (state.isSuccess) _drawRoute(state.result!);
///   if (state.isError)   _clearRoute();
///   setState(() {});      // rebuild info panel
/// }
/// ```
class RouteController extends ChangeNotifier {
  RouteState _state = const RouteState.idle();
  RouteState get state => _state;

  NLatLng? _start;
  NLatLng? _goal;
  NLatLng? get start => _start;
  NLatLng? get goal  => _goal;

  Future<void> fetchRoute({
    required NLatLng start,
    required NLatLng goal,
  }) async {
    _start = start;
    _goal  = goal;
    _state = const RouteState.loading();
    notifyListeners();

    try {
      final result = await DirectionService.instance.getRoute(
        start: start,
        goal:  goal,
      );
      _state = RouteState.success(result);
    } on DirectionException catch (e) {
      _state = RouteState.error(e.message);
    } catch (e) {
      _state = RouteState.error('Network error. Please check your connection.');
    }

    notifyListeners();
  }

  void clear() {
    _start = null;
    _goal  = null;
    _state = const RouteState.idle();
    notifyListeners();
  }

}

// ─────────────────────────── Map overlay helpers ──────────────────────

/// Draws a [NPathOverlay] for the route and fits the camera to its bounds.
///
/// Call from [MapScreen] inside a [RouteController] listener.
Future<void> drawRouteOnMap(
  NaverMapController ctrl,
  RouteResult result,
) async {
  // 1. Remove previous overlays if any.
  await clearRouteFromMap(ctrl);

  // 2. Draw the path.
  final pathOverlay = NPathOverlay(
    id: _kRouteOverlayId,
    coords: result.path,
    color: _kRouteColor,
    width: _kRouteWidth,
    outlineColor: Colors.white,
    outlineWidth: _kRouteOutlineWidth,
    patternImage: null,
  );
  await ctrl.addOverlay(pathOverlay);

  // 3. Fit camera so the entire route is visible.
  if (result.path.length >= 2) {
    double minLat = result.path.first.latitude;
    double maxLat = result.path.first.latitude;
    double minLng = result.path.first.longitude;
    double maxLng = result.path.first.longitude;

    for (final p in result.path) {
      if (p.latitude  < minLat) minLat = p.latitude;
      if (p.latitude  > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = NLatLngBounds(
      southWest: NLatLng(minLat, minLng),
      northEast: NLatLng(maxLat, maxLng),
    );

    final cameraUpdate = NCameraUpdate.fitBounds(
      bounds,
      padding: const EdgeInsets.all(60),
    );
    cameraUpdate.setAnimation(
      animation: NCameraAnimation.fly,
      duration: const Duration(milliseconds: 900),
    );
    await ctrl.updateCamera(cameraUpdate);
  }
}

/// Removes the route path overlay and endpoint markers from the map.
/// Safe to call even when the overlays don't exist yet.
Future<void> clearRouteFromMap(NaverMapController ctrl) async {
  Future<void> tryDelete(NOverlayInfo info) async {
    try {
      await ctrl.deleteOverlay(info);
    } catch (_) {
      // Overlay didn't exist — safe to ignore.
    }
  }

  await Future.wait([
    tryDelete(const NOverlayInfo(type: NOverlayType.pathOverlay, id: _kRouteOverlayId)),
    tryDelete(const NOverlayInfo(type: NOverlayType.marker, id: _kStartMarkerId)),
    tryDelete(const NOverlayInfo(type: NOverlayType.marker, id: _kGoalMarkerId)),
  ]);
}

// ─────────────────────────── Info panel widget ───────────────────────

const _kDriveColor = Color(0xFF007AFF);
const _kWalkColor  = Color(0xFF32D74B);
const _kPanelBg    = Color(0xFF1C1C1E);

/// Glassmorphism floating card shown at the bottom of the map while a route
/// is active. Displays driving and walking modes side-by-side (Bento layout).
class RouteInfoPanel extends StatelessWidget {
  const RouteInfoPanel({
    super.key,
    required this.state,
    required this.onClose,
  });

  final RouteState state;
  final VoidCallback onClose;

  /// Walking speed ≈ 1.25 m/s = 75 m/min.
  static int _walkMinutes(int meters) => (meters / 75).ceil();

  static String _walkLabel(int meters) {
    final mins = _walkMinutes(meters);
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '$h hr' : '$h hr $m min';
  }

  @override
  Widget build(BuildContext context) {
    if (state.isIdle) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: _kPanelBg.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 28,
                  spreadRadius: 0,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    // ── Loading ──
    if (state.isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _kDriveColor,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'Finding route…',
              style: GoogleFonts.notoSans(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      );
    }

    // ── Error ──
    if (state.isError) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                state.errorMessage ?? 'Route unavailable',
                style: GoogleFonts.notoSans(
                  fontSize: 13,
                  color: Colors.redAccent,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _CloseButton(onTap: onClose),
          ],
        ),
      );
    }

    // ── Success ──
    final result = state.result!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // ── Drive + Divider + Walk (expanded to fill available space) ──
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _ModeChip(
                    icon: Icons.directions_car_rounded,
                    label: 'Drive',
                    color: _kDriveColor,
                    distance: result.distanceLabel,
                    duration: result.durationLabel,
                  ),
                ),

                // Divider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Container(
                    width: 0.7,
                    height: 36,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),

                Expanded(
                  child: _ModeChip(
                    icon: Icons.directions_walk_rounded,
                    label: 'Walk',
                    color: _kWalkColor,
                    distance: result.distanceLabel,
                    duration: _walkLabel(result.distanceMeters),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // ── Start button ──
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF007AFF), Color(0xFF0055CC)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF007AFF).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.navigation_rounded, size: 14),
              label: Text(
                'Go',
                style: GoogleFonts.notoSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                elevation: 0,
                minimumSize: const Size(64, 38),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),
          _CloseButton(onTap: onClose),
        ],
      ),
    );
  }
}

// ─────────────────────────── Mode chip (compact) ─────────────────────────────

/// Compact horizontal chip: [icon] label  distance · duration
class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.distance,
    required this.duration,
  });

  final IconData icon;
  final String label;
  final Color color;
  final String distance;
  final String duration;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon + mode label
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.notoSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        // Distance bold
        Text(
          distance,
          style: GoogleFonts.notoSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1,
          ),
        ),
        const SizedBox(height: 2),
        // Duration subtle
        Text(
          duration,
          style: GoogleFonts.notoSans(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.55),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── Close button ────────────────────────────

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
        child: Icon(
          Icons.close_rounded,
          size: 14,
          color: Colors.white.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
