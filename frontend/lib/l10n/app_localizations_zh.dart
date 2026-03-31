// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Capstone';

  @override
  String get homeTitle => '首页';

  @override
  String get counterLabel => '您已按下按钮的次数：';

  @override
  String get incrementTooltip => '增加';

  @override
  String get languagePickerTooltip => '语言';

  @override
  String get languageSheetTitle => '选择语言';
}
