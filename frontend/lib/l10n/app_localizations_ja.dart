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

  @override
  String get navHome => 'ホーム';

  @override
  String get navMap => 'マップ';

  @override
  String get navCommunity => 'コミュニティ';

  @override
  String get navMyPage => 'マイページ';

  @override
  String get mapSearchHere => 'このエリアを検索';

  @override
  String get mapMyLocation => '現在地';

  @override
  String get mapPinSpot => 'ここをピン留め';

  @override
  String get mapGetDirections => 'ルートを検索';

  @override
  String get mapDirections => 'ルート';

  @override
  String get btnConfirm => '確認';

  @override
  String get btnCancel => 'キャンセル';

  @override
  String get btnSave => '保存';

  @override
  String get btnEdit => '編集';

  @override
  String get btnDelete => '削除';

  @override
  String get btnClose => '閉じる';

  @override
  String get btnNext => '次へ';

  @override
  String get btnBack => '戻る';

  @override
  String get filterAll => 'すべて';

  @override
  String get filterRestaurants => 'レストラン';

  @override
  String get filterRealEstate => '不動産';

  @override
  String get filterConvenience => 'コンビニ';

  @override
  String get filterAtm => 'ATM';

  @override
  String get statusLoadingMap => 'マップ読み込み中…';

  @override
  String get statusLocating => '位置情報取得中…';

  @override
  String get statusPermissionDenied => '権限が拒否されました';

  @override
  String get statusEnableGps => 'GPSを有効にしてください';

  @override
  String get foodMenu => 'メニュー';

  @override
  String get foodPrice => '料金';

  @override
  String get foodHours => '営業時間';

  @override
  String get foodHalal => 'ハラール';

  @override
  String get foodVeggie => 'ベジ';

  @override
  String get foodAuthentic => '本場の味';

  @override
  String get housingRent => '家賃';

  @override
  String get housingDeposit => '敷金';

  @override
  String get housingFee => '管理費';

  @override
  String get housingNoDeposit => '敷金なし';

  @override
  String get housingStationNearby => '駅近';

  @override
  String get actionCall => '電話';

  @override
  String get actionMessage => 'メッセージ';

  @override
  String get actionReview => 'レビュー';

  @override
  String get actionShare => 'シェア';

  @override
  String get actionPhoto => '写真';

  @override
  String distanceAway(String distance) {
    return '$distance先';
  }

  @override
  String minWalk(String time) {
    return '徒歩$time分';
  }

  @override
  String get alertEnterName => '名前を入力';

  @override
  String get alertWrongPhone => '番号が違います';

  @override
  String get alertNotFound => '見つかりません';

  @override
  String get alertTryAgain => '再試行';

  @override
  String get alertLoginFirst => 'ログインが必要';

  @override
  String get profileMyProfile => 'マイプロフィール';

  @override
  String get profileEdit => 'プロフィール編集';

  @override
  String get profileMyPosts => '投稿一覧';

  @override
  String get profileSavedPlaces => '保存済みの場所';

  @override
  String get profileLogout => 'ログアウト';

  @override
  String get profileDeleteAccount => 'アカウント削除';

  @override
  String get chatMessages => 'メッセージ';

  @override
  String get chatTyping => '入力中…';

  @override
  String get chatSent => '送信済み';

  @override
  String get chatDelivered => '配信済み';

  @override
  String get chatRead => '既読';

  @override
  String get chatCall => '通話';

  @override
  String get chatStartConversation => '会話を始めましょう';

  @override
  String get communityPostStory => '投稿する';

  @override
  String get communityWhatsOnMind => '今何を考えていますか？';

  @override
  String get communityPublic => '公開';

  @override
  String get communityPrivate => '非公開';

  @override
  String get communityAnonymous => '匿名';

  @override
  String get communityReport => '報告';

  @override
  String get settingsLanguage => '言語';

  @override
  String get settingsNotifications => '通知';

  @override
  String get settingsDarkMode => 'ダークモード';

  @override
  String get settingsTerms => '利用規約';

  @override
  String get settingsPrivacy => 'プライバシーポリシー';

  @override
  String get settingsHelp => 'ヘルプセンター';

  @override
  String get settingsVersion => 'バージョン';

  @override
  String get timeJustNow => 'たった今';

  @override
  String timeMinAgo(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString分前',
    );
    return '$_temp0';
  }

  @override
  String timeHourAgo(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString時間前',
    );
    return '$_temp0';
  }

  @override
  String get timeYesterday => '昨日';
}
