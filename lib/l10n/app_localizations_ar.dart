// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'دوك موبي';

  @override
  String get welcome => 'أهلاً بك';

  @override
  String get settings => 'الإعدادات';

  @override
  String get changeLanguage => 'تغيير اللغة';

  @override
  String get english => 'الإنجليزية';

  @override
  String get arabic => 'العربية';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get french => 'الفرنسية';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navAppointments => 'المواعيد';

  @override
  String get navReels => 'الريلز';

  @override
  String get navMessages => 'الرسائل';

  @override
  String get navProfile => 'الملف الشخصي';

  @override
  String get personalInfo => 'المعلومات الشخصية';

  @override
  String get myAppointment => 'موعدي';

  @override
  String get myDependents => 'المعالين';

  @override
  String get appointmentSetting => 'إعدادات المواعيد';

  @override
  String get myEarning => 'أرباحي';

  @override
  String get changePasswordLabel => 'تغيير كلمة المرور';

  @override
  String get helpSupport => 'المساعدة والدعم';

  @override
  String get logOut => 'تسجيل الخروج';

  @override
  String get loading => 'جارٍ التحميل...';

  @override
  String get checkingAuth => 'التحقق من المصادقة';

  @override
  String get invalidSession => 'جلسة غير صالحة';

  @override
  String get sessionExpiredMessage =>
      'جلستك غير صالحة.\nيرجى تسجيل الدخول مرة أخرى.';

  @override
  String get goToLogin => 'الذهاب إلى تسجيل الدخول';

  @override
  String get searchDoctorHint => 'البحث عن طبيب...';

  @override
  String get locationServicesDisabledTitle => 'خدمات الموقع معطلة';

  @override
  String get locationServicesDisabledMessage =>
      'خدمات الموقع معطلة. يرجى تمكينها لرؤية الأطباء القريبين.';

  @override
  String get locationPermissionRequiredTitle => 'مطلوب إذن الموقع';

  @override
  String get locationPermissionRequiredMessage =>
      'مطلوب إذن الموقع لإظهار الأطباء القريبين. يرجى منح الإذن في إعدادات التطبيق.';

  @override
  String get openSettings => 'افتح الإعدادات';

  @override
  String get cancel => 'إلغاء';

  @override
  String get loadingRoute => 'جارٍ تحميل المسار...';

  @override
  String get directionsApiDisabled =>
      'لم يتم تفعيل واجهة برمجة تطبيقات الاتجاهات. استخدام مسار الخط المستقيم.';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get loadingMap => 'جارٍ تحميل الخريطة...';

  @override
  String get distance => 'المسافة';

  @override
  String get upcomingAppointment => 'المواعيد القادمة';

  @override
  String get nearbyDoctors => 'أطباء قريبون';

  @override
  String get seeAll => 'مشاهدة الكل';

  @override
  String get noDoctorsFound => 'لم يتم العثور على أطباء';

  @override
  String get available => 'متاح';

  @override
  String get noSchedule => 'لا يوجد جدول';

  @override
  String get videoConsultation => 'استشارة فيديو';

  @override
  String get bookNow => 'احجز الآن';

  @override
  String get notAvailable => 'غير متاح';

  @override
  String get noScheduleSet => 'لم يتم تعيين جدول زمني';

  @override
  String searchFailed(String error) {
    return 'فشل البحث: $error';
  }

  @override
  String get sessionExpiredTitle => 'انتهت الجلسة';

  @override
  String get sessionExpiredMessageDoc =>
      'انتهت صلاحية جلستك. يرجى تسجيل الدخول مرة أخرى.';

  @override
  String get ok => 'حسناً';

  @override
  String get failedLoadPosts => 'فشل تحميل المنشورات';

  @override
  String get connectionError => 'خطأ في الاتصال. يرجى المحاولة مرة أخرى.';

  @override
  String get searchHintDoctor => 'ابحث عن أطباء، منشورات، تخصصات...';

  @override
  String get suggestions => 'اقتراحات';

  @override
  String get searching => 'جارٍ البحث...';

  @override
  String get searchAnything => 'ابحث عن أي شيء';

  @override
  String get findEverything => 'ابحث عن أطباء، منشورات، أو تخصصات';

  @override
  String get noResultsFound => 'لم يتم العثور على نتائج';

  @override
  String get tryDifferentKeywords => 'حاول البحث بكلمات رئيسية مختلفة';

  @override
  String get posts => 'المنشورات';

  @override
  String get noPostsYet => 'لا توجد منشورات بعد. كن أول من يشارك!';

  @override
  String get shareInsights => 'شارك أفكارك مع زملائك الأطباء...';

  @override
  String get photo => 'صور';

  @override
  String get video => 'فيديو';

  @override
  String get reels => 'ريلز';

  @override
  String get createPost => 'إنشاء منشور';

  @override
  String yearsExperience(int years) {
    return '$years سنوات الخبرة';
  }

  @override
  String get noBioAvailable => 'لا توجد سيرة ذاتية متاحة';

  @override
  String get message => 'رسالة';

  @override
  String get welcomeBack => 'مرحباً بعودتك';

  @override
  String loginToAccountAs(String userType) {
    return 'يرجى تسجيل الدخول إلى حسابك كـ $userType';
  }

  @override
  String get emailAddress => 'بريد إلكتروني';

  @override
  String get emailHint => 'you@gmail.com';

  @override
  String get password => 'كلمة المرور';

  @override
  String get passwordHint => '****************';

  @override
  String get forgotPassword => 'هل نسيت كلمة المرور؟';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get dontHaveAccount => 'ليس لديك حساب؟ ';

  @override
  String get signup => 'إنشاء حساب';

  @override
  String welcomeBackUser(String userName) {
    return 'مرحباً بعودتك، $userName!';
  }

  @override
  String get invalidAccountType => 'نوع الحساب غير صالح';

  @override
  String accountRegisteredAs(String role) {
    return 'هذا الحساب مسجل كـ $role. يرجى استخدام خيار تسجيل الدخول الصحيح.';
  }

  @override
  String get loginFailed =>
      'فشل تسجيل الدخول. يرجى التحقق من بيانات الاعتماد الخاصة بك.';

  @override
  String get enterEmail => 'يرجى إدخال بريدك الإلكتروني';

  @override
  String createAccount(String userType) {
    return 'إنشاء حساب $userType';
  }

  @override
  String get fillDetails => 'يرجى ملء التفاصيل أدناه';

  @override
  String get fullName => 'الاسم الكامل *';

  @override
  String get enterFullName => 'أدخل اسمك الكامل';

  @override
  String get emailAddressStar => 'البريد الإلكتروني *';

  @override
  String get emailExample => 'you@example.com';

  @override
  String get invalidEmail => 'يرجى إدخال بريد إلكتروني صالح';

  @override
  String get medicalLicenseNumber => 'رقم الترخيص الطبي *';

  @override
  String get enterLicenseNumber => 'أدخل رقم الترخيص';

  @override
  String get referralCode => 'رمز الإحالة';

  @override
  String get enterReferralCode => 'أدخل رمز الإحالة';

  @override
  String get medicalSpecialty => 'التخصص الطبي *';

  @override
  String get selectSpecialty => 'اختر التخصص';

  @override
  String get yearsExperienceStar => 'سنوات الخبرة *';

  @override
  String get yearsExperienceExample => 'مثال: 5';

  @override
  String get passwordStar => 'كلمة المرور *';

  @override
  String get passwordLength => '6 أحرف على الأقل';

  @override
  String get confirmPasswordStar => 'تأكيد كلمة المرور *';

  @override
  String get reenterPassword => 'أعد إدخال كلمة المرور';

  @override
  String get passwordsDoNotMatch => 'كلمات المرور غير متطابقة';

  @override
  String get passwordAtLeast6 => 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';

  @override
  String get licenseRequired => 'رقم الترخيص الطبي مطلوب';

  @override
  String get specialtyRequired => 'يرجى اختيار التخصص';

  @override
  String get experienceRequired => 'سنوات الخبرة مطلوبة';

  @override
  String get registrationSuccessful => 'تم التسجيل بنجاح!';

  @override
  String get alreadyHaveAccount => 'لديك حساب بالفعل؟ ';

  @override
  String get signInLabel => 'تسجيل الدخول';

  @override
  String get createAccountBtn => 'إنشاء حساب';

  @override
  String get forgotPasswordTitle => 'نسيت كلمة المرور';

  @override
  String get selectContactReset =>
      'حدد تفاصيل الاتصال التي يجب أن نستخدمها لإعادة تعيين كلمة المرور الخاصة بك';

  @override
  String get emailLabel => 'البريد الإلكتروني:';

  @override
  String get enterYourEmail => 'أدخل بريدك الإلكتروني';

  @override
  String get sending => 'جاري الإرسال...';

  @override
  String get continueText => 'متابعة';

  @override
  String get otpTitle => 'رمز التحقق';

  @override
  String get sentCodeEmail =>
      'لقد أرسلنا لك رمزاً لمرة واحدة إلى بريدك الإلكتروني';

  @override
  String get valid6DigitOtp => 'يرجى إدخال رمز تحقق صالح من 6 أرقام';

  @override
  String get emailNotFound =>
      'البريد الإلكتروني غير موجود. يرجى إعادة بدء العملية.';

  @override
  String get otpSentAgain => 'تم إعادة إرسال رمز التحقق بنجاح';

  @override
  String get didntGetCode => 'لم يصلك الرمز؟ ';

  @override
  String get resend => 'إعادة إرسال';

  @override
  String get resending => 'جاري إعادة الإرسال...';

  @override
  String get verifying => 'جاري التحقق...';

  @override
  String get resetPasswordTitle => 'إعادة تعيين كلمة المرور';

  @override
  String get setNewPassword => 'قم بتعيين كلمة مرور جديدة لحسابك';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get fillAllFields => 'يرجى ملء جميع الحقول';

  @override
  String get success => 'نجاح';

  @override
  String get passwordResetSuccess => 'تم إعادة تعيين كلمة المرور بنجاح';

  @override
  String get resetting => 'جاري إعادة التعيين...';

  @override
  String get appointmentManagement => 'إدارة المواعيد';

  @override
  String get manageConsultations => 'إدارة المشاورات المرئية\nوالجسدية';

  @override
  String get pending => 'قيد الانتظار';

  @override
  String get confirmed => 'مؤكد';

  @override
  String get completed => 'مكتمل';

  @override
  String noAppointments(String status) {
    return 'لا توجد مواعيد $status';
  }

  @override
  String forDependent(String name) {
    return 'من أجل: $name';
  }

  @override
  String get physical => 'جسدي';

  @override
  String get seeDetails => 'انظر التفاصيل';

  @override
  String get accept => 'قبول';

  @override
  String get startSession => 'بدء الجلسة';

  @override
  String get appointmentDetails => 'تفاصيل الموعد';

  @override
  String get patientInformation => 'معلومات المريض';

  @override
  String bookedFor(String name) {
    return 'محجوز لـ: $name';
  }

  @override
  String get symptoms => 'الأعراض';

  @override
  String get noSymptoms => 'لم يتم تقديم أي أعراض';

  @override
  String get medicalDocuments => 'المستندات الطبية';

  @override
  String docsUploaded(int count) {
    return 'تم تحميل $count مستند(ات)';
  }

  @override
  String get noDocsUploaded => 'لم يتم تحميل أي مستندات طبية';

  @override
  String get paymentScreenshot => 'لقطة شاشة الدفع';

  @override
  String get viewPaymentScreenshot => 'عرض لقطة شاشة الدفع';

  @override
  String get noPaymentScreenshot => 'لم يتم تحميل لقطة شاشة الدفع';

  @override
  String get documentUrl => 'رابط المستند';

  @override
  String get close => 'إغلاق';

  @override
  String errorOpeningDoc(String error) {
    return 'خطأ في فتح المستند: $error';
  }

  @override
  String get cancelAppointment => 'إلغاء الموعد';

  @override
  String get confirmCancel => 'هل أنت متأكد أنك تريد إلغاء هذا الموعد؟';

  @override
  String get no => 'لا';

  @override
  String get yes => 'نعم';

  @override
  String get appointmentAccepted => 'تم قبول الموعد بنجاح';

  @override
  String get failedAccept => 'فشل قبول الموعد';

  @override
  String get appointmentCancelled => 'تم إلغاء الموعد';

  @override
  String get cancelled => 'ملغي';

  @override
  String get failedCancel => 'فشل إلغاء الموعد';

  @override
  String get loadingImage => 'جاري تحميل الصورة...';

  @override
  String get failedLoadImage => 'فشل تحميل الصورة';

  @override
  String get medicalDocument => 'مستند طبي';

  @override
  String get resetZoom => 'إعادة تعيين الزووم';

  @override
  String get zoomInstructions => 'قرصة للتكبير • سحب للتحريك';

  @override
  String get upcoming => 'القادم';

  @override
  String upcomingCount(int count) {
    return 'القادم ($count)';
  }

  @override
  String get reschedule => 'إعادة جدولة';

  @override
  String get writeReview => 'اكتب تقييمًا';

  @override
  String get updateReview => 'تحديث تقييمك';

  @override
  String get rateExperience => 'قيم تجربتك';

  @override
  String withDoctor(String name) {
    return 'مع $name';
  }

  @override
  String get reviewSubmitted => 'تم تقديم التقييم بنجاح!';

  @override
  String get failedSubmitReview => 'فشل في تقديم التقييم';

  @override
  String get submit => 'إرسال';

  @override
  String get doctor => 'طبيب';

  @override
  String get videoAvailable => 'الاستشارة المرئية متاحة';

  @override
  String get inPersonOnly => 'حضور شخصي فقط';

  @override
  String reviewsCount(int count) {
    return '($count تقييمات)';
  }

  @override
  String get bio => 'السيرة الذاتية';

  @override
  String get specialty => 'التخصص';

  @override
  String get degree => 'الدرجة العلمية';

  @override
  String get fees => 'الرسوم';

  @override
  String get dzd => 'د.ج';

  @override
  String get visitingHours => 'ساعات الزيارة';

  @override
  String get notSet => 'غير محدد';

  @override
  String get messageDoctor => 'مراسلة الطبيب';

  @override
  String get invalidDoctor => 'طبيب غير صالح';

  @override
  String get doctorIdNotFound => 'معرف الطبيب غير موجود';

  @override
  String get failedCreateChat => 'فشل في إنشاء الدردشة';

  @override
  String get failedOpenChat => 'فشل في فتح الدردشة';

  @override
  String get physicalVisit => 'زيارة في العيادة';

  @override
  String get videoCall => 'مكالمة فيديو';

  @override
  String get rescheduleAppointment => 'إعادة جدولة الموعد';

  @override
  String get bookAppointment => 'حجز موعد';

  @override
  String get rescheduleBanner =>
      'أنت تقوم بإعادة جدولة موعدك. سيتم إلغاء الموعد القديم.';

  @override
  String get videoUploadWarning =>
      'المواعيد المرئية - يجب على المريض\nتحميل لقطة شاشة لعملية دفع BaridiMob';

  @override
  String get appointmentTypeLabel => 'نوع الموعد';

  @override
  String get payAtClinic => 'الدفع في العيادة';

  @override
  String get onlinePayment => 'الدفع عبر الإنترنت';

  @override
  String get bookAppointmentFor => 'حجز موعد لـ';

  @override
  String get myself => 'نفسي';

  @override
  String get orSelectDependent => 'أو اختر أحد التابعين:';

  @override
  String get addNewDependent => 'إضافة تابع جديد';

  @override
  String get selectDate => 'اختر التاريخ';

  @override
  String get datePlaceholder => 'يوم/شهر/سنة';

  @override
  String get availableTime => 'الوقت المتاح';

  @override
  String get noTimeSlots => 'لا توجد مواعيد متاحة لهذا التاريخ';

  @override
  String get timeTo => 'إلى';

  @override
  String get booked => 'محجوز';

  @override
  String get describeSymptoms => 'صف أعراضك';

  @override
  String get symptomsHint => 'يرجى وصف أعراضك بالتفصيل....';

  @override
  String get uploadMedicalDocs => 'تحميل المستندات الطبية';

  @override
  String get tapToUpload => 'اضغط لتحميل صورة أو ملف PDF';

  @override
  String get uploadPaymentScreenshot => 'تحميل لقطة شاشة عملية الدفع';

  @override
  String get tapToUploadPayment => 'اضغط لتحميل لقطة شاشة الدفع الخاصة بك';

  @override
  String get confirmReschedule => 'تأكيد إعادة الجدولة';

  @override
  String get submitAppointmentRequest => 'إرسال طلب الموعد';

  @override
  String get invalidDoctorBooking => 'طبيب غير صالح - لا يمكن حجز موعد';

  @override
  String get selectDateTime => 'يرجى اختيار التاريخ والوقت';

  @override
  String rescheduleFailed(String error) {
    return 'فشلت إعادة الجدولة: $error';
  }

  @override
  String get paymentRequired => 'لقطة شاشة الدفع مطلوبة لاستشارة الفيديو';

  @override
  String get bookingFailed => 'فشل الحجز';

  @override
  String get completeSession => 'إتمام الجلسة';

  @override
  String get sessionCompleted => 'تم إتمام الجلسة بنجاح! ✅';

  @override
  String get failedCompleteSession => 'فشل في إتمام الجلسة';

  @override
  String get sessionPaymentDetails => 'تفاصيل دفع الجلسة';

  @override
  String get enterSessionDetails => 'أدخل التفاصيل لإتمام هذه الجلسة';

  @override
  String get patientFullName => 'الاسم الكامل للمريض';

  @override
  String get enterPatientName => 'أدخل الاسم الكامل للمريض';

  @override
  String get patientNameRequired => 'يرجى إدخال اسم المريض';

  @override
  String get payableAmount => 'المبلغ المستحق (د.ج)';

  @override
  String get enterAmountReceived => 'أدخل المبلغ المستلم';

  @override
  String get amountRequired => 'يرجى إدخال المبلغ';

  @override
  String get validAmountRequired => 'يرجى إدخال مبلغ صالح';

  @override
  String get notificationTitle => 'إشعار';

  @override
  String get notificationsTitle => 'إشعارات';

  @override
  String get markAllAsRead => 'تحديد الكل كمقروء';

  @override
  String get newNotifications => 'جديد';

  @override
  String get earlierNotifications => 'سابقاً';

  @override
  String get noNotifications => 'لا توجد إشعارات';

  @override
  String get noNotificationsYet => 'لا توجد إشعارات بعد';

  @override
  String get doctorNotificationEmptySubtitle =>
      'سنخطرك عندما يقوم مريض بحجز أو تحديث موعد.';

  @override
  String get upcomingPatient => 'المريض القادم';

  @override
  String get addTextOrMedia => 'يرجى إضافة نص أو وسائط للنشر';

  @override
  String get reelPrivacy => 'خصوصية Reel';

  @override
  String get reelVisibleDoctorsOnly =>
      '🔒 سيكون هذا الـ reel مرئياً للأطباء فقط.';

  @override
  String get reelVisibleEveryone =>
      '🌍 سيكون هذا الـ reel مرئياً للجميع (الأطباء والمرضى).';

  @override
  String currentPrivacy(Object privacy) {
    return 'الخصوصية الحالية: $privacy';
  }

  @override
  String get privateDoctorsOnly => 'خاص (للأطباء فقط)';

  @override
  String get publicEveryone => 'عام (للجميع)';

  @override
  String get uploadReel => 'تحميل Reel';

  @override
  String get privateReelUploaded => '✓ تم تحميل Reel خاص! (للأطباء فقط)';

  @override
  String get publicReelUploaded => '✓ تم تحميل Reel عام! (يمكن للجميع رؤيته)';

  @override
  String get failedUploadReel => 'فشل تحميل الـ reel';

  @override
  String get postSharedSuccessfully => '✓ تم مشاركة المنشور بنجاح!';

  @override
  String get failedCreatePost => 'فشل في إنشاء المنشور';

  @override
  String get whatsOnYourMind => 'بماذا تفكر؟.......';

  @override
  String get videoSelected => 'تم اختيار الفيديو';

  @override
  String get failedLikePost => 'فشل في الإعجاب بالمنشور';

  @override
  String get deletePost => 'حذف المنشور';

  @override
  String get reportPost => 'الإبلاغ عن المنشور';

  @override
  String get reportComingSoon => 'الإبلاغ - قريباً!';

  @override
  String get confirmDeletePost => 'هل أنت متأكد أنك تريد حذف هذا المنشور؟';

  @override
  String get delete => 'حذف';

  @override
  String get postDeletedSuccessfully => '✓ تم حذف المنشور بنجاح';

  @override
  String get failedDeletePost => 'فشل في حذف المنشور';

  @override
  String get sharePost => 'مشاركة المنشور';

  @override
  String get shareExternally => 'مشاركة خارجيًا';

  @override
  String get sendMessage => 'إرسال رسالة';

  @override
  String get shareMessageComingSoon => 'المشاركة في رسالة - قريباً!';

  @override
  String authorPosted(Object name) {
    return 'نشر $name:';
  }

  @override
  String imagesCount(Object count) {
    return '$count صورة';
  }

  @override
  String videosCount(Object count) {
    return '$count فيديو';
  }

  @override
  String get noCommentsYet => 'لا توجد تعليقات بعد';

  @override
  String get writeComment => 'اكتب تعليقاً...';

  @override
  String get likeLabel => 'إعجاب';

  @override
  String get commentLabel => 'تعليق';

  @override
  String get shareLabel => 'مشاركة';

  @override
  String likesCount(num count) {
    return '$count إعجاب';
  }

  @override
  String commentsCount(num count) {
    return '$count تعليق';
  }

  @override
  String sharesCount(num count) {
    return '$count مشاركة';
  }

  @override
  String get post => 'نشر';

  @override
  String get commentsLabel => 'التعليقات';

  @override
  String get reelsLabel => 'ريلز';

  @override
  String get failedLoadReels => 'فشل تحميل الريلز';

  @override
  String get retryLabel => 'إعادة المحاولة';

  @override
  String get noReelsAvailable => 'لا يوجد ريلز متوفرة';

  @override
  String get unknownDoctor => 'طبيب غير معروف';

  @override
  String get unknown => 'غير معروف';

  @override
  String get doctorsOnlyLabel => 'للأطباء فقط';

  @override
  String get failedLikeReel => 'فشل الإعجاب بالريل';

  @override
  String authorSharedReel(Object name) {
    return '$name شارك ريل';
  }

  @override
  String playbackSpeed(Object speed) {
    return 'سرعة ${speed}x';
  }

  @override
  String get justNow => 'الآن';

  @override
  String get messagesLabel => 'الرسائل';

  @override
  String get allLabel => 'الكل';

  @override
  String get doctorsLabel => 'الأطباء';

  @override
  String get patientsLabel => 'المرضى';

  @override
  String get noMessagesYet => 'لا توجد رسائل بعد';

  @override
  String get noConversationsYet => 'لا توجد محادثات بعد';

  @override
  String get deleteChats => 'حذف المحادثات';

  @override
  String get deleteMessages => 'حذف الرسائل';

  @override
  String deleteConversationsConfirm(Object count) {
    return 'هل أنت متأكد أنك تريد حذف $count محادثات؟ سيؤدي هذا إلى إزالة جميع الرسائل.';
  }

  @override
  String deleteMessagesConfirm(Object count) {
    return 'هل أنت متأكد أنك تريد حذف $count رسائل؟';
  }

  @override
  String get deleteLabel => 'حذف';

  @override
  String get conversationsDeleted => 'تم حذف المحادثات';

  @override
  String get messagesDeleted => 'تم حذف الرسائل';

  @override
  String failedToDelete(Object error) {
    return 'فشل الحذف: $error';
  }

  @override
  String startConversationWith(Object name) {
    return 'ابدأ محادثة مع $name';
  }

  @override
  String get typeAMessage => 'اكتب رسالة...';

  @override
  String get failedToSendMessage => 'فشل إرسال الرسالة';

  @override
  String get cannotStartCallNoId =>
      'لا يمكن بدء المكالمة - معرف المستخدم غير موجود';

  @override
  String failedToStartCall(Object error) {
    return 'فشل بدء المكالمة: $error';
  }

  @override
  String get voiceCall => 'مكالمة صوتية';

  @override
  String get imageLabel => '[صورة]';

  @override
  String get fileLabel => '[ملف]';

  @override
  String get messageLabel => '[رسالة]';

  @override
  String get yesterday => 'أمس';

  @override
  String get todayLabel => 'اليوم';

  @override
  String daysAgo(Object count) {
    return 'منذ $count يوم';
  }

  @override
  String hoursAgo(Object count) {
    return 'منذ $count ساعة';
  }

  @override
  String minutesAgo(Object count) {
    return 'منذ $count دقيقة';
  }

  @override
  String get meLabel => 'أنا';

  @override
  String get patientLabel => 'مريض';

  @override
  String get doctorLabel => 'طبيب';

  @override
  String get startConversation => 'بدء المحادثة';

  @override
  String get helpSupportComingSoon => 'المساعدة والدعم - قريباً';

  @override
  String get noDependentsAdded => 'لم يتم إضافة معالين بعد';

  @override
  String get addDependent => 'إضافة معال';

  @override
  String get editDependent => 'تعديل المعال';

  @override
  String get inactive => 'غير نشط';

  @override
  String get active => 'نشط';

  @override
  String get ageLabel => 'العمر';

  @override
  String get genderLabel => 'الجنس';

  @override
  String get contactLabel => 'جهة الاتصال';

  @override
  String get deleteDependentTitle => 'حذف المعال؟';

  @override
  String deleteDependentConfirm(Object name) {
    return 'هل أنت متأكد أنك تريد حذف \"$name\"؟';
  }

  @override
  String get deleteDependentWarning =>
      'إذا كان لديهم مواعيد نشطة، يجب عليك إلغاؤها أولاً.';

  @override
  String get cannotDeleteTitle => 'تعذر الحذف';

  @override
  String get howToFix => 'كيفية الإصلاح:';

  @override
  String get deleteFixInstructions =>
      '1. انتقل إلى مواعيدي\n2. قم بإلغاء أي مواعيد معلقة/مقبولة لهذا المعال\n3. ثم حاول الحذف مرة أخرى';

  @override
  String get goToAppointments => 'انتقل إلى المواعيد';

  @override
  String dependentDeletedSuccess(Object name) {
    return 'تم حذف $name بنجاح';
  }

  @override
  String get dependentAddedSuccess => 'تم إضافة المعال بنجاح!';

  @override
  String get dependentUpdatedSuccess => 'تم تحديث المعال بنجاح!';

  @override
  String get failedToAddDependent => 'فشل في إضافة المعال';

  @override
  String get failedToUpdateDependent => 'فشل في تحديث المعال';

  @override
  String get basicInformation => 'معلومات أساسية';

  @override
  String get nameIsRequired => 'الاسم مطلوب';

  @override
  String get selectRelationship => 'يرجى اختيار صلة القرابة';

  @override
  String get selectDob => 'يرجى اختيار تاريخ الميلاد';

  @override
  String get relationshipLabel => 'صلة القرابة';

  @override
  String get relationshipHint => 'صلة القرابة (مثلاً: طفل، زوج)';

  @override
  String get contactDetails => 'تفاصيل الاتصال';

  @override
  String get guardianContactLabel => 'جهة اتصال ولي الأمر (أساسي)';

  @override
  String get userInfoWillBeUsed => 'سيتم استخدام معلومات المستخدم الخاصة بك';

  @override
  String get dependentContactHint => 'جهة اتصال المعال (إن وجد)';

  @override
  String get additionalInformation => 'معلومات إضافية';

  @override
  String get medicalNotesHint => 'ملاحظات طبية / حساسيات (اختياري)';

  @override
  String get saveDependent => 'حفظ المعال';

  @override
  String get updateDependent => 'تحديث المعال';

  @override
  String get relChild => 'طفل';

  @override
  String get relSpouse => 'زوج/زوجة';

  @override
  String get relFather => 'أب';

  @override
  String get relMother => 'أم';

  @override
  String get relBrother => 'أخ';

  @override
  String get relSister => 'أخت';

  @override
  String get relGrandparent => 'جد/جدة';

  @override
  String get relOther => 'آخر';

  @override
  String get relSon => 'ابن';

  @override
  String get relDaughter => 'ابنة';

  @override
  String get male => 'ذكر';

  @override
  String get female => 'أنثى';

  @override
  String get edit => 'تعديل';

  @override
  String get dateOfBirth => 'تاريخ الميلاد';

  @override
  String get editYourProfile => 'تعديل ملفك الشخصي';

  @override
  String get profilePicture => 'الصورة الشخصية';

  @override
  String get tapToChangePicture => 'انقر لتغيير صورتك';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get address => 'العنوان';

  @override
  String get updateProfile => 'تحديث الملف الشخصي';

  @override
  String get profileUpdatedSuccess => 'تم تحديث الملف الشخصي بنجاح';

  @override
  String get updateFailed => 'فشل التحديث';

  @override
  String get nameEmptyError => 'لا يمكن أن يكون الاسم فارغاً';

  @override
  String get noChangesToSave => 'لا توجد تغييرات لحفظها';

  @override
  String errorMsg(Object error) {
    return 'خطأ: $error';
  }

  @override
  String get addBio => 'إضافة نبذة شخصية';

  @override
  String get bioHint => 'أخبرنا عن نفسك...';

  @override
  String get degreeHint => 'بكالوريوس طب، دكتوراه، إلخ.';

  @override
  String get emailLockedNote => 'لا يمكن تغيير البريد الإلكتروني';

  @override
  String get clinicLocation => 'موقع العيادة';

  @override
  String get clinicLocationHint => 'حدد موقع عيادتك';

  @override
  String get contactNumberHint => 'رقم الاتصال';

  @override
  String get specCardiologist => 'طبيب قلب';

  @override
  String get specDermatologist => 'طبيب جلدية';

  @override
  String get specNeurologist => 'طبيب أعصاب';

  @override
  String get specOrthopedic => 'طبيب عظام';

  @override
  String get specPediatrician => 'طبيب أطفال';

  @override
  String get specPsychiatrist => 'طبيب نفسي';

  @override
  String get specGeneralPhysician => 'ممارس عام';

  @override
  String get specENT => 'أخصائي أنف وأذن وحنجرة';

  @override
  String get specGynecologist => 'طبيب نساء وتوليد';

  @override
  String get specOphthalmologist => 'طبيب عيون';

  @override
  String get specDentist => 'طبيب أسنان';

  @override
  String get specUrologist => 'طبيب مسالك بولية';

  @override
  String get statusLabel => 'الحالة';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get passwordLengthRequirement =>
      'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل';

  @override
  String get currentPassword => 'كلمة المرور الحالية';

  @override
  String get enterCurrentPassword => 'أدخل كلمة المرور الحالية';

  @override
  String get enterNewPassword => 'أدخل كلمة المرور الجديدة';

  @override
  String get confirmNewPassword => 'تأكيد كلمة المرور الجديدة';

  @override
  String get reEnterNewPassword => 'أعد إدخال كلمة المرور الجديدة';

  @override
  String get passwordsDoNotMatchError =>
      'كلمة المرور الجديدة وتأكيدها غير متطابقين';

  @override
  String get passwordChangedSuccess => 'تم تغيير كلمة المرور بنجاح';

  @override
  String get changePasswordFailed => 'فشل تغيير كلمة المرور';

  @override
  String get earningOverview => 'نظرة عامة على الأرباح';

  @override
  String get trackIncomeSubtitle => 'تتبع دخلك في جميع أنواع المواعيد.';

  @override
  String get daily => 'يومي';

  @override
  String get weekly => 'أسبوعي';

  @override
  String get monthly => 'شهري';

  @override
  String get totalEarning => 'إجمالي الأرباح';

  @override
  String appointmentsCount(Object count) {
    return '$count المواعيد';
  }

  @override
  String sessionsCount(Object count) {
    return '$count جلسات';
  }

  @override
  String get weeklyPerformance => 'الأداء الأسبوعي';

  @override
  String get failedFetchEarnings => 'فشل في جلب الأرباح';

  @override
  String get onlineAppointment => 'مواعيد عبر الإنترنت';

  @override
  String get consultationFees => 'رسوم الاستشارة (دز)';

  @override
  String get weeklySchedule => 'الجدول الأسبوعي';

  @override
  String get addNewSlot => 'إضافة موعد جديد';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get endTimeError => 'يجب أن يكون وقت النهاية بعد وقت البدء';

  @override
  String get enterConsultationFees => 'يرجى إدخال رسوم الاستشارة';

  @override
  String get scheduleSavedSuccess => 'تم حفظ الجدول بنجاح!';

  @override
  String get to => 'إلى';

  @override
  String get selectStartTime => 'اختيار وقت البدء';

  @override
  String get selectEndTime => 'اختيار وقت النهاية';

  @override
  String get selectTimeFromPicker => 'يرجى اختيار الوقت من المختار بالأسفل';
}
