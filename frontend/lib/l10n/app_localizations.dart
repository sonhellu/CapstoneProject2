import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_my.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('my'),
    Locale('vi'),
    Locale('zh'),
  ];

  /// Application title in task switcher
  ///
  /// In en, this message translates to:
  /// **'Capstone'**
  String get appTitle;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @counterLabel.
  ///
  /// In en, this message translates to:
  /// **'You have pushed the button this many times:'**
  String get counterLabel;

  /// No description provided for @incrementTooltip.
  ///
  /// In en, this message translates to:
  /// **'Increment'**
  String get incrementTooltip;

  /// No description provided for @languagePickerTooltip.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languagePickerTooltip;

  /// No description provided for @languageSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get languageSheetTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// No description provided for @navCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get navCommunity;

  /// No description provided for @navMyPage.
  ///
  /// In en, this message translates to:
  /// **'My Page'**
  String get navMyPage;

  /// No description provided for @mapSearchHere.
  ///
  /// In en, this message translates to:
  /// **'Search here'**
  String get mapSearchHere;

  /// No description provided for @mapMyLocation.
  ///
  /// In en, this message translates to:
  /// **'My Location'**
  String get mapMyLocation;

  /// No description provided for @mapPinSpot.
  ///
  /// In en, this message translates to:
  /// **'Pin this spot'**
  String get mapPinSpot;

  /// No description provided for @mapGetDirections.
  ///
  /// In en, this message translates to:
  /// **'Get directions'**
  String get mapGetDirections;

  /// No description provided for @mapDirections.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get mapDirections;

  /// No description provided for @btnConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get btnConfirm;

  /// No description provided for @btnCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get btnCancel;

  /// No description provided for @btnSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get btnSave;

  /// No description provided for @btnEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get btnEdit;

  /// No description provided for @btnDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get btnDelete;

  /// No description provided for @btnClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get btnClose;

  /// No description provided for @btnNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get btnNext;

  /// No description provided for @btnBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get btnBack;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Restaurants'**
  String get filterRestaurants;

  /// No description provided for @filterRealEstate.
  ///
  /// In en, this message translates to:
  /// **'Real Estate'**
  String get filterRealEstate;

  /// No description provided for @filterConvenience.
  ///
  /// In en, this message translates to:
  /// **'Convenience'**
  String get filterConvenience;

  /// No description provided for @filterAtm.
  ///
  /// In en, this message translates to:
  /// **'ATMs'**
  String get filterAtm;

  /// No description provided for @statusLoadingMap.
  ///
  /// In en, this message translates to:
  /// **'Loading map…'**
  String get statusLoadingMap;

  /// No description provided for @statusLocating.
  ///
  /// In en, this message translates to:
  /// **'Locating…'**
  String get statusLocating;

  /// No description provided for @statusPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get statusPermissionDenied;

  /// No description provided for @statusEnableGps.
  ///
  /// In en, this message translates to:
  /// **'Please enable GPS'**
  String get statusEnableGps;

  /// Food detail: menu label
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get foodMenu;

  /// Food detail: price label
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get foodPrice;

  /// Food detail: opening hours
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get foodHours;

  /// Food badge: halal certified
  ///
  /// In en, this message translates to:
  /// **'Halal'**
  String get foodHalal;

  /// Food badge: vegetarian options
  ///
  /// In en, this message translates to:
  /// **'Veggie'**
  String get foodVeggie;

  /// Food badge: home-country cuisine
  ///
  /// In en, this message translates to:
  /// **'Authentic'**
  String get foodAuthentic;

  /// Housing: monthly rent (월세)
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get housingRent;

  /// Housing: security deposit (보증금)
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get housingDeposit;

  /// Housing: management fee (관리비)
  ///
  /// In en, this message translates to:
  /// **'Mgmt Fee'**
  String get housingFee;

  /// Housing badge: no deposit required
  ///
  /// In en, this message translates to:
  /// **'No Deposit'**
  String get housingNoDeposit;

  /// Housing badge: close to subway
  ///
  /// In en, this message translates to:
  /// **'Near Station'**
  String get housingStationNearby;

  /// Action button: phone call
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get actionCall;

  /// Action button: send message
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get actionMessage;

  /// Action button: write review
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get actionReview;

  /// Action button: share place
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get actionShare;

  /// Action button: view photos
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get actionPhoto;

  /// Distance from current location
  ///
  /// In en, this message translates to:
  /// **'{distance} away'**
  String distanceAway(String distance);

  /// Walking time
  ///
  /// In en, this message translates to:
  /// **'{time} min walk'**
  String minWalk(String time);

  /// Validation: name field is empty
  ///
  /// In en, this message translates to:
  /// **'Enter name'**
  String get alertEnterName;

  /// Validation: phone number is invalid
  ///
  /// In en, this message translates to:
  /// **'Wrong number'**
  String get alertWrongPhone;

  /// Search result: nothing found
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get alertNotFound;

  /// Generic retry prompt
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get alertTryAgain;

  /// Auth gate: must be logged in
  ///
  /// In en, this message translates to:
  /// **'Login first'**
  String get alertLoginFirst;

  /// Profile screen: section title
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get profileMyProfile;

  /// Profile: open edit mode
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profileEdit;

  /// Profile: user's own posts
  ///
  /// In en, this message translates to:
  /// **'My Posts'**
  String get profileMyPosts;

  /// Profile: bookmarked map pins
  ///
  /// In en, this message translates to:
  /// **'Saved Places'**
  String get profileSavedPlaces;

  /// Profile: sign out
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get profileLogout;

  /// Profile: permanently remove account
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get profileDeleteAccount;

  /// Chat tab / inbox title
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get chatMessages;

  /// Chat: other user is composing
  ///
  /// In en, this message translates to:
  /// **'Typing…'**
  String get chatTyping;

  /// Message status: sent to server
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get chatSent;

  /// Message status: reached recipient device
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get chatDelivered;

  /// Message status: opened by recipient
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get chatRead;

  /// Chat: voice/video call button
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get chatCall;

  /// Empty chat state prompt
  ///
  /// In en, this message translates to:
  /// **'Start a conversation'**
  String get chatStartConversation;

  /// Community: create a new post CTA
  ///
  /// In en, this message translates to:
  /// **'Post a story'**
  String get communityPostStory;

  /// Community: post input placeholder
  ///
  /// In en, this message translates to:
  /// **'What\'s on your mind?'**
  String get communityWhatsOnMind;

  /// Post visibility: everyone can see
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get communityPublic;

  /// Post visibility: only me
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get communityPrivate;

  /// Post option: hide identity
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get communityAnonymous;

  /// Community: flag content
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get communityReport;

  /// Settings: language picker row
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Settings: push notification toggle
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// Settings: theme toggle
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get settingsDarkMode;

  /// Settings: ToS link
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get settingsTerms;

  /// Settings: privacy policy link
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacy;

  /// Settings: support / FAQ
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get settingsHelp;

  /// Settings: app version label
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// Timestamp: posted seconds ago
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeJustNow;

  /// Timestamp: N minutes ago
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 min ago} other{{count} mins ago}}'**
  String timeMinAgo(num count);

  /// Timestamp: N hours ago
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String timeHourAgo(num count);

  /// Timestamp: posted yesterday
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get timeYesterday;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'en',
    'ja',
    'ko',
    'my',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'my':
      return AppLocalizationsMy();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
