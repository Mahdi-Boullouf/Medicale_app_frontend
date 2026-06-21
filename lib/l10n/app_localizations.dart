import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

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
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @connectingToCall.
  ///
  /// In en, this message translates to:
  /// **'Connecting to call...'**
  String get connectingToCall;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirm;

  /// No description provided for @saveLabel.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveLabel;

  /// No description provided for @addLabel.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addLabel;

  /// No description provided for @addNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Add Note (Optional)'**
  String get addNoteOptional;

  /// No description provided for @vacationNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Summer Vacation'**
  String get vacationNoteHint;

  /// No description provided for @myVacations.
  ///
  /// In en, this message translates to:
  /// **'My Vacations'**
  String get myVacations;

  /// No description provided for @noVacationsPlanned.
  ///
  /// In en, this message translates to:
  /// **'No vacations planned'**
  String get noVacationsPlanned;

  /// No description provided for @vacationsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Vacations updated successfully'**
  String get vacationsUpdated;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @reportReason.
  ///
  /// In en, this message translates to:
  /// **'Report Reason'**
  String get reportReason;

  /// No description provided for @reviewWithin24h.
  ///
  /// In en, this message translates to:
  /// **'Our team will review within 24 hours'**
  String get reviewWithin24h;

  /// No description provided for @blockUserLabel.
  ///
  /// In en, this message translates to:
  /// **'Block User'**
  String get blockUserLabel;

  /// No description provided for @contentHiddenFromFeed.
  ///
  /// In en, this message translates to:
  /// **'Their content will be hidden from your feed'**
  String get contentHiddenFromFeed;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get locationPermissionDenied;

  /// No description provided for @noAppointmentsToExport.
  ///
  /// In en, this message translates to:
  /// **'No appointments to export'**
  String get noAppointmentsToExport;

  /// No description provided for @noAppointmentsInRange.
  ///
  /// In en, this message translates to:
  /// **'No appointments found in this date range'**
  String get noAppointmentsInRange;

  /// No description provided for @failedMarkAsRead.
  ///
  /// In en, this message translates to:
  /// **'Failed to mark as read'**
  String get failedMarkAsRead;

  /// No description provided for @reportReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Describe what is wrong with this content...'**
  String get reportReasonHint;

  /// No description provided for @reportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted'**
  String get reportSubmitted;

  /// No description provided for @userBlocked.
  ///
  /// In en, this message translates to:
  /// **'User blocked'**
  String get userBlocked;

  /// No description provided for @myWishlist.
  ///
  /// In en, this message translates to:
  /// **'My Wishlist'**
  String get myWishlist;

  /// No description provided for @selectAppointmentDateRange.
  ///
  /// In en, this message translates to:
  /// **'Select Appointment Date Range'**
  String get selectAppointmentDateRange;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'DocMobi'**
  String get appTitle;

  /// No description provided for @commune.
  ///
  /// In en, this message translates to:
  /// **'Commune'**
  String get commune;

  /// No description provided for @wilaya.
  ///
  /// In en, this message translates to:
  /// **'Wilaya'**
  String get wilaya;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// Button text to message a doctor
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// A welcome message
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// Settings label
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Label for changing language
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// English language name
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Arabic language name
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// Title for language selection dialog
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// French language name
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get french;

  /// Navigation label for Home
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Navigation label for Appointments
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get navAppointments;

  /// Navigation label for Reels
  ///
  /// In en, this message translates to:
  /// **'Reels'**
  String get navReels;

  /// Navigation label for Messages
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get navMessages;

  /// Navigation label for Profile
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// Profile menu item for Personal Info
  ///
  /// In en, this message translates to:
  /// **'Personal Info'**
  String get personalInfo;

  /// Title for patient appointments screen
  ///
  /// In en, this message translates to:
  /// **'My Appointment'**
  String get myAppointment;

  /// Profile menu item for My Dependents
  ///
  /// In en, this message translates to:
  /// **'My Dependents'**
  String get myDependents;

  /// Profile menu item for Appointment Setting
  ///
  /// In en, this message translates to:
  /// **'Appointment Setting'**
  String get appointmentSetting;

  /// Profile menu item for My Earning
  ///
  /// In en, this message translates to:
  /// **'My Earning'**
  String get myEarning;

  /// Profile menu item for Change Password
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordLabel;

  /// Profile menu item for Help & Support
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// Profile menu item for Log Out
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// General loading text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Text shown when checking login status
  ///
  /// In en, this message translates to:
  /// **'Checking authentication'**
  String get checkingAuth;

  /// Title for invalid session screen
  ///
  /// In en, this message translates to:
  /// **'Invalid Session'**
  String get invalidSession;

  /// Message for expired session
  ///
  /// In en, this message translates to:
  /// **'Your session is invalid.\nPlease login again.'**
  String get sessionExpiredMessage;

  /// Button to navigate to login
  ///
  /// In en, this message translates to:
  /// **'Go to Login'**
  String get goToLogin;

  /// Hint text for doctor search field
  ///
  /// In en, this message translates to:
  /// **'Search Doctor...'**
  String get searchDoctorHint;

  /// Title for location services disabled dialog
  ///
  /// In en, this message translates to:
  /// **'Location Services Disabled'**
  String get locationServicesDisabledTitle;

  /// Message for location services disabled dialog
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled. Please enable them to see nearby doctors.'**
  String get locationServicesDisabledMessage;

  /// Title for location permission required dialog
  ///
  /// In en, this message translates to:
  /// **'Location Permission Required'**
  String get locationPermissionRequiredTitle;

  /// Message for location permission required dialog
  ///
  /// In en, this message translates to:
  /// **'Location permission is required to show nearby doctors. Please grant permission in app settings.'**
  String get locationPermissionRequiredMessage;

  /// Button to open app/location settings
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// Button text to cancel appointment
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Text shown when loading map route
  ///
  /// In en, this message translates to:
  /// **'Loading route...'**
  String get loadingRoute;

  /// Message shown when directions API is unavailable
  ///
  /// In en, this message translates to:
  /// **'Directions API not enabled. Using straight line route.'**
  String get directionsApiDisabled;

  /// Retry button label
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Text shown while map is loading
  ///
  /// In en, this message translates to:
  /// **'Loading map...'**
  String get loadingMap;

  /// Label for distance
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// Section header for upcoming appointments
  ///
  /// In en, this message translates to:
  /// **'Upcoming Appointment'**
  String get upcomingAppointment;

  /// Section header for nearby doctors
  ///
  /// In en, this message translates to:
  /// **'Nearby Doctors'**
  String get nearbyDoctors;

  /// Button to see all items
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// Message shown when no doctors match criteria
  ///
  /// In en, this message translates to:
  /// **'No doctors found'**
  String get noDoctorsFound;

  /// Doctor availability status
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// Doctor unavailable status
  ///
  /// In en, this message translates to:
  /// **'No Schedule'**
  String get noSchedule;

  /// Label for video consultation availability
  ///
  /// In en, this message translates to:
  /// **'Video Consultation'**
  String get videoConsultation;

  /// Button text to book an appointment
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get bookNow;

  /// Status when booking is unavailable
  ///
  /// In en, this message translates to:
  /// **'Not Available'**
  String get notAvailable;

  /// Message when doctor has no schedule
  ///
  /// In en, this message translates to:
  /// **'No schedule set'**
  String get noScheduleSet;

  /// Error message when search fails
  ///
  /// In en, this message translates to:
  /// **'Search failed: {error}'**
  String searchFailed(String error);

  /// Title for session expired dialog
  ///
  /// In en, this message translates to:
  /// **'Session Expired'**
  String get sessionExpiredTitle;

  /// Message for session expired dialog
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please login again.'**
  String get sessionExpiredMessageDoc;

  /// OK button text
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Error message for post loading
  ///
  /// In en, this message translates to:
  /// **'Failed to load posts'**
  String get failedLoadPosts;

  /// General connection error message
  ///
  /// In en, this message translates to:
  /// **'Connection error. Please try again.'**
  String get connectionError;

  /// Hint text for search field in doctor home
  ///
  /// In en, this message translates to:
  /// **'Search doctors, posts, specialties...'**
  String get searchHintDoctor;

  /// Title for search suggestions
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get suggestions;

  /// Loading text during search
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searching;

  /// Empty state title for search
  ///
  /// In en, this message translates to:
  /// **'Search for anything'**
  String get searchAnything;

  /// Empty state subtitle for search
  ///
  /// In en, this message translates to:
  /// **'Find doctors, posts, or specialties'**
  String get findEverything;

  /// Message when no search results match
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// Advice for empty search results
  ///
  /// In en, this message translates to:
  /// **'Try searching with different keywords'**
  String get tryDifferentKeywords;

  /// Title for posts section
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get posts;

  /// Message when post list is empty
  ///
  /// In en, this message translates to:
  /// **'No posts yet. Be the first to share!'**
  String get noPostsYet;

  /// Hint text in create post box
  ///
  /// In en, this message translates to:
  /// **'Share your insights with fellow doctors...'**
  String get shareInsights;

  /// Label for photo action
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// Appointment type video
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// Label for reels action
  ///
  /// In en, this message translates to:
  /// **'Reels'**
  String get reels;

  /// Button to navigate to post creation
  ///
  /// In en, this message translates to:
  /// **'Create a Post'**
  String get createPost;

  /// Experience years label
  ///
  /// In en, this message translates to:
  /// **'{years} years of experience'**
  String yearsExperience(int years);

  /// Fallback text for doctor bio
  ///
  /// In en, this message translates to:
  /// **'No bio available'**
  String get noBioAvailable;

  /// Welcome message title
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// Login subtitle with user type
  ///
  /// In en, this message translates to:
  /// **'Please Login to your Account as {userType}'**
  String loginToAccountAs(String userType);

  /// Label for email field
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// Hint text for email field
  ///
  /// In en, this message translates to:
  /// **'you@gmail.com'**
  String get emailHint;

  /// Label for password field
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Hint text for password field
  ///
  /// In en, this message translates to:
  /// **'****************'**
  String get passwordHint;

  /// Text for forgot password link
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Button text for sign in
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// Text before signup link
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// Text for signup link
  ///
  /// In en, this message translates to:
  /// **'Signup'**
  String get signup;

  /// Success message after login
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {userName}!'**
  String welcomeBackUser(String userName);

  /// Error message for wrong account type
  ///
  /// In en, this message translates to:
  /// **'Invalid account type'**
  String get invalidAccountType;

  /// Error message when role doesn't match
  ///
  /// In en, this message translates to:
  /// **'This account is registered as {role}. Please use the correct login option.'**
  String accountRegisteredAs(String role);

  /// General login failure message
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please check your credentials.'**
  String get loginFailed;

  /// Validation error for empty email
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get enterEmail;

  /// Title for signup screen
  ///
  /// In en, this message translates to:
  /// **'Create {userType} Account'**
  String createAccount(String userType);

  /// Subtitle for signup screen
  ///
  /// In en, this message translates to:
  /// **'Please fill in the details below'**
  String get fillDetails;

  /// Label for full name field
  ///
  /// In en, this message translates to:
  /// **'Full Name *'**
  String get fullName;

  /// Hint text for full name field
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterFullName;

  /// Label for email field with asterisk
  ///
  /// In en, this message translates to:
  /// **'Email Address *'**
  String get emailAddressStar;

  /// Hint text for email field
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get emailExample;

  /// Validation error for invalid email
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get invalidEmail;

  /// Label for medical license field
  ///
  /// In en, this message translates to:
  /// **'Medical License Number *'**
  String get medicalLicenseNumber;

  /// Hint text for medical license field
  ///
  /// In en, this message translates to:
  /// **'Enter License Number'**
  String get enterLicenseNumber;

  /// No description provided for @referralCode.
  ///
  /// In en, this message translates to:
  /// **'Referral Code'**
  String get referralCode;

  /// No description provided for @enterReferralCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Referral Code'**
  String get enterReferralCode;

  /// Label for medical specialty field
  ///
  /// In en, this message translates to:
  /// **'Medical Specialty *'**
  String get medicalSpecialty;

  /// Hint text for medical specialty field
  ///
  /// In en, this message translates to:
  /// **'Select Specialty'**
  String get selectSpecialty;

  /// Label for experience years field
  ///
  /// In en, this message translates to:
  /// **'Years of Experience *'**
  String get yearsExperienceStar;

  /// Hint text for experience years field
  ///
  /// In en, this message translates to:
  /// **'e.g., 5'**
  String get yearsExperienceExample;

  /// Label for password field with asterisk
  ///
  /// In en, this message translates to:
  /// **'Password *'**
  String get passwordStar;

  /// Description for password field
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get passwordLength;

  /// Label for confirm password field
  ///
  /// In en, this message translates to:
  /// **'Confirm Password *'**
  String get confirmPasswordStar;

  /// Hint text for confirm password field
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get reenterPassword;

  /// Validation error for passwords mismatch
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// Validation error for short password
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordAtLeast6;

  /// Validation error for missing license
  ///
  /// In en, this message translates to:
  /// **'Medical license number is required'**
  String get licenseRequired;

  /// Validation error for missing specialty
  ///
  /// In en, this message translates to:
  /// **'Please select a specialty'**
  String get specialtyRequired;

  /// Validation error for missing experience
  ///
  /// In en, this message translates to:
  /// **'Years of experience is required'**
  String get experienceRequired;

  /// Success message after registration
  ///
  /// In en, this message translates to:
  /// **'Registration successful!'**
  String get registrationSuccessful;

  /// Text before sign-in link
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// Text for sign-in link
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInLabel;

  /// Button text for creating account
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccountBtn;

  /// Title for forgot password screen
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPasswordTitle;

  /// Subtitle for forgot password screen
  ///
  /// In en, this message translates to:
  /// **'Select which contact details should we use to reset your password'**
  String get selectContactReset;

  /// Label for email in forgot password
  ///
  /// In en, this message translates to:
  /// **'Email:'**
  String get emailLabel;

  /// Hint text for email in forgot password
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterYourEmail;

  /// Loading text during sending
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sending;

  /// Button text for continue
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// Title for OTP screen
  ///
  /// In en, this message translates to:
  /// **'OTP'**
  String get otpTitle;

  /// Subtitle for OTP screen
  ///
  /// In en, this message translates to:
  /// **'We have sent you a one time code to your email'**
  String get sentCodeEmail;

  /// Validation error for invalid OTP
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 6-digit OTP'**
  String get valid6DigitOtp;

  /// Error message when email is missing in OTP
  ///
  /// In en, this message translates to:
  /// **'Email not found. Please restart the process.'**
  String get emailNotFound;

  /// Success message after resending OTP
  ///
  /// In en, this message translates to:
  /// **'OTP sent again successfully'**
  String get otpSentAgain;

  /// Text before resend link
  ///
  /// In en, this message translates to:
  /// **'Didn\'t get the code? '**
  String get didntGetCode;

  /// Text for resend link
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resend;

  /// Loading text during resending
  ///
  /// In en, this message translates to:
  /// **'Resending...'**
  String get resending;

  /// Loading text during verifying
  ///
  /// In en, this message translates to:
  /// **'Verifying...'**
  String get verifying;

  /// Title for reset password screen
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordTitle;

  /// Subtitle for reset password screen
  ///
  /// In en, this message translates to:
  /// **'Set the new password for your account'**
  String get setNewPassword;

  /// Hint text for new password field
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// Hint text for confirm password field
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Validation error for empty fields
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields'**
  String get fillAllFields;

  /// Title for success dialog
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// Success message for password reset
  ///
  /// In en, this message translates to:
  /// **'Password has been reset successfully'**
  String get passwordResetSuccess;

  /// Loading text during resetting
  ///
  /// In en, this message translates to:
  /// **'Resetting...'**
  String get resetting;

  /// Title for appointments screen
  ///
  /// In en, this message translates to:
  /// **'Appointment Management'**
  String get appointmentManagement;

  /// Subtitle for appointments screen
  ///
  /// In en, this message translates to:
  /// **'Manage your Video and physical\nConsultations'**
  String get manageConsultations;

  /// Tab label for pending appointments
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// Tab label for confirmed appointments
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get confirmed;

  /// Tab label for completed appointments
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// Empty state message
  ///
  /// In en, this message translates to:
  /// **'No {status} appointments'**
  String noAppointments(String status);

  /// Label for dependent booking
  ///
  /// In en, this message translates to:
  /// **'For: {name}'**
  String forDependent(String name);

  /// Label for physical appointment type
  ///
  /// In en, this message translates to:
  /// **'Physical'**
  String get physical;

  /// Button text to see appointment details
  ///
  /// In en, this message translates to:
  /// **'See Details'**
  String get seeDetails;

  /// Button text to accept appointment
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// Button text to start video session
  ///
  /// In en, this message translates to:
  /// **'Start Session'**
  String get startSession;

  /// Title for appointment details sheet
  ///
  /// In en, this message translates to:
  /// **'Appointment Details'**
  String get appointmentDetails;

  /// Header in appointment details
  ///
  /// In en, this message translates to:
  /// **'Patient Information'**
  String get patientInformation;

  /// Label for who the appointment is for
  ///
  /// In en, this message translates to:
  /// **'Booked for: {name}'**
  String bookedFor(String name);

  /// Header for symptoms section
  ///
  /// In en, this message translates to:
  /// **'Symptoms'**
  String get symptoms;

  /// Fallback text for empty symptoms
  ///
  /// In en, this message translates to:
  /// **'No symptoms provided'**
  String get noSymptoms;

  /// Header for medical documents section
  ///
  /// In en, this message translates to:
  /// **'Medical Documents'**
  String get medicalDocuments;

  /// Count of uploaded documents
  ///
  /// In en, this message translates to:
  /// **'{count} document(s) uploaded'**
  String docsUploaded(int count);

  /// Fallback text for empty documents
  ///
  /// In en, this message translates to:
  /// **'No medical documents uploaded'**
  String get noDocsUploaded;

  /// Header for payment screenshot section
  ///
  /// In en, this message translates to:
  /// **'Payment Screenshot'**
  String get paymentScreenshot;

  /// Link text to view payment screenshot
  ///
  /// In en, this message translates to:
  /// **'View Payment Screenshot'**
  String get viewPaymentScreenshot;

  /// Fallback text for empty payment screenshot
  ///
  /// In en, this message translates to:
  /// **'No payment screenshot uploaded'**
  String get noPaymentScreenshot;

  /// Title for document URL dialog
  ///
  /// In en, this message translates to:
  /// **'Document URL'**
  String get documentUrl;

  /// Button text to close dialog
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Error message for document opening failure
  ///
  /// In en, this message translates to:
  /// **'Error opening document: {error}'**
  String errorOpeningDoc(String error);

  /// Title for cancel confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Cancel Appointment'**
  String get cancelAppointment;

  /// Content for cancel confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this appointment?'**
  String get confirmCancel;

  /// Button text for no
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// Button text for yes
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// Success snackbar after accepting
  ///
  /// In en, this message translates to:
  /// **'Appointment accepted successfully'**
  String get appointmentAccepted;

  /// Error snackbar after acceptance failure
  ///
  /// In en, this message translates to:
  /// **'Failed to accept appointment'**
  String get failedAccept;

  /// Success snackbar after cancellation
  ///
  /// In en, this message translates to:
  /// **'Appointment cancelled'**
  String get appointmentCancelled;

  /// Status label for cancelled appointment
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// Error snackbar after cancellation failure
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel appointment'**
  String get failedCancel;

  /// Loading text for image viewer
  ///
  /// In en, this message translates to:
  /// **'Loading image...'**
  String get loadingImage;

  /// Error text for image viewer
  ///
  /// In en, this message translates to:
  /// **'Failed to load image'**
  String get failedLoadImage;

  /// Title for image viewer
  ///
  /// In en, this message translates to:
  /// **'Medical Document'**
  String get medicalDocument;

  /// Tooltip for reset zoom button
  ///
  /// In en, this message translates to:
  /// **'Reset Zoom'**
  String get resetZoom;

  /// Instructions for image viewer
  ///
  /// In en, this message translates to:
  /// **'Pinch to zoom • Drag to pan'**
  String get zoomInstructions;

  /// Tab label for upcoming appointments
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// Tab label with count
  ///
  /// In en, this message translates to:
  /// **'Up Coming ({count})'**
  String upcomingCount(int count);

  /// Button text to reschedule
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get reschedule;

  /// No description provided for @appointmentRescheduled.
  ///
  /// In en, this message translates to:
  /// **'Appointment rescheduled. The patient has been notified.'**
  String get appointmentRescheduled;

  /// No description provided for @failedReschedule.
  ///
  /// In en, this message translates to:
  /// **'Failed to reschedule appointment'**
  String get failedReschedule;

  /// Button text to write review
  ///
  /// In en, this message translates to:
  /// **'Write a Review'**
  String get writeReview;

  /// Dialog title to update review
  ///
  /// In en, this message translates to:
  /// **'Update Your Review'**
  String get updateReview;

  /// Dialog title to rate experience
  ///
  /// In en, this message translates to:
  /// **'Rate Your Experience'**
  String get rateExperience;

  /// Subtitle for review dialog
  ///
  /// In en, this message translates to:
  /// **'with {name}'**
  String withDoctor(String name);

  /// Notification title when appointment is booked
  ///
  /// In en, this message translates to:
  /// **'New Appointment Request'**
  String get notif_appointment_booked_title;

  /// Notification body when appointment is booked
  ///
  /// In en, this message translates to:
  /// **'You have a new appointment request from a patient.'**
  String get notif_appointment_booked_body;

  /// Notification title when appointment is confirmed
  ///
  /// In en, this message translates to:
  /// **'Appointment Confirmed'**
  String get notif_appointment_confirmed_title;

  /// Notification body when appointment is confirmed
  ///
  /// In en, this message translates to:
  /// **'Your appointment with the doctor has been confirmed.'**
  String get notif_appointment_confirmed_body;

  /// Notification title when appointment is cancelled
  ///
  /// In en, this message translates to:
  /// **'Appointment Cancelled'**
  String get notif_appointment_cancelled_title;

  /// Notification body when appointment is cancelled
  ///
  /// In en, this message translates to:
  /// **'An appointment has been cancelled.'**
  String get notif_appointment_cancelled_body;

  /// Notification title when appointment is completed
  ///
  /// In en, this message translates to:
  /// **'Appointment Completed'**
  String get notif_appointment_completed_title;

  /// Notification body when appointment is completed
  ///
  /// In en, this message translates to:
  /// **'Your appointment has been marked as completed.'**
  String get notif_appointment_completed_body;

  /// Notification title when post is liked
  ///
  /// In en, this message translates to:
  /// **'New Like'**
  String get notif_post_liked_title;

  /// Notification body when post is liked
  ///
  /// In en, this message translates to:
  /// **'Someone liked your post.'**
  String get notif_post_liked_body;

  /// Notification title when post is commented
  ///
  /// In en, this message translates to:
  /// **'New Comment'**
  String get notif_post_commented_title;

  /// Notification body when post is commented
  ///
  /// In en, this message translates to:
  /// **'Someone commented on your post.'**
  String get notif_post_commented_body;

  /// Notification title when reel is liked
  ///
  /// In en, this message translates to:
  /// **'New Reel Like'**
  String get notif_reel_liked_title;

  /// Notification body when reel is liked
  ///
  /// In en, this message translates to:
  /// **'Someone liked your reel.'**
  String get notif_reel_liked_body;

  /// Notification title when reel is commented
  ///
  /// In en, this message translates to:
  /// **'New Reel Comment'**
  String get notif_reel_commented_title;

  /// Notification body when reel is commented
  ///
  /// In en, this message translates to:
  /// **'Someone commented on your reel.'**
  String get notif_reel_commented_body;

  /// Success snackbar after review submission
  ///
  /// In en, this message translates to:
  /// **'Review submitted successfully'**
  String get reviewSubmitted;

  /// Error snackbar after review failure
  ///
  /// In en, this message translates to:
  /// **'Failed to submit review'**
  String get failedSubmitReview;

  /// Button text to submit review
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// Fallback text for doctor name
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get doctor;

  /// Badge for video call availability
  ///
  /// In en, this message translates to:
  /// **'Video Consultation Available'**
  String get videoAvailable;

  /// Badge for in-person only appointments
  ///
  /// In en, this message translates to:
  /// **'In-Person Only'**
  String get inPersonOnly;

  /// Reviews count display
  ///
  /// In en, this message translates to:
  /// **'({count} reviews)'**
  String reviewsCount(int count);

  /// Label for doctor biography
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// Label for doctor specialty
  ///
  /// In en, this message translates to:
  /// **'Specialty'**
  String get specialty;

  /// Label for doctor degree
  ///
  /// In en, this message translates to:
  /// **'Degree'**
  String get degree;

  /// Label for doctor consultation fees
  ///
  /// In en, this message translates to:
  /// **'Fees'**
  String get fees;

  /// Algerian Dinar currency code
  ///
  /// In en, this message translates to:
  /// **'DZD'**
  String get dzd;

  /// Label for doctor visiting hours
  ///
  /// In en, this message translates to:
  /// **'Visiting Hours'**
  String get visitingHours;

  /// Fallback text when hours are not set
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// Button text to message a doctor
  ///
  /// In en, this message translates to:
  /// **'Message Doctor'**
  String get messageDoctor;

  /// Error message for invalid doctor selection
  ///
  /// In en, this message translates to:
  /// **'Invalid Doctor'**
  String get invalidDoctor;

  /// Error message when doctor ID is missing
  ///
  /// In en, this message translates to:
  /// **'Doctor ID not found'**
  String get doctorIdNotFound;

  /// Error message when chat creation fails
  ///
  /// In en, this message translates to:
  /// **'Failed to create chat'**
  String get failedCreateChat;

  /// Error message when opening a chat fails
  ///
  /// In en, this message translates to:
  /// **'Failed to open chat'**
  String get failedOpenChat;

  /// Appointment type physical visit
  ///
  /// In en, this message translates to:
  /// **'Physical Visit'**
  String get physicalVisit;

  /// Appointment type video call
  ///
  /// In en, this message translates to:
  /// **'Video Call'**
  String get videoCall;

  /// Audio/Video calls toggle title
  ///
  /// In en, this message translates to:
  /// **'Audio/Video Calls'**
  String get audioVideoCalls;

  /// Title for rescheduling screen
  ///
  /// In en, this message translates to:
  /// **'Reschedule Appointment'**
  String get rescheduleAppointment;

  /// Title for booking screen
  ///
  /// In en, this message translates to:
  /// **'Book Appointment'**
  String get bookAppointment;

  /// Banner message during reschedule
  ///
  /// In en, this message translates to:
  /// **'You are rescheduling your appointment. Old appointment will be cancelled.'**
  String get rescheduleBanner;

  /// Warning message for video payments
  ///
  /// In en, this message translates to:
  /// **'Video appointments- patient must\nupload BaridiMob payment screenshot'**
  String get videoUploadWarning;

  /// Heading for appointment type selection
  ///
  /// In en, this message translates to:
  /// **'Appointment Type'**
  String get appointmentTypeLabel;

  /// Subtitle for physical visit
  ///
  /// In en, this message translates to:
  /// **'Pay at Clinic'**
  String get payAtClinic;

  /// Subtitle for video call
  ///
  /// In en, this message translates to:
  /// **'Online Payment'**
  String get onlinePayment;

  /// Heading for patient selection
  ///
  /// In en, this message translates to:
  /// **'Book Appointment For'**
  String get bookAppointmentFor;

  /// Option to book for self
  ///
  /// In en, this message translates to:
  /// **'Myself'**
  String get myself;

  /// Section label for dependents
  ///
  /// In en, this message translates to:
  /// **'Or select a dependent:'**
  String get orSelectDependent;

  /// Button to add a dependent
  ///
  /// In en, this message translates to:
  /// **'Add New Dependent'**
  String get addNewDependent;

  /// Label for date selection
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// Placeholder for date field
  ///
  /// In en, this message translates to:
  /// **'dd/mm/yyyy'**
  String get datePlaceholder;

  /// Label for time slot selection
  ///
  /// In en, this message translates to:
  /// **'Available Time'**
  String get availableTime;

  /// Message when no slots are available
  ///
  /// In en, this message translates to:
  /// **'No available time slots for this date'**
  String get noTimeSlots;

  /// Connector between start and end time
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get timeTo;

  /// Status for an unavailable slot
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get booked;

  /// Label for symptoms input
  ///
  /// In en, this message translates to:
  /// **'Describe your Symptoms'**
  String get describeSymptoms;

  /// Hint for symptoms input
  ///
  /// In en, this message translates to:
  /// **'Please describe your symptoms in detail....'**
  String get symptomsHint;

  /// Label for document upload
  ///
  /// In en, this message translates to:
  /// **'Upload Medical Documents'**
  String get uploadMedicalDocs;

  /// Instruction for document upload
  ///
  /// In en, this message translates to:
  /// **'Tap to Upload image or PDF'**
  String get tapToUpload;

  /// Label for payment screenshot upload
  ///
  /// In en, this message translates to:
  /// **'Upload Payment Screenshot'**
  String get uploadPaymentScreenshot;

  /// Instruction for payment upload
  ///
  /// In en, this message translates to:
  /// **'Tap to Upload Your Payment Screenshot'**
  String get tapToUploadPayment;

  /// Button text to confirm rescheduling
  ///
  /// In en, this message translates to:
  /// **'Confirm Reschedule'**
  String get confirmReschedule;

  /// Button text to submit booking
  ///
  /// In en, this message translates to:
  /// **'Submit Appointment Request'**
  String get submitAppointmentRequest;

  /// Error during booking if doctor is invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid Doctor – Cannot book appointment'**
  String get invalidDoctorBooking;

  /// Validation error for missing date/time
  ///
  /// In en, this message translates to:
  /// **'Please select date and time'**
  String get selectDateTime;

  /// Error message when rescheduling fails
  ///
  /// In en, this message translates to:
  /// **'Reschedule failed: {error}'**
  String rescheduleFailed(String error);

  /// Validation error for missing payment proof
  ///
  /// In en, this message translates to:
  /// **'Payment screenshot required for Video Call'**
  String get paymentRequired;

  /// Generic booking failure message
  ///
  /// In en, this message translates to:
  /// **'Booking failed'**
  String get bookingFailed;

  /// Title for session completion screen
  ///
  /// In en, this message translates to:
  /// **'Complete Session'**
  String get completeSession;

  /// Success message after completing session
  ///
  /// In en, this message translates to:
  /// **'Session completed successfully!'**
  String get sessionCompleted;

  /// Error message when session completion fails
  ///
  /// In en, this message translates to:
  /// **'Failed to complete session'**
  String get failedCompleteSession;

  /// Heading for payment input section
  ///
  /// In en, this message translates to:
  /// **'Session Payment Details'**
  String get sessionPaymentDetails;

  /// Subtitle instructions for completion
  ///
  /// In en, this message translates to:
  /// **'Enter the details to complete this session'**
  String get enterSessionDetails;

  /// Label for patient name input
  ///
  /// In en, this message translates to:
  /// **'Patient Full Name'**
  String get patientFullName;

  /// Hint for patient name input
  ///
  /// In en, this message translates to:
  /// **'Enter patient\'s full name'**
  String get enterPatientName;

  /// Validation error for missing patient name
  ///
  /// In en, this message translates to:
  /// **'Please enter patient name'**
  String get patientNameRequired;

  /// Label for amount input with currency
  ///
  /// In en, this message translates to:
  /// **'Payable Amount (DZD)'**
  String get payableAmount;

  /// Hint for amount input
  ///
  /// In en, this message translates to:
  /// **'Enter amount received'**
  String get enterAmountReceived;

  /// Validation error for missing amount
  ///
  /// In en, this message translates to:
  /// **'Please enter amount'**
  String get amountRequired;

  /// Validation error for invalid amount format
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get validAmountRequired;

  /// Title for notification screen
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notificationTitle;

  /// Title for notifications screen
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// Tooltip for marking all notifications as read
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsRead;

  /// Section title for new notifications
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newNotifications;

  /// Section title for older notifications
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get earlierNotifications;

  /// Empty state message for notifications
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// Empty state title for doctor notifications
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// Empty state subtitle for doctor notifications
  ///
  /// In en, this message translates to:
  /// **'We\'ll notify you when a patient books or updates an appointment.'**
  String get doctorNotificationEmptySubtitle;

  /// Section title for upcoming patients in doctor notifications
  ///
  /// In en, this message translates to:
  /// **'Upcoming Patient'**
  String get upcomingPatient;

  /// No description provided for @addTextOrMedia.
  ///
  /// In en, this message translates to:
  /// **'Please add some text or media to post'**
  String get addTextOrMedia;

  /// No description provided for @reelPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Reel Privacy'**
  String get reelPrivacy;

  /// No description provided for @reelVisibleDoctorsOnly.
  ///
  /// In en, this message translates to:
  /// **'This reel will be visible to doctors only.'**
  String get reelVisibleDoctorsOnly;

  /// No description provided for @reelVisibleEveryone.
  ///
  /// In en, this message translates to:
  /// **'This reel will be visible to everyone (doctors and patients).'**
  String get reelVisibleEveryone;

  /// No description provided for @currentPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Current privacy: {privacy}'**
  String currentPrivacy(Object privacy);

  /// No description provided for @privateDoctorsOnly.
  ///
  /// In en, this message translates to:
  /// **'Private (Doctors Only)'**
  String get privateDoctorsOnly;

  /// No description provided for @publicEveryone.
  ///
  /// In en, this message translates to:
  /// **'Public (Everyone)'**
  String get publicEveryone;

  /// No description provided for @uploadReel.
  ///
  /// In en, this message translates to:
  /// **'Upload Reel'**
  String get uploadReel;

  /// No description provided for @privateReelUploaded.
  ///
  /// In en, this message translates to:
  /// **'✓ Private reel uploaded! (Doctors only)'**
  String get privateReelUploaded;

  /// No description provided for @publicReelUploaded.
  ///
  /// In en, this message translates to:
  /// **'✓ Public reel uploaded! (Everyone can see)'**
  String get publicReelUploaded;

  /// No description provided for @failedUploadReel.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload reel'**
  String get failedUploadReel;

  /// No description provided for @postSharedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'✓ Post shared successfully!'**
  String get postSharedSuccessfully;

  /// No description provided for @failedCreatePost.
  ///
  /// In en, this message translates to:
  /// **'Failed to create post'**
  String get failedCreatePost;

  /// No description provided for @whatsOnYourMind.
  ///
  /// In en, this message translates to:
  /// **'What\'s on your mind?.......'**
  String get whatsOnYourMind;

  /// No description provided for @videoSelected.
  ///
  /// In en, this message translates to:
  /// **'Video Selected'**
  String get videoSelected;

  /// No description provided for @failedLikePost.
  ///
  /// In en, this message translates to:
  /// **'Failed to like post'**
  String get failedLikePost;

  /// No description provided for @deletePost.
  ///
  /// In en, this message translates to:
  /// **'Delete Post'**
  String get deletePost;

  /// No description provided for @reportPost.
  ///
  /// In en, this message translates to:
  /// **'Report Post'**
  String get reportPost;

  /// No description provided for @reportComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Report - Coming soon!'**
  String get reportComingSoon;

  /// No description provided for @confirmDeletePost.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this post?'**
  String get confirmDeletePost;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @postDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'✓ Post deleted successfully'**
  String get postDeletedSuccessfully;

  /// No description provided for @failedDeletePost.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete post'**
  String get failedDeletePost;

  /// No description provided for @sharePost.
  ///
  /// In en, this message translates to:
  /// **'Share Post'**
  String get sharePost;

  /// No description provided for @shareExternally.
  ///
  /// In en, this message translates to:
  /// **'Share Externally'**
  String get shareExternally;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get sendMessage;

  /// No description provided for @shareMessageComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Share to message - Coming soon!'**
  String get shareMessageComingSoon;

  /// No description provided for @authorPosted.
  ///
  /// In en, this message translates to:
  /// **'{name} posted:'**
  String authorPosted(Object name);

  /// No description provided for @imagesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} image(s)'**
  String imagesCount(Object count);

  /// No description provided for @videosCount.
  ///
  /// In en, this message translates to:
  /// **'{count} video(s)'**
  String videosCount(Object count);

  /// No description provided for @noCommentsYet.
  ///
  /// In en, this message translates to:
  /// **'No comments yet'**
  String get noCommentsYet;

  /// No description provided for @writeComment.
  ///
  /// In en, this message translates to:
  /// **'Write a comment...'**
  String get writeComment;

  /// No description provided for @likeLabel.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get likeLabel;

  /// No description provided for @commentLabel.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get commentLabel;

  /// No description provided for @shareLabel.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareLabel;

  /// No description provided for @likesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{like} other{likes}}'**
  String likesCount(num count);

  /// No description provided for @commentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{comment} other{comments}}'**
  String commentsCount(num count);

  /// No description provided for @sharesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{share} other{shares}}'**
  String sharesCount(num count);

  /// No description provided for @post.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get post;

  /// No description provided for @commentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get commentsLabel;

  /// No description provided for @reelsLabel.
  ///
  /// In en, this message translates to:
  /// **'Reels'**
  String get reelsLabel;

  /// No description provided for @failedLoadReels.
  ///
  /// In en, this message translates to:
  /// **'Failed to load reels'**
  String get failedLoadReels;

  /// No description provided for @retryLabel.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryLabel;

  /// No description provided for @noReelsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No reels available'**
  String get noReelsAvailable;

  /// No description provided for @unknownDoctor.
  ///
  /// In en, this message translates to:
  /// **'Unknown Doctor'**
  String get unknownDoctor;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @doctorsOnlyLabel.
  ///
  /// In en, this message translates to:
  /// **'Doctors Only'**
  String get doctorsOnlyLabel;

  /// No description provided for @failedLikeReel.
  ///
  /// In en, this message translates to:
  /// **'Failed to like reel'**
  String get failedLikeReel;

  /// No description provided for @authorSharedReel.
  ///
  /// In en, this message translates to:
  /// **'{name} shared a reel'**
  String authorSharedReel(Object name);

  /// No description provided for @playbackSpeed.
  ///
  /// In en, this message translates to:
  /// **'{speed}x Speed'**
  String playbackSpeed(Object speed);

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @messagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messagesLabel;

  /// No description provided for @allLabel.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allLabel;

  /// No description provided for @doctorsLabel.
  ///
  /// In en, this message translates to:
  /// **'Doctors'**
  String get doctorsLabel;

  /// No description provided for @patientsLabel.
  ///
  /// In en, this message translates to:
  /// **'Patients'**
  String get patientsLabel;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// No description provided for @noConversationsYet.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noConversationsYet;

  /// No description provided for @deleteChats.
  ///
  /// In en, this message translates to:
  /// **'Delete Chats'**
  String get deleteChats;

  /// No description provided for @deleteMessages.
  ///
  /// In en, this message translates to:
  /// **'Delete Messages'**
  String get deleteMessages;

  /// No description provided for @deleteConversationsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count} conversations? This will remove all messages.'**
  String deleteConversationsConfirm(Object count);

  /// No description provided for @deleteMessagesConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count} messages?'**
  String deleteMessagesConfirm(Object count);

  /// No description provided for @deleteLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteLabel;

  /// No description provided for @deleteReel.
  ///
  /// In en, this message translates to:
  /// **'Delete Reel'**
  String get deleteReel;

  /// No description provided for @deleteReelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this reel? This action cannot be undone.'**
  String get deleteReelConfirm;

  /// No description provided for @reelDeleted.
  ///
  /// In en, this message translates to:
  /// **'Reel deleted'**
  String get reelDeleted;

  /// No description provided for @failedDeleteReel.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete reel'**
  String get failedDeleteReel;

  /// No description provided for @conversationsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Conversations deleted'**
  String get conversationsDeleted;

  /// No description provided for @messagesDeleted.
  ///
  /// In en, this message translates to:
  /// **'Messages deleted'**
  String get messagesDeleted;

  /// No description provided for @failedToDelete.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete: {error}'**
  String failedToDelete(Object error);

  /// No description provided for @startConversationWith.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation with {name}'**
  String startConversationWith(Object name);

  /// No description provided for @typeAMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeAMessage;

  /// No description provided for @failedToSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to send message'**
  String get failedToSendMessage;

  /// No description provided for @cannotStartCallNoId.
  ///
  /// In en, this message translates to:
  /// **'Cannot start call - user ID not found'**
  String get cannotStartCallNoId;

  /// No description provided for @failedToStartCall.
  ///
  /// In en, this message translates to:
  /// **'Failed to start call: {error}'**
  String failedToStartCall(Object error);

  /// No description provided for @voiceCall.
  ///
  /// In en, this message translates to:
  /// **'Voice Call'**
  String get voiceCall;

  /// No description provided for @doctorUnavailableForCalls.
  ///
  /// In en, this message translates to:
  /// **'Doctor is not available for calls at this time'**
  String get doctorUnavailableForCalls;

  /// No description provided for @doctorUnavailableForCallsDescription.
  ///
  /// In en, this message translates to:
  /// **'The doctor is not available for {type} calls. You can send a message or try again later.'**
  String doctorUnavailableForCallsDescription(Object type);

  /// No description provided for @imageLabel.
  ///
  /// In en, this message translates to:
  /// **'[Image]'**
  String get imageLabel;

  /// No description provided for @fileLabel.
  ///
  /// In en, this message translates to:
  /// **'[File]'**
  String get fileLabel;

  /// No description provided for @messageLabel.
  ///
  /// In en, this message translates to:
  /// **'[Message]'**
  String get messageLabel;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayLabel;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String daysAgo(Object count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String hoursAgo(Object count);

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String minutesAgo(Object count);

  /// No description provided for @meLabel.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get meLabel;

  /// No description provided for @patientLabel.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get patientLabel;

  /// No description provided for @doctorLabel.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get doctorLabel;

  /// No description provided for @startConversation.
  ///
  /// In en, this message translates to:
  /// **'Start conversation'**
  String get startConversation;

  /// No description provided for @helpSupportComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Help & Support - Coming Soon'**
  String get helpSupportComingSoon;

  /// No description provided for @noDependentsAdded.
  ///
  /// In en, this message translates to:
  /// **'No dependents added yet'**
  String get noDependentsAdded;

  /// No description provided for @addDependent.
  ///
  /// In en, this message translates to:
  /// **'Add Dependent'**
  String get addDependent;

  /// No description provided for @editDependent.
  ///
  /// In en, this message translates to:
  /// **'Edit Dependent'**
  String get editDependent;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @ageLabel.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get ageLabel;

  /// No description provided for @genderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get genderLabel;

  /// No description provided for @contactLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contactLabel;

  /// No description provided for @deleteDependentTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Dependent?'**
  String get deleteDependentTitle;

  /// No description provided for @deleteDependentConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String deleteDependentConfirm(Object name);

  /// No description provided for @deleteDependentWarning.
  ///
  /// In en, this message translates to:
  /// **'If they have active appointments, you must cancel those first.'**
  String get deleteDependentWarning;

  /// No description provided for @cannotDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Cannot Delete'**
  String get cannotDeleteTitle;

  /// No description provided for @howToFix.
  ///
  /// In en, this message translates to:
  /// **'How to fix:'**
  String get howToFix;

  /// No description provided for @deleteFixInstructions.
  ///
  /// In en, this message translates to:
  /// **'1. Go to My Appointments\n2. Cancel any pending/accepted appointments for this dependent\n3. Then try deleting again'**
  String get deleteFixInstructions;

  /// No description provided for @goToAppointments.
  ///
  /// In en, this message translates to:
  /// **'Go to Appointments'**
  String get goToAppointments;

  /// No description provided for @dependentDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'{name} deleted successfully'**
  String dependentDeletedSuccess(Object name);

  /// No description provided for @dependentAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Dependent added successfully!'**
  String get dependentAddedSuccess;

  /// No description provided for @dependentUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Dependent updated successfully!'**
  String get dependentUpdatedSuccess;

  /// No description provided for @failedToAddDependent.
  ///
  /// In en, this message translates to:
  /// **'Failed to add dependent'**
  String get failedToAddDependent;

  /// No description provided for @failedToUpdateDependent.
  ///
  /// In en, this message translates to:
  /// **'Failed to update dependent'**
  String get failedToUpdateDependent;

  /// No description provided for @basicInformation.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInformation;

  /// No description provided for @nameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameIsRequired;

  /// No description provided for @selectRelationship.
  ///
  /// In en, this message translates to:
  /// **'Please select relationship'**
  String get selectRelationship;

  /// No description provided for @selectDob.
  ///
  /// In en, this message translates to:
  /// **'Please select date of birth'**
  String get selectDob;

  /// No description provided for @relationshipLabel.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get relationshipLabel;

  /// No description provided for @relationshipHint.
  ///
  /// In en, this message translates to:
  /// **'Relationship (e.g. Child, Spouse)'**
  String get relationshipHint;

  /// No description provided for @contactDetails.
  ///
  /// In en, this message translates to:
  /// **'Contact Details'**
  String get contactDetails;

  /// No description provided for @guardianContactLabel.
  ///
  /// In en, this message translates to:
  /// **'Parent/Guardian Contact (Primary)'**
  String get guardianContactLabel;

  /// No description provided for @userInfoWillBeUsed.
  ///
  /// In en, this message translates to:
  /// **'Your user info will be used'**
  String get userInfoWillBeUsed;

  /// No description provided for @dependentContactHint.
  ///
  /// In en, this message translates to:
  /// **'Dependent\'s Contact (if applicable)'**
  String get dependentContactHint;

  /// No description provided for @additionalInformation.
  ///
  /// In en, this message translates to:
  /// **'Additional Information'**
  String get additionalInformation;

  /// No description provided for @medicalNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Medical Notes / Allergies (Optional)'**
  String get medicalNotesHint;

  /// No description provided for @saveDependent.
  ///
  /// In en, this message translates to:
  /// **'Save Dependent'**
  String get saveDependent;

  /// No description provided for @updateDependent.
  ///
  /// In en, this message translates to:
  /// **'Update Dependent'**
  String get updateDependent;

  /// No description provided for @relChild.
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get relChild;

  /// No description provided for @relSpouse.
  ///
  /// In en, this message translates to:
  /// **'Spouse'**
  String get relSpouse;

  /// No description provided for @relFather.
  ///
  /// In en, this message translates to:
  /// **'Father'**
  String get relFather;

  /// No description provided for @relMother.
  ///
  /// In en, this message translates to:
  /// **'Mother'**
  String get relMother;

  /// No description provided for @relBrother.
  ///
  /// In en, this message translates to:
  /// **'Brother'**
  String get relBrother;

  /// No description provided for @relSister.
  ///
  /// In en, this message translates to:
  /// **'Sister'**
  String get relSister;

  /// No description provided for @relGrandparent.
  ///
  /// In en, this message translates to:
  /// **'Grandparent'**
  String get relGrandparent;

  /// No description provided for @relOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get relOther;

  /// No description provided for @relSon.
  ///
  /// In en, this message translates to:
  /// **'Son'**
  String get relSon;

  /// No description provided for @relDaughter.
  ///
  /// In en, this message translates to:
  /// **'Daughter'**
  String get relDaughter;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @editYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Your Profile'**
  String get editYourProfile;

  /// No description provided for @profilePicture.
  ///
  /// In en, this message translates to:
  /// **'Profile Picture'**
  String get profilePicture;

  /// No description provided for @tapToChangePicture.
  ///
  /// In en, this message translates to:
  /// **'Tap to Change your Picture'**
  String get tapToChangePicture;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @updateProfile.
  ///
  /// In en, this message translates to:
  /// **'Update Profile'**
  String get updateProfile;

  /// No description provided for @profileUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccess;

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed'**
  String get updateFailed;

  /// No description provided for @nameEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty'**
  String get nameEmptyError;

  /// No description provided for @noChangesToSave.
  ///
  /// In en, this message translates to:
  /// **'No changes to save'**
  String get noChangesToSave;

  /// No description provided for @errorMsg.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorMsg(Object error);

  /// No description provided for @addBio.
  ///
  /// In en, this message translates to:
  /// **'Add Bio'**
  String get addBio;

  /// No description provided for @bioHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us about yourself...'**
  String get bioHint;

  /// No description provided for @degreeHint.
  ///
  /// In en, this message translates to:
  /// **'MBBS, MD, etc.'**
  String get degreeHint;

  /// No description provided for @emailLockedNote.
  ///
  /// In en, this message translates to:
  /// **'Email cannot be changed'**
  String get emailLockedNote;

  /// No description provided for @clinicLocation.
  ///
  /// In en, this message translates to:
  /// **'Clinic Location'**
  String get clinicLocation;

  /// No description provided for @clinicLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Set your clinic location'**
  String get clinicLocationHint;

  /// No description provided for @contactNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Contact number'**
  String get contactNumberHint;

  /// No description provided for @specCardiologist.
  ///
  /// In en, this message translates to:
  /// **'Cardiologist'**
  String get specCardiologist;

  /// No description provided for @specDermatologist.
  ///
  /// In en, this message translates to:
  /// **'Dermatologist'**
  String get specDermatologist;

  /// No description provided for @specNeurologist.
  ///
  /// In en, this message translates to:
  /// **'Neurologist'**
  String get specNeurologist;

  /// No description provided for @specOrthopedic.
  ///
  /// In en, this message translates to:
  /// **'Orthopedic'**
  String get specOrthopedic;

  /// No description provided for @specPediatrician.
  ///
  /// In en, this message translates to:
  /// **'Pediatrician'**
  String get specPediatrician;

  /// No description provided for @specPsychiatrist.
  ///
  /// In en, this message translates to:
  /// **'Psychiatrist'**
  String get specPsychiatrist;

  /// No description provided for @specGeneralPhysician.
  ///
  /// In en, this message translates to:
  /// **'General Physician'**
  String get specGeneralPhysician;

  /// No description provided for @specENT.
  ///
  /// In en, this message translates to:
  /// **'ENT Specialist'**
  String get specENT;

  /// No description provided for @specGynecologist.
  ///
  /// In en, this message translates to:
  /// **'Gynecologist'**
  String get specGynecologist;

  /// No description provided for @specOphthalmologist.
  ///
  /// In en, this message translates to:
  /// **'Ophthalmologist'**
  String get specOphthalmologist;

  /// No description provided for @specDentist.
  ///
  /// In en, this message translates to:
  /// **'Dentist'**
  String get specDentist;

  /// No description provided for @specUrologist.
  ///
  /// In en, this message translates to:
  /// **'Urologist'**
  String get specUrologist;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @passwordLengthRequirement.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters long'**
  String get passwordLengthRequirement;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @enterCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter current password'**
  String get enterCurrentPassword;

  /// No description provided for @enterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get enterNewPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @reEnterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Re-enter new password'**
  String get reEnterNewPassword;

  /// No description provided for @passwordsDoNotMatchError.
  ///
  /// In en, this message translates to:
  /// **'New password and confirm password do not match'**
  String get passwordsDoNotMatchError;

  /// No description provided for @passwordChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangedSuccess;

  /// No description provided for @changePasswordFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to change password'**
  String get changePasswordFailed;

  /// No description provided for @earningOverview.
  ///
  /// In en, this message translates to:
  /// **'Earning Overview'**
  String get earningOverview;

  /// No description provided for @trackIncomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track your income across all appointment types.'**
  String get trackIncomeSubtitle;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @totalEarning.
  ///
  /// In en, this message translates to:
  /// **'Total Earning'**
  String get totalEarning;

  /// No description provided for @appointmentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} appointments'**
  String appointmentsCount(Object count);

  /// No description provided for @sessionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} sessions'**
  String sessionsCount(Object count);

  /// No description provided for @weeklyPerformance.
  ///
  /// In en, this message translates to:
  /// **'Weekly Performance'**
  String get weeklyPerformance;

  /// No description provided for @failedFetchEarnings.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch earnings'**
  String get failedFetchEarnings;

  /// No description provided for @onlineAppointment.
  ///
  /// In en, this message translates to:
  /// **'Online Appointment'**
  String get onlineAppointment;

  /// No description provided for @consultationFees.
  ///
  /// In en, this message translates to:
  /// **'Consultation Fees (DZD)'**
  String get consultationFees;

  /// No description provided for @weeklySchedule.
  ///
  /// In en, this message translates to:
  /// **'Weekly Schedule'**
  String get weeklySchedule;

  /// No description provided for @addNewSlot.
  ///
  /// In en, this message translates to:
  /// **'Add New Slot'**
  String get addNewSlot;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @endTimeError.
  ///
  /// In en, this message translates to:
  /// **'End time must be after start time'**
  String get endTimeError;

  /// No description provided for @enterConsultationFees.
  ///
  /// In en, this message translates to:
  /// **'Please enter consultation fees'**
  String get enterConsultationFees;

  /// No description provided for @scheduleSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Schedule saved successfully!'**
  String get scheduleSavedSuccess;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @selectStartTime.
  ///
  /// In en, this message translates to:
  /// **'Select Start Time'**
  String get selectStartTime;

  /// No description provided for @selectEndTime.
  ///
  /// In en, this message translates to:
  /// **'Select End Time'**
  String get selectEndTime;

  /// No description provided for @selectTimeFromPicker.
  ///
  /// In en, this message translates to:
  /// **'Please select time from the picker below'**
  String get selectTimeFromPicker;

  /// No description provided for @faqTitle.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions (FAQ)'**
  String get faqTitle;

  /// No description provided for @faq1Question.
  ///
  /// In en, this message translates to:
  /// **'1. How do I create an account?'**
  String get faq1Question;

  /// No description provided for @faq1Answer.
  ///
  /// In en, this message translates to:
  /// **'You can sign up as a patient or doctor by choosing your role and completing the registration steps in the app.'**
  String get faq1Answer;

  /// No description provided for @faq2Question.
  ///
  /// In en, this message translates to:
  /// **'2. I forgot my password. What should I do?'**
  String get faq2Question;

  /// No description provided for @faq2Answer.
  ///
  /// In en, this message translates to:
  /// **'Go to the login screen and tap on “Forgot Password”. Follow the instructions to reset your password securely.'**
  String get faq2Answer;

  /// No description provided for @faq3Question.
  ///
  /// In en, this message translates to:
  /// **'3. How can I book an appointment with a doctor?'**
  String get faq3Question;

  /// No description provided for @faq3Answer.
  ///
  /// In en, this message translates to:
  /// **'Search for a doctor or specialty, select an available time slot, and confirm your appointment.'**
  String get faq3Answer;

  /// No description provided for @faq4Question.
  ///
  /// In en, this message translates to:
  /// **'4. Can I cancel or reschedule my appointment?'**
  String get faq4Question;

  /// No description provided for @faq4Answer.
  ///
  /// In en, this message translates to:
  /// **'Yes, you can cancel or reschedule appointments from the “My Appointments” section, depending on the appointment status.'**
  String get faq4Answer;

  /// No description provided for @faq5Question.
  ///
  /// In en, this message translates to:
  /// **'5. How do online audio/video consultations work?'**
  String get faq5Question;

  /// No description provided for @faq5Answer.
  ///
  /// In en, this message translates to:
  /// **'Once your appointment is confirmed, you can start an audio or video call directly from the chat at the scheduled time (if enabled by the doctor).'**
  String get faq5Answer;

  /// No description provided for @faq6Question.
  ///
  /// In en, this message translates to:
  /// **'6. Why can’t I start a call with the doctor?'**
  String get faq6Question;

  /// No description provided for @faq6Answer.
  ///
  /// In en, this message translates to:
  /// **'The doctor may have disabled audio/video calls temporarily. Please try again later or contact support.'**
  String get faq6Answer;

  /// No description provided for @faq7Question.
  ///
  /// In en, this message translates to:
  /// **'7. How do I change the app language?'**
  String get faq7Question;

  /// No description provided for @faq7Answer.
  ///
  /// In en, this message translates to:
  /// **'You can change the language from the app settings at any time.'**
  String get faq7Answer;

  /// No description provided for @faq8Question.
  ///
  /// In en, this message translates to:
  /// **'8. How can doctors manage their profile information?'**
  String get faq8Question;

  /// No description provided for @faq8Answer.
  ///
  /// In en, this message translates to:
  /// **'Doctors can edit their personal and professional information from the profile settings.'**
  String get faq8Answer;

  /// No description provided for @faq9Question.
  ///
  /// In en, this message translates to:
  /// **'9. How does the referral system work?'**
  String get faq9Question;

  /// No description provided for @faq9Answer.
  ///
  /// In en, this message translates to:
  /// **'If referral codes are enabled, doctors can register using a valid referral code provided by the admin.'**
  String get faq9Answer;

  /// No description provided for @stillNeedHelp.
  ///
  /// In en, this message translates to:
  /// **'Still need help?'**
  String get stillNeedHelp;

  /// No description provided for @emailUs.
  ///
  /// In en, this message translates to:
  /// **'Email Us'**
  String get emailUs;

  /// No description provided for @callUs.
  ///
  /// In en, this message translates to:
  /// **'Call Us'**
  String get callUs;

  /// No description provided for @emailSubject.
  ///
  /// In en, this message translates to:
  /// **'Help & Support Request'**
  String get emailSubject;

  /// Success message for booking
  ///
  /// In en, this message translates to:
  /// **'Appointment booked successfully!'**
  String get bookingSuccess;

  /// Profile menu item for Delete Account
  ///
  /// In en, this message translates to:
  /// **'Delete Your account'**
  String get deleteAccount;

  /// No description provided for @applyFilter.
  ///
  /// In en, this message translates to:
  /// **'Apply Filter'**
  String get applyFilter;

  /// No description provided for @allDoctors.
  ///
  /// In en, this message translates to:
  /// **'All Doctors'**
  String get allDoctors;

  /// No description provided for @yourProfile.
  ///
  /// In en, this message translates to:
  /// **'Your Profile'**
  String get yourProfile;

  /// No description provided for @reviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reviews & Ratings'**
  String get reviewsTitle;

  /// No description provided for @myReviews.
  ///
  /// In en, this message translates to:
  /// **'My Reviews'**
  String get myReviews;

  /// No description provided for @noReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get noReviewsYet;

  /// No description provided for @mesPatients.
  ///
  /// In en, this message translates to:
  /// **'My Patients'**
  String get mesPatients;

  /// No description provided for @searchPatient.
  ///
  /// In en, this message translates to:
  /// **'Search patient...'**
  String get searchPatient;

  /// No description provided for @noPatientsFound.
  ///
  /// In en, this message translates to:
  /// **'No patients found'**
  String get noPatientsFound;

  /// No description provided for @patientsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} patients'**
  String patientsCount(int count);

  /// No description provided for @appointmentsCompletedOf.
  ///
  /// In en, this message translates to:
  /// **'{completed} completed of {total}'**
  String appointmentsCompletedOf(int completed, int total);

  /// No description provided for @submitReview.
  ///
  /// In en, this message translates to:
  /// **'Submit Review'**
  String get submitReview;

  /// No description provided for @failedReview.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit review'**
  String get failedReview;

  /// No description provided for @yourRating.
  ///
  /// In en, this message translates to:
  /// **'Your Rating'**
  String get yourRating;

  /// No description provided for @yourComment.
  ///
  /// In en, this message translates to:
  /// **'Your comment (optional)'**
  String get yourComment;

  /// No description provided for @howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How It Works'**
  String get howItWorks;

  /// No description provided for @howItWorksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Watch our tutorial videos to get started'**
  String get howItWorksSubtitle;

  /// No description provided for @doctorTutorialTitle.
  ///
  /// In en, this message translates to:
  /// **'For Doctors'**
  String get doctorTutorialTitle;

  /// No description provided for @doctorTutorialDesc.
  ///
  /// In en, this message translates to:
  /// **'Learn how to manage your appointments, connect with patients, and grow your practice using DocMobi.'**
  String get doctorTutorialDesc;

  /// No description provided for @patientTutorialTitle.
  ///
  /// In en, this message translates to:
  /// **'For Patients'**
  String get patientTutorialTitle;

  /// No description provided for @patientTutorialDesc.
  ///
  /// In en, this message translates to:
  /// **'Discover how to find doctors near you, book appointments, and manage your health with DocMobi.'**
  String get patientTutorialDesc;

  /// No description provided for @watchVideo.
  ///
  /// In en, this message translates to:
  /// **'Watch Video'**
  String get watchVideo;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
