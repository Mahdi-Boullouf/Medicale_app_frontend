import 'package:docmobi/services/push_notification_service.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_config.dart';
import '../services/push_notification_service.dart';
import '../services/callkit_service.dart';
import '../services/notification_api_service.dart'; // Ensure token gets registered

class ApiService {
  static String? _token;
  static String get _baseUrl => ApiConfig.baseUrl;
  static final Map<String, Map<String, dynamic>> _profileCache = {};

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      debugPrint(
        'ApiService initialized. Token: ${_token != null ? "Found" : "Not found"}',
      );

      if (_token != null) {
        debugPrint(
          ' Token status: ${isLoggedIn ? "Logged In" : "Not Logged In"}',
        );
      }
    } catch (e) {
      debugPrint(' Error initializing ApiService: $e');
    }
  }

  /// Sync user session - Call this AFTER app launch to verify user_id
  /// This is deferred to avoid blocking app startup with network calls
  static Future<void> syncUserSession() async {
    try {
      if (!isLoggedIn) {
        debugPrint(' Not logged in - skipping session sync');
        return;
      }

      debugPrint(' Syncing user session...');
      final prefs = await SharedPreferences.getInstance();

      final profile = await getUserProfile();
      if (profile['success'] == true) {
        final realId = profile['data']['_id']?.toString();
        if (realId != null) {
          final currentSavedId = prefs.getString('user_id');
          if (realId != currentSavedId) {
            debugPrint(
              'Session ID Mismatch! Syncing $currentSavedId -> $realId',
            );
            await prefs.setString('user_id', realId);
          } else {
            debugPrint('Session ID synced: $realId');
          }
        }
      }
    } catch (e) {
      debugPrint(' Profile sync failed: $e');
      // Non-critical - don't block the app
    }
  }

  /// Token save kora
  static Future<void> saveToken(String token) async {
    try {
      _token = token;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      debugPrint(
        ' Token saved: ${token.substring(0, min(token.length, 20))}...',
      );
    } catch (e) {
      debugPrint(' Error saving token: $e');
    }
  }

  /// Token clear kora
  static Future<void> clearToken() async {
    try {
      _token = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      debugPrint(' Token cleared');
    } catch (e) {
      debugPrint(' Error clearing token: $e');
    }
  }

  /// Check if logged in
  static bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  /// Get current token
  static String? get token => _token;

  /// Headers generate - WITH TOKEN
  static Map<String, String> _getHeaders({bool requiresAuth = true}) {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth && _token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
      debugPrint(
        'Token added to headers: Bearer ${_token!.substring(0, min(_token!.length, 20))}...',
      );
    } else if (requiresAuth && (_token == null || _token!.isEmpty)) {
      debugPrint(' WARNING: Auth required but no token available!');
    }

    return headers;
  }

  /// GET Request
  /// GET Request with Retry Logic
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    bool requiresAuth = true,
    int retries = 2,
    Duration delay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;
    while (attempts <= retries) {
      attempts++;
      try {
        if (requiresAuth && !isLoggedIn) {
          debugPrint('No token found - cannot make authenticated request');
          return {
            'success': false,
            'message': 'Token not found. Please login again.',
            'requiresLogin': true,
          };
        }

        final url = '$_baseUrl$endpoint';
        if (attempts == 1) {
          debugPrint('GET: $url');
        } else {
          debugPrint('Retry GET ($attempts/$retries): $url');
        }

        final headers = _getHeaders(requiresAuth: requiresAuth);

        final response = await http
            .get(Uri.parse(url), headers: headers)
            .timeout(const Duration(seconds: 15));

        return _handleResponse(response);
      } catch (e) {
        debugPrint(' GET Error (Attempt $attempts): $e');
        if (attempts > retries) {
          return {'success': false, 'message': _getErrorMessage(e)};
        }
        // Exponential backoff: 1s, 4s, 9s...
        await Future.delayed(delay * (attempts * attempts));
      }
    }
    return {'success': false, 'message': 'Request failed after retries'};
  }

  /// POST Request
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
    x,
  }) async {
    try {
      // Token check BEFORE request
      if (requiresAuth && !isLoggedIn) {
        debugPrint('No token found - cannot make authenticated request');
        return {
          'success': false,
          'message': 'Token not found. Please login again.',
          'requiresLogin': true,
        };
      }

      final url = '$_baseUrl$endpoint';
      debugPrint('POST: $url');
      debugPrint('Body: $body');
      debugPrint(' Auth Required: $requiresAuth');
      debugPrint('Token Status: ${isLoggedIn ? "Available" : "Missing"}');

      final headers = _getHeaders(requiresAuth: requiresAuth);

      final response = await http
          .post(Uri.parse(url), headers: headers, body: json.encode(body))
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      debugPrint(' POST Error: $e');
      return {'success': false, 'message': _getErrorMessage(e)};
    }
  }

  /// PUT Request
  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    try {
      if (requiresAuth && !isLoggedIn) {
        return {
          'success': false,
          'message': 'Token not found. Please login again.',
          'requiresLogin': true,
        };
      }

      final url = '$_baseUrl$endpoint';
      debugPrint(' PUT: $url');
      debugPrint(' Body: $body');

      final headers = _getHeaders(requiresAuth: requiresAuth);

      final response = await http
          .put(Uri.parse(url), headers: headers, body: json.encode(body))
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      debugPrint(' PUT Error: $e');
      return {'success': false, 'message': _getErrorMessage(e)};
    }
  }

  /// PATCH Request
  static Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    try {
      if (requiresAuth && !isLoggedIn) {
        return {
          'success': false,
          'message': 'Token not found. Please login again.',
          'requiresLogin': true,
        };
      }

      final url = '$_baseUrl$endpoint';
      debugPrint(' PATCH: $url');
      debugPrint(' Body: $body');

      final headers = _getHeaders(requiresAuth: requiresAuth);

      final response = await http
          .patch(Uri.parse(url), headers: headers, body: json.encode(body))
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      debugPrint(' PATCH Error: $e');
      return {'success': false, 'message': _getErrorMessage(e)};
    }
  }

  /// DELETE Request
  static Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    try {
      if (requiresAuth && !isLoggedIn) {
        return {
          'success': false,
          'message': 'Token not found. Please login again.',
          'requiresLogin': true,
        };
      }

      final url = '$_baseUrl$endpoint';
      debugPrint(' DELETE: $url');

      final headers = _getHeaders(requiresAuth: requiresAuth);

      final response = await http
          .delete(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      debugPrint(' DELETE Error: $e');
      return {'success': false, 'message': _getErrorMessage(e)};
    }
  }

  /// Get Agora Token
  static Future<Map<String, dynamic>> getAgoraToken({
    required String channelName,
  }) async {
    return await get(
      '/api/v1/call/token?channelName=$channelName',
      requiresAuth: true,
    );
  }

  /// Initiate Call - Enhanced with Doctor Availability Check
  static Future<Map<String, dynamic>> initiateCall({
    required String chatId,
    required String receiverId,
    required bool isVideo,
  }) async {
    debugPrint(' Initiating ${isVideo ? "video" : "audio"} call');
    debugPrint('   • Chat ID: $chatId');
    debugPrint('   • Receiver ID: $receiverId');

    try {
      final response = await post('/api/v1/call/initiate', {
        'chatId': chatId,
        'receiverId': receiverId,
        'callType': isVideo ? 'video' : 'audio',
      }, requiresAuth: true);

      debugPrint(
        '   • Response: ${response['success'] ? 'SUCCESS' : 'FAILED'}',
      );

      if (response['success'] == false) {
        // Enhanced error handling for doctor unavailable
        final message =
            response['message'] as String? ?? 'Call initiation failed';
        debugPrint('   • Error: $message');

        if (response['code'] == 'DOCTOR_UNAVAILABLE' ||
            message.toLowerCase().contains('not available')) {
          debugPrint('   • Type: Doctor unavailable for calls');
        }
      }

      return response;
    } catch (e) {
      debugPrint(' Call initiation error: $e');
      rethrow;
    }
  }

  /// Accept call via REST API (Fallback for slow socket connection)
  static Future<Map<String, dynamic>> acceptCall(
    Map<String, dynamic> data,
  ) async {
    try {
      debugPrint(' Accepting call via API: $data');
      return await post('/api/v1/call/accept', data, requiresAuth: true);
    } catch (e) {
      debugPrint(' Error accepting call via API: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> rejectCall(
    Map<String, dynamic> data,
  ) async {
    try {
      debugPrint(' Rejecting call via API: $data');
      return await post('/api/v1/call/reject', data, requiresAuth: true);
    } catch (e) {
      debugPrint(' Error rejecting call via API: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ========================================
  // AUTH APIs
  // ========================================

  /// Login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final result = await post('/api/v1/auth/login', {
      'email': email,
      'password': password,
    }, requiresAuth: false);

    // Auto-save token on successful login
    if (result['success'] == true) {
      final token =
          result['data']?['accessToken'] ??
          result['data']?['token'] ??
          result['token'] ??
          result['accessToken'];

      final userRole =
          result['data']?['user']?['role'] ??
          result['data']?['role'] ??
          result['user']?['role'] ??
          result['role'];

      if (token != null) {
        await saveToken(token);
        debugPrint('Login successful - Token saved');

        final prefs = await SharedPreferences.getInstance();

        if (userRole != null) {
          await prefs.setString('user_role', userRole.toString().toLowerCase());
          debugPrint(' User role saved: $userRole');
        }

        // Extract user_id
        final userId =
            result['data']?['user']?['_id'] ??
            result['data']?['user']?['id'] ??
            result['data']?['_id'] ??
            result['user']?['_id'];

        if (userId != null) {
          await prefs.setString('user_id', userId.toString());
          debugPrint(' User ID saved: $userId');
        } else {
          debugPrint('User ID NOT found in login response!');
        }

        // Save Full Name and Avatar for notification attributes
        final fullName =
            result['data']?['user']?['fullName'] ??
            result['data']?['fullName'] ??
            result['user']?['fullName'];
        final avatarUrl =
            result['data']?['user']?['avatar']?['url'] ??
            result['data']?['avatar']?['url'] ??
            result['user']?['avatar']?['url'];

        if (fullName != null) {
          await prefs.setString('user_full_name', fullName.toString());
          debugPrint('Full Name saved: $fullName');
        }
        if (avatarUrl != null) {
          await prefs.setString('user_avatar', avatarUrl.toString());
          debugPrint('Avatar URL saved: $avatarUrl');
        }

        // ✅ CRITICAL BUG FIX: Register device AFTER login so tokens go to backend!
        try {
          await PushNotificationService.registerUserDevice();
          debugPrint('Device registered post-login');
        } catch (e) {
          debugPrint('Error triggering token registration post-login: $e');
        }
      }
    }

    return result;
  }

  /// Register
  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? wilaya,
    String? commune,
    String? medicalLicenseNumber,
    String? specialty,
    String? experienceYears,
    String? referralCode,
  }) async {
    final Map<String, dynamic> body = {
      'fullName': fullName,
      'email': email,
      'password': password,
      'confirmPassword': password, // Backend might require this
      'role': role.toLowerCase(),
      if (wilaya != null) 'wilaya': wilaya,
      if (commune != null) 'commune': commune,
    };

    // Add doctor-specific fields
    if (role.toLowerCase() == 'doctor') {
      if (medicalLicenseNumber != null) {
        body['medicalLicenseNumber'] = medicalLicenseNumber;
      }

      if (specialty != null) {
        body['specialty'] = specialty;
      }
      if (experienceYears != null) {
        body['experienceYears'] = experienceYears;
      }
      if (referralCode != null && referralCode.isNotEmpty) {
        body['refferalCode'] = referralCode;
      }
    }

    final result = await post(
      '/api/v1/auth/register',
      body,
      requiresAuth: false,
    );

    return result;
  }

  /// Logout
  static Future<Map<String, dynamic>> logout() async {
    try {
      await post('/api/v1/auth/logout', {}, requiresAuth: true);
    } catch (e) {
      debugPrint(' Logout request failed: $e');
    }

    await clearToken();

    return {'success': true, 'message': 'Logged out successfully'};
  }

  /// Get Chat Messages
  static Future<Map<String, dynamic>> getChatMessages({
    required String chatId,
    required int page,
    required int limit,
  }) async {
    debugPrint(' Getting messages for chatId: $chatId');
    return await get(
      '/api/v1/chat/$chatId/messages?page=$page&limit=$limit',
      requiresAuth: true,
    );
  }

  /// Get Agora Chat Token
  static Future<Map<String, dynamic>> getAgoraChatToken() async {
    debugPrint(' Fetching Agora Chat Token from backend');
    return await get('/api/v1/chat/token', requiresAuth: true);
  }

  /// Get My Chats
  static Future<Map<String, dynamic>> getMyChats() async {
    debugPrint(' Getting my chats');
    return await get('/api/v1/chat', requiresAuth: true);
  }

  /// Create or Get Chat
  static Future<Map<String, dynamic>> createOrGetChat({
    required String userId,
  }) async {
    //  Sanitize userId to remove any socket/device suffix (e.g. userId/deviceId)
    final cleanUserId = userId.split('/').first;
    debugPrint(
      ' Creating/Getting chat with userId: $cleanUserId (Original: $userId)',
    );
    return await post('/api/v1/chat', {
      'userId': cleanUserId,
    }, requiresAuth: true);
  }

  /// Mark Chat as Read
  static Future<Map<String, dynamic>> markChatAsRead({
    required String chatId,
  }) async {
    debugPrint(' Marking chat as read: $chatId');
    return await patch('/api/v1/chat/$chatId/read', {}, requiresAuth: true);
  }

  /// Send Message
  static Future<Map<String, dynamic>> sendMessage({
    required String chatId,
    String? content,
    List<File>? files,
    String? contentType,
  }) async {
    try {
      if (!isLoggedIn) {
        return {
          'success': false,
          'message': 'Token not found. Please login again.',
          'requiresLogin': true,
        };
      }

      final url = '$_baseUrl/api/v1/chat/$chatId/messages';
      debugPrint(' POST (Multipart): $url');
      debugPrint(' Chat ID: $chatId');
      debugPrint(' Content: $content');
      debugPrint(' Files: ${files?.length ?? 0}');

      var request = http.MultipartRequest('POST', Uri.parse(url));

      // Add auth header
      if (_token != null && _token!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $_token';
      }

      // Add content
      if (content != null && content.isNotEmpty) {
        request.fields['content'] = content;
      } else {
        request.fields['content'] = files != null && files.isNotEmpty
            ? ' '
            : '';
      }

      // Determine content type
      if (contentType != null) {
        request.fields['contentType'] = contentType;
      } else if (files != null && files.isNotEmpty) {
        request.fields['contentType'] = 'file';
      } else {
        request.fields['contentType'] = 'text';
      }

      // Add files
      if (files != null && files.isNotEmpty) {
        for (var file in files) {
          request.files.add(
            await http.MultipartFile.fromPath('files', file.path),
          );
        }
      }

      debugPrint(' Request Fields: ${request.fields}');
      debugPrint(' Request Files: ${request.files.length}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ Send Message Error: $e');
      return {'success': false, 'message': _getErrorMessage(e)};
    }
  }

  /// Create Post
  static Future<Map<String, dynamic>> createPost({
    required String content,
    List<File>? mediaFiles,
    String visibility = 'public',
  }) async {
    try {
      if (!isLoggedIn) {
        return {
          'success': false,
          'message': 'Token not found. Please login again.',
          'requiresLogin': true,
        };
      }

      final url = '$_baseUrl/api/v1/posts';
      debugPrint(' POST (Multipart): $url');
      debugPrint(' Content: $content');
      debugPrint(' Visibility: $visibility');
      debugPrint(' Files: ${mediaFiles?.length ?? 0}');

      var request = http.MultipartRequest('POST', Uri.parse(url));

      // Add auth header
      if (_token != null && _token!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $_token';
      }

      // Add text fields
      request.fields['content'] = content;
      request.fields['visibility'] = visibility;

      // Add media files
      if (mediaFiles != null && mediaFiles.isNotEmpty) {
        for (var file in mediaFiles) {
          request.files.add(
            await http.MultipartFile.fromPath('media', file.path),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      debugPrint(' Create Post Error: $e');
      return {'success': false, 'message': _getErrorMessage(e)};
    }
  }

  /// Get All Posts
  static Future<Map<String, dynamic>> getAllPosts({
    int page = 1,
    int limit = 20,
  }) async {
    return await get(
      '${ApiConfig.posts}?page=$page&limit=$limit',
      requiresAuth: true,
    );
  }

  /// Get User Posts
  static Future<Map<String, dynamic>> getUserPosts({
    required String userId,
    int page = 1,
    int limit = 20,
  }) async {
    return await get(
      '/api/v1/posts/user/$userId?page=$page&limit=$limit',
      requiresAuth: true,
    );
  }

  /// Comment on Post
  static Future<Map<String, dynamic>> commentOnPost({
    required String postId,
    required String comment,
  }) async {
    return await post('/api/v1/posts/$postId/comment', {
      'comment': comment,
    }, requiresAuth: true);
  }

  static Future<Map<String, dynamic>> deletePost(String postId) async {
    try {
      debugPrint('🗑️ Deleting post: $postId');

      final response = await delete(
        '/api/v1/posts/$postId',
        requiresAuth: true,
      );

      return response;
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete post: $e'};
    }
  }

  /// Get User Profile
  static Future<Map<String, dynamic>> getUserProfile({String? userId}) async {
    // 1. Check cache first
    if (userId != null && _profileCache.containsKey(userId)) {
      debugPrint('⚡ Cache Hit: User profile for $userId');
      return _profileCache[userId]!;
    }

    final endpoint = userId != null
        ? '${ApiConfig.getUserById}/$userId'
        : ApiConfig.userProfile;

    final result = await get(endpoint, requiresAuth: true);

    // 2. Save successful results to cache
    if (result['success'] == true && userId != null) {
      _profileCache[userId] = result;
      debugPrint('Cache Saved: User profile for $userId');
    }

    return result;
  }

  /// Update User Profile
  static Future<Map<String, dynamic>> updateUserProfile({
    required Map<String, dynamic> data,
  }) async {
    return await put('/api/v1/user/profile', data, requiresAuth: true);
  }

  /// Search Users
  static Future<Map<String, dynamic>> searchUsers({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    return await get(
      '/api/v1/users/search?q=$query&page=$page&limit=$limit',
      requiresAuth: true,
    );
  }

  /// Register Device Tokens (Professional Multi-Device Approach)
  static Future<Map<String, dynamic>> registerDeviceTokens({
    String? fcmToken,
    String? voipToken,
    required String platform,
    String? deviceId,
  }) async {
    return await post('/api/v1/user/fcm-token', {
      'fcmToken': fcmToken,
      'voipToken': voipToken,
      'platform': platform.toLowerCase(),
      'deviceId': deviceId,
    }, requiresAuth: true);
  }

  /// Deprecated: keeping for compatibility during transition
  static Future<Map<String, dynamic>> registerFCMToken({
    required String token,
    required String platform,
    String tokenType = 'standard',
  }) async {
    return await registerDeviceTokens(
      fcmToken: tokenType == 'standard' ? token : null,
      voipToken: tokenType == 'voip' ? token : null,
      platform: platform,
    );
  }

  ///  Unregister FCM Token (on logout — prevents calls to logged-out devices)
  static Future<Map<String, dynamic>> unregisterFCMToken({
    required String token,
  }) async {
    try {
      if (!isLoggedIn) return {'success': false, 'message': 'Not logged in'};
      final url = '$_baseUrl/api/v1/user/fcm-token';
      final headers = _getHeaders(requiresAuth: true);
      final response = await http
          .delete(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode({'token': token}),
          )
          .timeout(const Duration(seconds: 5));
      return _handleResponse(response);
    } catch (e) {
      debugPrint(' FCM token unregister failed: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Get Appointments
  static Future<Map<String, dynamic>> getAppointments() async {
    return await get(ApiConfig.appointments, requiresAuth: true);
  }

  /// Create Appointment
  static Future<Map<String, dynamic>> createAppointment({
    required Map<String, dynamic> appointmentData,
  }) async {
    return await post(
      '/api/v1/appointment',
      appointmentData,
      requiresAuth: true,
    );
  }

  /// Update Appointment Status
  static Future<Map<String, dynamic>> updateAppointmentStatus({
    required String appointmentId,
    required String status,
  }) async {
    return await patch('/api/v1/appointment/$appointmentId', {
      'status': status,
    }, requiresAuth: true);
  }

  /// Cancel Appointment
  static Future<Map<String, dynamic>> cancelAppointment({
    required String appointmentId,
  }) async {
    return await patch(
      '/api/v1/appointment/$appointmentId/cancel',
      {},
      requiresAuth: true,
    );
  }

  /// Get All Doctors
  static Future<Map<String, dynamic>> getAllDoctors({
    int page = 1,
    int limit = 20,
    String? specialty,
  }) async {
    String endpoint = '/api/v1/doctors?page=$page&limit=$limit';
    if (specialty != null && specialty.isNotEmpty) {
      endpoint += '&specialty=$specialty';
    }
    return await get(endpoint, requiresAuth: false);
  }

  /// Get Doctor Details
  static Future<Map<String, dynamic>> getDoctorDetails({
    required String doctorId,
  }) async {
    return await get('/api/v1/doctors/$doctorId', requiresAuth: false);
  }

  /// Search Doctors
  static Future<Map<String, dynamic>> searchDoctors({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    return await get(
      '/api/v1/doctors/search?q=$query&page=$page&limit=$limit',
      requiresAuth: false,
    );
  }

  /// Get All Categories
  static Future<Map<String, dynamic>> getAllCategories() async {
    return await get('/api/v1/category', requiresAuth: false);
  }

  /// Get Referral Setting
  static Future<Map<String, dynamic>> getReferralSetting() async {
    return await get(
      '/api/v1/app-setting/get-referral-setting',
      requiresAuth: false,
    );
  }

  /// Get Earnings
  static Future<Map<String, dynamic>> getEarnings() async {
    return await get('/api/v1/earnings', requiresAuth: true);
  }

  /// Get Transactions
  static Future<Map<String, dynamic>> getTransactions({
    int page = 1,
    int limit = 20,
  }) async {
    return await get(
      '/api/v1/transactions?page=$page&limit=$limit',
      requiresAuth: true,
    );
  }

  // ========================================
  // 🎬 REELS APIs
  // ========================================

  /// Create Reel - FIXED
  static Future<Map<String, dynamic>> createReel({
    File? videoFile,
    String? caption,
    String visibility = 'public',
  }) async {
    try {
      if (!isLoggedIn) {
        return {
          'success': false,
          'message': 'Token not found. Please login again.',
          'requiresLogin': true,
        };
      }

      final url = '$_baseUrl/api/v1/reels';
      debugPrint(' POST (Multipart): $url');
      debugPrint(' Caption: $caption');
      debugPrint(' Visibility: $visibility');
      debugPrint(' Video file: ${videoFile?.path}');

      var request = http.MultipartRequest('POST', Uri.parse(url));

      // Add auth header
      if (_token != null && _token!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $_token';
        debugPrint(' Token added to request');
      }

      // Add text fields
      request.fields['visibility'] = visibility;
      if (caption != null && caption.isNotEmpty) {
        request.fields['caption'] = caption;
      }

      debugPrint('Fields: ${request.fields}');

      // Use 'video' as field name (NOT 'videoFile')
      if (videoFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('video', videoFile.path),
        );
        debugPrint(' Video file added: ${videoFile.path}');
      }

      debugPrint(' Sending request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint(' Response status: ${response.statusCode}');
      debugPrint(' Response body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      debugPrint(' Create Reel Error: $e');
      return {'success': false, 'message': 'Failed to upload reel: $e'};
    }
  }

  static Future<Map<String, dynamic>> getAllReels({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      debugPrint(' Fetching all reels (page: $page, limit: $limit)');

      final response = await get(
        '/api/v1/reels/all-reels?page=$page&limit=$limit',
        requiresAuth: true,
      );

      debugPrint('Reels response: $response');
      return response;
    } catch (e) {
      debugPrint(' Error fetching reels: $e');
      return {'success': false, 'message': 'Failed to fetch reels: $e'};
    }
  }

  /// Like/Unlike a reel
  static Future<Map<String, dynamic>> likeReel(String reelId) async {
    try {
      debugPrint('Toggling like for reel: $reelId');

      final result = await post(
        '/api/v1/reels/$reelId/like',
        {},
        requiresAuth: true,
      );

      debugPrint(' Like reel response: $result');
      return result;
    } catch (e) {
      debugPrint(' Error liking reel: $e');
      return {'success': false, 'message': 'Failed to like reel'};
    }
  }

  /// Add comment to a reel
  static Future<Map<String, dynamic>> addReelComment({
    required String reelId,
    required String content,
  }) async {
    try {
      debugPrint(' Adding comment to reel: $reelId');

      final result = await post('/api/v1/reels/$reelId/comments', {
        'content': content,
      }, requiresAuth: true);

      debugPrint('Comment added successfully');
      return result;
    } catch (e) {
      debugPrint('Error adding reel comment: $e');
      return {'success': false, 'message': 'Failed to add comment'};
    }
  }

  /// Get comments for a reel
  static Future<Map<String, dynamic>> getReelComments({
    required String reelId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      debugPrint(
        ' Fetching reel comments (reelId: $reelId, page: $page, limit: $limit)',
      );

      final result = await get(
        '/api/v1/reels/$reelId/comments?page=$page&limit=$limit',
        requiresAuth: true,
      );

      debugPrint(
        'Reel comments response: ${result['data']?['items']?.length ?? 0} comments',
      );
      return result;
    } catch (e) {
      debugPrint(' Error fetching reel comments: $e');
      return {
        'success': false,
        'message': 'Failed to fetch comments',
        'data': {'items': [], 'pagination': {}},
      };
    }
  }

  /// Upload Single File
  static Future<Map<String, dynamic>> uploadFile({
    required String filePath,
    required String fieldName,
  }) async {
    try {
      if (!isLoggedIn) {
        return {
          'success': false,
          'message': 'Token not found. Please login again.',
          'requiresLogin': true,
        };
      }

      final url = '$_baseUrl/api/v1/upload';
      debugPrint('Uploading file: $filePath');

      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll(_getHeaders(requiresAuth: true));

      request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      debugPrint(' File upload error: $e');
      return {'success': false, 'message': _getErrorMessage(e)};
    }
  }

  /// Upload Multiple Files
  static Future<Map<String, dynamic>> uploadMultipleFiles({
    required List<String> filePaths,
    required String fieldName,
  }) async {
    try {
      if (!isLoggedIn) {
        return {
          'success': false,
          'message': 'Token not found. Please login again.',
          'requiresLogin': true,
        };
      }

      final url = '$_baseUrl/api/v1/upload/multiple';
      debugPrint('Uploading ${filePaths.length} files');

      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll(_getHeaders(requiresAuth: true));

      for (var filePath in filePaths) {
        request.files.add(
          await http.MultipartFile.fromPath(fieldName, filePath),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      debugPrint(' Multiple file upload error: $e');
      return {'success': false, 'message': _getErrorMessage(e)};
    }
  }

  static Future<Map<String, dynamic>> likePost(String postId) async {
    try {
      debugPrint('Toggling like for post: $postId');

      final response = await post(
        '/api/v1/posts/$postId/like',
        {},
        requiresAuth: true,
      );

      debugPrint(' Like response: $response');
      return response;
    } catch (e) {
      debugPrint(' Error liking post: $e');
      return {'success': false, 'message': 'Failed to like post: $e'};
    }
  }

  /// Get Post Likes
  static Future<Map<String, dynamic>> getPostLikes({
    required String postId,
    int page = 1,
    int limit = 20,
  }) async {
    return await get(
      '/api/v1/posts/$postId/likes?page=$page&limit=$limit',
      requiresAuth: true,
    );
  }

  /// Add Post Comment - NEW
  static Future<Map<String, dynamic>> addPostComment({
    required String postId,
    required String content,
  }) async {
    return await post('/api/v1/posts/$postId/comments', {
      'content': content,
    }, requiresAuth: true);
  }

  /// Get Post Comments - NEW
  static Future<Map<String, dynamic>> getPostComments({
    required String postId,
    int page = 1,
    int limit = 20,
  }) async {
    return await get(
      '/api/v1/posts/$postId/comments?page=$page&limit=$limit',
      requiresAuth: true,
    );
  }

  /// Delete Comment
  static Future<Map<String, dynamic>> deletePostComment({
    required String postId,
    required String commentId,
  }) async {
    return await delete(
      '/api/v1/posts/$postId/comments/$commentId',
      requiresAuth: true,
    );
  }

  /// Share Post (Future implementation)
  static Future<Map<String, dynamic>> sharePost({
    required String postId,
  }) async {
    return await post('/api/v1/posts/$postId/share', {}, requiresAuth: true);
  }

  /// Explicitly End Call (Triggers FCM/APNs Cancellation) - NEW
  static Future<Map<String, dynamic>> endCall({
    required String chatId,
    required String toUserId,
    String? uuid,
  }) async {
    return await post('/api/v1/call/end', {
      'chatId': chatId,
      'userId': toUserId,
      'uuid': uuid ?? '',
    }, requiresAuth: true);
  }

  // ========================================
  // 🔧 HELPER METHODS
  // ========================================

  /// Response handler
  static Map<String, dynamic> _handleResponse(http.Response response) {
    debugPrint(' Status: ${response.statusCode}');

    // Safe substring for logging
    final bodyPreview = response.body.length > 500
        ? response.body.substring(0, 500)
        : response.body;
    debugPrint(
      ' Response Body: $bodyPreview${response.body.length > 500 ? "..." : ""}',
    );

    try {
      final body = response.body;
      dynamic data;
      try {
        data = json.decode(body);
      } catch (e) {
        debugPrint(' JSON Decode Error: $e');

        // Detect HTML response (like 502 Bad Gateway)
        if (body.contains('<html>') || body.contains('nginx')) {
          return {
            'success': false,
            'message':
                'Server is currently unavailable (502 Bad Gateway). Please try again later.',
            'statusCode': response.statusCode,
            'error': '502 Bad Gateway',
          };
        }

        // If it's not JSON, it might be a plain text error from nginx/server
        return {
          'success': false,
          'message': body.isNotEmpty
              ? body.substring(0, min(body.length, 200))
              : 'Unknown server error',
          'statusCode': response.statusCode,
        };
      }

      if (data is! Map<String, dynamic>) {
        return {
          'success': false,
          'message': 'Invalid response format (not a valid JSON object)',
          'statusCode': response.statusCode,
        };
      }

      // Success response (200-299)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'statusCode': response.statusCode, ...data};
      }

      // Extract error message safely
      String errorMessage = data['message'] ?? 'Request failed';
      if (data['error'] != null && data['error'] is String) {
        errorMessage = data['error'];
      }

      // Unauthorized (401) - Token invalid/expired
      if (response.statusCode == 401) {
        debugPrint('401 Unauthorized - Clearing token');
        clearToken();
        return {
          'success': false,
          'message': errorMessage,
          'requiresLogin': true,
          'statusCode': response.statusCode,
        };
      }

      // Return structured error
      return {
        'success': false,
        'message': errorMessage,
        'statusCode': response.statusCode,
        'errors': data['errors'] ?? [],
        'data': data, // Include data just in case
      };
    } catch (e, stack) {
      debugPrint('Response handling error: $e');
      debugPrint(stack.toString());
      return {
        'success': false,
        'message': 'Failed to process server response',
        'statusCode': response.statusCode,
      };
    }
  }

  /// Error message generator
  static String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('socketexception') ||
        errorString.contains('failed host lookup')) {
      return 'Cannot connect to server. Please check your internet connection.';
    } else if (errorString.contains('connection refused')) {
      return 'Server is not responding. Please try again later.';
    } else if (errorString.contains('timeout')) {
      return 'Request timeout. Please check your connection and try again.';
    } else if (errorString.contains('format')) {
      return 'Invalid data format received from server.';
    } else {
      return 'An error occurred: ${error.toString()}';
    }
  }

  /// Helper for min function
  static int min(int a, int b) => a < b ? a : b;
}
