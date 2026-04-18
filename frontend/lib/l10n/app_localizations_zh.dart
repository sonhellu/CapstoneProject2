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
  String get mapPinSaved => '已收藏';

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
  String get filterPharmacy => '药店';

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

  @override
  String get homeViewAll => '查看全部';

  @override
  String get homeIntlNews => '国际资讯 🌏';

  @override
  String get homeCampusLife => '校园生活 🇰🇷';

  @override
  String get profilePersonalInfo => '个人信息';

  @override
  String get profileEditInfo => '编辑信息';

  @override
  String get profileNativeLang => '母语';

  @override
  String get profileUniversity => '大学';

  @override
  String get profileMajor => '专业';

  @override
  String get profileNationality => '国籍';

  @override
  String get profileEmail => '邮箱';

  @override
  String get profileFullName => '姓名';

  @override
  String get profileVerified => '已认证';

  @override
  String get profileLogoutConfirm => '确定要退出登录吗？';

  @override
  String get profileSaveChanges => '保存更改';

  @override
  String get communityBoardTitle => '社区公告板';

  @override
  String get communitySearchHint => '搜索帖子、作者…';

  @override
  String communityPostCount(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString篇帖子',
    );
    return '$_temp0';
  }

  @override
  String get communitySortRecent => '最新';

  @override
  String get communitySortPopular => '热门';

  @override
  String get communityNoPosts => '未找到帖子';

  @override
  String get createPostNew => '新帖子';

  @override
  String get createPostCategory => '分类';

  @override
  String get createPostTitleLabel => '标题';

  @override
  String get createPostTitleHint => '请输入简洁明了的标题…';

  @override
  String get createPostLanguage => '帖子语言';

  @override
  String get createPostContent => '内容';

  @override
  String get createPostContentHint => '在此撰写您的帖子…';

  @override
  String get createPostPhotos => '照片';

  @override
  String get createPostAddPhoto => '添加';

  @override
  String get createPostGallery => '相册';

  @override
  String get createPostCamera => '拍照';

  @override
  String get createPostPublish => '发布';

  @override
  String get postCopied => '已复制到剪贴板';

  @override
  String get postFollow => '关注';

  @override
  String get postFollowing => '已关注';

  @override
  String get postActionCopy => '复制';

  @override
  String get postActionLike => '点赞';

  @override
  String get postActionComment => '评论';

  @override
  String get postActionSave => '收藏';

  @override
  String get postNoImage => '无图片';

  @override
  String get reviewsTitle => '评论';

  @override
  String reviewsCount(int count) {
    return '$count条评论';
  }

  @override
  String get reviewNoItems => '暂无评论，快来第一个吧！';

  @override
  String get reviewWriteHint => '写评论…';

  @override
  String get reviewSubmit => '提交';

  @override
  String get reviewSeeAll => '查看全部';

  @override
  String reviewTimeAgo(int n, String unit) {
    return '$n$unit前';
  }

  @override
  String get reviewTimeUnitMinute => '分钟';

  @override
  String get reviewTimeUnitHour => '小时';

  @override
  String get reviewTimeUnitDay => '天';

  @override
  String get authHeaderTitle => '你好，留学生！';

  @override
  String get authHeaderSubtitle => '一起开启你的全球学习之旅。';

  @override
  String get authLoginTitle => '登录';

  @override
  String get authLoginSubtitle => '请输入邮箱和密码。';

  @override
  String get authRegisterTitle => '注册';

  @override
  String get authRegisterSubtitle => '创建账号，开启留学生活。';

  @override
  String get authFooterNoAccount => '还没有账号？';

  @override
  String get authFooterHasAccount => '已有账号？';

  @override
  String get authSwitchToRegister => '注册';

  @override
  String get authSwitchToLogin => '登录';

  @override
  String get authFieldEmail => '邮箱';

  @override
  String get authFieldPassword => '密码';

  @override
  String get authFieldPasswordConfirm => '确认密码';

  @override
  String get authFieldFullName => '姓名';

  @override
  String get authHintEmail => 'you@school.edu';

  @override
  String get authHintPasswordDots => '••••••••';

  @override
  String get authHintPasswordMin => '至少 8 位';

  @override
  String get authHintConfirmPassword => '再次输入密码';

  @override
  String get authHintNameExample => '张三';

  @override
  String get authButtonLogin => '登录';

  @override
  String get authButtonRegister => '创建账号';

  @override
  String get authSocialGoogleLoginDemo => 'Google 登录（演示）';

  @override
  String get authSocialKakaoLoginDemo => 'KakaoTalk 登录（演示）';

  @override
  String get authSocialGoogleRegisterDemo => 'Google 注册（演示）';

  @override
  String get authSocialKakaoRegisterDemo => 'KakaoTalk 注册（演示）';

  @override
  String get authSocialOr => '或';

  @override
  String get authSocialContinueGoogle => '使用 Google 继续';

  @override
  String get authSocialKakaoLabel => 'KakaoTalk ID';

  @override
  String get authValidationEmailEmpty => '请输入邮箱';

  @override
  String get authValidationEmailInvalid => '邮箱格式不正确';

  @override
  String get authValidationPasswordEmpty => '请输入密码';

  @override
  String get authValidationPasswordMin => '密码至少 8 位';

  @override
  String get authValidationNameEmpty => '请输入姓名';

  @override
  String get authValidationNameShort => '姓名过短';

  @override
  String get authValidationConfirmEmpty => '请确认密码';

  @override
  String get authValidationConfirmMismatch => '两次密码不一致';

  @override
  String get authValidationUniversityEmail => '请使用合作大学的 .ac.kr 邮箱';

  @override
  String get authValidationLocalPart => '只能使用字母、数字、. _ -';

  @override
  String get authTooltipShowPassword => '显示密码';

  @override
  String get authTooltipHidePassword => '隐藏密码';

  @override
  String get languageSheetSubtitle => '选择你偏好的应用显示语言';

  @override
  String get mapPinFormTitle => '标记地点';

  @override
  String get mapPinSectionVisibility => '可见范围';

  @override
  String get mapPinSectionType => '地点类型';

  @override
  String get mapPinSectionName => '地点名称 *';

  @override
  String get mapPinSectionNotes => '给朋友的备注';

  @override
  String get mapPinSectionRating => '评分';

  @override
  String get mapPinSectionPhotos => '照片';

  @override
  String get mapPinNameHint => '例如：O. Sáu 牛肉粉';

  @override
  String get mapPinNotesHint => '价格、氛围、菜品… 真实分享！';

  @override
  String get mapPinVisibilityPublic => '公开 — 所有学生可见';

  @override
  String get mapPinVisibilityPrivate => '仅自己';

  @override
  String get mapPinSaveFail => '保存失败，请重试。';

  @override
  String get mapPinAddPhoto => '添加照片';

  @override
  String get mapPinSaveButton => '保存地点';

  @override
  String get mapPinEditTitle => '编辑地点';

  @override
  String get mapPinSaveChanges => '保存更改';

  @override
  String get mapPinDeleteConfirmTitle => '删除标记？';

  @override
  String get mapPinDeleteConfirmMessage => '此标记将从地图中永久删除。';

  @override
  String get mapPinDeletedToast => '已删除标记';

  @override
  String get mapPinUpdatedToast => '已更新标记';

  @override
  String get mapPinSuccessTitle => '标记成功！';

  @override
  String get mapPinShareTitle => '要分享这个地点吗？';

  @override
  String get mapPinShareMessage => '标记美食、房源或校园附近的便利地点。';

  @override
  String get mapPinShareAction => '标记此地点';

  @override
  String get mapLocationServicesDisabled => '请开启定位服务。';

  @override
  String get mapLocationPermissionRequired => '需要位置权限。';

  @override
  String get statusFetchingLocation => '正在获取你的位置…';

  @override
  String get mapUnavailable => '地图不可用';

  @override
  String get mapSdkInitializing => '正在初始化 Naver 地图 SDK…';

  @override
  String mapSdkError(String error) {
    return '错误：$error';
  }

  @override
  String get mapPinInfoPublicShort => '公开';

  @override
  String get pinTypeRestaurant => '美食';

  @override
  String get pinTypeRealEstate => '房源';

  @override
  String get pinTypeUtility => '其他设施';

  @override
  String get pinTypePharmacy => '药店';

  @override
  String get partnerSearchTitle => '语言伙伴';

  @override
  String get partnerGenderAny => '不限';

  @override
  String get partnerGenderMale => '男';

  @override
  String get partnerGenderFemale => '女';

  @override
  String get partnerEmptyTitle => '未找到伙伴';

  @override
  String get partnerEmptySubtitle => '试试更改筛选条件。';

  @override
  String get partnerOnline => '在线';

  @override
  String get partnerSendRequest => '发送请求';

  @override
  String get partnerPending => '等待中…';

  @override
  String get partnerAccepted => '已接受！';

  @override
  String get partnerOpenChat => '发送消息';

  @override
  String get partnerRequestSentSuccess => '请求已发送。';

  @override
  String get partnerRequestNotSignedIn => '请先登录再发送请求。';

  @override
  String get partnerRequestProfileMissing => '该用户暂无资料。';

  @override
  String get partnerRequestAlreadyPending => '您已向此人发送待处理的请求。';

  @override
  String get partnerRequestIncomingPending => '对方已向您发送请求。请打开“聊天”标签接受。';

  @override
  String get partnerRequestAlreadyAccepted => '你们已连接。';

  @override
  String get partnerRequestFailed => '无法发送请求，请重试。';

  @override
  String get chatSearchConversations => '搜索会话…';

  @override
  String get chatEmptyTitle => '暂无会话';

  @override
  String get chatEmptySubtitle => '寻找语言伙伴开始聊天吧！';

  @override
  String get chatFindPartnerButton => '找伙伴';

  @override
  String get chatFilterFindPartner => '寻找语言伙伴';

  @override
  String get chatFilterGender => '性别';

  @override
  String get chatFilterTargetLanguage => '想学的语言';

  @override
  String get chatFilterFindPartners => '查找伙伴';

  @override
  String get chatRequestPending => '请求待处理…';

  @override
  String get chatRequestsIncoming => '收到的请求';

  @override
  String get chatRequestBannerSubtitle => '想与你建立联系 👋';

  @override
  String get chatRequestAccept => '接受';

  @override
  String get chatRequestDecline => '拒绝';

  @override
  String get chatFilterLanguageAny => '不限';

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
  String get chatSoftUnmatchMenu => '断开连接';

  @override
  String get chatSoftUnmatchConfirmTitle => '断开连接？';

  @override
  String get chatSoftUnmatchConfirmBody => '确定要断开连接吗？之后仍可在搜索中找到此人。';

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
  String get chatShareLocation => '分享位置';

  @override
  String get chatOpenInMap => '在地图中查看';

  @override
  String get authSuccessLogin => '欢迎回来！';

  @override
  String get authSuccessRegister => '注册成功！请验证您的电子邮件。';

  @override
  String get authErrInvalidCredential => '电子邮件或密码不正确';

  @override
  String get authErrWrongPassword => '密码不正确';

  @override
  String get authErrTooManyRequests => '尝试次数过多，请稍后再试';

  @override
  String get authErrUserDisabled => '该账户已被禁用';

  @override
  String get authErrEmailInUse => '该邮箱已被注册';

  @override
  String get authErrInvalidEmail => '无效的电子邮件地址';

  @override
  String get authErrWeakPassword => '密码太弱（最少6个字符）';

  @override
  String authErrDefault(String message) {
    return '验证失败：$message';
  }

  @override
  String get verifyEmailTitle => '请查看您的收件箱';

  @override
  String verifyEmailSubtitle(String email) {
    return '我们已向 $email 发送了验证链接，请点击链接激活您的账户。';
  }

  @override
  String get verifyEmailCheckButton => '我已验证';

  @override
  String get verifyEmailResendButton => '重新发送邮件';

  @override
  String get verifyEmailResendSent => '验证邮件已发送！';

  @override
  String verifyEmailResendCooldown(int seconds) {
    return '$seconds秒后重新发送';
  }

  @override
  String get authSuccessVerified => '邮箱已验证！请登录。';

  @override
  String get verifyEmailNotYet => '邮箱尚未验证，请检查您的收件箱。';

  @override
  String get errorChatRequestNotFound => '此请求已不存在。';

  @override
  String get errorChatRequestNotPending => '此请求已被处理。';

  @override
  String get errorTransactionAborted => '连接繁忙 — 请重试。';

  @override
  String get errorNetwork => '网络错误，请检查您的连接。';

  @override
  String get errorPermissionDenied => '您没有执行此操作的权限。';

  @override
  String get errorNotFound => '未找到请求的内容。';

  @override
  String get errorDataConflict => '数据冲突，请刷新后重试。';

  @override
  String get errorUnexpected => '发生意外错误，请重试。';

  @override
  String mapDistanceFromYouMeters(int meters) {
    return '距您${meters}m';
  }

  @override
  String mapDistanceFromYouKilometers(String km) {
    return '距您${km}km';
  }

  @override
  String get postMenuEdit => '编辑';

  @override
  String get postMenuDelete => '删除';

  @override
  String get postUpdateSuccess => '帖子已更新';

  @override
  String get postEditSheetTitle => '编辑帖子';

  @override
  String get postEditTitleLabel => '标题';

  @override
  String get postEditContentLabel => '内容';

  @override
  String get postEditUpdateBtn => '更新';

  @override
  String get postDeleteSuccess => '帖子已删除';

  @override
  String get postDeleteTitle => '删除帖子';

  @override
  String get postDeleteMessage => '您确定要删除这篇帖子吗？此操作无法撤销。';

  @override
  String get postDeleteCancel => '取消';

  @override
  String get postDeleteConfirm => '删除';

  @override
  String get postTranslating => '翻译中…';

  @override
  String get postShowOriginal => '显示原文';

  @override
  String get postTranslate => '翻译';
}
