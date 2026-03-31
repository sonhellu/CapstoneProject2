// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Capstone';

  @override
  String get homeTitle => 'ホーム';

  @override
  String get counterLabel => 'ボタンを押した回数:';

  @override
  String get incrementTooltip => '増やす';

  @override
  String get languagePickerTooltip => '言語';

  @override
  String get languageSheetTitle => '言語を選択';
}
