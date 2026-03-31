import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'app_locale_tag';

/// Quản lý [Locale] cho [MaterialApp] + lưu [SharedPreferences].
class LocaleController extends ChangeNotifier {
  LocaleController() {
    _loadSaved();
  }

  Locale _locale = const Locale('vi');
  Locale get locale => _locale;

  bool _isLocaleChanging = false;
  bool get isLocaleChanging => _isLocaleChanging;

  Future<void> _loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tag = prefs.getString(_prefsKey);
      if (tag != null && tag.isNotEmpty) {
        final normalized = tag == 'zh_CN' || tag == 'zh-CN' ? 'zh' : tag;
        final parsed = _parseLocaleTag(normalized);
        if (parsed != null) {
          _locale = parsed;
          if (normalized != tag) {
            await prefs.setString(_prefsKey, _localeToTag(_locale));
          }
          notifyListeners();
        }
      }
    } catch (e, st) {
      debugPrint('LocaleController load: $e\n$st');
    }
  }

  static Locale? _parseLocaleTag(String tag) {
    final parts = tag.split(RegExp(r'[-_]'));
    if (parts.isEmpty) return null;
    if (parts.length >= 2 && parts[1].isNotEmpty) {
      return Locale(parts[0], parts[1]);
    }
    return Locale(parts[0]);
  }

  static String _localeToTag(Locale l) {
    if (l.countryCode != null && l.countryCode!.isNotEmpty) {
      return '${l.languageCode}_${l.countryCode}';
    }
    return l.languageCode;
  }

  Future<void> setLocale(Locale next) async {
    if (_locale == next) return;

    _isLocaleChanging = true;
    notifyListeners();

    // Cho overlay vẽ một frame trước khi rebuild nặng với locale mới.
    await Future<void>.delayed(const Duration(milliseconds: 32));

    _locale = next;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, _localeToTag(next));
    } catch (e, st) {
      debugPrint('LocaleController save: $e\n$st');
    }

    // Giữ shimmer ngắn để chuỗi l10n / layout kịp ổn định.
    await Future<void>.delayed(const Duration(milliseconds: 260));

    _isLocaleChanging = false;
    notifyListeners();
  }
}
