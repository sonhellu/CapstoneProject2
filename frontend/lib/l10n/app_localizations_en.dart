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
  String get mapPinSaved => 'Saved';

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
  String get filterPharmacy => 'Pharmacy';

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

  @override
  String get homeViewAll => 'View All';

  @override
  String get homeIntlNews => 'International News 🌏';

  @override
  String get homeCampusLife => 'Campus Life 🇰🇷';

  @override
  String get profilePersonalInfo => 'Personal Information';

  @override
  String get profileEditInfo => 'Edit Information';

  @override
  String get profileNativeLang => 'Native Language';

  @override
  String get profileUniversity => 'University';

  @override
  String get profileMajor => 'Major';

  @override
  String get profileNationality => 'Nationality';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileFullName => 'Full Name';

  @override
  String get profileVerified => 'Verified';

  @override
  String get profileLogoutConfirm => 'Are you sure you want to sign out?';

  @override
  String get profileSaveChanges => 'Save Changes';

  @override
  String get communityBoardTitle => 'Community Board';

  @override
  String get communitySearchHint => 'Search posts, authors…';

  @override
  String communityPostCount(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString posts',
      one: '1 post',
    );
    return '$_temp0';
  }

  @override
  String get communitySortRecent => 'Recent';

  @override
  String get communitySortPopular => 'Popular';

  @override
  String get communityNoPosts => 'No posts found';

  @override
  String get createPostNew => 'New Post';

  @override
  String get createPostCategory => 'Category';

  @override
  String get createPostTitleLabel => 'Title';

  @override
  String get createPostTitleHint => 'Enter a clear, concise title…';

  @override
  String get createPostLanguage => 'Post Language';

  @override
  String get createPostContent => 'Content';

  @override
  String get createPostContentHint => 'Write your post here…';

  @override
  String get createPostPhotos => 'Photos';

  @override
  String get createPostAddPhoto => 'Add';

  @override
  String get createPostGallery => 'Gallery';

  @override
  String get createPostCamera => 'Camera';

  @override
  String get createPostPublish => 'Publish Post';

  @override
  String get postCopied => 'Copied to clipboard';

  @override
  String get postFollow => 'Follow';

  @override
  String get postFollowing => 'Following';

  @override
  String get postActionCopy => 'Copy';

  @override
  String get postActionLike => 'Like';

  @override
  String get postActionComment => 'Comment';

  @override
  String get postActionSave => 'Save';

  @override
  String get postNoImage => 'No image';

  @override
  String get reviewsTitle => 'Reviews';

  @override
  String reviewsCount(int count) {
    return '$count reviews';
  }

  @override
  String get reviewNoItems => 'No reviews yet. Be the first!';

  @override
  String get reviewWriteHint => 'Write a review…';

  @override
  String get reviewSubmit => 'Submit';

  @override
  String get reviewSeeAll => 'See all';

  @override
  String reviewTimeAgo(int n, String unit) {
    return '$n $unit ago';
  }

  @override
  String get reviewTimeUnitMinute => 'min';

  @override
  String get reviewTimeUnitHour => 'hr';

  @override
  String get reviewTimeUnitDay => 'day';

  @override
  String get authHeaderTitle => 'Hello, international student!';

  @override
  String get authHeaderSubtitle =>
      'Together, let\'s conquer your global learning journey.';

  @override
  String get authLoginTitle => 'Sign in';

  @override
  String get authLoginSubtitle => 'Enter your email and password to continue.';

  @override
  String get authRegisterTitle => 'Sign up';

  @override
  String get authRegisterSubtitle =>
      'Create an account to unlock your study abroad journey.';

  @override
  String get authFooterNoAccount => 'Don\'t have an account?';

  @override
  String get authFooterHasAccount => 'Already have an account?';

  @override
  String get authSwitchToRegister => 'Sign up';

  @override
  String get authSwitchToLogin => 'Sign in';

  @override
  String get authFieldEmail => 'Email';

  @override
  String get authFieldPassword => 'Password';

  @override
  String get authFieldPasswordConfirm => 'Confirm password';

  @override
  String get authFieldFullName => 'Full name';

  @override
  String get authHintEmail => 'you@school.edu';

  @override
  String get authHintPasswordDots => '••••••••';

  @override
  String get authHintPasswordMin => 'At least 8 characters';

  @override
  String get authHintConfirmPassword => 'Re-enter password';

  @override
  String get authHintNameExample => 'Jane Doe';

  @override
  String get authButtonLogin => 'Sign in';

  @override
  String get authButtonRegister => 'Create account';

  @override
  String get authSocialGoogleLoginDemo => 'Google sign-in (demo)';

  @override
  String get authSocialKakaoLoginDemo => 'KakaoTalk sign-in (demo)';

  @override
  String get authSocialGoogleRegisterDemo => 'Google sign-up (demo)';

  @override
  String get authSocialKakaoRegisterDemo => 'KakaoTalk sign-up (demo)';

  @override
  String get authSocialOr => 'or';

  @override
  String get authSocialContinueGoogle => 'Continue with Google';

  @override
  String get authSocialKakaoLabel => 'KakaoTalk ID';

  @override
  String get authValidationEmailEmpty => 'Please enter email';

  @override
  String get authValidationEmailInvalid => 'Invalid email';

  @override
  String get authValidationPasswordEmpty => 'Please enter password';

  @override
  String get authValidationPasswordMin =>
      'Password must be at least 8 characters';

  @override
  String get authValidationNameEmpty => 'Please enter your name';

  @override
  String get authValidationNameShort => 'Name is too short';

  @override
  String get authValidationConfirmEmpty => 'Please confirm password';

  @override
  String get authValidationConfirmMismatch => 'Passwords do not match';

  @override
  String get authTooltipShowPassword => 'Show password';

  @override
  String get authTooltipHidePassword => 'Hide password';

  @override
  String get languageSheetSubtitle => 'Choose your preferred app language';

  @override
  String get mapPinFormTitle => 'Pin location';

  @override
  String get mapPinSectionVisibility => 'Visibility';

  @override
  String get mapPinSectionType => 'Place type';

  @override
  String get mapPinSectionName => 'Place name *';

  @override
  String get mapPinSectionNotes => 'Notes for friends';

  @override
  String get mapPinSectionRating => 'Rating';

  @override
  String get mapPinSectionPhotos => 'Photos';

  @override
  String get mapPinNameHint => 'e.g. O. Sáu beef noodle';

  @override
  String get mapPinNotesHint => 'Price, vibe, dishes… share honestly!';

  @override
  String get mapPinVisibilityPublic => 'Public — visible to all students';

  @override
  String get mapPinVisibilityPrivate => 'Only me';

  @override
  String get mapPinSaveFail => 'Save failed. Please try again.';

  @override
  String get mapPinAddPhoto => 'Add photo';

  @override
  String get mapPinSaveButton => 'Save place';

  @override
  String get mapPinEditTitle => 'Edit place';

  @override
  String get mapPinSaveChanges => 'Save changes';

  @override
  String get mapPinDeleteConfirmTitle => 'Delete pin?';

  @override
  String get mapPinDeleteConfirmMessage =>
      'This will permanently remove the pin from the map.';

  @override
  String get mapPinDeletedToast => 'Pin deleted';

  @override
  String get mapPinUpdatedToast => 'Pin updated';

  @override
  String get mapPinSuccessTitle => 'Pinned successfully!';

  @override
  String get mapPinShareTitle => 'Share this place?';

  @override
  String get mapPinShareMessage =>
      'Pin a great eatery, housing, or a handy spot near campus.';

  @override
  String get mapPinShareAction => 'Pin this place';

  @override
  String get mapLocationServicesDisabled => 'Please enable location services.';

  @override
  String get mapLocationPermissionRequired =>
      'Location permission is required.';

  @override
  String get statusFetchingLocation => 'Fetching your location';

  @override
  String get mapUnavailable => 'Map unavailable';

  @override
  String get mapSdkInitializing => 'Initializing Naver Map SDK…';

  @override
  String mapSdkError(String error) {
    return 'Error: $error';
  }

  @override
  String get mapPinInfoPublicShort => 'Public';

  @override
  String get pinTypeRestaurant => 'Good eats';

  @override
  String get pinTypeRealEstate => 'Housing';

  @override
  String get pinTypeUtility => 'Other utilities';

  @override
  String get pinTypePharmacy => 'Pharmacy';

  @override
  String get partnerSearchTitle => 'Language partners';

  @override
  String get partnerGenderAny => 'Any';

  @override
  String get partnerGenderMale => 'Male';

  @override
  String get partnerGenderFemale => 'Female';

  @override
  String get partnerEmptyTitle => 'No partners found';

  @override
  String get partnerEmptySubtitle => 'Try changing your filter settings.';

  @override
  String get partnerOnline => 'Online';

  @override
  String get partnerSendRequest => 'Send request';

  @override
  String get partnerPending => 'Pending…';

  @override
  String get partnerAccepted => 'Accepted!';

  @override
  String get chatSearchConversations => 'Search conversations…';

  @override
  String get chatEmptyTitle => 'No conversations yet';

  @override
  String get chatEmptySubtitle => 'Find a language partner to start chatting!';

  @override
  String get chatFindPartnerButton => 'Find partner';

  @override
  String get chatFilterFindPartner => 'Find language partner';

  @override
  String get chatFilterGender => 'Gender';

  @override
  String get chatFilterTargetLanguage => 'Target language to learn';

  @override
  String get chatFilterFindPartners => 'Find partners';

  @override
  String get chatRequestPending => 'Request pending…';

  @override
  String get chatFilterLanguageAny => 'Any';
}
