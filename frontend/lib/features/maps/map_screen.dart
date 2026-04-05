import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/naver_map/naver_map_sdk_controller.dart';
import '../../l10n/app_localizations.dart';
import '../shell/theme/shell_theme.dart';
import 'models/user_pin_model.dart';
import 'widgets/pin_bottom_sheet.dart';

// ──────────────────────────── Constants ────────────────────────────

const _kSeoulStation = NLatLng(37.5547, 126.9706);
const double _kUserZoom    = 15.0;
const Duration _kFlyDuration     = Duration(milliseconds: 800);
const Duration _kOverlayFadeDuration = Duration(milliseconds: 500);

// ──────────────────────────── Marker colours ────────────────────────────

const _kUserPinColor   = Color(0xFFFFB300); // gold  — community pins
const _kUserPinBorder  = Color(0xFF8A6000); // dark gold border

// ──────────────────────────── MapScreen ────────────────────────────

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with AutomaticKeepAliveClientMixin {
  // ── Map controller ───────────────────────────────────────────────
  NaverMapController? _mapCtrl;

  // ── Location state ───────────────────────────────────────────────
  NLatLng? _userPosition;
  bool _isLocating    = false;
  bool _isCentredOnUser = false;

  // ── UI state ────────────────────────────────────────────────────
  bool _isMapReady     = false;
  bool _overlayVisible = true;

  // ── Community pins ───────────────────────────────────────────────
  /// In-memory list of pins saved this session.
  final List<UserPinModel> _pins = [];

  // ── Search ───────────────────────────────────────────────────────
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  bool _searchActive = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ────────────────────────────────────────────────────────────────
  // Search Logic
  // ────────────────────────────────────────────────────────────────

  /// Called on every keystroke. Flies the camera to the first matching pin.
  /// Replace the body with a real API call when the backend is ready.
  void _onSearch(String query) {
    debugPrint('[Map] search: "$query"');
    if (query.trim().isEmpty || _mapCtrl == null) return;

    final q = query.trim().toLowerCase();
    final match = _pins.firstWhereOrNull(
      (p) => p.name.toLowerCase().contains(q),
    );
    if (match == null) return;

    final update = NCameraUpdate.scrollAndZoomTo(
      target: match.latLng,
      zoom: 16.0,
    );
    update.setAnimation(
      animation: NCameraAnimation.fly,
      duration: const Duration(milliseconds: 700),
    );
    _mapCtrl!.updateCamera(update);
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() => _searchActive = false);
    _searchFocus.unfocus();
  }

  // ────────────────────────────────────────────────────────────────
  // Location Logic
  // ────────────────────────────────────────────────────────────────

  Future<void> _goToCurrentLocation({bool userTriggered = false}) async {
    if (_isLocating) return;

    // Fast path — already have position, just fly back.
    if (userTriggered && _userPosition != null) {
      if (_isCentredOnUser) {
        HapticFeedback.lightImpact();
        return;
      }
      await _flyToPosition(_userPosition!);
      return;
    }

    if (mounted) setState(() => _isLocating = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        _showSnack(AppLocalizations.of(context)!.mapLocationServicesDisabled);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        _showSnack(AppLocalizations.of(context)!.mapLocationPermissionRequired);
        return;
      }

      Position? pos = await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final target = NLatLng(pos.latitude, pos.longitude);
      if (mounted) setState(() => _userPosition = target);

      final ctrl = _mapCtrl;
      if (ctrl == null) return;

      ctrl.getLocationOverlay().setIsVisible(true);
      await _flyToPosition(target);
    } catch (e) {
      debugPrint('[Map] Location error: $e');
    } finally {
      if (mounted) setState(() => _isLocating = false);
      _maybeDismissOverlay();
    }
  }

  Future<void> _flyToPosition(NLatLng target) async {
    final ctrl = _mapCtrl;
    if (ctrl == null) return;

    final update = NCameraUpdate.withParams(target: target, zoom: _kUserZoom);
    update.setAnimation(animation: NCameraAnimation.fly, duration: _kFlyDuration);
    await ctrl.updateCamera(update);

    if (mounted) setState(() => _isCentredOnUser = true);
  }

  void _maybeDismissOverlay() {
    if (_isMapReady && !_isLocating && _overlayVisible) {
      if (mounted) setState(() => _overlayVisible = false);
    }
  }

  // ────────────────────────────────────────────────────────────────
  // Community Pinning Logic
  // ────────────────────────────────────────────────────────────────

  /// Called when user long-presses the map.
  Future<void> _onMapLongTap(NPoint point, NLatLng latLng) async {
    HapticFeedback.heavyImpact();

    // Step 1 — confirm intent with CupertinoActionSheet.
    final confirmed = await _showPinConfirmSheet();
    if (!confirmed || !mounted) return;

    // Step 2 — open the form bottom sheet.
    final pin = await showPinBottomSheet(context, latLng);
    if (pin == null || !mounted) return;

    // Step 3 — add marker immediately (optimistic), then show success toast.
    setState(() => _pins.add(pin));
    await _addMarkerForPin(pin);
    _showSuccessToast(pin);
  }

  /// Shows a [CupertinoActionSheet] asking if user wants to pin this location.
  /// Returns true if they tapped the confirm action.
  Future<bool> _showPinConfirmSheet() async {
    final result = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (ctx) {
        final l = AppLocalizations.of(ctx)!;
        return CupertinoActionSheet(
          title: Text(
            l.mapPinShareTitle,
            style: GoogleFonts.notoSansKr(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          message: Text(
            l.mapPinShareMessage,
            style: GoogleFonts.notoSansKr(fontSize: 13),
          ),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                '📍  ${l.mapPinShareAction}',
                style: GoogleFonts.notoSansKr(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF003478),
                ),
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l.btnCancel,
              style: GoogleFonts.notoSansKr(fontSize: 16),
            ),
          ),
        );
      },
    );
    return result ?? false;
  }

  /// Adds a gold [NMarker] on the map for the given [pin].
  Future<void> _addMarkerForPin(UserPinModel pin) async {
    final ctrl = _mapCtrl;
    if (ctrl == null) return;

    final marker = NMarker(
      id: pin.id,
      position: pin.latLng,
    );

    // Gold overlay icon — draws a filled circle using NOverlayImage.
    marker.setIcon(
      await NOverlayImage.fromWidget(
        widget: _GoldPinIcon(emoji: pin.type.emoji),
        size: const Size(48, 56),
        context: context,
      ),
    );

    marker.setCaption(NOverlayCaption(
      text: pin.name,
      textSize: 12,
      color: _kUserPinBorder,
      haloColor: Colors.white,
    ));

    marker.setOnTapListener((_) {
      _showPinInfoSheet(pin);
    });

    await ctrl.addOverlay(marker);
  }

  /// Rebuilds all saved-pin markers (e.g. after hot-reload / tab re-entry).
  Future<void> _restoreMarkers() async {
    for (final pin in _pins) {
      await _addMarkerForPin(pin);
    }
  }

  // ────────────────────────────────────────────────────────────────
  // UI Helpers
  // ────────────────────────────────────────────────────────────────

  void _showSuccessToast(UserPinModel pin) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 3),
        content: _SuccessToast(pin: pin),
      ),
    );
  }

  void _showPinInfoSheet(UserPinModel pin) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PinInfoSheet(pin: pin),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: GoogleFonts.notoSansKr(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Build
  // ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final sdk = context.watch<NaverMapSdkController>();
    if (!sdk.isInitialized) {
      return _SdkErrorBody(error: sdk.initError);
    }

    final fabBottom = MediaQuery.of(context).padding.bottom + 30.0;

    return Scaffold(
      backgroundColor: ShellColors.background,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _isMapReady
          ? Padding(
              padding: EdgeInsets.only(bottom: fabBottom - 16),
              child: _LocationFab(
                isLocating: _isLocating,
                isCentred: _isCentredOnUser,
                onTap: () => _goToCurrentLocation(userTriggered: true),
              ),
            )
          : null,
      body: Stack(
        fit: StackFit.expand,
        children: [
          NaverMap(
            options: NaverMapViewOptions(
              initialCameraPosition: NCameraPosition(
                target: _userPosition ?? _kSeoulStation,
                zoom: _kUserZoom,
              ),
              locationButtonEnable: false,
              indoorEnable: true,
              consumeSymbolTapEvents: false,
            ),
            onMapReady: (controller) async {
              _mapCtrl = controller;
              if (!mounted) return;
              setState(() => _isMapReady = true);
              await _goToCurrentLocation();
              // Restore any pins that were saved before this onMapReady
              // (e.g. after tab switch rebuilds the platform view).
              await _restoreMarkers();
            },
            onCameraChange: (updateReason, animated) {
              if (updateReason == NCameraUpdateReason.gesture) {
                if (_isCentredOnUser && mounted) {
                  setState(() => _isCentredOnUser = false);
                }
              }
            },
            onMapTapped: (point, latLng) {
              FocusScope.of(context).unfocus();
            },
            onMapLongTapped: _onMapLongTap,
          ),

          // Loading overlay — fades out after map + GPS ready.
          IgnorePointer(
            ignoring: !_overlayVisible,
            child: AnimatedOpacity(
              opacity: _overlayVisible ? 1.0 : 0.0,
              duration: _kOverlayFadeDuration,
              curve: Curves.easeOut,
              child: const _LoadingOverlay(),
            ),
          ),

          // Floating search bar — always on top, below status bar.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _MapSearchBar(
                  controller: _searchCtrl,
                  focusNode: _searchFocus,
                  isActive: _searchActive,
                  onChanged: (q) {
                    setState(() => _searchActive = q.isNotEmpty);
                    _onSearch(q);
                  },
                  onClear: _clearSearch,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────── _MapSearchBar ────────────────────────────

class _MapSearchBar extends StatelessWidget {
  const _MapSearchBar({
    required this.controller,
    required this.focusNode,
    required this.isActive,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isActive;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 16,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: onChanged,
              style: GoogleFonts.notoSansKr(
                fontSize: 14,
                color: const Color(0xFF1A1A1A),
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: l.mapSearchHere,
                hintStyle: GoogleFonts.notoSansKr(
                  fontSize: 14,
                  color: const Color(0xFFADB5BD),
                ),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: isActive
                ? GestureDetector(
                    key: const ValueKey('clear'),
                    onTap: onClear,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Icon(Icons.close_rounded,
                          color: Color(0xFF94A3B8), size: 20),
                    ),
                  )
                : const Padding(
                    key: ValueKey('mic'),
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Icon(Icons.tune_rounded,
                        color: Color(0xFF003478), size: 20),
                  ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────── _GoldPinIcon ────────────────────────────
/// Rendered into an NOverlayImage via NOverlayImage.fromWidget.

class _GoldPinIcon extends StatelessWidget {
  const _GoldPinIcon({required this.emoji});
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _kUserPinColor,
            shape: BoxShape.circle,
            border: Border.all(color: _kUserPinBorder, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x44000000),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(emoji,
                style: const TextStyle(fontSize: 20, height: 1)),
          ),
        ),
        // Teardrop tail
        CustomPaint(
          size: const Size(12, 8),
          painter: _TrianglePainter(color: _kUserPinBorder),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  const _TrianglePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => old.color != color;
}

// ──────────────────────────── _SuccessToast ────────────────────────────

class _SuccessToast extends StatelessWidget {
  const _SuccessToast({required this.pin});
  final UserPinModel pin;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _kUserPinColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: _kUserPinColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l.mapPinSuccessTitle,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${pin.type.emoji}  ${pin.name}',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────── _PinInfoSheet ────────────────────────────

class _PinInfoSheet extends StatelessWidget {
  const _PinInfoSheet({required this.pin});
  final UserPinModel pin;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE3EA),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(pin.type.emoji,
                    style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pin.name,
                        style: GoogleFonts.notoSansKr(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        pin.type.localizedLabel(l),
                        style: GoogleFonts.notoSansKr(
                            fontSize: 12,
                            color: const Color(0xFF6A6A6A)),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(5, (i) => Icon(
                    i < pin.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: _kUserPinColor,
                    size: 18,
                  )),
                ),
              ],
            ),
            if (pin.notes.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  pin.notes,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 14,
                    color: const Color(0xFF1A1A1A),
                    height: 1.6,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  pin.isPublic
                      ? Icons.public_rounded
                      : Icons.lock_outline_rounded,
                  size: 14,
                  color: const Color(0xFFADB5BD),
                ),
                const SizedBox(width: 4),
                Text(
                  pin.isPublic ? l.mapPinInfoPublicShort : l.mapPinVisibilityPrivate,
                  style: GoogleFonts.notoSansKr(
                      fontSize: 11, color: const Color(0xFFADB5BD)),
                ),
                const Spacer(),
                Text(
                  '${pin.latLng.latitude.toStringAsFixed(5)}, '
                  '${pin.latLng.longitude.toStringAsFixed(5)}',
                  style: GoogleFonts.notoSansKr(
                      fontSize: 11, color: const Color(0xFFADB5BD)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────── _LocationFab ────────────────────────────

class _LocationFab extends StatelessWidget {
  const _LocationFab({
    required this.isLocating,
    required this.isCentred,
    required this.onTap,
  });
  final bool isLocating;
  final bool isCentred;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: isLocating
            ? const Padding(
                padding: EdgeInsets.all(13),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      ShellColors.primaryBlue),
                ),
              )
            : Icon(
                isCentred
                    ? Icons.my_location_rounded
                    : Icons.location_searching_rounded,
                color: ShellColors.primaryBlue,
                size: 24,
              ),
      ),
    );
  }
}

// ──────────────────────────── _LoadingOverlay ────────────────────────────

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.88, end: 1.0),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          builder: (_, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 52,
                height: 52,
                child: CircularProgressIndicator(
                  strokeWidth: 3.2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      ShellColors.primaryBlue),
                  backgroundColor: Color(0x1F003478),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l.statusLoadingMap,
                style: GoogleFonts.notoSansKr(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ShellColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l.statusFetchingLocation,
                style: GoogleFonts.notoSansKr(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────── _SdkErrorBody ────────────────────────────

class _SdkErrorBody extends StatelessWidget {
  const _SdkErrorBody({required this.error});
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: ShellColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined,
                  size: 56,
                  color: ShellColors.primaryBlue.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              Text(
                l.mapUnavailable,
                style: GoogleFonts.notoSansKr(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error == null
                    ? l.mapSdkInitializing
                    : l.mapSdkError(error.toString()),
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansKr(
                  fontSize: 13,
                  color: const Color(0xFF6A6A6A),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
