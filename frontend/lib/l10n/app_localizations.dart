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

  /// Section header: link to see all posts
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get homeViewAll;

  /// Home screen: international section title
  ///
  /// In en, this message translates to:
  /// **'International News 🌏'**
  String get homeIntlNews;

  /// Home screen: campus section title
  ///
  /// In en, this message translates to:
  /// **'Campus Life 🇰🇷'**
  String get homeCampusLife;

  /// Profile card title
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get profilePersonalInfo;

  /// Profile edit card title
  ///
  /// In en, this message translates to:
  /// **'Edit Information'**
  String get profileEditInfo;

  /// Profile field label
  ///
  /// In en, this message translates to:
  /// **'Native Language'**
  String get profileNativeLang;

  /// Profile field label
  ///
  /// In en, this message translates to:
  /// **'University'**
  String get profileUniversity;

  /// Profile field label
  ///
  /// In en, this message translates to:
  /// **'Major'**
  String get profileMajor;

  /// Profile field label
  ///
  /// In en, this message translates to:
  /// **'Nationality'**
  String get profileNationality;

  /// Profile field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmail;

  /// Profile edit field label
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get profileFullName;

  /// Profile badge: university-verified email
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get profileVerified;

  /// Logout confirmation dialog body
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get profileLogoutConfirm;

  /// Profile edit save button
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get profileSaveChanges;

  /// Post list screen title
  ///
  /// In en, this message translates to:
  /// **'Community Board'**
  String get communityBoardTitle;

  /// Post list search field hint
  ///
  /// In en, this message translates to:
  /// **'Search posts, authors…'**
  String get communitySearchHint;

  /// Post count label
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 post} other{{count} posts}}'**
  String communityPostCount(num count);

  /// Sort chip: newest first
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get communitySortRecent;

  /// Sort chip: most likes
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get communitySortPopular;

  /// Post list empty state
  ///
  /// In en, this message translates to:
  /// **'No posts found'**
  String get communityNoPosts;

  /// Create post screen app bar title
  ///
  /// In en, this message translates to:
  /// **'New Post'**
  String get createPostNew;

  /// Create post: category section label
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get createPostCategory;

  /// Create post: title field label
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get createPostTitleLabel;

  /// Create post: title field hint
  ///
  /// In en, this message translates to:
  /// **'Enter a clear, concise title…'**
  String get createPostTitleHint;

  /// Create post: language picker label
  ///
  /// In en, this message translates to:
  /// **'Post Language'**
  String get createPostLanguage;

  /// Create post: content field label
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get createPostContent;

  /// Create post: content field hint
  ///
  /// In en, this message translates to:
  /// **'Write your post here…'**
  String get createPostContentHint;

  /// Create post: photos section label
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get createPostPhotos;

  /// Create post: add photo button
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get createPostAddPhoto;

  /// Create post: gallery bottom bar button
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get createPostGallery;

  /// Create post: camera bottom bar button
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get createPostCamera;

  /// Create post: submit button
  ///
  /// In en, this message translates to:
  /// **'Publish Post'**
  String get createPostPublish;

  /// Snackbar after copying post content
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get postCopied;

  /// Follow button: not yet following
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get postFollow;

  /// Follow button: already following
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get postFollowing;

  /// Post detail action: copy text
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get postActionCopy;

  /// Post card image error placeholder
  ///
  /// In en, this message translates to:
  /// **'No image'**
  String get postNoImage;

  /// No description provided for @authHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Hello, international student!'**
  String get authHeaderTitle;

  /// No description provided for @authHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Together, let\'s conquer your global learning journey.'**
  String get authHeaderSubtitle;

  /// No description provided for @authLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authLoginTitle;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and password to continue.'**
  String get authLoginSubtitle;

  /// No description provided for @authRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get authRegisterTitle;

  /// No description provided for @authRegisterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create an account to unlock your study abroad journey.'**
  String get authRegisterSubtitle;

  /// No description provided for @authFooterNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get authFooterNoAccount;

  /// No description provided for @authFooterHasAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authFooterHasAccount;

  /// No description provided for @authSwitchToRegister.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get authSwitchToRegister;

  /// No description provided for @authSwitchToLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSwitchToLogin;

  /// No description provided for @authFieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authFieldEmail;

  /// No description provided for @authFieldPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authFieldPassword;

  /// No description provided for @authFieldPasswordConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authFieldPasswordConfirm;

  /// No description provided for @authFieldFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get authFieldFullName;

  /// No description provided for @authHintEmail.
  ///
  /// In en, this message translates to:
  /// **'you@school.edu'**
  String get authHintEmail;

  /// No description provided for @authHintPasswordDots.
  ///
  /// In en, this message translates to:
  /// **'••••••••'**
  String get authHintPasswordDots;

  /// No description provided for @authHintPasswordMin.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get authHintPasswordMin;

  /// No description provided for @authHintConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Re-enter password'**
  String get authHintConfirmPassword;

  /// No description provided for @authHintNameExample.
  ///
  /// In en, this message translates to:
  /// **'Jane Doe'**
  String get authHintNameExample;

  /// No description provided for @authButtonLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authButtonLogin;

  /// No description provided for @authButtonRegister.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authButtonRegister;

  /// No description provided for @authSocialGoogleLoginDemo.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in (demo)'**
  String get authSocialGoogleLoginDemo;

  /// No description provided for @authSocialKakaoLoginDemo.
  ///
  /// In en, this message translates to:
  /// **'KakaoTalk sign-in (demo)'**
  String get authSocialKakaoLoginDemo;

  /// No description provided for @authSocialGoogleRegisterDemo.
  ///
  /// In en, this message translates to:
  /// **'Google sign-up (demo)'**
  String get authSocialGoogleRegisterDemo;

  /// No description provided for @authSocialKakaoRegisterDemo.
  ///
  /// In en, this message translates to:
  /// **'KakaoTalk sign-up (demo)'**
  String get authSocialKakaoRegisterDemo;

  /// No description provided for @authSocialOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get authSocialOr;

  /// No description provided for @authSocialContinueGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authSocialContinueGoogle;

  /// No description provided for @authSocialKakaoLabel.
  ///
  /// In en, this message translates to:
  /// **'KakaoTalk ID'**
  String get authSocialKakaoLabel;

  /// No description provided for @authValidationEmailEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter email'**
  String get authValidationEmailEmpty;

  /// No description provided for @authValidationEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get authValidationEmailInvalid;

  /// No description provided for @authValidationPasswordEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter password'**
  String get authValidationPasswordEmpty;

  /// No description provided for @authValidationPasswordMin.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get authValidationPasswordMin;

  /// No description provided for @authValidationNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get authValidationNameEmpty;

  /// No description provided for @authValidationNameShort.
  ///
  /// In en, this message translates to:
  /// **'Name is too short'**
  String get authValidationNameShort;

  /// No description provided for @authValidationConfirmEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please confirm password'**
  String get authValidationConfirmEmpty;

  /// No description provided for @authValidationConfirmMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get authValidationConfirmMismatch;

  /// No description provided for @authTooltipShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authTooltipShowPassword;

  /// No description provided for @authTooltipHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authTooltipHidePassword;

  /// No description provided for @languageSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred app language'**
  String get languageSheetSubtitle;

  /// No description provided for @mapPinFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Pin location'**
  String get mapPinFormTitle;

  /// No description provided for @mapPinSectionVisibility.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get mapPinSectionVisibility;

  /// No description provided for @mapPinSectionType.
  ///
  /// In en, this message translates to:
  /// **'Place type'**
  String get mapPinSectionType;

  /// No description provided for @mapPinSectionName.
  ///
  /// In en, this message translates to:
  /// **'Place name *'**
  String get mapPinSectionName;

  /// No description provided for @mapPinSectionNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes for friends'**
  String get mapPinSectionNotes;

  /// No description provided for @mapPinSectionRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get mapPinSectionRating;

  /// No description provided for @mapPinSectionPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get mapPinSectionPhotos;

  /// No description provided for @mapPinNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. O. Sáu beef noodle'**
  String get mapPinNameHint;

  /// No description provided for @mapPinNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Price, vibe, dishes… share honestly!'**
  String get mapPinNotesHint;

  /// No description provided for @mapPinVisibilityPublic.
  ///
  /// In en, this message translates to:
  /// **'Public — visible to all students'**
  String get mapPinVisibilityPublic;

  /// No description provided for @mapPinVisibilityPrivate.
  ///
  /// In en, this message translates to:
  /// **'Only me'**
  String get mapPinVisibilityPrivate;

  /// No description provided for @mapPinSaveFail.
  ///
  /// In en, this message translates to:
  /// **'Save failed. Please try again.'**
  String get mapPinSaveFail;

  /// No description provided for @mapPinAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get mapPinAddPhoto;

  /// No description provided for @mapPinSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save place'**
  String get mapPinSaveButton;

  /// No description provided for @mapPinSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Pinned successfully!'**
  String get mapPinSuccessTitle;

  /// No description provided for @mapPinShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share this place?'**
  String get mapPinShareTitle;

  /// No description provided for @mapPinShareMessage.
  ///
  /// In en, this message translates to:
  /// **'Pin a great eatery, housing, or a handy spot near campus.'**
  String get mapPinShareMessage;

  /// No description provided for @mapPinShareAction.
  ///
  /// In en, this message translates to:
  /// **'Pin this place'**
  String get mapPinShareAction;

  /// No description provided for @mapLocationServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Please enable location services.'**
  String get mapLocationServicesDisabled;

  /// No description provided for @mapLocationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required.'**
  String get mapLocationPermissionRequired;

  /// No description provided for @statusFetchingLocation.
  ///
  /// In en, this message translates to:
  /// **'Fetching your location'**
  String get statusFetchingLocation;

  /// No description provided for @mapUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Map unavailable'**
  String get mapUnavailable;

  /// No description provided for @mapSdkInitializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing Naver Map SDK…'**
  String get mapSdkInitializing;

  /// No description provided for @mapSdkError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String mapSdkError(String error);

  /// No description provided for @mapPinInfoPublicShort.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get mapPinInfoPublicShort;

  /// No description provided for @pinTypeRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Good eats'**
  String get pinTypeRestaurant;

  /// No description provided for @pinTypeRealEstate.
  ///
  /// In en, this message translates to:
  /// **'Housing'**
  String get pinTypeRealEstate;

  /// No description provided for @pinTypeUtility.
  ///
  /// In en, this message translates to:
  /// **'Other utilities'**
  String get pinTypeUtility;

  /// No description provided for @partnerSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Language partners'**
  String get partnerSearchTitle;

  /// No description provided for @partnerGenderAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get partnerGenderAny;

  /// No description provided for @partnerGenderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get partnerGenderMale;

  /// No description provided for @partnerGenderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get partnerGenderFemale;

  /// No description provided for @partnerEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No partners found'**
  String get partnerEmptyTitle;

  /// No description provided for @partnerEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try changing your filter settings.'**
  String get partnerEmptySubtitle;

  /// No description provided for @partnerOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get partnerOnline;

  /// No description provided for @partnerSendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get partnerSendRequest;

  /// No description provided for @partnerPending.
  ///
  /// In en, this message translates to:
  /// **'Pending…'**
  String get partnerPending;

  /// No description provided for @partnerAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted!'**
  String get partnerAccepted;

  /// No description provided for @chatSearchConversations.
  ///
  /// In en, this message translates to:
  /// **'Search conversations…'**
  String get chatSearchConversations;

  /// No description provided for @chatEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get chatEmptyTitle;

  /// No description provided for @chatEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find a language partner to start chatting!'**
  String get chatEmptySubtitle;

  /// No description provided for @chatFindPartnerButton.
  ///
  /// In en, this message translates to:
  /// **'Find partner'**
  String get chatFindPartnerButton;

  /// No description provided for @chatFilterFindPartner.
  ///
  /// In en, this message translates to:
  /// **'Find language partner'**
  String get chatFilterFindPartner;

  /// No description provided for @chatFilterGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get chatFilterGender;

  /// No description provided for @chatFilterTargetLanguage.
  ///
  /// In en, this message translates to:
  /// **'Target language to learn'**
  String get chatFilterTargetLanguage;

  /// No description provided for @chatFilterFindPartners.
  ///
  /// In en, this message translates to:
  /// **'Find partners'**
  String get chatFilterFindPartners;

  /// No description provided for @chatRequestPending.
  ///
  /// In en, this message translates to:
  /// **'Request pending…'**
  String get chatRequestPending;

  /// No description provided for @chatFilterLanguageAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get chatFilterLanguageAny;
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
