import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../core/naver_map/naver_map_sdk_controller.dart';
import '../shell/theme/shell_theme.dart';

/// Naver Map screen (keeps alive across tab switches).
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with AutomaticKeepAliveClientMixin {
  static const NLatLng _defaultPosition = NLatLng(35.8562, 128.4838); // Keimyung University, Daegu

  NaverMapController? _controller;
  bool _isMapReady = false;
  bool _isLocating = false;
  NLatLng? _currentPosition;

  @override
  bool get wantKeepAlive => true;

  /// Di chuyển camera về vị trí hiện tại (dùng cho nút định vị).
  Future<void> _goToCurrentLocation() async {
    if (_isLocating) return;
    if (mounted) setState(() => _isLocating = true);
    try {
      // 1. Kiểm tra location service có bật không
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[Map] Location service is disabled');
        return;
      }

      // 2. Kiểm tra & xin quyền
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('[Map] Location permission denied: $permission');
        return;
      }

      // 3. Lấy vị trí — thử cached trước cho nhanh, rồi mới lấy mới
      Position? pos = await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 15),
        ),
      );
      debugPrint('[Map] Got position: ${pos.latitude}, ${pos.longitude}');

      final c = _controller;
      if (c == null) return;

      final target = NLatLng(pos.latitude, pos.longitude);
      if (mounted) setState(() => _currentPosition = target);

      await c.updateCamera(
        NCameraUpdate.scrollAndZoomTo(target: target, zoom: 15),
      );
    } catch (e) {
      debugPrint('[Map] Error getting location: $e');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final sdk = context.watch<NaverMapSdkController>();
    if (!sdk.isInitialized) {
      final err = sdk.initError;
      return Scaffold(
        backgroundColor: ShellColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 54,
                  color: ShellColors.primaryBlue.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Không thể khởi tạo Naver Map',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  err == null ? 'Đang khởi tạo…' : 'Lỗi: $err',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final initialPosition = _currentPosition ?? _defaultPosition;

    final bottomOffset = MediaQuery.of(context).padding.bottom + 100;

    return Scaffold(
      backgroundColor: ShellColors.background,
      // Đặt nút ra ngoài Stack của NaverMap để tránh platform view nuốt touch
      floatingActionButton: _isMapReady
          ? Padding(
              padding: EdgeInsets.only(bottom: bottomOffset - 16),
              child: _LocationButton(
                isLocating: _isLocating,
                onTap: _goToCurrentLocation,
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Stack(
        fit: StackFit.expand,
        children: [
          NaverMap(
            options: NaverMapViewOptions(
              initialCameraPosition: NCameraPosition(
                target: initialPosition,
                zoom: 15,
              ),
              locationButtonEnable: false,
              indoorEnable: true,
            ),
            onMapReady: (controller) async {
              _controller = controller;
              if (!mounted) return;
              setState(() => _isMapReady = true);
              // Lấy vị trí ngay sau khi map sẵn sàng — không race condition
              await _goToCurrentLocation();
            },
          ),
          if (!_isMapReady)
            const _MapInitOverlay(label: 'Đang khởi tạo bản đồ…'),
        ],
      ),
    );
  }
}

class _LocationButton extends StatelessWidget {
  const _LocationButton({required this.isLocating, required this.onTap});

  final bool isLocating;
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: isLocating
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: ShellColors.primaryBlue,
                ),
              )
            : Icon(
                Icons.my_location_rounded,
                color: ShellColors.primaryBlue,
                size: 24,
              ),
      ),
    );
  }
}

class _MapInitOverlay extends StatelessWidget {
  const _MapInitOverlay({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.88, end: 1),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: CircularProgressIndicator(
                  strokeWidth: 3.2,
                  color: ShellColors.primaryBlue,
                  backgroundColor:
                      ShellColors.primaryBlue.withValues(alpha: 0.12),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: ShellColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
