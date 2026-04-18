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
  String get mapPinSaved => '저장됨';

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
  String get filterPharmacy => '약국';

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

  @override
  String get homeViewAll => '전체보기';

  @override
  String get homeIntlNews => '국제 뉴스 🌏';

  @override
  String get homeCampusLife => '캠퍼스 라이프 🇰🇷';

  @override
  String get profilePersonalInfo => '개인 정보';

  @override
  String get profileEditInfo => '정보 수정';

  @override
  String get profileNativeLang => '모국어';

  @override
  String get profileUniversity => '대학교';

  @override
  String get profileMajor => '전공';

  @override
  String get profileNationality => '국적';

  @override
  String get profileEmail => '이메일';

  @override
  String get profileFullName => '이름';

  @override
  String get profileVerified => '인증됨';

  @override
  String get profileLogoutConfirm => '로그아웃하시겠습니까?';

  @override
  String get profileSaveChanges => '변경 사항 저장';

  @override
  String get communityBoardTitle => '커뮤니티 게시판';

  @override
  String get communitySearchHint => '게시물, 작성자 검색…';

  @override
  String communityPostCount(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString개 게시물',
    );
    return '$_temp0';
  }

  @override
  String get communitySortRecent => '최신';

  @override
  String get communitySortPopular => '인기';

  @override
  String get communityNoPosts => '게시물이 없습니다';

  @override
  String get createPostNew => '새 게시물';

  @override
  String get createPostCategory => '카테고리';

  @override
  String get createPostTitleLabel => '제목';

  @override
  String get createPostTitleHint => '명확한 제목을 입력하세요…';

  @override
  String get createPostLanguage => '언어 선택';

  @override
  String get createPostContent => '내용';

  @override
  String get createPostContentHint => '내용을 입력하세요…';

  @override
  String get createPostPhotos => '사진';

  @override
  String get createPostAddPhoto => '추가';

  @override
  String get createPostGallery => '갤러리';

  @override
  String get createPostCamera => '카메라';

  @override
  String get createPostPublish => '게시하기';

  @override
  String get postCopied => '클립보드에 복사됨';

  @override
  String get postFollow => '팔로우';

  @override
  String get postFollowing => '팔로잉';

  @override
  String get postActionCopy => '복사';

  @override
  String get postActionLike => '좋아요';

  @override
  String get postActionComment => '댓글';

  @override
  String get postActionSave => '저장';

  @override
  String get postNoImage => '이미지 없음';

  @override
  String get reviewsTitle => '리뷰';

  @override
  String reviewsCount(int count) {
    return '$count개의 리뷰';
  }

  @override
  String get reviewNoItems => '아직 리뷰가 없어요. 첫 번째가 되어보세요!';

  @override
  String get reviewWriteHint => '리뷰 작성…';

  @override
  String get reviewSubmit => '제출';

  @override
  String get reviewSeeAll => '모두 보기';

  @override
  String reviewTimeAgo(int n, String unit) {
    return '$n$unit 전';
  }

  @override
  String get reviewTimeUnitMinute => '분';

  @override
  String get reviewTimeUnitHour => '시간';

  @override
  String get reviewTimeUnitDay => '일';

  @override
  String get authHeaderTitle => '안녕하세요, 유학생 여러분!';

  @override
  String get authHeaderSubtitle => '함께 글로벌 학습 여정을 완성해요.';

  @override
  String get authLoginTitle => '로그인';

  @override
  String get authLoginSubtitle => '이메일과 비밀번호를 입력하세요.';

  @override
  String get authRegisterTitle => '회원가입';

  @override
  String get authRegisterSubtitle => '계정을 만들어 유학 생활을 시작하세요.';

  @override
  String get authFooterNoAccount => '계정이 없으신가요?';

  @override
  String get authFooterHasAccount => '이미 계정이 있으신가요?';

  @override
  String get authSwitchToRegister => '회원가입';

  @override
  String get authSwitchToLogin => '로그인';

  @override
  String get authFieldEmail => '이메일';

  @override
  String get authFieldPassword => '비밀번호';

  @override
  String get authFieldPasswordConfirm => '비밀번호 확인';

  @override
  String get authFieldFullName => '이름';

  @override
  String get authHintEmail => 'you@school.edu';

  @override
  String get authHintPasswordDots => '••••••••';

  @override
  String get authHintPasswordMin => '최소 8자';

  @override
  String get authHintConfirmPassword => '비밀번호 다시 입력';

  @override
  String get authHintNameExample => '홍길동';

  @override
  String get authButtonLogin => '로그인';

  @override
  String get authButtonRegister => '계정 만들기';

  @override
  String get authSocialGoogleLoginDemo => 'Google 로그인 (데모)';

  @override
  String get authSocialKakaoLoginDemo => '카카오톡 로그인 (데모)';

  @override
  String get authSocialGoogleRegisterDemo => 'Google 회원가입 (데모)';

  @override
  String get authSocialKakaoRegisterDemo => '카카오톡 회원가입 (데모)';

  @override
  String get authSocialOr => '또는';

  @override
  String get authSocialContinueGoogle => 'Google로 계속';

  @override
  String get authSocialKakaoLabel => '카카오톡 ID';

  @override
  String get authValidationEmailEmpty => '이메일을 입력하세요';

  @override
  String get authValidationEmailInvalid => '이메일 형식이 올바르지 않습니다';

  @override
  String get authValidationPasswordEmpty => '비밀번호를 입력하세요';

  @override
  String get authValidationPasswordMin => '비밀번호는 최소 8자입니다';

  @override
  String get authValidationNameEmpty => '이름을 입력하세요';

  @override
  String get authValidationNameShort => '이름이 너무 짧습니다';

  @override
  String get authValidationConfirmEmpty => '비밀번호를 확인하세요';

  @override
  String get authValidationConfirmMismatch => '비밀번호가 일치하지 않습니다';

  @override
  String get authValidationUniversityEmail => '제휴 대학교의 .ac.kr 이메일을 사용해 주세요';

  @override
  String get authValidationLocalPart => '영문자, 숫자, . _ - 만 사용 가능합니다';

  @override
  String get authTooltipShowPassword => '비밀번호 표시';

  @override
  String get authTooltipHidePassword => '비밀번호 숨기기';

  @override
  String get languageSheetSubtitle => '원하는 앱 언어를 선택하세요';

  @override
  String get mapPinFormTitle => '장소 저장';

  @override
  String get mapPinSectionVisibility => '공개 범위';

  @override
  String get mapPinSectionType => '장소 유형';

  @override
  String get mapPinSectionName => '장소 이름 *';

  @override
  String get mapPinSectionNotes => '친구에게 남기는 메모';

  @override
  String get mapPinSectionRating => '별점';

  @override
  String get mapPinSectionPhotos => '사진';

  @override
  String get mapPinNameHint => '예: O. Sáu 콩나물국밥';

  @override
  String get mapPinNotesHint => '가격, 분위기, 메뉴… 솔직하게 공유해요!';

  @override
  String get mapPinVisibilityPublic => '공개 — 모든 학생에게 보임';

  @override
  String get mapPinVisibilityPrivate => '나만 보기';

  @override
  String get mapPinSaveFail => '저장에 실패했습니다. 다시 시도하세요.';

  @override
  String get mapPinAddPhoto => '사진 추가';

  @override
  String get mapPinSaveButton => '장소 저장';

  @override
  String get mapPinEditTitle => '장소 수정';

  @override
  String get mapPinSaveChanges => '변경 저장';

  @override
  String get mapPinDeleteConfirmTitle => '핀을 삭제하시겠습니까?';

  @override
  String get mapPinDeleteConfirmMessage => '이 핀이 지도에서 영구적으로 삭제됩니다.';

  @override
  String get mapPinDeletedToast => '핀이 삭제되었습니다';

  @override
  String get mapPinUpdatedToast => '핀이 수정되었습니다';

  @override
  String get mapPinSuccessTitle => '저장되었습니다!';

  @override
  String get mapPinShareTitle => '이 장소를 공유할까요?';

  @override
  String get mapPinShareMessage => '맛집, 하우징, 또는 캠퍼스 근처 편의 장소를 저장하세요.';

  @override
  String get mapPinShareAction => '이 장소 저장';

  @override
  String get mapLocationServicesDisabled => '위치 서비스를 켜주세요.';

  @override
  String get mapLocationPermissionRequired => '위치 권한이 필요합니다.';

  @override
  String get statusFetchingLocation => '위치를 가져오는 중…';

  @override
  String get mapUnavailable => '지도를 사용할 수 없음';

  @override
  String get mapSdkInitializing => '네이버 지도 SDK 초기화 중…';

  @override
  String mapSdkError(String error) {
    return '오류: $error';
  }

  @override
  String get mapPinInfoPublicShort => '공개';

  @override
  String get pinTypeRestaurant => '맛집';

  @override
  String get pinTypeRealEstate => '하우징';

  @override
  String get pinTypeUtility => '기타 편의시설';

  @override
  String get pinTypePharmacy => '약국';

  @override
  String get partnerSearchTitle => '언어 파트너';

  @override
  String get partnerGenderAny => '전체';

  @override
  String get partnerGenderMale => '남성';

  @override
  String get partnerGenderFemale => '여성';

  @override
  String get partnerEmptyTitle => '파트너를 찾을 수 없음';

  @override
  String get partnerEmptySubtitle => '필터를 변경해 보세요.';

  @override
  String get partnerOnline => '온라인';

  @override
  String get partnerSendRequest => '요청 보내기';

  @override
  String get partnerPending => '대기 중…';

  @override
  String get partnerAccepted => '수락됨!';

  @override
  String get partnerOpenChat => '메시지 보내기';

  @override
  String get partnerRequestSentSuccess => '요청을 보냈습니다.';

  @override
  String get partnerRequestNotSignedIn => '로그인한 후 요청을 보내세요.';

  @override
  String get partnerRequestProfileMissing => '이 사용자의 프로필이 없습니다.';

  @override
  String get partnerRequestAlreadyPending => '이미 이 사용자에게 보낸 대기 중인 요청이 있습니다.';

  @override
  String get partnerRequestIncomingPending =>
      '상대방이 이미 요청을 보냈습니다. Chat 탭에서 수락하세요.';

  @override
  String get partnerRequestAlreadyAccepted => '이미 연결되어 있습니다.';

  @override
  String get partnerRequestFailed => '요청을 보낼 수 없습니다. 다시 시도하세요.';

  @override
  String get chatSearchConversations => '대화 검색…';

  @override
  String get chatEmptyTitle => '아직 대화가 없습니다';

  @override
  String get chatEmptySubtitle => '언어 파트너를 찾아 대화를 시작하세요!';

  @override
  String get chatFindPartnerButton => '파트너 찾기';

  @override
  String get chatFilterFindPartner => '언어 파트너 찾기';

  @override
  String get chatFilterGender => '성별';

  @override
  String get chatFilterTargetLanguage => '배우고 싶은 언어';

  @override
  String get chatFilterFindPartners => '파트너 찾기';

  @override
  String get chatRequestPending => '요청 대기 중…';

  @override
  String get chatRequestsIncoming => '받은 요청';

  @override
  String get chatRequestBannerSubtitle => '연결 요청을 보냈습니다 👋';

  @override
  String get chatRequestAccept => '수락';

  @override
  String get chatRequestDecline => '거절';

  @override
  String get chatFilterLanguageAny => '전체';

  @override
  String get chatDisconnectedListSubtitle => 'Paused — open chat to reconnect';

  @override
  String get chatDisconnectMenu => 'Pause connection';

  @override
  String get chatDisconnectConfirmTitle => 'Pause this chat?';

  @override
  String get chatDisconnectConfirmBody =>
      'You will not be able to send messages until you reconnect. You can reopen this chat anytime and tap Reconnect.';

  @override
  String get chatSoftUnmatchMenu => '연결 끊기';

  @override
  String get chatSoftUnmatchConfirmTitle => '연결을 끊을까요?';

  @override
  String get chatSoftUnmatchConfirmBody =>
      '연결을 끊으시겠습니까? 나중에 검색에서 이 사람을 다시 찾을 수 있습니다.';

  @override
  String get chatReconnect => 'Reconnect';

  @override
  String get chatDisconnectedBanner =>
      'Connection paused. Reconnect to send messages.';

  @override
  String get chatSendBlockedDisconnected => 'Reconnect to send messages.';

  @override
  String get chatDisconnectSuccess => 'Chat paused.';

  @override
  String get chatReconnectSuccess => 'Connection restored.';

  @override
  String get chatShareLocation => '위치 공유';

  @override
  String get chatOpenInMap => '지도에서 보기';

  @override
  String get authSuccessLogin => '다시 오신 것을 환영합니다!';

  @override
  String get authSuccessRegister => '가입 완료! 이메일을 인증해 주세요.';

  @override
  String get authErrInvalidCredential => '이메일 또는 비밀번호가 올바르지 않습니다';

  @override
  String get authErrWrongPassword => '비밀번호가 올바르지 않습니다';

  @override
  String get authErrTooManyRequests => '시도 횟수가 너무 많습니다. 나중에 다시 시도하세요';

  @override
  String get authErrUserDisabled => '이 계정은 비활성화되었습니다';

  @override
  String get authErrEmailInUse => '이미 등록된 이메일입니다';

  @override
  String get authErrInvalidEmail => '유효하지 않은 이메일 주소입니다';

  @override
  String get authErrWeakPassword => '비밀번호가 너무 약합니다 (최소 6자)';

  @override
  String authErrDefault(String message) {
    return '인증 실패: $message';
  }

  @override
  String get verifyEmailTitle => '받은 편지함을 확인하세요';

  @override
  String verifyEmailSubtitle(String email) {
    return '$email로 인증 링크를 보냈습니다. 링크를 클릭하여 계정을 활성화하세요.';
  }

  @override
  String get verifyEmailCheckButton => '이미 인증했습니다';

  @override
  String get verifyEmailResendButton => '이메일 재전송';

  @override
  String get verifyEmailResendSent => '인증 이메일이 전송되었습니다!';

  @override
  String verifyEmailResendCooldown(int seconds) {
    return '$seconds초 후 재전송';
  }

  @override
  String get authSuccessVerified => '이메일이 인증되었습니다! 로그인하세요.';

  @override
  String get verifyEmailNotYet => '아직 이메일이 인증되지 않았습니다. 받은 편지함을 확인하세요.';

  @override
  String get errorChatRequestNotFound => '이 요청이 더 이상 존재하지 않습니다.';

  @override
  String get errorChatRequestNotPending => '이 요청은 이미 처리되었습니다.';

  @override
  String get errorTransactionAborted => '연결이 바쁩니다 — 다시 시도해 주세요.';

  @override
  String get errorNetwork => '네트워크 오류. 연결을 확인하세요.';

  @override
  String get errorPermissionDenied => '이 작업을 수행할 권한이 없습니다.';

  @override
  String get errorNotFound => '요청한 항목을 찾을 수 없습니다.';

  @override
  String get errorDataConflict => '데이터 충돌. 새로고침 후 다시 시도해 주세요.';

  @override
  String get errorUnexpected => '예기치 않은 오류가 발생했습니다. 다시 시도해 주세요.';

  @override
  String mapDistanceFromYouMeters(int meters) {
    return '내 위치에서 ${meters}m';
  }

  @override
  String mapDistanceFromYouKilometers(String km) {
    return '내 위치에서 ${km}km';
  }

  @override
  String get postMenuEdit => '수정';

  @override
  String get postMenuDelete => '삭제';

  @override
  String get postUpdateSuccess => '게시물이 수정되었습니다';

  @override
  String get postEditSheetTitle => '게시물 수정';

  @override
  String get postEditTitleLabel => '제목';

  @override
  String get postEditContentLabel => '내용';

  @override
  String get postEditUpdateBtn => '수정';

  @override
  String get postDeleteSuccess => '게시물이 삭제되었습니다';

  @override
  String get postDeleteTitle => '게시물 삭제';

  @override
  String get postDeleteMessage => '이 게시물을 삭제하시겠습니까? 이 작업은 취소할 수 없습니다.';

  @override
  String get postDeleteCancel => '취소';

  @override
  String get postDeleteConfirm => '삭제';

  @override
  String get postTranslating => '번역 중…';

  @override
  String get postShowOriginal => '원문 보기';

  @override
  String get postTranslate => '번역';
}
