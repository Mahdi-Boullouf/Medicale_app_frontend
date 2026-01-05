class ApiConfig {
  // ========== Base URL ==========
  // Production e change korben: 'https://yourdomain.com'
  static const String baseUrl = 'http://localhost:5000';
  
  // ========== Auth Endpoints ==========
  static const String register = '/api/v1/auth/register';
  static const String login = '/api/v1/auth/login';
  static const String logout = '/api/v1/auth/logout';
  static const String forgotPassword = '/api/v1/auth/forgot-password';
  static const String resetPassword = '/api/v1/auth/reset-password';
  static const String verifyOTP = '/api/v1/auth/verify-otp';
  static const String refreshToken = '/api/v1/auth/refresh-token';
  static const String changePassword = '/api/v1/auth/change-password';
  
  // ========== User Endpoints ==========
  static const String profile = '/api/v1/user/profile';
  static const String userProfile = '/api/v1/user/profile';
  static const String updateProfile = '/api/v1/user/profile/update';
  static const String getUserById = '/api/v1/user';
  static const String deleteUser = '/api/v1/user';
  
  // ========== Appointment Endpoints ==========
  static const String appointments = '/api/v1/appointment';
  static const String createAppointment = '/api/v1/appointment';
  static const String getAppointmentById = '/api/v1/appointment'; // + /:id
  static const String updateAppointment = '/api/v1/appointment'; // + /:id
  static const String deleteAppointment = '/api/v1/appointment'; // + /:id
  static const String cancelAppointment = '/api/v1/appointment'; // + /:id/status
  static const String patientAppointments = '/api/v1/appointment/patient';
  static const String doctorAppointments = '/api/v1/appointment/doctor';
  static const String upcomingAppointments = '/api/v1/appointment/upcoming';
  static const String pastAppointments = '/api/v1/appointment/past';
  
  // ========== Doctor Endpoints ==========
  static const String doctors = '/api/v1/user/role/doctor';
  static const String doctorById = '/api/v1/user';
  static const String searchDoctors = '/api/v1/user/role/doctor';
  static const String nearbyDoctors = '/api/v1/user/role/doctor/nearby';
  static const String doctorsBySpecialty = '/api/v1/user/role/doctor/specialty';
  static const String topRatedDoctors = '/api/v1/user/role/doctor/top-rated';
  
  // ========== Category Endpoints ==========
  static const String categories = '/api/v1/category';
  static const String categoryById = '/api/v1/category'; // + /:id
  static const String createCategory = '/api/v1/category/create';
  static const String updateCategory = '/api/v1/category'; // + /:id
  static const String deleteCategory = '/api/v1/category'; // + /:id
  
  // ========== Notification Endpoints ==========
  static const String notifications = '/api/v1/notification';
  static const String markAsRead = '/api/v1/notification'; // + /:id/read
  static const String markAllAsRead = '/api/v1/notification/read-all';
  static const String deleteNotification = '/api/v1/notification'; // + /:id
  static const String unreadCount = '/api/v1/notification/unread-count';
  
  // ========== Doctor Review Endpoints ==========
  static const String reviews = '/api/v1/doctor-review';
  static const String createReview = '/api/v1/doctor-review/create';
  static const String doctorReviews = '/api/v1/doctor-review/doctor'; // + /:id
  static const String updateReview = '/api/v1/doctor-review'; // + /:id
  static const String deleteReview = '/api/v1/doctor-review'; // + /:id
  static const String myReviews = '/api/v1/doctor-review/my-reviews';
  
  // ========== Post Endpoints ==========
  static const String posts = '/api/v1/post';
  static const String createPost = '/api/v1/post/create';
  static const String getPostById = '/api/v1/post'; // + /:id
  static const String updatePost = '/api/v1/post'; // + /:id
  static const String deletePost = '/api/v1/post'; // + /:id
  static const String likePost = '/api/v1/post'; // + /:id/like
  static const String commentOnPost = '/api/v1/post'; // + /:id/comment
  static const String myPosts = '/api/v1/post/my-posts';
  static const String userPosts = '/api/v1/post/user'; // + /:userId
  
  // ========== Chat Endpoints ==========
  static const String chats = '/api/v1/chat';
  static const String messages = '/api/v1/chat/messages';
  static const String sendMessage = '/api/v1/chat/send';
  static const String createChat = '/api/v1/chat/create';
  static const String getChatById = '/api/v1/chat'; // + /:id
  static const String deleteChatMessage = '/api/v1/chat/message'; // + /:id
  static const String markChatAsRead = '/api/v1/chat'; // + /:id/read
  
  // ========== Reel Endpoints ==========
  static const String reels = '/api/v1/reel';
  static const String createReel = '/api/v1/reel/create';
  static const String getReelById = '/api/v1/reel'; // + /:id
  static const String updateReel = '/api/v1/reel'; // + /:id
  static const String deleteReel = '/api/v1/reel'; // + /:id
  static const String likeReel = '/api/v1/reel'; // + /:id/like
  static const String commentOnReel = '/api/v1/reel'; // + /:id/comment
  
  // ========== Referral Code Endpoints ==========
  static const String referralCode = '/api/v1/referral';
  static const String applyReferral = '/api/v1/referral/apply';
  static const String myReferrals = '/api/v1/referral/my-referrals';
  static const String referralStats = '/api/v1/referral/stats';
  
  // ========== System Settings Endpoints ==========
  static const String systemSettings = '/api/v1/system-setting';
  static const String getSettingByKey = '/api/v1/system-setting'; // + /:key
  static const String updateSystemSetting = '/api/v1/system-setting'; // + /:key
  
  // ========== Payment Endpoints (jodi backend e thake) ==========
  static const String payments = '/api/v1/payment';
  static const String createPayment = '/api/v1/payment/create';
  static const String verifyPayment = '/api/v1/payment/verify';
  static const String paymentHistory = '/api/v1/payment/history';
  
  // ========== Upload Endpoints ==========
  static const String uploadImage = '/api/v1/upload/image';
  static const String uploadFile = '/api/v1/upload/file';
  static const String uploadVideo = '/api/v1/upload/video';
  
  // ========== Helper Methods ==========
  
  /// Get full URL for any endpoint
  static String getFullUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
  
  /// Get appointment by ID URL
  static String getAppointmentByIdUrl(String id) {
    return '$appointments/$id';
  }
  
  /// Get doctor by ID URL
  static String getDoctorByIdUrl(String id) {
    return '$doctorById/$id';
  }
  
  /// Get user by ID URL
  static String getUserByIdUrl(String id) {
    return '$getUserById/$id';
  }
  
  /// Cancel appointment URL
  static String getCancelAppointmentUrl(String id) {
    return '$appointments/$id/status';
  }
  
  /// Get category by ID URL
  static String getCategoryByIdUrl(String id) {
    return '$categoryById/$id';
  }
  
  /// Get post by ID URL
  static String getPostByIdUrl(String id) {
    return '$getPostById/$id';
  }
  
  /// Get reel by ID URL
  static String getReelByIdUrl(String id) {
    return '$getReelById/$id';
  }
  
  /// Get doctor reviews URL
  static String getDoctorReviewsUrl(String doctorId) {
    return '$doctorReviews/$doctorId';
  }
  
  /// Mark notification as read URL
  static String getMarkAsReadUrl(String notificationId) {
    return '$markAsRead/$notificationId/read';
  }
  
  /// Get chat by ID URL
  static String getChatByIdUrl(String chatId) {
    return '$chats/$chatId';
  }
  
  /// Environment check
  static bool get isDevelopment => baseUrl.contains('localhost');
  static bool get isProduction => !isDevelopment;
}