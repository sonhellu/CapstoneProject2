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
Future<void> clearRouteFromMap(NaverMapController ctrl) async {
  await Future.wait([
    ctrl.deleteOverlay(
      const NOverlayInfo(type: NOverlayType.pathOverlay, id: _kRouteOverlayId),
    ),
    ctrl.deleteOverlay(
      const NOverlayInfo(type: NOverlayType.marker, id: _kStartMarkerId),
    ),
    ctrl.deleteOverlay(
      const NOverlayInfo(type: NOverlayType.marker, id: _kGoalMarkerId),
    ),
  ]);
}

// ─────────────────────────── Info panel widget ───────────────────────

/// Floating card shown at the bottom of the map while a route is active.
///
/// Shows distance + duration on success, a spinner while loading,
/// and an error message on failure.  Has a close button to dismiss.
class RouteInfoPanel extends StatelessWidget {
  const RouteInfoPanel({
    super.key,
    required this.state,
    required this.onClose,
  });

  final RouteState state;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    if (state.isIdle) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        elevation: 6,
        shadowColor: Colors.black26,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // ── Icon ──
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: state.isLoading
                    ? SizedBox(
                        key: const ValueKey('spinner'),
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: cs.primary,
                        ),
                      )
                    : Icon(
                        state.isError
                            ? Icons.error_outline_rounded
                            : Icons.directions_car_rounded,
                        key: ValueKey(state.status),
                        color: state.isError ? Colors.red : cs.primary,
                        size: 22,
                      ),
              ),
              const SizedBox(width: 12),

              // ── Text ──
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: state.isLoading
                      ? Text(
                          'Finding route…',
                          key: const ValueKey('loading'),
                          style: GoogleFonts.notoSansKr(
                            fontSize: 13,
                            color: cs.onSurfaceVariant,
                          ),
                        )
                      : state.isError
                          ? Text(
                              state.errorMessage ?? 'Route unavailable',
                              key: const ValueKey('error'),
                              style: GoogleFonts.notoSansKr(
                                fontSize: 13,
                                color: Colors.red,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            )
                          : _RouteStats(
                              key: const ValueKey('stats'),
                              result: state.result!,
                            ),
                ),
              ),

              // ── Close ──
              if (!state.isLoading)
                IconButton(
                  onPressed: onClose,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteStats extends StatelessWidget {
  const _RouteStats({super.key, required this.result});
  final RouteResult result;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        // Distance
        _StatChip(
          icon: Icons.straighten_rounded,
          label: result.distanceLabel,
          color: cs.primary,
        ),
        const SizedBox(width: 10),
        // Duration
        _StatChip(
          icon: Icons.schedule_rounded,
          label: result.durationLabel,
          color: const Color(0xFF00695C),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.notoSansKr(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
