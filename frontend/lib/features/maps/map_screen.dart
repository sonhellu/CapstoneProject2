import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/locale/app_locale_resolver.dart';
import '../../core/naver_map/naver_map_sdk_controller.dart';
import '../../core/services/geocoding_service.dart';
import '../../core/services/place_search_service.dart';
import '../../core/services/translation_service.dart';
import '../../l10n/app_localizations.dart';
import '../shell/theme/shell_theme.dart';
import 'map_focus_controller.dart';
import 'models/user_pin_model.dart';
import 'widgets/pin_bottom_sheet.dart';
import 'widgets/review_modal.dart';
import 'widgets/route_layer.dart';

// ──────────────────────────── Constants ────────────────────────────

const _kKeimyungUniv = NLatLng(35.8562, 128.4896); // Keimyung University
const _kSeoulStation = NLatLng(37.5547, 126.9706); // fallback
const double _kUserZoom = 15.0;
const Duration _kFlyDuration = Duration(milliseconds: 800);
const Duration _kOverlayFadeDuration = Duration(milliseconds: 500);

// ──────────────────────────── Filter key constants ────────────────────────────

const _kFilterAll = 'all';
const _kFilterRestaurant = 'restaurant';
const _kFilterRealEstate = 'realEstate';
const _kFilterUtility = 'utility';
const _kFilterPharmacy = 'pharmacy';

// ──────────────────────────── Marker colours ────────────────────────────

