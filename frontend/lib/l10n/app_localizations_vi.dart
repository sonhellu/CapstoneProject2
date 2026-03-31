// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Capstone';

  @override
  String get homeTitle => 'Trang chủ';

  @override
  String get counterLabel => 'Bạn đã bấm nút số lần:';

  @override
  String get incrementTooltip => 'Tăng';

  @override
  String get languagePickerTooltip => 'Ngôn ngữ';

  @override
  String get languageSheetTitle => 'Chọn ngôn ngữ';
}
