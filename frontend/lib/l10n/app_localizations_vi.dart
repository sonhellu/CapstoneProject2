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
}