const _kUserPinColor = Color(0xFFFFB300); // gold  — community pins
const _kUserPinBorder = Color(0xFF8A6000); // dark gold border

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
  bool _isLocating = false;
  bool _isCentredOnUser = false;

  /// true  → use Keimyung University coords as mock position.
  /// false → use real GPS via geolocator (set when GPS is ready).
  static const bool _isMockLocation = true;

  // ── UI state ────────────────────────────────────────────────────
  bool _isMapReady = false;
  bool _overlayVisible = true;

  // ── Community pins ───────────────────────────────────────────────
  /// In-memory list of pins saved this session.
  final List<UserPinModel> _pins = [];

  /// Live NMarker references keyed by pin.id — used for visibility toggling.
  final Map<String, NMarker> _markers = {};

  // ── Search ───────────────────────────────────────────────────────
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  bool _searchActive = false;
  List<UserPinModel> _searchResults = [];

  // ── Naver Place Search ───────────────────────────────────────────
  Timer? _debounce;
  List<NaverPlace> _placeResults = [];
  bool _isSearchingPlaces = false;
  NMarker? _searchMarker;

  // ── Loading timeout ──────────────────────────────────────────────
  Timer? _loadingTimeout;

  // ── Filter ───────────────────────────────────────────────────────
  String _selectedFilter = _kFilterAll;

  // ── Saved pins ───────────────────────────────────────────────────
  final Set<String> _savedPinIds = {};

  // ── In-app routing ───────────────────────────────────────────────
  final _routeCtrl = RouteController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // If onMapReady hasn't fired after 12 s, dismiss the overlay anyway
    // so the user isn't stuck on a blank screen.
    _loadingTimeout = Timer(const Duration(seconds: 12), () {
      if (mounted && _overlayVisible) {
        setState(() => _overlayVisible = false);
      }
    });
    MapFocusController.instance.addListener(_onMapFocusRequest);
    _routeCtrl.addListener(_onRouteStateChanged);
  }

  @override
  void dispose() {
    MapFocusController.instance.removeListener(_onMapFocusRequest);
    _routeCtrl.removeListener(_onRouteStateChanged);
    _routeCtrl.dispose();
    _debounce?.cancel();
    _loadingTimeout?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onMapFocusRequest() {
    final loc = MapFocusController.instance.consume();
    if (loc == null) return;
    _flyToPosition(NLatLng(loc.lat, loc.lng));
  }

  // ────────────────────────────────────────────────────────────────
  // Search Logic
  // ────────────────────────────────────────────────────────────────

  /// Single source of truth for dropdown results.
  /// Combines active text query AND selected chip filter.
  void _refreshSearchResults() {
    final query = _searchCtrl.text.trim().toLowerCase();
    final hasQuery = query.isNotEmpty;
    final hasFilter = _selectedFilter != _kFilterAll;

    if (!hasQuery && !hasFilter) {
      setState(() => _searchResults = []);
      return;
    }

    final matches = _pins.where((p) {
      final matchesQuery = !hasQuery || p.name.toLowerCase().contains(query);
      final matchesFilter = !hasFilter || _pinMatchesFilter(p, _selectedFilter);
      return matchesQuery && matchesFilter;
    }).toList();

    setState(() => _searchResults = matches);
  }

  /// Called on every keystroke — debounces Naver API, filters local pins immediately.
  void _onSearch(String query) {
    debugPrint('[Map] search: "$query"');
    setState(() => _searchActive = query.isNotEmpty);
    _refreshSearchResults();

    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _placeResults = [];
        _isSearchingPlaces = false;
      });
      return;
    }

    setState(() => _isSearchingPlaces = true);
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      // Pass user position (fallback: campus centre) so results are
      // filtered to within 5 km — avoids Seoul/Busan noise.
      final centre = _userPosition ?? _kKeimyungUniv;
      final results = await PlaceSearchService.search(
        query.trim(),
        centerLat: centre.latitude,
        centerLng: centre.longitude,
      );
      if (mounted) {
        setState(() {
          _placeResults = results;
          _isSearchingPlaces = false;
        });
      }
    });
  }

  void _onSelectResult(UserPinModel pin) {
    _searchCtrl.clear();
    _searchFocus.unfocus();
    setState(() {
      _searchActive = false;
      _searchResults = [];
      _placeResults = [];
    });
    if (_mapCtrl == null) return;
    final update = NCameraUpdate.scrollAndZoomTo(
      target: pin.latLng,
      zoom: 16.0,
    );
    update.setAnimation(
      animation: NCameraAnimation.fly,
      duration: const Duration(milliseconds: 700),
    );
    _mapCtrl!.updateCamera(update);
  }

  /// Flies the camera to a Naver place result and drops a temporary marker.
  Future<void> _onSelectPlace(NaverPlace place) async {
    _debounce?.cancel();
    _searchCtrl.clear();
    _searchFocus.unfocus();
    setState(() {
      _searchActive = false;
      _placeResults = [];
      _searchResults = [];
      _isSearchingPlaces = false;
    });

    final target = NLatLng(place.lat, place.lng);
    final ctrl = _mapCtrl;
    if (ctrl == null) return;

    // Remove previous search-result marker if any.
    if (_searchMarker != null) {
      await ctrl.deleteOverlay(
        const NOverlayInfo(type: NOverlayType.marker, id: '_place_search'),
      );
      _searchMarker = null;
    }

    // Fly camera to the selected place.
    final update = NCameraUpdate.scrollAndZoomTo(target: target, zoom: 16.0);
    update.setAnimation(
      animation: NCameraAnimation.fly,
      duration: const Duration(milliseconds: 700),
    );
    await ctrl.updateCamera(update);

    // Drop a temporary blue marker.
    final marker = NMarker(id: '_place_search', position: target);
    marker.setCaption(
      NOverlayCaption(
        text: place.name,
        textSize: 13,
        color: const Color(0xFF003478),
        haloColor: Colors.white,
      ),
    );
    await ctrl.addOverlay(marker);
    _searchMarker = marker;
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchCtrl.clear();
    _searchFocus.unfocus();
    setState(() {
      _searchActive = false;
      _searchResults = [];
      _placeResults = [];
      _isSearchingPlaces = false;
    });
  }

  // ────────────────────────────────────────────────────────────────
  // Symbol Tap (Naver Map built-in POIs)
  // ────────────────────────────────────────────────────────────────

  void _onSymbolTapped(NSymbolInfo symbol) {
    final targetLang = AppLocaleResolver.targetLang(context);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SymbolInfoSheet(
        symbol: symbol,
        targetLang: targetLang,
        userPosition: _userPosition,
        onAddPin: () {
          Navigator.of(context).pop();
          _onMapLongTap(
            NPoint(symbol.position.longitude, symbol.position.latitude),
            symbol.position,
          );
        },
        onDirections: () {
          Navigator.of(context).pop();
          _startDirections(symbol.position);
        },
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Filter Logic
  // ────────────────────────────────────────────────────────────────

  void _onFilterTap(String filterKey) {
    final next = _selectedFilter == filterKey ? _kFilterAll : filterKey;
    setState(() => _selectedFilter = next);
    _updateVisibleMarkers(next);
    _refreshSearchResults();
  }

  /// Shows/hides existing NMarker overlays based on [filter].
  /// Uses the locally cached [_markers] map to avoid a round-trip to the
  /// platform channel (NaverMapController has no getOverlay() API).
  Future<void> _updateVisibleMarkers(String filter) async {
    for (final pin in _pins) {
      final visible = filter == _kFilterAll || _pinMatchesFilter(pin, filter);
      _markers[pin.id]?.setIsVisible(visible);
    }
  }

  bool _pinMatchesFilter(UserPinModel pin, String filter) {
    return switch (filter) {
      _kFilterRestaurant => pin.type == PinType.restaurant,
      _kFilterRealEstate => pin.type == PinType.realEstate,
      _kFilterUtility => pin.type == PinType.utility,
      _kFilterPharmacy => pin.type == PinType.pharmacy,
      _ => true,
    };
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
      // ── Mock path: use Keimyung University as fixed position ──
      if (_isMockLocation) {
        const target = _kKeimyungUniv;
        if (mounted) setState(() => _userPosition = target);
        _applyLocationOverlay(target);
        await _flyToPosition(target);
        return;
      }

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

      _applyLocationOverlay(target);
      await _flyToPosition(target);
    } catch (e) {
      debugPrint('[Map] Location error: $e');
    } finally {
      if (mounted) setState(() => _isLocating = false);
      _maybeDismissOverlay();
    }
  }

  void _applyLocationOverlay(NLatLng position) {
    final ctrl = _mapCtrl;
    if (ctrl == null) return;
    final overlay = ctrl.getLocationOverlay();
    overlay.setIsVisible(true);
    overlay.setPosition(position);
    overlay.setBearing(0);
  }

  Future<void> _flyToPosition(NLatLng target) async {
    final ctrl = _mapCtrl;
    if (ctrl == null) return;

    final update = NCameraUpdate.withParams(target: target, zoom: _kUserZoom);
    update.setAnimation(
      animation: NCameraAnimation.fly,
      duration: _kFlyDuration,
    );
    await ctrl.updateCamera(update);

    if (mounted) setState(() => _isCentredOnUser = true);
  }

  void _maybeDismissOverlay() {
    if (_isMapReady && !_isLocating && _overlayVisible) {
      if (mounted) setState(() => _overlayVisible = false);
    }
  }

  // ────────────────────────────────────────────────────────────────
  // In-app Routing
  // ────────────────────────────────────────────────────────────────

  void _onRouteStateChanged() {
    final ctrl = _mapCtrl;
    if (ctrl == null) return;
    final s = _routeCtrl.state;
    if (s.isSuccess) {
      drawRouteOnMap(ctrl, s.result!).catchError((e) {
        debugPrint('[Route] drawRouteOnMap error: $e');
      });
    }
    if (s.isIdle) {
      clearRouteFromMap(ctrl).catchError((e) {
        debugPrint('[Route] clearRouteFromMap error: $e');
      });
    }
    if (mounted) setState(() {});
  }

  Future<void> _startDirections(NLatLng goal) async {
    // Capture l before any await
    final noLocationMsg = AppLocalizations.of(
      context,
    )!.mapLocationPermissionRequired;
    final start = _userPosition;
    if (start == null) {
      _showSnack(noLocationMsg);
      return;
    }
    await _routeCtrl.fetchRoute(start: start, goal: goal);
  }

  void _clearRoute() {
    final ctrl = _mapCtrl;
    if (ctrl != null) clearRouteFromMap(ctrl);
    _routeCtrl.clear();
  }

  // ────────────────────────────────────────────────────────────────
  // Reverse Geocoding on map tap
  // ────────────────────────────────────────────────────────────────

  void _showMapTapSheet(NLatLng latLng) {
    final targetLang = AppLocaleResolver.targetLang(context);
    final addressFuture = GeocodingService.instance.getLocalizedAddress(
      latLng.latitude,
      latLng.longitude,
      targetLang,
    );
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MapTapSheet(
        latLng: latLng,
        addressFuture: addressFuture,
        userPosition: _userPosition,
        onPinHere: () {
          Navigator.of(context).pop();
          _onMapLongTap(NPoint(latLng.longitude, latLng.latitude), latLng);
        },
        onDirections: () {
          Navigator.of(context).pop();
          _startDirections(latLng);
        },
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Community Pinning Logic
  // ────────────────────────────────────────────────────────────────

  /// Called when user long-presses the map.
  Future<void> _onMapLongTap(NPoint point, NLatLng latLng) async {
    HapticFeedback.heavyImpact();

    // Kick off geocoding immediately — sheet opens at the same time,
    // shows a spinner until the address resolves.
    final targetLang = AppLocaleResolver.targetLang(context);
    final addressFuture = GeocodingService.instance.getLocalizedAddress(
      latLng.latitude,
      latLng.longitude,
      targetLang,
    );

    if (!mounted) return;

    // Open form directly — no extra confirm sheet.
    final pin = await showPinBottomSheet(
      context,
      latLng,
      addressFuture: addressFuture,
    );
    if (pin == null || !mounted) return;

    // Add marker immediately (optimistic), then show success toast.
    setState(() => _pins.add(pin));
    await _addMarkerForPin(pin);
    _showSuccessToast(pin);
  }

  /// Adds a gold [NMarker] on the map for the given [pin].
  Future<void> _addMarkerForPin(UserPinModel pin) async {
    final ctrl = _mapCtrl;
    if (ctrl == null) return;

    final marker = NMarker(id: pin.id, position: pin.latLng);

    // Gold overlay icon — draws a filled circle using NOverlayImage.
    marker.setIcon(
      await NOverlayImage.fromWidget(
        widget: _GoldPinIcon(emoji: pin.type.emoji),
        size: const Size(48, 56),
        context: context,
      ),
    );

    marker.setCaption(
      NOverlayCaption(
        text: pin.name,
        textSize: 12,
        color: _kUserPinBorder,
        haloColor: Colors.white,
      ),
    );

    marker.setOnTapListener((_) {
      _showPinInfoSheet(pin);
    });

    await ctrl.addOverlay(marker);

    // Keep a reference so we can toggle visibility when filter changes.
    _markers[pin.id] = marker;
  }

  /// Rebuilds all saved-pin markers (e.g. after hot-reload / tab re-entry).
  /// Clears stale [_markers] entries first to prevent duplicates on re-init.
  Future<void> _restoreMarkers() async {
    _markers.clear();
    await Future.wait(_pins.map(_addMarkerForPin));
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

  // ── Save ──────────────────────────────────────────────────────────
  void _toggleSave(UserPinModel pin) {
    setState(() {
      if (_savedPinIds.contains(pin.id)) {
        _savedPinIds.remove(pin.id);
      } else {
        _savedPinIds.add(pin.id);
      }
    });
    final isSaved = _savedPinIds.contains(pin.id);
    _showSnack(isSaved ? '📌 ${pin.name} saved' : 'Removed from saved');
  }

  // ── Share ─────────────────────────────────────────────────────────
  Future<void> _sharePin(UserPinModel pin) async {
    final lat = pin.latLng.latitude.toStringAsFixed(5);
    final lng = pin.latLng.longitude.toStringAsFixed(5);
    await Share.share(
      '${pin.type.emoji} ${pin.name}\n'
      'https://map.naver.com/v5/search/$lat,$lng',
    );
  }

  // ── Directions ────────────────────────────────────────────────────
  Future<void> _openDirections(UserPinModel pin) async {
    await _startDirections(pin.latLng);
  }

  // ── Report ────────────────────────────────────────────────────────
  Future<void> _reportPin(BuildContext sheetCtx, UserPinModel pin) async {
    final reasons = [
      'Wrong location',
      'Spam',
      'Closed / no longer exists',
      'Inappropriate content',
    ];
    await showCupertinoModalPopup<void>(
      context: sheetCtx,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Report this pin'),
        message: Text(pin.name),
        actions: reasons
            .map(
              (r) => CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _showSnack('Report submitted. Thank you!');
                },
                child: Text(r),
              ),
            )
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: false,
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showPinInfoSheet(UserPinModel pin) {
    final parentCtx = context;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isOwner = pin.authorId == currentUserId || pin.authorId.isEmpty;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _PinInfoSheet(
        pin: pin,
        isOwner: isOwner,
        onDeleteConfirmed: () {
          Navigator.of(sheetCtx).pop();
          _deletePin(pin);
        },
        onEditTap: () async {
          Navigator.of(sheetCtx).pop();
          if (!mounted) return;
          final updated = await showPinBottomSheet(
            parentCtx,
            pin.latLng,
            existingPin: pin,
          );
          if (updated != null) _updatePin(pin, updated);
        },
        isSaved: _savedPinIds.contains(pin.id),
        onSave: () {
          Navigator.of(sheetCtx).pop();
          _toggleSave(pin);
        },
        onShare: () {
          Navigator.of(sheetCtx).pop();
          _sharePin(pin);
        },
        onReport: () => _reportPin(sheetCtx, pin),
        onDirections: () {
          Navigator.of(sheetCtx).pop();
          _openDirections(pin);
        },
        userPosition: _userPosition,
      ),
    );
  }

  Future<void> _deletePin(UserPinModel pin) async {
    // Complete map work before updating Flutter state so UI and map stay in sync.
    await _mapCtrl?.deleteOverlay(
      NOverlayInfo(type: NOverlayType.marker, id: pin.id),
    );
    _markers.remove(pin.id);
    if (!mounted) return;
    setState(() => _pins.removeWhere((p) => p.id == pin.id));
    _showSnack(AppLocalizations.of(context)!.mapPinDeletedToast);
  }

  Future<void> _updatePin(UserPinModel old, UserPinModel updated) async {
    final idx = _pins.indexWhere((p) => p.id == old.id);
    if (idx == -1) return;
    await _mapCtrl?.deleteOverlay(
      NOverlayInfo(type: NOverlayType.marker, id: old.id),
    );
    _markers.remove(old.id);
    await _addMarkerForPin(updated);
    // If a filter is active, the new marker may need to be hidden immediately
    // (e.g. user changed pin type from restaurant → pharmacy while filter='restaurant').
    if (_selectedFilter != _kFilterAll) {
      _markers[updated.id]?.setIsVisible(
        _pinMatchesFilter(updated, _selectedFilter),
      );
    }
    if (!mounted) return;
    setState(() => _pins[idx] = updated);
    _showSnack(AppLocalizations.of(context)!.mapPinUpdatedToast);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.notoSansKr(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              consumeSymbolTapEvents: true,
            ),
            onMapReady: (controller) async {
              _mapCtrl = controller;
              if (!mounted) return;
              setState(() => _isMapReady = true);
              await _goToCurrentLocation();

              // ── TEST ONLY: remove before production ──
              _pins.add(
                UserPinModel(
                  id: '',
                  latLng: NLatLng(37.5560, 126.9723),
                  name: 'Phở Hà Nội Ngon',
                  notes: 'Quán ngon, giá rẻ, gần ga Seoul. Nên đến buổi trưa.',
                  type: PinType.restaurant,
                  isPublic: true,
                  rating: 4,
                  createdAt: DateTime(2025, 1, 1),
                  authorId: 'other_user',
                  authorName: 'kim_seoul',
                  isVerified: true,
                  reviewCount: 42,
                ),
              ); // 2. Cây ATM Global (Hỗ trợ thẻ Visa/Mastercard quốc tế)
              _pins.add(
                UserPinModel(
                  id: 'public_atm_01',
                  latLng: NLatLng(37.5570, 126.9260),
                  name: 'Global pharmacy Woori Bank',
                  notes:
                      'Cây này rút được bằng thẻ Việt Nam, phí rẻ, có tiếng Anh.',
                  type: PinType.pharmacy,
                  isPublic: true,
                  rating: 4,
                  createdAt: DateTime(2026, 3, 20),
                  authorId: 'admin_hicampus',
                  authorName: 'Admin_Hicampus',
                  isVerified: true,
                  reviewCount: 89,
                ),
              );
              // ─────────────────────────────────────────

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
            onSymbolTapped: _onSymbolTapped,
            onMapTapped: (point, latLng) {
              FocusScope.of(context).unfocus();
              if (!_searchFocus.hasFocus) {
                _showMapTapSheet(latLng);
              }
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

          // Filter chip bar — sits below the search bar.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                // 12 (top gap) + 52 (search bar height) + 8 (gap) = 72
                padding: const EdgeInsets.only(top: 72),
                child: _MapFilterBar(
                  selectedFilter: _selectedFilter,
                  onFilterTap: _onFilterTap,
                ),
              ),
            ),
          ),

          // Naver place results — shown while user is typing a query.
          if (_searchActive && (_placeResults.isNotEmpty || _isSearchingPlaces))
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  // 12 (top gap) + 52 (search bar) + 6 (gap)
                  padding: const EdgeInsets.fromLTRB(16, 70, 16, 0),
                  child: _PlaceResultsDropdown(
                    results: _placeResults,
                    isLoading: _isSearchingPlaces,
                    onSelect: _onSelectPlace,
                  ),
                ),
              ),
            ),

          // Community pin results — shown when a filter chip is active (no text query).
          if (!_searchActive && _searchResults.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 70, 16, 0),
                  child: _SearchResultsDropdown(
                    results: _searchResults,
                    onSelect: _onSelectResult,
                  ),
                ),
              ),
            ),

          // ── Route info panel (shown while route is active) ──
          // bottom aligns with the location FAB; right leaves room for the FAB (56 px + 16 px margin).
          if (!_routeCtrl.state.isIdle)
            Positioned(
              bottom: fabBottom - 16,
              left: 2,
              right: 62,
              child: RouteInfoPanel(
                state: _routeCtrl.state,
                onClose: _clearRoute,
              ),
            ),
        ],
      ),
    );
  }
}

