// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get connectingToCall => 'Connecting to call...';

  @override
  String get logoutConfirm => 'Are you sure you want to log out?';

  @override
  String get saveLabel => 'Save';

  @override
  String get addLabel => 'Add';

  @override
  String get addNoteOptional => 'Add Note (Optional)';

  @override
  String get vacationNoteHint => 'e.g. Summer Vacation';

  @override
  String get myVacations => 'My Vacations';

  @override
  String get noVacationsPlanned => 'No vacations planned';

  @override
  String get vacationsUpdated => 'Vacations updated successfully';

  @override
  String get report => 'Report';

  @override
  String get reportReason => 'Report Reason';

  @override
  String get reviewWithin24h => 'Our team will review within 24 hours';

  @override
  String get blockUserLabel => 'Block User';

  @override
  String get contentHiddenFromFeed =>
      'Their content will be hidden from your feed';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get locationPermissionDenied => 'Location permission denied';

  @override
  String get noAppointmentsToExport => 'No appointments to export';

  @override
  String get noAppointmentsInRange =>
      'No appointments found in this date range';

  @override
  String get failedMarkAsRead => 'Failed to mark as read';

  @override
  String get reportReasonHint => 'Describe what is wrong with this content...';

  @override
  String get reportSubmitted => 'Report submitted';

  @override
  String get userBlocked => 'User blocked';

  @override
  String get myWishlist => 'My Wishlist';

  @override
  String get selectAppointmentDateRange => 'Select Appointment Date Range';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get appTitle => 'DocMobi';

  @override
  String get commune => 'Commune';

  @override
  String get wilaya => 'Wilaya';

  @override
  String get filter => 'Filter';

  @override
  String get message => 'Message';

  @override
  String get welcome => 'Welcome';

  @override
  String get settings => 'Settings';

  @override
  String get changeLanguage => 'Change Language';

  @override
  String get english => 'English';

  @override
  String get arabic => 'Arabic';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get french => 'French';

  @override
  String get navHome => 'Home';

  @override
  String get navAppointments => 'Appointments';

  @override
  String get navReels => 'Reels';

  @override
  String get navMessages => 'Messages';

  @override
  String get navProfile => 'Profile';

  @override
  String get personalInfo => 'Personal Info';

  @override
  String get myAppointment => 'My Appointment';

  @override
  String get myDependents => 'My Dependents';

  @override
  String get appointmentSetting => 'Appointment Setting';

  @override
  String get myEarning => 'My Earning';

  @override
  String get changePasswordLabel => 'Change Password';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get logOut => 'Log Out';

  @override
  String get loading => 'Loading...';

  @override
  String get checkingAuth => 'Checking authentication';

  @override
  String get invalidSession => 'Invalid Session';

  @override
  String get sessionExpiredMessage =>
      'Your session is invalid.\nPlease login again.';

  @override
  String get goToLogin => 'Go to Login';

  @override
  String get searchDoctorHint => 'Search Doctor...';

  @override
  String get locationServicesDisabledTitle => 'Location Services Disabled';

  @override
  String get locationServicesDisabledMessage =>
      'Location services are disabled. Please enable them to see nearby doctors.';

  @override
  String get locationPermissionRequiredTitle => 'Location Permission Required';

  @override
  String get locationPermissionRequiredMessage =>
      'Location permission is required to show nearby doctors. Please grant permission in app settings.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get cancel => 'Cancel';

  @override
  String get loadingRoute => 'Loading route...';

  @override
  String get directionsApiDisabled =>
      'Directions API not enabled. Using straight line route.';

  @override
  String get retry => 'Retry';

  @override
  String get loadingMap => 'Loading map...';

  @override
  String get distance => 'Distance';

  @override
  String get upcomingAppointment => 'Upcoming Appointment';

  @override
  String get nearbyDoctors => 'Nearby Doctors';

  @override
  String get seeAll => 'See All';

  @override
  String get noDoctorsFound => 'No doctors found';

  @override
  String get available => 'Available';

  @override
  String get noSchedule => 'No Schedule';

  @override
  String get videoConsultation => 'Video Consultation';

  @override
  String get bookNow => 'Book Now';

  @override
  String get notAvailable => 'Not Available';

  @override
  String get noScheduleSet => 'No schedule set';

  @override
  String searchFailed(String error) {
    return 'Search failed: $error';
  }

  @override
  String get sessionExpiredTitle => 'Session Expired';

  @override
  String get sessionExpiredMessageDoc =>
      'Your session has expired. Please login again.';

  @override
  String get ok => 'OK';

  @override
  String get failedLoadPosts => 'Failed to load posts';

  @override
  String get connectionError => 'Connection error. Please try again.';

  @override
  String get searchHintDoctor => 'Search doctors, posts, specialties...';

  @override
  String get suggestions => 'Suggestions';

  @override
  String get searching => 'Searching...';

  @override
  String get searchAnything => 'Search for anything';

  @override
  String get findEverything => 'Find doctors, posts, or specialties';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get tryDifferentKeywords => 'Try searching with different keywords';

  @override
  String get posts => 'Posts';

  @override
  String get noPostsYet => 'No posts yet. Be the first to share!';

  @override
  String get shareInsights => 'Share your insights with fellow doctors...';

  @override
  String get photo => 'Photo';

  @override
  String get video => 'Video';

  @override
  String get reels => 'Reels';

  @override
  String get createPost => 'Create a Post';

  @override
  String yearsExperience(int years) {
    return '$years years of experience';
  }

  @override
  String get noBioAvailable => 'No bio available';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String loginToAccountAs(String userType) {
    return 'Please Login to your Account as $userType';
  }

  @override
  String get emailAddress => 'Email Address';

  @override
  String get emailHint => 'you@gmail.com';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => '****************';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get signIn => 'Sign in';

  @override
  String get dontHaveAccount => 'Don\'t have an account? ';

  @override
  String get signup => 'Signup';

  @override
  String welcomeBackUser(String userName) {
    return 'Welcome back, $userName!';
  }

  @override
  String get invalidAccountType => 'Invalid account type';

  @override
  String accountRegisteredAs(String role) {
    return 'This account is registered as $role. Please use the correct login option.';
  }

  @override
  String get loginFailed => 'Login failed. Please check your credentials.';

  @override
  String get enterEmail => 'Please enter your email';

  @override
  String createAccount(String userType) {
    return 'Create $userType Account';
  }

  @override
  String get fillDetails => 'Please fill in the details below';

  @override
  String get fullName => 'Full Name *';

  @override
  String get enterFullName => 'Enter your full name';

  @override
  String get emailAddressStar => 'Email Address *';

  @override
  String get emailExample => 'you@example.com';

  @override
  String get invalidEmail => 'Please enter a valid email';

  @override
  String get medicalLicenseNumber => 'Medical License Number *';

  @override
  String get enterLicenseNumber => 'Enter License Number';

  @override
  String get referralCode => 'Referral Code';

  @override
  String get enterReferralCode => 'Enter Referral Code';

  @override
  String get medicalSpecialty => 'Medical Specialty *';

  @override
  String get selectSpecialty => 'Select Specialty';

  @override
  String get yearsExperienceStar => 'Years of Experience *';

  @override
  String get yearsExperienceExample => 'e.g., 5';

  @override
  String get passwordStar => 'Password *';

  @override
  String get passwordLength => 'At least 6 characters';

  @override
  String get confirmPasswordStar => 'Confirm Password *';

  @override
  String get reenterPassword => 'Re-enter your password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get passwordAtLeast6 => 'Password must be at least 6 characters';

  @override
  String get licenseRequired => 'Medical license number is required';

  @override
  String get specialtyRequired => 'Please select a specialty';

  @override
  String get experienceRequired => 'Years of experience is required';

  @override
  String get registrationSuccessful => 'Registration successful!';

  @override
  String get alreadyHaveAccount => 'Already have an account? ';

  @override
  String get signInLabel => 'Sign In';

  @override
  String get createAccountBtn => 'Create Account';

  @override
  String get forgotPasswordTitle => 'Forgot Password';

  @override
  String get selectContactReset =>
      'Select which contact details should we use to reset your password';

  @override
  String get emailLabel => 'Email:';

  @override
  String get enterYourEmail => 'Enter your email';

  @override
  String get sending => 'Sending...';

  @override
  String get continueText => 'Continue';

  @override
  String get otpTitle => 'OTP';

  @override
  String get sentCodeEmail => 'We have sent you a one time code to your email';

  @override
  String get valid6DigitOtp => 'Please enter a valid 6-digit OTP';

  @override
  String get emailNotFound => 'Email not found. Please restart the process.';

  @override
  String get otpSentAgain => 'OTP sent again successfully';

  @override
  String get didntGetCode => 'Didn\'t get the code? ';

  @override
  String get resend => 'Resend';

  @override
  String get resending => 'Resending...';

  @override
  String get verifying => 'Verifying...';

  @override
  String get resetPasswordTitle => 'Reset Password';

  @override
  String get setNewPassword => 'Set the new password for your account';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get fillAllFields => 'Please fill in all fields';

  @override
  String get success => 'Success';

  @override
  String get passwordResetSuccess => 'Password has been reset successfully';

  @override
  String get resetting => 'Resetting...';

  @override
  String get appointmentManagement => 'Appointment Management';

  @override
  String get manageConsultations =>
      'Manage your Video and physical\nConsultations';

  @override
  String get pending => 'Pending';

  @override
  String get confirmed => 'Confirmed';

  @override
  String get completed => 'Completed';

  @override
  String noAppointments(String status) {
    return 'No $status appointments';
  }

  @override
  String forDependent(String name) {
    return 'For: $name';
  }

  @override
  String get physical => 'Physical';

  @override
  String get seeDetails => 'See Details';

  @override
  String get accept => 'Accept';

  @override
  String get startSession => 'Start Session';

  @override
  String get appointmentDetails => 'Appointment Details';

  @override
  String get patientInformation => 'Patient Information';

  @override
  String bookedFor(String name) {
    return 'Booked for: $name';
  }

  @override
  String get symptoms => 'Symptoms';

  @override
  String get noSymptoms => 'No symptoms provided';

  @override
  String get medicalDocuments => 'Medical Documents';

  @override
  String docsUploaded(int count) {
    return '$count document(s) uploaded';
  }

  @override
  String get noDocsUploaded => 'No medical documents uploaded';

  @override
  String get paymentScreenshot => 'Payment Screenshot';

  @override
  String get viewPaymentScreenshot => 'View Payment Screenshot';

  @override
  String get noPaymentScreenshot => 'No payment screenshot uploaded';

  @override
  String get documentUrl => 'Document URL';

  @override
  String get close => 'Close';

  @override
  String errorOpeningDoc(String error) {
    return 'Error opening document: $error';
  }

  @override
  String get cancelAppointment => 'Cancel Appointment';

  @override
  String get confirmCancel =>
      'Are you sure you want to cancel this appointment?';

  @override
  String get no => 'No';

  @override
  String get yes => 'Yes';

  @override
  String get appointmentAccepted => 'Appointment accepted successfully';

  @override
  String get failedAccept => 'Failed to accept appointment';

  @override
  String get appointmentCancelled => 'Appointment cancelled';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get failedCancel => 'Failed to cancel appointment';

  @override
  String get loadingImage => 'Loading image...';

  @override
  String get failedLoadImage => 'Failed to load image';

  @override
  String get medicalDocument => 'Medical Document';

  @override
  String get resetZoom => 'Reset Zoom';

  @override
  String get zoomInstructions => 'Pinch to zoom • Drag to pan';

  @override
  String get upcoming => 'Upcoming';

  @override
  String upcomingCount(int count) {
    return 'Up Coming ($count)';
  }

  @override
  String get reschedule => 'Reschedule';

  @override
  String get appointmentRescheduled =>
      'Appointment rescheduled. The patient has been notified.';

  @override
  String get failedReschedule => 'Failed to reschedule appointment';

  @override
  String get writeReview => 'Write a Review';

  @override
  String get updateReview => 'Update Your Review';

  @override
  String get rateExperience => 'Rate Your Experience';

  @override
  String withDoctor(String name) {
    return 'with $name';
  }

  @override
  String get notif_appointment_booked_title => 'New Appointment Request';

  @override
  String get notif_appointment_booked_body =>
      'You have a new appointment request from a patient.';

  @override
  String get notif_appointment_confirmed_title => 'Appointment Confirmed';

  @override
  String get notif_appointment_confirmed_body =>
      'Your appointment with the doctor has been confirmed.';

  @override
  String get notif_appointment_cancelled_title => 'Appointment Cancelled';

  @override
  String get notif_appointment_cancelled_body =>
      'An appointment has been cancelled.';

  @override
  String get notif_appointment_completed_title => 'Appointment Completed';

  @override
  String get notif_appointment_completed_body =>
      'Your appointment has been marked as completed.';

  @override
  String get notif_post_liked_title => 'New Like';

  @override
  String get notif_post_liked_body => 'Someone liked your post.';

  @override
  String get notif_post_commented_title => 'New Comment';

  @override
  String get notif_post_commented_body => 'Someone commented on your post.';

  @override
  String get notif_reel_liked_title => 'New Reel Like';

  @override
  String get notif_reel_liked_body => 'Someone liked your reel.';

  @override
  String get notif_reel_commented_title => 'New Reel Comment';

  @override
  String get notif_reel_commented_body => 'Someone commented on your reel.';

  @override
  String get reviewSubmitted => 'Review submitted successfully';

  @override
  String get failedSubmitReview => 'Failed to submit review';

  @override
  String get submit => 'Submit';

  @override
  String get doctor => 'Doctor';

  @override
  String get videoAvailable => 'Video Consultation Available';

  @override
  String get inPersonOnly => 'In-Person Only';

  @override
  String reviewsCount(int count) {
    return '($count reviews)';
  }

  @override
  String get bio => 'Bio';

  @override
  String get specialty => 'Specialty';

  @override
  String get degree => 'Degree';

  @override
  String get fees => 'Fees';

  @override
  String get dzd => 'DZD';

  @override
  String get visitingHours => 'Visiting Hours';

  @override
  String get notSet => 'Not set';

  @override
  String get messageDoctor => 'Message Doctor';

  @override
  String get invalidDoctor => 'Invalid Doctor';

  @override
  String get doctorIdNotFound => 'Doctor ID not found';

  @override
  String get failedCreateChat => 'Failed to create chat';

  @override
  String get failedOpenChat => 'Failed to open chat';

  @override
  String get physicalVisit => 'Physical Visit';

  @override
  String get videoCall => 'Video Call';

  @override
  String get audioVideoCalls => 'Audio/Video Calls';

  @override
  String get rescheduleAppointment => 'Reschedule Appointment';

  @override
  String get bookAppointment => 'Book Appointment';

  @override
  String get rescheduleBanner =>
      'You are rescheduling your appointment. Old appointment will be cancelled.';

  @override
  String get videoUploadWarning =>
      'Video appointments- patient must\nupload BaridiMob payment screenshot';

  @override
  String get appointmentTypeLabel => 'Appointment Type';

  @override
  String get payAtClinic => 'Pay at Clinic';

  @override
  String get onlinePayment => 'Online Payment';

  @override
  String get bookAppointmentFor => 'Book Appointment For';

  @override
  String get myself => 'Myself';

  @override
  String get orSelectDependent => 'Or select a dependent:';

  @override
  String get addNewDependent => 'Add New Dependent';

  @override
  String get selectDate => 'Select Date';

  @override
  String get datePlaceholder => 'dd/mm/yyyy';

  @override
  String get availableTime => 'Available Time';

  @override
  String get noTimeSlots => 'No available time slots for this date';

  @override
  String get timeTo => 'To';

  @override
  String get booked => 'Booked';

  @override
  String get describeSymptoms => 'Describe your Symptoms';

  @override
  String get symptomsHint => 'Please describe your symptoms in detail....';

  @override
  String get uploadMedicalDocs => 'Upload Medical Documents';

  @override
  String get tapToUpload => 'Tap to Upload image or PDF';

  @override
  String get uploadPaymentScreenshot => 'Upload Payment Screenshot';

  @override
  String get tapToUploadPayment => 'Tap to Upload Your Payment Screenshot';

  @override
  String get confirmReschedule => 'Confirm Reschedule';

  @override
  String get submitAppointmentRequest => 'Submit Appointment Request';

  @override
  String get invalidDoctorBooking => 'Invalid Doctor – Cannot book appointment';

  @override
  String get selectDateTime => 'Please select date and time';

  @override
  String rescheduleFailed(String error) {
    return 'Reschedule failed: $error';
  }

  @override
  String get paymentRequired => 'Payment screenshot required for Video Call';

  @override
  String get bookingFailed => 'Booking failed';

  @override
  String get completeSession => 'Complete Session';

  @override
  String get sessionCompleted => 'Session completed successfully!';

  @override
  String get failedCompleteSession => 'Failed to complete session';

  @override
  String get sessionPaymentDetails => 'Session Payment Details';

  @override
  String get enterSessionDetails =>
      'Enter the details to complete this session';

  @override
  String get patientFullName => 'Patient Full Name';

  @override
  String get enterPatientName => 'Enter patient\'s full name';

  @override
  String get patientNameRequired => 'Please enter patient name';

  @override
  String get payableAmount => 'Payable Amount (DZD)';

  @override
  String get enterAmountReceived => 'Enter amount received';

  @override
  String get amountRequired => 'Please enter amount';

  @override
  String get validAmountRequired => 'Please enter a valid amount';

  @override
  String get notificationTitle => 'Notification';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get markAllAsRead => 'Mark all as read';

  @override
  String get newNotifications => 'New';

  @override
  String get earlierNotifications => 'Earlier';

  @override
  String get noNotifications => 'No notifications';

  @override
  String get noNotificationsYet => 'No notifications yet';

  @override
  String get doctorNotificationEmptySubtitle =>
      'We\'ll notify you when a patient books or updates an appointment.';

  @override
  String get upcomingPatient => 'Upcoming Patient';

  @override
  String get addTextOrMedia => 'Please add some text or media to post';

  @override
  String get reelPrivacy => 'Reel Privacy';

  @override
  String get reelVisibleDoctorsOnly =>
      'This reel will be visible to doctors only.';

  @override
  String get reelVisibleEveryone =>
      'This reel will be visible to everyone (doctors and patients).';

  @override
  String currentPrivacy(Object privacy) {
    return 'Current privacy: $privacy';
  }

  @override
  String get privateDoctorsOnly => 'Private (Doctors Only)';

  @override
  String get publicEveryone => 'Public (Everyone)';

  @override
  String get uploadReel => 'Upload Reel';

  @override
  String get privateReelUploaded => '✓ Private reel uploaded! (Doctors only)';

  @override
  String get publicReelUploaded => '✓ Public reel uploaded! (Everyone can see)';

  @override
  String get failedUploadReel => 'Failed to upload reel';

  @override
  String get postSharedSuccessfully => '✓ Post shared successfully!';

  @override
  String get failedCreatePost => 'Failed to create post';

  @override
  String get whatsOnYourMind => 'What\'s on your mind?.......';

  @override
  String get videoSelected => 'Video Selected';

  @override
  String get failedLikePost => 'Failed to like post';

  @override
  String get deletePost => 'Delete Post';

  @override
  String get reportPost => 'Report Post';

  @override
  String get reportComingSoon => 'Report - Coming soon!';

  @override
  String get confirmDeletePost => 'Are you sure you want to delete this post?';

  @override
  String get delete => 'Delete';

  @override
  String get postDeletedSuccessfully => '✓ Post deleted successfully';

  @override
  String get failedDeletePost => 'Failed to delete post';

  @override
  String get sharePost => 'Share Post';

  @override
  String get shareExternally => 'Share Externally';

  @override
  String get sendMessage => 'Send Message';

  @override
  String get shareMessageComingSoon => 'Share to message - Coming soon!';

  @override
  String authorPosted(Object name) {
    return '$name posted:';
  }

  @override
  String imagesCount(Object count) {
    return '$count image(s)';
  }

  @override
  String videosCount(Object count) {
    return '$count video(s)';
  }

  @override
  String get noCommentsYet => 'No comments yet';

  @override
  String get writeComment => 'Write a comment...';

  @override
  String get likeLabel => 'Like';

  @override
  String get commentLabel => 'Comment';

  @override
  String get shareLabel => 'Share';

  @override
  String likesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'likes',
      one: 'like',
    );
    return '$count $_temp0';
  }

  @override
  String commentsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'comments',
      one: 'comment',
    );
    return '$count $_temp0';
  }

  @override
  String sharesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'shares',
      one: 'share',
    );
    return '$count $_temp0';
  }

  @override
  String get post => 'Post';

  @override
  String get commentsLabel => 'Comments';

  @override
  String get reelsLabel => 'Reels';

  @override
  String get failedLoadReels => 'Failed to load reels';

  @override
  String get retryLabel => 'Retry';

  @override
  String get noReelsAvailable => 'No reels available';

  @override
  String get unknownDoctor => 'Unknown Doctor';

  @override
  String get unknown => 'Unknown';

  @override
  String get doctorsOnlyLabel => 'Doctors Only';

  @override
  String get failedLikeReel => 'Failed to like reel';

  @override
  String authorSharedReel(Object name) {
    return '$name shared a reel';
  }

  @override
  String playbackSpeed(Object speed) {
    return '${speed}x Speed';
  }

  @override
  String get justNow => 'Just now';

  @override
  String get messagesLabel => 'Messages';

  @override
  String get allLabel => 'All';

  @override
  String get doctorsLabel => 'Doctors';

  @override
  String get patientsLabel => 'Patients';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get noConversationsYet => 'No conversations yet';

  @override
  String get deleteChats => 'Delete Chats';

  @override
  String get deleteMessages => 'Delete Messages';

  @override
  String deleteConversationsConfirm(Object count) {
    return 'Are you sure you want to delete $count conversations? This will remove all messages.';
  }

  @override
  String deleteMessagesConfirm(Object count) {
    return 'Are you sure you want to delete $count messages?';
  }

  @override
  String get deleteLabel => 'Delete';

  @override
  String get deleteReel => 'Delete Reel';

  @override
  String get deleteReelConfirm =>
      'Are you sure you want to delete this reel? This action cannot be undone.';

  @override
  String get reelDeleted => 'Reel deleted';

  @override
  String get failedDeleteReel => 'Failed to delete reel';

  @override
  String get conversationsDeleted => 'Conversations deleted';

  @override
  String get messagesDeleted => 'Messages deleted';

  @override
  String failedToDelete(Object error) {
    return 'Failed to delete: $error';
  }

  @override
  String startConversationWith(Object name) {
    return 'Start a conversation with $name';
  }

  @override
  String get typeAMessage => 'Type a message...';

  @override
  String get failedToSendMessage => 'Failed to send message';

  @override
  String get cannotStartCallNoId => 'Cannot start call - user ID not found';

  @override
  String failedToStartCall(Object error) {
    return 'Failed to start call: $error';
  }

  @override
  String get voiceCall => 'Voice Call';

  @override
  String get doctorUnavailableForCalls =>
      'Doctor is not available for calls at this time';

  @override
  String doctorUnavailableForCallsDescription(Object type) {
    return 'The doctor is not available for $type calls. You can send a message or try again later.';
  }

  @override
  String get imageLabel => '[Image]';

  @override
  String get fileLabel => '[File]';

  @override
  String get messageLabel => '[Message]';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get todayLabel => 'Today';

  @override
  String daysAgo(Object count) {
    return '${count}d ago';
  }

  @override
  String hoursAgo(Object count) {
    return '${count}h ago';
  }

  @override
  String minutesAgo(Object count) {
    return '${count}m ago';
  }

  @override
  String get meLabel => 'Me';

  @override
  String get patientLabel => 'Patient';

  @override
  String get doctorLabel => 'Doctor';

  @override
  String get startConversation => 'Start conversation';

  @override
  String get helpSupportComingSoon => 'Help & Support - Coming Soon';

  @override
  String get noDependentsAdded => 'No dependents added yet';

  @override
  String get addDependent => 'Add Dependent';

  @override
  String get editDependent => 'Edit Dependent';

  @override
  String get inactive => 'Inactive';

  @override
  String get active => 'Active';

  @override
  String get ageLabel => 'Age';

  @override
  String get genderLabel => 'Gender';

  @override
  String get contactLabel => 'Contact';

  @override
  String get deleteDependentTitle => 'Delete Dependent?';

  @override
  String deleteDependentConfirm(Object name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get deleteDependentWarning =>
      'If they have active appointments, you must cancel those first.';

  @override
  String get cannotDeleteTitle => 'Cannot Delete';

  @override
  String get howToFix => 'How to fix:';

  @override
  String get deleteFixInstructions =>
      '1. Go to My Appointments\n2. Cancel any pending/accepted appointments for this dependent\n3. Then try deleting again';

  @override
  String get goToAppointments => 'Go to Appointments';

  @override
  String dependentDeletedSuccess(Object name) {
    return '$name deleted successfully';
  }

  @override
  String get dependentAddedSuccess => 'Dependent added successfully!';

  @override
  String get dependentUpdatedSuccess => 'Dependent updated successfully!';

  @override
  String get failedToAddDependent => 'Failed to add dependent';

  @override
  String get failedToUpdateDependent => 'Failed to update dependent';

  @override
  String get basicInformation => 'Basic Information';

  @override
  String get nameIsRequired => 'Name is required';

  @override
  String get selectRelationship => 'Please select relationship';

  @override
  String get selectDob => 'Please select date of birth';

  @override
  String get relationshipLabel => 'Relationship';

  @override
  String get relationshipHint => 'Relationship (e.g. Child, Spouse)';

  @override
  String get contactDetails => 'Contact Details';

  @override
  String get guardianContactLabel => 'Parent/Guardian Contact (Primary)';

  @override
  String get userInfoWillBeUsed => 'Your user info will be used';

  @override
  String get dependentContactHint => 'Dependent\'s Contact (if applicable)';

  @override
  String get additionalInformation => 'Additional Information';

  @override
  String get medicalNotesHint => 'Medical Notes / Allergies (Optional)';

  @override
  String get saveDependent => 'Save Dependent';

  @override
  String get updateDependent => 'Update Dependent';

  @override
  String get relChild => 'Child';

  @override
  String get relSpouse => 'Spouse';

  @override
  String get relFather => 'Father';

  @override
  String get relMother => 'Mother';

  @override
  String get relBrother => 'Brother';

  @override
  String get relSister => 'Sister';

  @override
  String get relGrandparent => 'Grandparent';

  @override
  String get relOther => 'Other';

  @override
  String get relSon => 'Son';

  @override
  String get relDaughter => 'Daughter';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get edit => 'Edit';

  @override
  String get dateOfBirth => 'Date of Birth';

  @override
  String get editYourProfile => 'Edit Your Profile';

  @override
  String get profilePicture => 'Profile Picture';

  @override
  String get tapToChangePicture => 'Tap to Change your Picture';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get address => 'Address';

  @override
  String get updateProfile => 'Update Profile';

  @override
  String get profileUpdatedSuccess => 'Profile updated successfully';

  @override
  String get updateFailed => 'Update failed';

  @override
  String get nameEmptyError => 'Name cannot be empty';

  @override
  String get noChangesToSave => 'No changes to save';

  @override
  String errorMsg(Object error) {
    return 'Error: $error';
  }

  @override
  String get addBio => 'Add Bio';

  @override
  String get bioHint => 'Tell us about yourself...';

  @override
  String get degreeHint => 'MBBS, MD, etc.';

  @override
  String get emailLockedNote => 'Email cannot be changed';

  @override
  String get clinicLocation => 'Clinic Location';

  @override
  String get clinicLocationHint => 'Set your clinic location';

  @override
  String get contactNumberHint => 'Contact number';

  @override
  String get specCardiologist => 'Cardiologist';

  @override
  String get specDermatologist => 'Dermatologist';

  @override
  String get specNeurologist => 'Neurologist';

  @override
  String get specOrthopedic => 'Orthopedic';

  @override
  String get specPediatrician => 'Pediatrician';

  @override
  String get specPsychiatrist => 'Psychiatrist';

  @override
  String get specGeneralPhysician => 'General Physician';

  @override
  String get specENT => 'ENT Specialist';

  @override
  String get specGynecologist => 'Gynecologist';

  @override
  String get specOphthalmologist => 'Ophthalmologist';

  @override
  String get specDentist => 'Dentist';

  @override
  String get specUrologist => 'Urologist';

  @override
  String get statusLabel => 'Status';

  @override
  String get changePassword => 'Change Password';

  @override
  String get passwordLengthRequirement =>
      'Password must be at least 6 characters long';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get enterCurrentPassword => 'Enter current password';

  @override
  String get enterNewPassword => 'Enter new password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get reEnterNewPassword => 'Re-enter new password';

  @override
  String get passwordsDoNotMatchError =>
      'New password and confirm password do not match';

  @override
  String get passwordChangedSuccess => 'Password changed successfully';

  @override
  String get changePasswordFailed => 'Failed to change password';

  @override
  String get earningOverview => 'Earning Overview';

  @override
  String get trackIncomeSubtitle =>
      'Track your income across all appointment types.';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get totalEarning => 'Total Earning';

  @override
  String appointmentsCount(Object count) {
    return '$count appointments';
  }

  @override
  String sessionsCount(Object count) {
    return '$count sessions';
  }

  @override
  String get weeklyPerformance => 'Weekly Performance';

  @override
  String get failedFetchEarnings => 'Failed to fetch earnings';

  @override
  String get onlineAppointment => 'Online Appointment';

  @override
  String get consultationFees => 'Consultation Fees (DZD)';

  @override
  String get weeklySchedule => 'Weekly Schedule';

  @override
  String get sessionDuration => 'Session Duration';

  @override
  String get sessionDurationHint => 'Used when auto-generating slots';

  @override
  String get minuteShort => 'min';

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String get addNewSlot => 'Add New Slot';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get endTimeError => 'End time must be after start time';

  @override
  String get enterConsultationFees => 'Please enter consultation fees';

  @override
  String get scheduleSavedSuccess => 'Schedule saved successfully!';

  @override
  String get to => 'To';

  @override
  String get selectStartTime => 'Select Start Time';

  @override
  String get selectEndTime => 'Select End Time';

  @override
  String get selectTimeFromPicker => 'Please select time from the picker below';

  @override
  String get faqTitle => 'Frequently Asked Questions (FAQ)';

  @override
  String get faq1Question => '1. How do I create an account?';

  @override
  String get faq1Answer =>
      'You can sign up as a patient or doctor by choosing your role and completing the registration steps in the app.';

  @override
  String get faq2Question => '2. I forgot my password. What should I do?';

  @override
  String get faq2Answer =>
      'Go to the login screen and tap on “Forgot Password”. Follow the instructions to reset your password securely.';

  @override
  String get faq3Question => '3. How can I book an appointment with a doctor?';

  @override
  String get faq3Answer =>
      'Search for a doctor or specialty, select an available time slot, and confirm your appointment.';

  @override
  String get faq4Question => '4. Can I cancel or reschedule my appointment?';

  @override
  String get faq4Answer =>
      'Yes, you can cancel or reschedule appointments from the “My Appointments” section, depending on the appointment status.';

  @override
  String get faq5Question => '5. How do online audio/video consultations work?';

  @override
  String get faq5Answer =>
      'Once your appointment is confirmed, you can start an audio or video call directly from the chat at the scheduled time (if enabled by the doctor).';

  @override
  String get faq6Question => '6. Why can’t I start a call with the doctor?';

  @override
  String get faq6Answer =>
      'The doctor may have disabled audio/video calls temporarily. Please try again later or contact support.';

  @override
  String get faq7Question => '7. How do I change the app language?';

  @override
  String get faq7Answer =>
      'You can change the language from the app settings at any time.';

  @override
  String get faq8Question =>
      '8. How can doctors manage their profile information?';

  @override
  String get faq8Answer =>
      'Doctors can edit their personal and professional information from the profile settings.';

  @override
  String get faq9Question => '9. How does the referral system work?';

  @override
  String get faq9Answer =>
      'If referral codes are enabled, doctors can register using a valid referral code provided by the admin.';

  @override
  String get stillNeedHelp => 'Still need help?';

  @override
  String get emailUs => 'Email Us';

  @override
  String get callUs => 'Call Us';

  @override
  String get emailSubject => 'Help & Support Request';

  @override
  String get bookingSuccess => 'Appointment booked successfully!';

  @override
  String get deleteAccount => 'Delete Your account';

  @override
  String get applyFilter => 'Apply Filter';

  @override
  String get allDoctors => 'All Doctors';

  @override
  String get yourProfile => 'Your Profile';

  @override
  String get reviewsTitle => 'Reviews & Ratings';

  @override
  String get myReviews => 'My Reviews';

  @override
  String get noReviewsYet => 'No reviews yet';

  @override
  String get mesPatients => 'My Patients';

  @override
  String get searchPatient => 'Search patient...';

  @override
  String get noPatientsFound => 'No patients found';

  @override
  String patientsCount(int count) {
    return '$count patients';
  }

  @override
  String appointmentsCompletedOf(int completed, int total) {
    return '$completed completed of $total';
  }

  @override
  String get tapToViewDetails => 'Tap to view details';

  @override
  String get attachments => 'Attachments';

  @override
  String get noAttachments => 'No attachments';

  @override
  String get submitReview => 'Submit Review';

  @override
  String get failedReview => 'Failed to submit review';

  @override
  String get yourRating => 'Your Rating';

  @override
  String get yourComment => 'Your comment (optional)';

  @override
  String get howItWorks => 'How It Works';

  @override
  String get howItWorksSubtitle => 'Watch our tutorial videos to get started';

  @override
  String get doctorTutorialTitle => 'For Doctors';

  @override
  String get doctorTutorialDesc =>
      'Learn how to manage your appointments, connect with patients, and grow your practice using DocMobi.';

  @override
  String get patientTutorialTitle => 'For Patients';

  @override
  String get patientTutorialDesc =>
      'Discover how to find doctors near you, book appointments, and manage your health with DocMobi.';

  @override
  String get watchVideo => 'Watch Video';
}
