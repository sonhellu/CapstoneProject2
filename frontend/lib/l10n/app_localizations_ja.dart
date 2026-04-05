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

  @override
  String get homeViewAll => 'すべて見る';

  @override
  String get homeIntlNews => '国際ニュース 🌏';

  @override
  String get homeCampusLife => 'キャンパスライフ 🇰🇷';

  @override
  String get profilePersonalInfo => '個人情報';

  @override
  String get profileEditInfo => '情報編集';

  @override
  String get profileNativeLang => '母国語';

  @override
  String get profileUniversity => '大学';

  @override
  String get profileMajor => '専攻';

  @override
  String get profileNationality => '国籍';

  @override
  String get profileEmail => 'メール';

  @override
  String get profileFullName => '氏名';

  @override
  String get profileVerified => '認証済み';

  @override
  String get profileLogoutConfirm => '本当にサインアウトしますか？';

  @override
  String get profileSaveChanges => '変更を保存';

  @override
  String get communityBoardTitle => 'コミュニティ掲示板';

  @override
  String get communitySearchHint => '投稿、ユーザーを検索…';

  @override
  String communityPostCount(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString件の投稿',
    );
    return '$_temp0';
  }

  @override
  String get communitySortRecent => '新着';

  @override
  String get communitySortPopular => '人気';

  @override
  String get communityNoPosts => '投稿が見つかりません';

  @override
  String get createPostNew => '新規投稿';

  @override
  String get createPostCategory => 'カテゴリー';

  @override
  String get createPostTitleLabel => 'タイトル';

  @override
  String get createPostTitleHint => '明確なタイトルを入力…';

  @override
  String get createPostLanguage => '投稿言語';

  @override
  String get createPostContent => '内容';

  @override
  String get createPostContentHint => 'ここに投稿内容を入力…';

  @override
  String get createPostPhotos => '写真';

  @override
  String get createPostAddPhoto => '追加';

  @override
  String get createPostGallery => 'ギャラリー';

  @override
  String get createPostCamera => 'カメラ';

  @override
  String get createPostPublish => '投稿する';

  @override
  String get postCopied => 'クリップボードにコピーしました';

  @override
  String get postFollow => 'フォロー';

  @override
  String get postFollowing => 'フォロー中';

  @override
  String get postActionCopy => 'コピー';

  @override
  String get postNoImage => '画像なし';

  @override
  String get authHeaderTitle => '留学生の皆さん、こんにちは！';

  @override
  String get authHeaderSubtitle => '一緒にグローバルな学びの旅を歩みましょう。';

  @override
  String get authLoginTitle => 'ログイン';

  @override
  String get authLoginSubtitle => 'メールとパスワードを入力してください。';

  @override
  String get authRegisterTitle => '新規登録';

  @override
  String get authRegisterSubtitle => 'アカウントを作成して留学ライフを始めましょう。';

  @override
  String get authFooterNoAccount => 'アカウントをお持ちでないですか？';

  @override
  String get authFooterHasAccount => 'すでにアカウントをお持ちですか？';

  @override
  String get authSwitchToRegister => '新規登録';

  @override
  String get authSwitchToLogin => 'ログイン';

  @override
  String get authFieldEmail => 'メール';

  @override
  String get authFieldPassword => 'パスワード';

  @override
  String get authFieldPasswordConfirm => 'パスワード確認';

  @override
  String get authFieldFullName => '氏名';

  @override
  String get authHintEmail => 'you@school.edu';

  @override
  String get authHintPasswordDots => '••••••••';

  @override
  String get authHintPasswordMin => '8文字以上';

  @override
  String get authHintConfirmPassword => 'パスワードを再入力';

  @override
  String get authHintNameExample => '山田 太郎';

  @override
  String get authButtonLogin => 'ログイン';

  @override
  String get authButtonRegister => 'アカウント作成';

  @override
  String get authSocialGoogleLoginDemo => 'Googleでログイン（デモ）';

  @override
  String get authSocialKakaoLoginDemo => 'KakaoTalkでログイン（デモ）';

  @override
  String get authSocialGoogleRegisterDemo => 'Googleで登録（デモ）';

  @override
  String get authSocialKakaoRegisterDemo => 'KakaoTalkで登録（デモ）';

  @override
  String get authSocialOr => 'または';

  @override
  String get authSocialContinueGoogle => 'Googleで続ける';

  @override
  String get authSocialKakaoLabel => 'KakaoTalk ID';

  @override
  String get authValidationEmailEmpty => 'メールを入力してください';

  @override
  String get authValidationEmailInvalid => 'メール形式が正しくありません';

  @override
  String get authValidationPasswordEmpty => 'パスワードを入力してください';

  @override
  String get authValidationPasswordMin => 'パスワードは8文字以上にしてください';

  @override
  String get authValidationNameEmpty => '名前を入力してください';

  @override
  String get authValidationNameShort => '名前が短すぎます';

  @override
  String get authValidationConfirmEmpty => 'パスワードを確認してください';

  @override
  String get authValidationConfirmMismatch => 'パスワードが一致しません';

  @override
  String get authTooltipShowPassword => 'パスワードを表示';

  @override
  String get authTooltipHidePassword => 'パスワードを隠す';

  @override
  String get languageSheetSubtitle => '表示言語を選んでください';

  @override
  String get mapPinFormTitle => '場所を保存';

  @override
  String get mapPinSectionVisibility => '公開範囲';

  @override
  String get mapPinSectionType => 'スポットの種類';

  @override
  String get mapPinSectionName => '場所名 *';

  @override
  String get mapPinSectionNotes => '友だちへのメモ';

  @override
  String get mapPinSectionRating => '評価';

  @override
  String get mapPinSectionPhotos => '写真';

  @override
  String get mapPinNameHint => '例：O. Sáu ビーフン';

  @override
  String get mapPinNotesHint => '価格、雰囲気、おすすめ料理…正直にシェア！';

  @override
  String get mapPinVisibilityPublic => '公開 — 全員に表示';

  @override
  String get mapPinVisibilityPrivate => '自分だけ';

  @override
  String get mapPinSaveFail => '保存に失敗しました。もう一度お試しください。';

  @override
  String get mapPinAddPhoto => '写真を追加';

  @override
  String get mapPinSaveButton => '場所を保存';

  @override
  String get mapPinSuccessTitle => '保存しました！';

  @override
  String get mapPinShareTitle => 'この場所を共有しますか？';

  @override
  String get mapPinShareMessage => 'おすすめの店、住まい、キャンパス近くの便利スポットをピン留めしましょう。';

  @override
  String get mapPinShareAction => 'この場所をピン留め';

  @override
  String get mapLocationServicesDisabled => '位置情報サービスをオンにしてください。';

  @override
  String get mapLocationPermissionRequired => '位置情報の許可が必要です。';

  @override
  String get statusFetchingLocation => '位置情報を取得中…';

  @override
  String get mapUnavailable => '地図を利用できません';

  @override
  String get mapSdkInitializing => 'Naver Map SDK を初期化中…';

  @override
  String mapSdkError(String error) {
    return 'エラー: $error';
  }

  @override
  String get mapPinInfoPublicShort => '公開';

  @override
  String get pinTypeRestaurant => 'グルメ';

  @override
  String get pinTypeRealEstate => '住まい';

  @override
  String get pinTypeUtility => 'その他の施設';

  @override
  String get partnerSearchTitle => '語学パートナー';

  @override
  String get partnerGenderAny => '指定なし';

  @override
  String get partnerGenderMale => '男性';

  @override
  String get partnerGenderFemale => '女性';

  @override
  String get partnerEmptyTitle => 'パートナーが見つかりません';

  @override
  String get partnerEmptySubtitle => 'フィルターを変えてみてください。';

  @override
  String get partnerOnline => 'オンライン';

  @override
  String get partnerSendRequest => 'リクエストを送る';

  @override
  String get partnerPending => '保留中…';

  @override
  String get partnerAccepted => '承認済み！';

  @override
  String get chatSearchConversations => '会話を検索…';

  @override
  String get chatEmptyTitle => 'まだ会話がありません';

  @override
  String get chatEmptySubtitle => '語学パートナーを見つけてチャットを始めましょう！';

  @override
  String get chatFindPartnerButton => 'パートナーを探す';

  @override
  String get chatFilterFindPartner => '語学パートナーを探す';

  @override
  String get chatFilterGender => '性別';

  @override
  String get chatFilterTargetLanguage => '学びたい言語';

  @override
  String get chatFilterFindPartners => 'パートナーを探す';

  @override
  String get chatRequestPending => 'リクエスト保留中…';

  @override
  String get chatFilterLanguageAny => '指定なし';
}
