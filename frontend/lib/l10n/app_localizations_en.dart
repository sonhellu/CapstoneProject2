// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Capstone';

  @override
  String get homeTitle => 'Home';

  @override
  String get counterLabel => 'You have pushed the button this many times:';

  @override
  String get incrementTooltip => 'Increment';

  @override
  String get languagePickerTooltip => 'Language';

  @override
  String get languageSheetTitle => 'Choose language';

  @override
  String get navHome => 'Home';

  @override
  String get navMap => 'Map';

  @override
  String get navCommunity => 'Community';

  @override
  String get navMyPage => 'My Page';

  @override
  String get mapSearchHere => 'Search here';

  @override
  String get mapMyLocation => 'My Location';

  @override
  String get mapPinSpot => 'Pin this spot';

  @override
  String get mapGetDirections => 'Get directions';

  @override
  String get mapDirections => 'Directions';

  @override
  String get btnConfirm => 'Confirm';

  @override
  String get btnCancel => 'Cancel';

  @override
  String get btnSave => 'Save';

  @override
  String get btnEdit => 'Edit';

  @override
  String get btnDelete => 'Delete';

  @override
  String get btnClose => 'Close';

  @override
  String get btnNext => 'Next';

  @override
  String get btnBack => 'Back';

  @override
  String get filterAll => 'All';

  @override
  String get filterRestaurants => 'Restaurants';

  @override
  String get filterRealEstate => 'Real Estate';

  @override
  String get filterConvenience => 'Convenience';

  @override
  String get filterAtm => 'ATMs';

  @override
  String get statusLoadingMap => 'Loading map…';

  @override
  String get statusLocating => 'Locating…';

  @override
  String get statusPermissionDenied => 'Permission denied';

  @override
  String get statusEnableGps => 'Please enable GPS';

  @override
  String get foodMenu => 'Menu';

  @override
  String get foodPrice => 'Price';

  @override
  String get foodHours => 'Hours';

  @override
  String get foodHalal => 'Halal';

  @override
  String get foodVeggie => 'Veggie';

  @override
  String get foodAuthentic => 'Authentic';

  @override
  String get housingRent => 'Rent';

  @override
  String get housingDeposit => 'Deposit';

  @override
  String get housingFee => 'Mgmt Fee';

  @override
  String get housingNoDeposit => 'No Deposit';

  @override
  String get housingStationNearby => 'Near Station';

  @override
  String get actionCall => 'Call';

  @override
  String get actionMessage => 'Message';

  @override
  String get actionReview => 'Review';

  @override
  String get actionShare => 'Share';

  @override
  String get actionPhoto => 'Photo';

  @override
  String distanceAway(String distance) {
    return '$distance away';
  }

  @override
  String minWalk(String time) {
    return '$time min walk';
  }

  @override
  String get alertEnterName => 'Enter name';

  @override
  String get alertWrongPhone => 'Wrong number';

  @override
  String get alertNotFound => 'Not found';

  @override
  String get alertTryAgain => 'Try again';

  @override
  String get alertLoginFirst => 'Login first';

  @override
  String get profileMyProfile => 'My Profile';

  @override
  String get profileEdit => 'Edit Profile';

  @override
  String get profileMyPosts => 'My Posts';

  @override
  String get profileSavedPlaces => 'Saved Places';

  @override
  String get profileLogout => 'Logout';

  @override
  String get profileDeleteAccount => 'Delete Account';

  @override
  String get chatMessages => 'Messages';

  @override
  String get chatTyping => 'Typing…';

  @override
  String get chatSent => 'Sent';

  @override
  String get chatDelivered => 'Delivered';

  @override
  String get chatRead => 'Read';

  @override
  String get chatCall => 'Call';

  @override
  String get chatStartConversation => 'Start a conversation';

  @override
  String get communityPostStory => 'Post a story';

  @override
  String get communityWhatsOnMind => 'What\'s on your mind?';

  @override
  String get communityPublic => 'Public';

  @override
  String get communityPrivate => 'Private';

  @override
  String get communityAnonymous => 'Anonymous';

  @override
  String get communityReport => 'Report';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsDarkMode => 'Dark Mode';

  @override
  String get settingsTerms => 'Terms of Service';

  @override
  String get settingsPrivacy => 'Privacy Policy';

  @override
  String get settingsHelp => 'Help Center';

  @override
  String get settingsVersion => 'Version';

  @override
  String get timeJustNow => 'Just now';

  @override
  String timeMinAgo(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString mins ago',
      one: '1 min ago',
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
      other: '$countString hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String get timeYesterday => 'Yesterday';
}
