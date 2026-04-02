import 'package:flutter/foundation.dart';

/// Trạng thái SDK Naver Map (tránh phụ thuộc vào member internal của package).
class NaverMapSdkController extends ChangeNotifier {
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Object? _initError;
  Object? get initError => _initError;

  void markInitialized() {
    if (_isInitialized) return;
    _isInitialized = true;
    _initError = null;
    notifyListeners();
  }

  void markFailed(Object error) {
    _isInitialized = false;
    _initError = error;
    notifyListeners();
  }
}

