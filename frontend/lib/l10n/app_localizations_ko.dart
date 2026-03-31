// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Capstone';

  @override
  String get homeTitle => '홈';

  @override
  String get counterLabel => '버튼을 누른 횟수:';

  @override
  String get incrementTooltip => '증가';

  @override
  String get languagePickerTooltip => '언어';

  @override
  String get languageSheetTitle => '언어 선택';
}
