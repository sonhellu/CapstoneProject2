// Web-only implementation of MapScreen using Naver Maps Web JS SDK.
// Compiled only when building for web (dart.library.html).
// Do NOT import flutter_naver_map here — it is not available on web.

import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web/web.dart' as web;

import '../../core/theme/theme_ext.dart';

// ── JS interop — binds to the global functions defined in web/index.html ─────

@JS('initNaverMap')
external void _jsInitNaverMap(
    JSString viewId, JSNumber lat, JSNumber lng, JSNumber zoom);

@JS('addNaverMarker')
external void _jsAddNaverMarker(JSString viewId, JSNumber lat, JSNumber lng,
    JSString title, JSString notes, JSString emoji);

@JS('moveNaverMap')
external void _jsMoveNaverMap(
    JSString viewId, JSNumber lat, JSNumber lng, JSNumber zoom);

// ── Pin seed data ─────────────────────────────────────────────────────────────
// Mirrors MockPinService._db — hardcoded to avoid a transitive
// flutter_naver_map import (NLatLng) that cannot compile on web.

const _kPins = <Map<String, Object>>[
  {
    'name': '계명대학교 정문',
    'lat': 35.8562,
    'lng': 128.4896,
    'notes': '메인 게이트 — 버스 정류장 바로 앞',
    'emoji': '📍',
  },
  {
    'name': '학생회관 편의점',
    'lat': 35.8571,
    'lng': 128.4882,
    'notes': '캠퍼스 내 CU 편의점, 24시간 운영',
    'emoji': '🍜',
  },
  {
    'name': '정문 약국',
    'lat': 35.8548,
    'lng': 128.4912,
    'notes': '정문 바로 앞, 학생 할인 적용',
    'emoji': '💊',
  },
  {
    'name': '국제학생 기숙사',
    'lat': 35.8583,
    'lng': 128.4870,
    'notes': '유학생 전용 기숙사 — 신청은 학생처',
    'emoji': '🏠',
  },
  {
    'name': '캠퍼스 ATM (하나은행)',
    'lat': 35.8558,
    'lng': 128.4905,
    'notes': '외국 카드 사용 가능, Visa/Mastercard OK',
    'emoji': '📍',
  },
];

const _kDefaultLat = 35.8562;
const _kDefaultLng = 128.4896;
const _kDefaultZoom = 15;

// ── MapScreen (web) ───────────────────────────────────────────────────────────

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final String _viewId;
  bool _mapReady = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _viewId = 'naver-map-web-${DateTime.now().millisecondsSinceEpoch}';

    // Register the platform view factory before the first build.
    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int id) {
        final div =
            web.document.createElement('div') as web.HTMLDivElement;
        div.id = 'naver-map-$_viewId';
        div.setAttribute('style', 'width:100%;height:100%');
        return div;
      },
    );

    // Init map after the element is mounted in the DOM.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 600), _initMap);
    });
  }

  // ── Map init ────────────────────────────────────────────────────────────────

  void _initMap() {
    if (!mounted) return;
    try {
      _jsInitNaverMap(
        _viewId.toJS,
        _kDefaultLat.toJS,
        _kDefaultLng.toJS,
        _kDefaultZoom.toJS,
      );

      for (final pin in _kPins) {
        _jsAddNaverMarker(
          _viewId.toJS,
          (pin['lat']! as double).toJS,
          (pin['lng']! as double).toJS,
          (pin['name']! as String).toJS,
          (pin['notes']! as String).toJS,
          (pin['emoji']! as String).toJS,
        );
      }
    } catch (e) {
      debugPrint('[NaverMapWeb] JS init error: $e');
      // JS handles its own DOM-ready retry — safe to proceed.
    }

    if (mounted) setState(() => _mapReady = true);
  }

  // ── Geolocation ─────────────────────────────────────────────────────────────

  Future<void> _moveToMyLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final pos = await _getCurrentPosition();
      final lat = pos.coords.latitude;
      final lng = pos.coords.longitude;
      _jsMoveNaverMap(_viewId.toJS, lat.toJS, lng.toJS, 16.toJS);
    } catch (e) {
      debugPrint('[NaverMapWeb] geolocation error: $e');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  /// Wraps the callback-based [Geolocation.getCurrentPosition] in a [Future].
  Future<web.GeolocationPosition> _getCurrentPosition() {
    final c = Completer<web.GeolocationPosition>();
    web.window.navigator.geolocation.getCurrentPosition(
      ((web.GeolocationPosition pos) => c.complete(pos)).toJS,
      ((web.GeolocationPositionError err) =>
          c.completeError(err.message)).toJS,
    );
    return c.future;
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: context.bg,
      body: Stack(
        children: [
          // ── Naver Map HTML element ────────────────────────────────
          HtmlElementView(viewType: _viewId),

          // ── Loading overlay ───────────────────────────────────────
          if (!_mapReady)
            Container(
              color: cs.surface,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: cs.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Naver Maps 로딩 중...',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 14,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── My Location FAB ───────────────────────────────────────
          Positioned(
            right: 16,
            bottom: 100,
            child: FloatingActionButton.small(
              heroTag: 'web_map_location',
              onPressed: _locating ? null : _moveToMyLocation,
              backgroundColor: cs.surface,
              elevation: 4,
              child: _locating
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.primary,
                      ),
                    )
                  : Icon(Icons.my_location_rounded,
                      color: cs.primary, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