// ──────────────────────────── Distance helper ────────────────────────────

/// Returns a localized distance string (e.g. "現在地から350m", "Cách bạn 1.2km").
/// Returns null when [userPos] is null.
String? _distanceLabel(NLatLng? userPos, NLatLng target, AppLocalizations l) {
  if (userPos == null) return null;
  final meters = Geolocator.distanceBetween(
    userPos.latitude,
    userPos.longitude,
    target.latitude,
    target.longitude,
  );
  if (meters < 1000) {
    return l.mapDistanceFromYouMeters(meters.round());
  }
  return l.mapDistanceFromYouKilometers((meters / 1000).toStringAsFixed(1));
}

// ──────────────────────────── _SymbolInfoSheet ────────────────────────────

class _SymbolInfoSheet extends StatefulWidget {
  const _SymbolInfoSheet({
    required this.symbol,
    required this.targetLang,
    required this.onAddPin,
    required this.onDirections,
    this.userPosition,
  });

  final NSymbolInfo symbol;
  final String targetLang;
  final VoidCallback onAddPin;
  final VoidCallback onDirections;
  final NLatLng? userPosition;

  @override
  State<_SymbolInfoSheet> createState() => _SymbolInfoSheetState();
}

class _SymbolInfoSheetState extends State<_SymbolInfoSheet> {
  Future<String>? _translationFuture;
  Future<LocalizedAddress>? _addressFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_translationFuture != null) return; // init only once

    final targetLang = widget.targetLang;

    if (targetLang == LangCode.ko || widget.symbol.caption.trim().isEmpty) {
      _translationFuture = Future.value(widget.symbol.caption);
    } else {
      _translationFuture = TranslationService.instance.translateText(
        widget.symbol.caption,
        from: LangCode.ko,
        to: targetLang,
      );
    }

    _addressFuture = GeocodingService.instance.getLocalizedAddress(
      widget.symbol.position.latitude,
      widget.symbol.position.longitude,
      targetLang,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lat = widget.symbol.position.latitude.toStringAsFixed(6);
    final lng = widget.symbol.position.longitude.toStringAsFixed(6);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: SafeArea(
        top: false,
        child: FutureBuilder<String>(
          future: _translationFuture,
          builder: (context, snapshot) {
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;
            final translated = snapshot.data;
            final hasTranslation =
                translated != null &&
                translated != widget.symbol.caption &&
                translated.isNotEmpty;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Drag handle ──────────────────────────────────────
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

                // ── Icon + name block ────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF003478),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.place_rounded,
                        color: Color(0xFF003478),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Loading spinner while translation resolves
                          if (isLoading)
                            const SizedBox(
                              height: 10,
                              width: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF003478),
                              ),
                            )
                          else
                            // Translated name (primary title)
                            Text(
                              hasTranslation
                                  ? translated
                                  : widget.symbol.caption,
                              style: GoogleFonts.notoSansKr(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A1A1A),
                              ),
                            ),

                          // Original Korean — shown below translated name
                          if (!isLoading && hasTranslation)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Original: ${widget.symbol.caption}',
                                style: GoogleFonts.notoSansKr(
                                  fontSize: 12,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Address (reverse-geocoded) ────────────────────────
                FutureBuilder<LocalizedAddress>(
                  future: _addressFuture,
                  builder: (context, addrSnap) {
                    if (addrSnap.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Color(0xFF94A3B8),
                        ),
                      );
                    }
                    final addr = addrSnap.data;
                    final addressText = addr?.localized.isNotEmpty == true
                        ? addr!.localized
                        : addr?.korean.isNotEmpty == true
                        ? addr!.korean
                        : '$lat, $lng';
                    return Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            addressText,
                            style: GoogleFonts.notoSansKr(
                              fontSize: 12,
                              color: const Color(0xFF94A3B8),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                // ── Distance from user ────────────────────────────────
                if (_distanceLabel(
                      widget.userPosition,
                      widget.symbol.position,
                      AppLocalizations.of(context)!,
                    )
                    case final dist?) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.near_me_rounded,
                        size: 13,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        dist,
                        style: GoogleFonts.notoSans(
                          fontSize: 12,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),

                // ── Action buttons ───────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.onDirections,
                        icon: const Icon(Icons.directions_rounded, size: 18),
                        label: Text(
                          AppLocalizations.of(context)!.mapDirections,
                          style: GoogleFonts.notoSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.onAddPin,
                        icon: const Icon(Icons.push_pin_rounded, size: 18),
                        label: Text(
                          AppLocalizations.of(context)!.mapPinSpot,
                          style: GoogleFonts.notoSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003478),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ──────────────────────────── _MapFilterBar ────────────────────────────

class _MapFilterBar extends StatelessWidget {
  const _MapFilterBar({
    required this.selectedFilter,
    required this.onFilterTap,
  });

  final String selectedFilter;
  final ValueChanged<String> onFilterTap;

  static const _filters = [
    (_kFilterAll, Icons.grid_view_rounded),
    (_kFilterRestaurant, Icons.restaurant_rounded),
    (_kFilterRealEstate, Icons.apartment_rounded),
    (_kFilterUtility, Icons.store_rounded),
    (_kFilterPharmacy, Icons.local_pharmacy_rounded),
  ];

  String _label(AppLocalizations l, String key) => switch (key) {
    _kFilterAll => l.filterAll,
    _kFilterRestaurant => l.filterRestaurants,
    _kFilterRealEstate => l.filterRealEstate,
    _kFilterUtility => l.filterConvenience,
    _kFilterPharmacy => l.filterPharmacy,
    _ => key,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (key, icon) = _filters[i];
          final selected = selectedFilter == key;
          return GestureDetector(
            onTap: () => onFilterTap(key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF003478) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x20000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 15,
                    color: selected ? Colors.white : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _label(l, key),
                    style: GoogleFonts.notoSansKr(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? Colors.white : const Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ──────────────────────────── _PlaceResultsDropdown ────────────────────────────

class _PlaceResultsDropdown extends StatelessWidget {
  const _PlaceResultsDropdown({
    required this.results,
    required this.isLoading,
    required this.onSelect,
  });

  final List<NaverPlace> results;
  final bool isLoading;
  final ValueChanged<NaverPlace> onSelect;

  @override
  Widget build(BuildContext context) {
    const maxVisible = 5;
    final items = results.take(maxVisible).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: isLoading && items.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF003478),
                    ),
                  ),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < items.length; i++) ...[
                    if (i > 0)
                      const Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: Color(0xFFF0F0F0),
                      ),
                    _PlaceTile(
                      place: items[i],
                      onTap: () => onSelect(items[i]),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _PlaceTile extends StatelessWidget {
  const _PlaceTile({required this.place, required this.onTap});
  final NaverPlace place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF003478), width: 1.5),
              ),
              child: const Icon(
                Icons.place_rounded,
                color: Color(0xFF003478),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (place.category.isNotEmpty || place.address.isNotEmpty)
                    Text(
                      [
                        place.category,
                        place.address,
                      ].where((s) => s.isNotEmpty).join(' · '),
                      style: GoogleFonts.notoSansKr(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: Color(0xFFCBD5E1),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────── _SearchResultsDropdown ────────────────────────────

class _SearchResultsDropdown extends StatelessWidget {
  const _SearchResultsDropdown({required this.results, required this.onSelect});

  final List<UserPinModel> results;
  final ValueChanged<UserPinModel> onSelect;

  @override
  Widget build(BuildContext context) {
    const maxVisible = 5;
    final items = results.take(maxVisible).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < items.length; i++) ...[
              if (i > 0)
                const Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Color(0xFFF0F0F0),
                ),
              _ResultTile(pin: items[i], onTap: () => onSelect(items[i])),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.pin, required this.onTap});
  final UserPinModel pin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFB300), width: 1.5),
              ),
              child: Center(
                child: Text(
                  pin.type.emoji,
                  style: const TextStyle(fontSize: 17, height: 1),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pin.name,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (pin.notes.isNotEmpty)
                    Text(
                      pin.notes,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: Color(0xFFCBD5E1),
            ),
          ],
        ),
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
                      child: Icon(
                        Icons.close_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                    ),
                  )
                : const Padding(
                    key: ValueKey('mic'),
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Icon(
                      Icons.tune_rounded,
                      color: Color(0xFF003478),
                      size: 20,
                    ),
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
            child: Text(emoji, style: const TextStyle(fontSize: 20, height: 1)),
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
            child: const Icon(
              Icons.check_circle_rounded,
              color: _kUserPinColor,
              size: 22,
            ),
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
  const _PinInfoSheet({
    required this.pin,
    required this.isOwner,
    required this.isSaved,
    // Owner callbacks
    required this.onDeleteConfirmed,
    required this.onEditTap,
    // Public callbacks
    required this.onSave,
    required this.onShare,
    required this.onReport,
    required this.onDirections,
    this.userPosition,
  });

  final UserPinModel pin;
  final bool isOwner;
  final bool isSaved;
  final VoidCallback onDeleteConfirmed;
  final VoidCallback onEditTap;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onReport;
  final VoidCallback onDirections;
  final NLatLng? userPosition;

  Future<void> _confirmDelete(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l.mapPinDeleteConfirmTitle),
        content: Text(l.mapPinDeleteConfirmMessage),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.btnDelete),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.btnCancel),
          ),
        ],
      ),
    );
    if (confirmed == true) onDeleteConfirmed();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
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

              if (isOwner)
                _OwnerView(
                  pin: pin,
                  onEditTap: onEditTap,
                  onConfirmDelete: () => _confirmDelete(context),
                  userPosition: userPosition,
                )
              else
                _PublicView(
                  pin: pin,
                  isSaved: isSaved,
                  onSave: onSave,
                  onShare: onShare,
                  onReport: onReport,
                  onDirections: onDirections,
                  userPosition: userPosition,
                ),
            ],
          ), // Column
        ), // SingleChildScrollView
      ), // SafeArea
    ); // Container
  }
}

