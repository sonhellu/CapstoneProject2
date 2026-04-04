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

  @override
  String get navHome => '首页';

  @override
  String get navMap => '地图';

  @override
  String get navCommunity => '社区';

  @override
  String get navMyPage => '我的';

  @override
  String get mapSearchHere => '搜索此处';

  @override
  String get mapMyLocation => '我的位置';

  @override
  String get mapPinSpot => '标记此地';

  @override
  String get mapGetDirections => '获取路线';

  @override
  String get mapDirections => '导航';

  @override
  String get btnConfirm => '确认';

  @override
  String get btnCancel => '取消';

  @override
  String get btnSave => '保存';

  @override
  String get btnEdit => '编辑';

  @override
  String get btnDelete => '删除';

  @override
  String get btnClose => '关闭';

  @override
  String get btnNext => '下一步';

  @override
  String get btnBack => '返回';

  @override
  String get filterAll => '全部';

  @override
  String get filterRestaurants => '餐厅';

  @override
  String get filterRealEstate => '房产';

  @override
  String get filterConvenience => '便利店';

  @override
  String get filterAtm => 'ATM';

  @override
  String get statusLoadingMap => '地图加载中…';

  @override
  String get statusLocating => '定位中…';

  @override
  String get statusPermissionDenied => '权限被拒绝';

  @override
  String get statusEnableGps => '请开启GPS';

  @override
  String get foodMenu => '菜单';

  @override
  String get foodPrice => '价格';

  @override
  String get foodHours => '营业时间';

  @override
  String get foodHalal => '清真';

  @override
  String get foodVeggie => '素食';

  @override
  String get foodAuthentic => '正宗';

  @override
  String get housingRent => '月租';

  @override
  String get housingDeposit => '押金';

  @override
  String get housingFee => '管理费';

  @override
  String get housingNoDeposit => '免押金';

  @override
  String get housingStationNearby => '近地铁';

  @override
  String get actionCall => '拨打';

  @override
  String get actionMessage => '发消息';

  @override
  String get actionReview => '评价';

  @override
  String get actionShare => '分享';

  @override
  String get actionPhoto => '照片';

  @override
  String distanceAway(String distance) {
    return '距此$distance';
  }

  @override
  String minWalk(String time) {
    return '步行$time分钟';
  }

  @override
  String get alertEnterName => '请输入姓名';

  @override
  String get alertWrongPhone => '号码有误';

  @override
  String get alertNotFound => '未找到';

  @override
  String get alertTryAgain => '请重试';

  @override
  String get alertLoginFirst => '请先登录';

  @override
  String get profileMyProfile => '我的主页';

  @override
  String get profileEdit => '编辑资料';

  @override
  String get profileMyPosts => '我的帖子';

  @override
  String get profileSavedPlaces => '收藏地点';

  @override
  String get profileLogout => '退出登录';

  @override
  String get profileDeleteAccount => '注销账号';

  @override
  String get chatMessages => '消息';

  @override
  String get chatTyping => '正在输入…';

  @override
  String get chatSent => '已发送';

  @override
  String get chatDelivered => '已送达';

  @override
  String get chatRead => '已读';

  @override
  String get chatCall => '通话';

  @override
  String get chatStartConversation => '开始聊天吧';

  @override
  String get communityPostStory => '发布动态';

  @override
  String get communityWhatsOnMind => '你在想什么？';

  @override
  String get communityPublic => '公开';

  @override
  String get communityPrivate => '仅自己';

  @override
  String get communityAnonymous => '匿名';

  @override
  String get communityReport => '举报';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsNotifications => '通知';

  @override
  String get settingsDarkMode => '深色模式';

  @override
  String get settingsTerms => '服务条款';

  @override
  String get settingsPrivacy => '隐私政策';

  @override
  String get settingsHelp => '帮助中心';

  @override
  String get settingsVersion => '版本';

  @override
  String get timeJustNow => '刚刚';

  @override
  String timeMinAgo(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString分钟前',
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
      other: '$countString小时前',
    );
    return '$_temp0';
  }

  @override
  String get timeYesterday => '昨天';
}
