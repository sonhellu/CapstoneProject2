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

  @override
  String get navHome => '홈';

  @override
  String get navMap => '지도';

  @override
  String get navCommunity => '커뮤니티';

  @override
  String get navMyPage => '마이페이지';

  @override
  String get mapSearchHere => '이 지역 검색';

  @override
  String get mapMyLocation => '내 위치';

  @override
  String get mapPinSpot => '이 장소 저장';

  @override
  String get mapGetDirections => '길 찾기';

  @override
  String get mapDirections => '길 찾기';

  @override
  String get btnConfirm => '확인';

  @override
  String get btnCancel => '취소';

  @override
  String get btnSave => '저장';

  @override
  String get btnEdit => '수정';

  @override
  String get btnDelete => '삭제';

  @override
  String get btnClose => '닫기';

  @override
  String get btnNext => '다음';

  @override
  String get btnBack => '뒤로';

  @override
  String get filterAll => '전체';

  @override
  String get filterRestaurants => '식당';

  @override
  String get filterRealEstate => '부동산';

  @override
  String get filterConvenience => '편의점';

  @override
  String get filterAtm => 'ATM';

  @override
  String get statusLoadingMap => '지도 불러오는 중…';

  @override
  String get statusLocating => '위치 확인 중…';

  @override
  String get statusPermissionDenied => '권한이 거부되었습니다';

  @override
  String get statusEnableGps => 'GPS를 켜주세요';

  @override
  String get foodMenu => '메뉴';

  @override
  String get foodPrice => '가격';

  @override
  String get foodHours => '영업시간';

  @override
  String get foodHalal => '할랄';

  @override
  String get foodVeggie => '채식';

  @override
  String get foodAuthentic => '현지맛';

  @override
  String get housingRent => '월세';

  @override
  String get housingDeposit => '보증금';

  @override
  String get housingFee => '관리비';

  @override
  String get housingNoDeposit => '무보증금';

  @override
  String get housingStationNearby => '역 근처';

  @override
  String get actionCall => '전화';

  @override
  String get actionMessage => '메시지';

  @override
  String get actionReview => '리뷰';

  @override
  String get actionShare => '공유';

  @override
  String get actionPhoto => '사진';

  @override
  String distanceAway(String distance) {
    return '$distance 거리';
  }

  @override
  String minWalk(String time) {
    return '도보 $time분';
  }

  @override
  String get alertEnterName => '이름 입력';

  @override
  String get alertWrongPhone => '잘못된 번호';

  @override
  String get alertNotFound => '찾을 수 없음';

  @override
  String get alertTryAgain => '다시 시도';

  @override
  String get alertLoginFirst => '로그인 필요';

  @override
  String get profileMyProfile => '내 프로필';

  @override
  String get profileEdit => '프로필 수정';

  @override
  String get profileMyPosts => '내 게시물';

  @override
  String get profileSavedPlaces => '저장한 장소';

  @override
  String get profileLogout => '로그아웃';

  @override
  String get profileDeleteAccount => '계정 삭제';

  @override
  String get chatMessages => '메시지';

  @override
  String get chatTyping => '입력 중…';

  @override
  String get chatSent => '전송됨';

  @override
  String get chatDelivered => '전달됨';

  @override
  String get chatRead => '읽음';

  @override
  String get chatCall => '통화';

  @override
  String get chatStartConversation => '대화를 시작해보세요';

  @override
  String get communityPostStory => '게시물 올리기';

  @override
  String get communityWhatsOnMind => '무슨 생각을 하고 있나요?';

  @override
  String get communityPublic => '전체 공개';

  @override
  String get communityPrivate => '나만 보기';

  @override
  String get communityAnonymous => '익명';

  @override
  String get communityReport => '신고';

  @override
  String get settingsLanguage => '언어';

  @override
  String get settingsNotifications => '알림';

  @override
  String get settingsDarkMode => '다크 모드';

  @override
  String get settingsTerms => '이용약관';

  @override
  String get settingsPrivacy => '개인정보 처리방침';

  @override
  String get settingsHelp => '고객센터';

  @override
  String get settingsVersion => '버전';

  @override
  String get timeJustNow => '방금';

  @override
  String timeMinAgo(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString분 전',
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
      other: '$countString시간 전',
    );
    return '$_temp0';
  }

  @override
  String get timeYesterday => '어제';
}
