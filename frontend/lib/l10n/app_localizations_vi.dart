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

  @override
  String get navHome => 'Trang chủ';

  @override
  String get navMap => 'Bản đồ';

  @override
  String get navCommunity => 'Cộng đồng';

  @override
  String get navMyPage => 'Cá nhân';

  @override
  String get mapSearchHere => 'Tìm khu vực này';

  @override
  String get mapMyLocation => 'Vị trí của tôi';

  @override
  String get mapPinSpot => 'Ghim địa điểm';

  @override
  String get mapGetDirections => 'Chỉ đường';

  @override
  String get mapDirections => 'Chỉ đường';

  @override
  String get mapPinSaved => 'Đã lưu';

  @override
  String get btnConfirm => 'Xác nhận';

  @override
  String get btnCancel => 'Hủy';

  @override
  String get btnSave => 'Lưu';

  @override
  String get btnEdit => 'Chỉnh sửa';

  @override
  String get btnDelete => 'Xóa';

  @override
  String get btnClose => 'Đóng';

  @override
  String get btnNext => 'Tiếp theo';

  @override
  String get btnBack => 'Quay lại';

  @override
  String get filterAll => 'Tất cả';

  @override
  String get filterRestaurants => 'Nhà hàng';

  @override
  String get filterRealEstate => 'Bất động sản';

  @override
  String get filterConvenience => 'Tiện lợi';

  @override
  String get filterAtm => 'ATM';

  @override
  String get filterPharmacy => 'Nhà thuốc';

  @override
  String get statusLoadingMap => 'Đang tải bản đồ…';

  @override
  String get statusLocating => 'Đang định vị…';

  @override
  String get statusPermissionDenied => 'Quyền truy cập bị từ chối';

  @override
  String get statusEnableGps => 'Vui lòng bật GPS';

  @override
  String get foodMenu => 'Thực đơn';

  @override
  String get foodPrice => 'Giá';

  @override
  String get foodHours => 'Giờ mở cửa';

  @override
  String get foodHalal => 'Halal';

  @override
  String get foodVeggie => 'Chay';

  @override
  String get foodAuthentic => 'Chuẩn vị';

  @override
  String get housingRent => 'Tiền thuê';

  @override
  String get housingDeposit => 'Đặt cọc';

  @override
  String get housingFee => 'Phí QL';

  @override
  String get housingNoDeposit => 'Không cọc';

  @override
  String get housingStationNearby => 'Gần ga';

  @override
  String get actionCall => 'Gọi';

  @override
  String get actionMessage => 'Nhắn tin';

  @override
  String get actionReview => 'Đánh giá';

  @override
  String get actionShare => 'Chia sẻ';

  @override
  String get actionPhoto => 'Ảnh';

  @override
  String distanceAway(String distance) {
    return 'Cách $distance';
  }

  @override
  String minWalk(String time) {
    return 'Đi bộ $time phút';
  }

  @override
  String get alertEnterName => 'Nhập tên';

  @override
  String get alertWrongPhone => 'Sai số ĐT';

  @override
  String get alertNotFound => 'Không tìm thấy';

  @override
  String get alertTryAgain => 'Thử lại';

  @override
  String get alertLoginFirst => 'Đăng nhập trước';

  @override
  String get profileMyProfile => 'Trang cá nhân';

  @override
  String get profileEdit => 'Chỉnh sửa';

  @override
  String get profileMyPosts => 'Bài viết của tôi';

  @override
  String get profileSavedPlaces => 'Địa điểm đã lưu';

  @override
  String get profileLogout => 'Đăng xuất';

  @override
  String get profileDeleteAccount => 'Xóa tài khoản';

  @override
  String get chatMessages => 'Tin nhắn';

  @override
  String get chatTyping => 'Đang nhập…';

  @override
  String get chatSent => 'Đã gửi';

  @override
  String get chatDelivered => 'Đã nhận';

  @override
  String get chatRead => 'Đã xem';

  @override
  String get chatCall => 'Gọi';

  @override
  String get chatStartConversation => 'Bắt đầu trò chuyện';

  @override
  String get communityPostStory => 'Đăng bài';

  @override
  String get communityWhatsOnMind => 'Bạn đang nghĩ gì?';

  @override
  String get communityPublic => 'Công khai';

  @override
  String get communityPrivate => 'Riêng tư';

  @override
  String get communityAnonymous => 'Ẩn danh';

  @override
  String get communityReport => 'Báo cáo';

  @override
  String get settingsLanguage => 'Ngôn ngữ';

  @override
  String get settingsNotifications => 'Thông báo';

  @override
  String get settingsDarkMode => 'Chế độ tối';

  @override
  String get settingsTerms => 'Điều khoản dịch vụ';

  @override
  String get settingsPrivacy => 'Chính sách bảo mật';

  @override
  String get settingsHelp => 'Trung tâm hỗ trợ';

  @override
  String get settingsVersion => 'Phiên bản';

  @override
  String get timeJustNow => 'Vừa xong';

  @override
  String timeMinAgo(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString phút trước',
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
      other: '$countString giờ trước',
    );
    return '$_temp0';
  }

  @override
  String get timeYesterday => 'Hôm qua';

  @override
  String get homeViewAll => 'Xem tất cả';

  @override
  String get homeIntlNews => 'Tin quốc tế 🌏';

  @override
  String get homeCampusLife => 'Cuộc sống campus 🇰🇷';

  @override
  String get profilePersonalInfo => 'Thông tin cá nhân';

  @override
  String get profileEditInfo => 'Chỉnh sửa thông tin';

  @override
  String get profileNativeLang => 'Ngôn ngữ mẹ đẻ';

  @override
  String get profileUniversity => 'Trường đại học';

  @override
  String get profileMajor => 'Chuyên ngành';

  @override
  String get profileNationality => 'Quốc tịch';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileFullName => 'Họ và tên';

  @override
  String get profileVerified => 'Đã xác minh';

  @override
  String get profileLogoutConfirm => 'Bạn có chắc muốn đăng xuất không?';

  @override
  String get profileSaveChanges => 'Lưu thay đổi';

  @override
  String get communityBoardTitle => 'Bảng cộng đồng';

  @override
  String get communitySearchHint => 'Tìm bài viết, tác giả…';

  @override
  String communityPostCount(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString bài viết',
    );
    return '$_temp0';
  }

  @override
  String get communitySortRecent => 'Mới nhất';

  @override
  String get communitySortPopular => 'Phổ biến';

  @override
  String get communityNoPosts => 'Không tìm thấy bài viết';

  @override
  String get createPostNew => 'Bài viết mới';

  @override
  String get createPostCategory => 'Danh mục';

  @override
  String get createPostTitleLabel => 'Tiêu đề';

  @override
  String get createPostTitleHint => 'Nhập tiêu đề rõ ràng, súc tích…';

  @override
  String get createPostLanguage => 'Ngôn ngữ bài viết';

  @override
  String get createPostContent => 'Nội dung';

  @override
  String get createPostContentHint => 'Viết bài của bạn tại đây…';

  @override
  String get createPostPhotos => 'Ảnh';

  @override
  String get createPostAddPhoto => 'Thêm';

  @override
  String get createPostGallery => 'Thư viện ảnh';

  @override
  String get createPostCamera => 'Camera';

  @override
  String get createPostPublish => 'Đăng bài';

  @override
  String get postCopied => 'Đã sao chép vào bộ nhớ tạm';

  @override
  String get postFollow => 'Theo dõi';

  @override
  String get postFollowing => 'Đang theo dõi';

  @override
  String get postActionCopy => 'Sao chép';

  @override
  String get postActionLike => 'Thích';

  @override
  String get postActionComment => 'Bình luận';

  @override
  String get postActionSave => 'Lưu';

  @override
  String get postNoImage => 'Không có ảnh';

  @override
  String get reviewsTitle => 'Đánh giá';

  @override
  String reviewsCount(int count) {
    return '$count đánh giá';
  }

  @override
  String get reviewNoItems => 'Chưa có đánh giá nào. Hãy là người đầu tiên!';

  @override
  String get reviewWriteHint => 'Viết nhận xét…';

  @override
  String get reviewSubmit => 'Gửi';

  @override
  String get reviewSeeAll => 'Xem thêm';

  @override
  String reviewTimeAgo(int n, String unit) {
    return '$n $unit trước';
  }

  @override
  String get reviewTimeUnitMinute => 'phút';

  @override
  String get reviewTimeUnitHour => 'giờ';

  @override
  String get reviewTimeUnitDay => 'ngày';

  @override
  String get authHeaderTitle => 'Chào bạn, du học sinh!';

  @override
  String get authHeaderSubtitle =>
      'Cùng nhau chinh phục hành trình học tập toàn cầu.';

  @override
  String get authLoginTitle => 'Đăng nhập';

  @override
  String get authLoginSubtitle => 'Nhập email và mật khẩu để tiếp tục.';

  @override
  String get authRegisterTitle => 'Đăng ký';

  @override
  String get authRegisterSubtitle =>
      'Tạo tài khoản để mở khóa lộ trình du học.';

  @override
  String get authFooterNoAccount => 'Chưa có tài khoản?';

  @override
  String get authFooterHasAccount => 'Đã có tài khoản?';

  @override
  String get authSwitchToRegister => 'Đăng ký';

  @override
  String get authSwitchToLogin => 'Đăng nhập';

  @override
  String get authFieldEmail => 'Email';

  @override
  String get authFieldPassword => 'Mật khẩu';

  @override
  String get authFieldPasswordConfirm => 'Xác nhận mật khẩu';

  @override
  String get authFieldFullName => 'Họ và tên';

  @override
  String get authHintEmail => 'ten.email@duhoc.vn';

  @override
  String get authHintPasswordDots => '••••••••';

  @override
  String get authHintPasswordMin => 'Ít nhất 8 ký tự';

  @override
  String get authHintConfirmPassword => 'Nhập lại mật khẩu';

  @override
  String get authHintNameExample => 'Nguyễn Văn A';

  @override
  String get authButtonLogin => 'Đăng nhập';

  @override
  String get authButtonRegister => 'Tạo tài khoản';

  @override
  String get authSocialGoogleLoginDemo => 'Đăng nhập Google (demo)';

  @override
  String get authSocialKakaoLoginDemo => 'Đăng nhập KakaoTalk (demo)';

  @override
  String get authSocialGoogleRegisterDemo => 'Đăng ký với Google (demo)';

  @override
  String get authSocialKakaoRegisterDemo => 'Đăng ký với KakaoTalk (demo)';

  @override
  String get authSocialOr => 'hoặc';

  @override
  String get authSocialContinueGoogle => 'Tiếp tục với Google';

  @override
  String get authSocialKakaoLabel => 'KakaoTalk ID';

  @override
  String get authValidationEmailEmpty => 'Vui lòng nhập email';

  @override
  String get authValidationEmailInvalid => 'Email không hợp lệ';

  @override
  String get authValidationPasswordEmpty => 'Vui lòng nhập mật khẩu';

  @override
  String get authValidationPasswordMin => 'Mật khẩu cần ít nhất 8 ký tự';

  @override
  String get authValidationNameEmpty => 'Vui lòng nhập họ tên';

  @override
  String get authValidationNameShort => 'Họ tên quá ngắn';

  @override
  String get authValidationConfirmEmpty => 'Vui lòng xác nhận mật khẩu';

  @override
  String get authValidationConfirmMismatch => 'Mật khẩu xác nhận không khớp';

  @override
  String get authValidationUniversityEmail =>
      'Vui lòng sử dụng email đuôi .ac.kr từ các trường đại học liên kết';

  @override
  String get authValidationLocalPart => 'Chỉ được dùng chữ cái, số, . _ -';

  @override
  String get authTooltipShowPassword => 'Hiện mật khẩu';

  @override
  String get authTooltipHidePassword => 'Ẩn mật khẩu';

  @override
  String get languageSheetSubtitle => 'Chọn ngôn ngữ hiển thị ưa thích';

  @override
  String get mapPinFormTitle => 'Ghim địa điểm';

  @override
  String get mapPinSectionVisibility => 'Chế độ hiển thị';

  @override
  String get mapPinSectionType => 'Loại địa điểm';

  @override
  String get mapPinSectionName => 'Tên địa điểm *';

  @override
  String get mapPinSectionNotes => 'Cảm nhận / Lưu ý cho bạn bè';

  @override
  String get mapPinSectionRating => 'Đánh giá';

  @override
  String get mapPinSectionPhotos => 'Ảnh thực tế';

  @override
  String get mapPinNameHint => 'VD: Quán bún bò O. Sáu';

  @override
  String get mapPinNotesHint =>
      'Giá cả, không khí, món ngon… chia sẻ thật lòng nhé!';

  @override
  String get mapPinVisibilityPublic => 'Công khai — mọi sinh viên đều thấy';

  @override
  String get mapPinVisibilityPrivate => 'Chỉ mình tôi';

  @override
  String get mapPinSaveFail => 'Lưu thất bại. Vui lòng thử lại.';

  @override
  String get mapPinAddPhoto => 'Thêm ảnh';

  @override
  String get mapPinSaveButton => 'Lưu địa điểm';

  @override
  String get mapPinEditTitle => 'Sửa địa điểm';

  @override
  String get mapPinSaveChanges => 'Lưu thay đổi';

  @override
  String get mapPinDeleteConfirmTitle => 'Xóa ghim?';

  @override
  String get mapPinDeleteConfirmMessage =>
      'Ghim này sẽ bị xóa vĩnh viễn khỏi bản đồ.';

  @override
  String get mapPinDeletedToast => 'Đã xóa ghim';

  @override
  String get mapPinUpdatedToast => 'Đã cập nhật ghim';

  @override
  String get mapPinSuccessTitle => 'Đã ghim thành công!';

  @override
  String get mapPinShareTitle => 'Bạn muốn chia sẻ địa điểm này?';

  @override
  String get mapPinShareMessage =>
      'Ghim một quán ăn ngon, phòng trọ tốt hay tiện ích gần trường.';

  @override
  String get mapPinShareAction => 'Ghim địa điểm này?';

  @override
  String get mapLocationServicesDisabled => 'Vui lòng bật dịch vụ định vị.';

  @override
  String get mapLocationPermissionRequired => 'Cần quyền truy cập vị trí.';

  @override
  String get statusFetchingLocation => 'Đang lấy vị trí của bạn…';

  @override
  String get mapUnavailable => 'Không thể tải bản đồ';

  @override
  String get mapSdkInitializing => 'Đang khởi tạo Naver Map SDK…';

  @override
  String mapSdkError(String error) {
    return 'Lỗi: $error';
  }

  @override
  String get mapPinInfoPublicShort => 'Công khai';

  @override
  String get pinTypeRestaurant => 'Quán ăn ngon';

  @override
  String get pinTypeRealEstate => 'Bất động sản tốt';

  @override
  String get pinTypeUtility => 'Tiện ích khác';

  @override
  String get pinTypePharmacy => 'Nhà thuốc';

  @override
  String get partnerSearchTitle => 'Tìm partner ngôn ngữ';

  @override
  String get partnerGenderAny => 'Tất cả';

  @override
  String get partnerGenderMale => 'Nam';

  @override
  String get partnerGenderFemale => 'Nữ';

  @override
  String get partnerEmptyTitle => 'Không tìm thấy partner';

  @override
  String get partnerEmptySubtitle => 'Thử đổi bộ lọc.';

  @override
  String get partnerOnline => 'Online';

  @override
  String get partnerSendRequest => 'Gửi lời mời';

  @override
  String get partnerPending => 'Đang chờ…';

  @override
  String get partnerAccepted => 'Đã chấp nhận!';

  @override
  String get partnerRequestSentSuccess => 'Đã gửi lời mời.';

  @override
  String get partnerRequestNotSignedIn => 'Vui lòng đăng nhập để gửi lời mời.';

  @override
  String get partnerRequestProfileMissing => 'Người này chưa có hồ sơ.';

  @override
  String get partnerRequestAlreadyPending =>
      'Bạn đã có lời mời đang chờ với người này.';

  @override
  String get partnerRequestIncomingPending =>
      'Họ đã gửi lời mời cho bạn. Mở tab Chat để chấp nhận.';

  @override
  String get partnerRequestAlreadyAccepted => 'Hai bạn đã kết nối rồi.';

  @override
  String get partnerRequestPreviouslyDeclined =>
      'Lời mời trước đã bị từ chối. Chưa thể gửi lại.';

  @override
  String get partnerRequestFailed =>
      'Không gửi được lời mời. Vui lòng thử lại.';

  @override
  String get chatSearchConversations => 'Tìm cuộc trò chuyện…';

  @override
  String get chatEmptyTitle => 'Chưa có cuộc trò chuyện';

  @override
  String get chatEmptySubtitle => 'Tìm partner ngôn ngữ để bắt đầu chat!';

  @override
  String get chatFindPartnerButton => 'Tìm partner';

  @override
  String get chatFilterFindPartner => 'Tìm partner ngôn ngữ';

  @override
  String get chatFilterGender => 'Giới tính';

  @override
  String get chatFilterTargetLanguage => 'Ngôn ngữ muốn học';

  @override
  String get chatFilterFindPartners => 'Tìm partner';

  @override
  String get chatRequestPending => 'Đang chờ phản hồi…';

  @override
  String get chatRequestsIncoming => 'Lời mời kết bạn';

  @override
  String get chatRequestBannerSubtitle => 'Muốn kết nối với bạn 👋';

  @override
  String get chatRequestAccept => 'Chấp nhận';

  @override
  String get chatRequestDecline => 'Từ chối';

  @override
  String get chatFilterLanguageAny => 'Tất cả';

  @override
  String get chatDisconnectedListSubtitle =>
      'Da tam ngat — mo chat de ket noi lai';

  @override
  String get chatDisconnectMenu => 'Tam ngat ket noi';

  @override
  String get chatDisconnectConfirmTitle => 'Tam ngat cuoc tro chuyen?';

  @override
  String get chatDisconnectConfirmBody =>
      'Ban se khong gui tin duoc cho den khi ket noi lai. Luon co the mo lai cuoc tro chuyen va chon Ket noi lai.';

  @override
  String get chatReconnect => 'Ket noi lai';

  @override
  String get chatDisconnectedBanner =>
      'Da tam ngat ket noi. Ket noi lai de nhan tin.';

  @override
  String get chatSendBlockedDisconnected => 'Hay ket noi lai de gui tin.';

  @override
  String get chatDisconnectSuccess => 'Da tam ngat chat.';

  @override
  String get chatReconnectSuccess => 'Da ket noi lai.';

  @override
  String get authSuccessLogin => 'Chào mừng trở lại!';

  @override
  String get authSuccessRegister =>
      'Đăng ký thành công! Vui lòng xác thực email.';

  @override
  String get authErrInvalidCredential => 'Email hoặc mật khẩu không đúng';

  @override
  String get authErrWrongPassword => 'Mật khẩu không đúng';

  @override
  String get authErrTooManyRequests =>
      'Quá nhiều lần thử, vui lòng thử lại sau';

  @override
  String get authErrUserDisabled => 'Tài khoản này đã bị khóa';

  @override
  String get authErrEmailInUse => 'Email này đã được đăng ký';

  @override
  String get authErrInvalidEmail => 'Email không hợp lệ';

  @override
  String get authErrWeakPassword => 'Mật khẩu quá yếu (tối thiểu 6 ký tự)';

  @override
  String authErrDefault(String message) {
    return 'Xác thực thất bại: $message';
  }

  @override
  String get verifyEmailTitle => 'Kiểm tra hòm thư của bạn';

  @override
  String verifyEmailSubtitle(String email) {
    return 'Chúng tôi đã gửi link xác thực đến $email. Vui lòng nhấn vào link để kích hoạt tài khoản.';
  }

  @override
  String get verifyEmailCheckButton => 'Tôi đã xác thực rồi';

  @override
  String get verifyEmailResendButton => 'Gửi lại email';

  @override
  String get verifyEmailResendSent => 'Đã gửi email xác thực!';

  @override
  String verifyEmailResendCooldown(int seconds) {
    return 'Gửi lại sau ${seconds}s';
  }

  @override
  String get authSuccessVerified => 'Email đã xác thực! Vui lòng đăng nhập.';

  @override
  String get verifyEmailNotYet =>
      'Email chưa được xác thực. Vui lòng kiểm tra hộp thư.';

  @override
  String get errorChatRequestNotFound => 'Lời mời này không còn tồn tại.';

  @override
  String get errorChatRequestNotPending => 'Lời mời này đã được xử lý.';

  @override
  String get errorTransactionAborted => 'Kết nối bận — vui lòng thử lại.';

  @override
  String get errorNetwork => 'Lỗi mạng. Kiểm tra kết nối của bạn.';

  @override
  String get errorPermissionDenied =>
      'Bạn không có quyền thực hiện thao tác này.';

  @override
  String get errorNotFound => 'Không tìm thấy mục yêu cầu.';

  @override
  String get errorDataConflict =>
      'Xung đột dữ liệu. Vui lòng làm mới và thử lại.';

  @override
  String get errorUnexpected =>
      'Đã xảy ra lỗi không mong muốn. Vui lòng thử lại.';

  @override
  String mapDistanceFromYouMeters(int meters) {
    return 'Cách bạn ${meters}m';
  }

  @override
  String mapDistanceFromYouKilometers(String km) {
    return 'Cách bạn ${km}km';
  }

  @override
  String get postMenuEdit => 'Chỉnh sửa';

  @override
  String get postMenuDelete => 'Xóa';

  @override
  String get postUpdateSuccess => 'Bài viết đã được cập nhật';

  @override
  String get postEditSheetTitle => 'Chỉnh sửa bài viết';

  @override
  String get postEditTitleLabel => 'Tiêu đề';

  @override
  String get postEditContentLabel => 'Nội dung';

  @override
  String get postEditUpdateBtn => 'Cập nhật';

  @override
  String get postDeleteSuccess => 'Đã xóa bài viết';

  @override
  String get postDeleteTitle => 'Xóa bài viết';

  @override
  String get postDeleteMessage =>
      'Bạn có chắc muốn xóa bài viết này? Hành động này không thể hoàn tác.';

  @override
  String get postDeleteCancel => 'Hủy';

  @override
  String get postDeleteConfirm => 'Xóa';

  @override
  String get postTranslating => 'Đang dịch…';

  @override
  String get postShowOriginal => 'Xem bản gốc';

  @override
  String get postTranslate => 'Dịch';
}