// ── Owner View ──────────────────────────────────────────────────────────

class _OwnerView extends StatelessWidget {
  const _OwnerView({
    required this.pin,
    required this.onEditTap,
    required this.onConfirmDelete,
    this.userPosition,
  });
  final UserPinModel pin;
  final VoidCallback onEditTap;
  final VoidCallback onConfirmDelete;
  final NLatLng? userPosition;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PinHeader(pin: pin),
        if (pin.notes.isNotEmpty) ...[
          const SizedBox(height: 14),
          _NotesBox(notes: pin.notes),
        ],
        const SizedBox(height: 12),
        _CoordRow(pin: pin, l: l, userPosition: userPosition),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _InfoSheetButton(
                label: l.btnEdit,
                icon: Icons.edit_rounded,
                backgroundColor: const Color(0xFF003478),
                foregroundColor: Colors.white,
                onTap: onEditTap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoSheetButton(
                label: l.btnDelete,
                icon: Icons.delete_outline_rounded,
                backgroundColor: const Color(0xFFFFF0F0),
                foregroundColor: const Color(0xFFD32F2F),
                onTap: onConfirmDelete,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Public View ─────────────────────────────────────────────────────────

class _PublicView extends StatelessWidget {
  const _PublicView({
    required this.pin,
    required this.isSaved,
    required this.onSave,
    required this.onShare,
    required this.onReport,
    required this.onDirections,
    this.userPosition,
  });
  final UserPinModel pin;
  final bool isSaved;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onReport;
  final VoidCallback onDirections;
  final NLatLng? userPosition;

  // Category chip colours
  static const _categoryColors = <PinType, Color>{
    PinType.restaurant: Color(0xFFE65100),
    PinType.realEstate: Color(0xFF003478),
    PinType.utility: Color(0xFF7B1FA2),
    PinType.pharmacy: Color(0xFF2E7D32),
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final catColor = _categoryColors[pin.type] ?? const Color(0xFF003478);
    final initial = pin.authorName.isNotEmpty
        ? pin.authorName[0].toUpperCase()
        : '?';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Author header ──
        Row(
          children: [
            // Avatar
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFF003478),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: GoogleFonts.notoSansKr(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        pin.authorName.isNotEmpty
                            ? '@${pin.authorName}'
                            : '@unknown',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      if (pin.isVerified) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF003478),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                color: Colors.white,
                                size: 10,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Verified',
                                style: GoogleFonts.notoSansKr(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    'Posted by',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 11,
                      color: const Color(0xFFADB5BD),
                    ),
                  ),
                ],
              ),
            ),
            // Report icon (small, unobtrusive)
            GestureDetector(
              onTap: onReport,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.flag_outlined,
                  size: 16,
                  color: Color(0xFFD32F2F),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        const Divider(height: 1, color: Color(0xFFF0F0F0)),
        const SizedBox(height: 14),

        // ── Name + category chip ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pin.type.emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
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
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      pin.type.localizedLabel(l),
                      style: GoogleFonts.notoSansKr(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: catColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // ── Stars + review count (tap → open review modal) ──
        GestureDetector(
          onTap: () => showReviewModal(context, pinName: pin.name),
          child: Row(
            children: [
              ...List.generate(
                5,
                (i) => Icon(
                  i < pin.rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: _kUserPinColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${pin.rating}.0',
                style: GoogleFonts.notoSansKr(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                AppLocalizations.of(context)!.reviewsCount(pin.reviewCount),
                style: GoogleFonts.notoSansKr(
                  fontSize: 12,
                  color: const Color(0xFF003478),
                  decoration: TextDecoration.underline,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right_rounded,
                size: 14,
                color: Color(0xFF003478),
              ),
            ],
          ),
        ),

        if (pin.notes.isNotEmpty) ...[
          const SizedBox(height: 14),
          _NotesBox(notes: pin.notes),
        ],

        const SizedBox(height: 12),
        _CoordRow(pin: pin, l: l, userPosition: userPosition),
        const SizedBox(height: 20),

        // ── Secondary action bar: Save · Share ──
        Builder(
          builder: (context) {
            final l = AppLocalizations.of(context)!;
            return Row(
              children: [
                Expanded(
                  child: _InfoSheetButton(
                    label: isSaved ? l.mapPinSaved : l.btnSave,
                    icon: isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    backgroundColor: isSaved
                        ? const Color(0xFF003478)
                        : const Color(0xFFF0F4FF),
                    foregroundColor: isSaved
                        ? Colors.white
                        : const Color(0xFF003478),
                    onTap: onSave,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoSheetButton(
                    label: l.actionShare,
                    icon: Icons.share_rounded,
                    backgroundColor: const Color(0xFFF5F7FA),
                    foregroundColor: const Color(0xFF6A6A6A),
                    onTap: onShare,
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 10),

        // ── Primary CTA: Directions ──
        Builder(
          builder: (context) {
            final l = AppLocalizations.of(context)!;
            return _InfoSheetButton(
              label: l.mapDirections,
              icon: Icons.directions_rounded,
              backgroundColor: const Color(0xFF003478),
              foregroundColor: Colors.white,
              onTap: onDirections,
              fullWidth: true,
            );
          },
        ),
      ],
    );
  }
}

// ── Shared sub-widgets ───────────────────────────────────────────────────

class _PinHeader extends StatelessWidget {
  const _PinHeader({required this.pin});
  final UserPinModel pin;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Row(
      children: [
        Text(pin.type.emoji, style: const TextStyle(fontSize: 28)),
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
                  color: const Color(0xFF6A6A6A),
                ),
              ),
            ],
          ),
        ),
        Row(
          children: List.generate(
            5,
            (i) => Icon(
              i < pin.rating ? Icons.star_rounded : Icons.star_outline_rounded,
              color: _kUserPinColor,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }
}

class _NotesBox extends StatelessWidget {
  const _NotesBox({required this.notes});
  final String notes;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        notes,
        style: GoogleFonts.notoSansKr(
          fontSize: 14,
          color: const Color(0xFF1A1A1A),
          height: 1.6,
        ),
      ),
    );
  }
}

class _CoordRow extends StatelessWidget {
  const _CoordRow({required this.pin, required this.l, this.userPosition});
  final UserPinModel pin;
  final AppLocalizations l;
  final NLatLng? userPosition;

  @override
  Widget build(BuildContext context) {
    final dist = _distanceLabel(userPosition, pin.latLng, l);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              pin.isPublic ? Icons.public_rounded : Icons.lock_outline_rounded,
              size: 14,
              color: const Color(0xFFADB5BD),
            ),
            const SizedBox(width: 4),
            Text(
              pin.isPublic
                  ? l.mapPinInfoPublicShort
                  : l.mapPinVisibilityPrivate,
              style: GoogleFonts.notoSansKr(
                fontSize: 11,
                color: const Color(0xFFADB5BD),
              ),
            ),
            const Spacer(),
            Text(
              '${pin.latLng.latitude.toStringAsFixed(5)}, '
              '${pin.latLng.longitude.toStringAsFixed(5)}',
              style: GoogleFonts.notoSansKr(
                fontSize: 11,
                color: const Color(0xFFADB5BD),
              ),
            ),
          ],
        ),
        if (dist != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.near_me_rounded,
                size: 13,
                color: Color(0xFF2563EB),
              ),
              const SizedBox(width: 4),
              Text(
                dist,
                style: GoogleFonts.notoSans(
                  fontSize: 12,
                  color: const Color(0xFF2563EB),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ──────────────────────────── _InfoSheetButton ────────────────────────────

class _InfoSheetButton extends StatelessWidget {
  const _InfoSheetButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
    this.fullWidth = false,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: foregroundColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.notoSansKr(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: foregroundColor,
              ),
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
                    ShellColors.primaryBlue,
                  ),
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
                    ShellColors.primaryBlue,
                  ),
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
              Icon(
                Icons.map_outlined,
                size: 56,
                color: ShellColors.primaryBlue.withValues(alpha: 0.4),
              ),
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

// ──────────────────────────── _MapTapSheet ────────────────────────────

class _MapTapSheet extends StatelessWidget {
  const _MapTapSheet({
    required this.latLng,
    required this.addressFuture,
    required this.onPinHere,
    required this.onDirections,
    this.userPosition,
  });

  final NLatLng latLng;
  final Future<LocalizedAddress> addressFuture;
  final VoidCallback onPinHere;
  final VoidCallback onDirections;
  final NLatLng? userPosition;

  @override
  Widget build(BuildContext context) {
    final lat = latLng.latitude.toStringAsFixed(6);
    final lng = latLng.longitude.toStringAsFixed(6);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
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

            // Address block
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEF2FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.place_rounded,
                    color: Color(0xFF003478),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FutureBuilder<LocalizedAddress>(
                    future: addressFuture,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF003478),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$lat, $lng',
                              style: GoogleFonts.notoSans(
                                fontSize: 12,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        );
                      }
                      final addr = snap.data;
                      final primary = addr?.localized.isNotEmpty == true
                          ? addr!.localized
                          : addr?.korean ?? '$lat, $lng';
                      final secondary = (addr?.hasTranslation == true)
                          ? addr!.korean
                          : '$lat, $lng';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            primary,
                            style: GoogleFonts.notoSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            secondary,
                            style: GoogleFonts.notoSans(
                              fontSize: 12,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                          if (_distanceLabel(
                                userPosition,
                                latLng,
                                AppLocalizations.of(context)!,
                              )
                              case final dist?) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.near_me_rounded,
                                  size: 13,
                                  color: Color(0xFF2563EB),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  dist,
                                  style: GoogleFonts.notoSans(
                                    fontSize: 12,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _InfoSheetButton(
                    label: AppLocalizations.of(context)!.mapDirections,
                    icon: Icons.directions_rounded,
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    onTap: onDirections,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoSheetButton(
                    label: AppLocalizations.of(context)!.mapPinSpot,
                    icon: Icons.push_pin_rounded,
                    backgroundColor: const Color(0xFF003478),
                    foregroundColor: Colors.white,
                    onTap: onPinHere,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
