import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_config.dart'; // ✅ Import ApiConfig

class ApiService {
  static String? _token;
  static String get _baseUrl => ApiConfig.baseUrl; // ✅ Use ApiConfig

  /// Initialize - Token load kora
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      debugPrint(
        '✅ ApiService initialized. Token: ${_token != null ? "Found" : "Not found"}',
      );

      if (_token != null) {
        debugPrint(
          '🔍 Token status: ${isLoggedIn ? "Logged In" : "Not Logged In"}',
        );

        // ✅ SYNC SESSION: Fetch profile to ensure user_id in SharedPreferences is correct
        try {
          final profile = await getUserProfile();
          if (profile['success'] == true) {
            final realId = profile['data']['_id']?.toString();
            if (realId != null) {
              final currentSavedId = prefs.getString('user_id');
              if (realId != currentSavedId) {
                debugPrint(
                  '⚠️ Session ID Mismatch! Syncing $currentSavedId -> $realId',
                );
                await prefs.setString('user_id', realId);
              } else {
                debugPrint('✅ Session ID synced: $realId');
              }
            }
          }
        } catch (e) {
          debugPrint('⚠️ Profile sync failed during init: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Error initializing ApiService: $e');
    }
  }

  /// Token save kora
  static Future<void> saveToken(String token) async {
    try {
      _token = token;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      debugPrint(
        '✅ Token saved: ${token.substring(0, min(token.length, 20))}...',
      );
    } catch (e) {
      debugPrint('❌ Error saving token: $e');
    }
  }

  /// Token clear kora
  static Future<void> clearToken() async {
    try {
      _token = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      debugPrint('✅ Token cleared');
    } catch (e) {
      debugPrint('❌ Error clearing token: $e');
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
        '🔐 Token added to headers: Bearer ${_token!.substring(0, min(_token!.length, 20))}...',
      );
    } else if (requiresAuth && (_token == null || _token!.isEmpty)) {
      debugPrint('⚠️ WARNING: Auth required but no token available!');
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
          debugPrint('❌ No token found - cannot make authenticated request');
          return {
            'success': false,
            'message': 'Token not found. Please login again.',
            'requiresLogin': true,
          };
        }

        final url = '$_baseUrl$endpoint';
        if (attempts == 1)
          debugPrint('📤 GET: $url');
        else
          debugPrint('🔁 Retry GET ($attempts/$retries): $url');

        final headers = _getHeaders(requiresAuth: requiresAuth);

        final response = await http
            .get(Uri.parse(url), headers: headers)
            .timeout(const Duration(seconds: 15));

        return _handleResponse(response);
      } catch (e) {
        debugPrint('❌ GET Error (Attempt $attempts): $e');
        if (attempts > retries) {
          return {'success': false, 'message': _getErrorMessage(e)};
        }
        await Future.delayed(delay * attempts);
      }
    }
    return {'success': false, 'message': 'Request failed after retries'};
  }

  /// POST Request
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    try {
      // Token check BEFORE request
      if (requiresAuth && !isLoggedIn) {
        debugPrint('❌ No token found - cannot make authenticated request');
        return {
          'success': false,
          'message': 'Token not found. Please login again.',
          'requiresLogin': true,
        };
      }

      final url = '$_baseUrl$endpoint';
      debugPrint('📤 POST: $url');
      debugPrint('📦 Body: $body');
      debugPrint('🔐 Auth Required: $requiresAuth');
      debugPrint('🔐 Token Status: ${isLoggedIn ? "Available" : "Missing"}');

      final headers = _getHeaders(requiresAuth: requiresAuth);

      final response = await http
          .post(Uri.parse(url), headers: headers, body: json.encode(body))
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ POST Error: $e');
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
      debugPrint('📤 PUT: $url');
      debugPrint('📦 Body: $body');

      final headers = _getHeaders(requiresAuth: requiresAuth);

      final response = await http
          .put(Uri.parse(url), headers: headers, body: json.encode(body))
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ PUT Error: $e');
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
      debugPrint('📤 PATCH: $url');
      debugPrint('📦 Body: $body');

      final headers = _getHeaders(requiresAuth: requiresAuth);

      final response = await http
          .patch(Uri.parse(url), headers: headers, body: json.encode(body))
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ PATCH Error: $e');
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
      debugPrint('📤 DELETE: $url');

      final headers = _getHeaders(requiresAuth: requiresAuth);

      final response = await http
          .delete(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ DELETE Error: $e');
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
    debugPrint('📞 Initiating ${isVideo ? "video" : "audio"} call');
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
      debugPrint('❌ Call initiation error: $e');
      rethrow;
    }
  }

  // ========================================
  // 🔐 AUTH APIs
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
        debugPrint('✅ Login successful - Token saved');

        final prefs = await SharedPreferences.getInstance();

        if (userRole != null) {
          await prefs.setString('user_role', userRole.toString().toLowerCase());
          debugPrint('✅ User role saved: $userRole');
        }

        // ✅ FIXED: Save user_id for Socket Connection
        final userId =
            result['data']?['user']?['_id'] ??
            result['data']?['user']?['id'] ??
            result['data']?['_id'] ??
            result['user']?['_id'];

        if (userId != null) {
          await prefs.setString('user_id', userId.toString());
          debugPrint('✅ User ID saved: $userId');
        } else {
          debugPrint('⚠️ User ID NOT found in login response!');
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
    String? medicalLicenseNumber,
    String? specialty,
    String? experienceYears,
  }) async {
    final Map<String, dynamic> body = {
      'fullName': fullName,
      'email': email,
      'password': password,
      'confirmPassword': password, // Backend might require this
      'role': role.toLowerCase(),
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
      debugPrint('⚠️ Logout request failed: $e');
    }

    await clearToken();

    return {'success': true, 'message': 'Logged out successfully'};
  }

  // ========================================
  // 📱 CHAT & MESSAGING APIs
  // ========================================

  /// Get Chat Messages
  static Future<Map<String, dynamic>> getChatMessages({
    required String chatId,
    required int page,
    required int limit,
  }) async {
    debugPrint('🔍 Getting messages for chatId: $chatId');
    return await get(
      '/api/v1/chat/$chatId/messages?page=$page&limit=$limit',
      requiresAuth: true,
    );
  }

  /// Get Agora Chat Token
  static Future<Map<String, dynamic>> getAgoraChatToken() async {
    debugPrint('🔍 Fetching Agora Chat Token from backend');
    return await get('/api/v1/chat/token', requiresAuth: true);
  }

  /// Get My Chats
  static Future<Map<String, dynamic>> getMyChats() async {
    debugPrint('🔍 Getting my chats');
    return await get('/api/v1/chat', requiresAuth: true);
  }

  /// Create or Get Chat
  static Future<Map<String, dynamic>> createOrGetChat({
    required String userId,
  }) async {
    debugPrint('🔍 Creating/Getting chat with userId: $userId');
    return await post('/api/v1/chat', {'userId': userId}, requiresAuth: true);
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
      debugPrint('📤 POST (Multipart): $url');
      debugPrint('📦 Chat ID: $chatId');
      debugPrint('📦 Content: $content');
      debugPrint('📦 Files: ${files?.length ?? 0}');

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

      debugPrint('📋 Request Fields: ${request.fields}');
      debugPrint('📋 Request Files: ${request.files.length}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ Send Message Error: $e');
      return {'success': false, 'message': _getErrorMessage(e)};
    }
  }

  // ========================================
  // 📝 POST APIs
  // ========================================

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
      debugPrint('📤 POST (Multipart): $url');
      debugPrint('📦 Content: $content');
      debugPrint('📦 Visibility: $visibility');
      debugPrint('📦 Files: ${mediaFiles?.length ?? 0}');

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
      debugPrint('❌ Create Post Error: $e');
      return {'success': false, 'message': _getErrorMessage(e)};
    }
  }

  /// Get All Posts
  static Future<Map<String, dynamic>> getAllPosts({
    int page = 1,
    int limit = 20,
  }) async {
    return await get(
      '${ApiConfig.posts}?page=$page&limit=$limit', // ✅ Use ApiConfig
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

  // ✅ KEEP ONLY THIS:
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

  // ========================================
  // 👤 USER APIs
  // ========================================

  /// Get User Profile
  static Future<Map<String, dynamic>> getUserProfile({String? userId}) async {
    final endpoint = userId != null
        ? '${ApiConfig.getUserById}/$userId'
        : ApiConfig.userProfile;
    return await get(endpoint, requiresAuth: true);
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

  // ========================================
  // 📅 APPOINTMENT APIs
  // ========================================

  /// Get Appointments
  static Future<Map<String, dynamic>> getAppointments() async {
    return await get(
      ApiConfig.appointments, // ✅ Use ApiConfig
      requiresAuth: true,
    );
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

  // ========================================
  // 🏥 DOCTOR APIs
  // ========================================

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

  // ========================================
  // 💰 PAYMENT/EARNINGS APIs
  // ========================================

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
      debugPrint('📤 POST (Multipart): $url');
      debugPrint('📦 Caption: $caption');
      debugPrint('📦 Visibility: $visibility');
      debugPrint('📦 Video file: ${videoFile?.path}');

      var request = http.MultipartRequest('POST', Uri.parse(url));

      // Add auth header
      if (_token != null && _token!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $_token';
        debugPrint('🔐 Token added to request');
      }

      // Add text fields
      request.fields['visibility'] = visibility;
      if (caption != null && caption.isNotEmpty) {
        request.fields['caption'] = caption;
      }

      debugPrint('📋 Fields: ${request.fields}');

      // ✅ FIXED: Use 'video' as field name (NOT 'videoFile')
      if (videoFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'video', // ✅ Backend expects 'video'
            videoFile.path,
          ),
        );
        debugPrint('📹 Video file added: ${videoFile.path}');
      }

      debugPrint('📤 Sending request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ Create Reel Error: $e');
      return {'success': false, 'message': 'Failed to upload reel: $e'};
    }
  }

  /// Get All Reels - FIXED
  static Future<Map<String, dynamic>> getAllReels({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      debugPrint('📤 Fetching all reels (page: $page, limit: $limit)');

      final response = await get(
        '/api/v1/reels/all-reels?page=$page&limit=$limit',
        requiresAuth: true,
      );

      debugPrint('📥 Reels response: $response');
      return response;
    } catch (e) {
      debugPrint('❌ Error fetching reels: $e');
      return {'success': false, 'message': 'Failed to fetch reels: $e'};
    }
  }

  /// Like/Unlike a reel
  static Future<Map<String, dynamic>> likeReel(String reelId) async {
    try {
      debugPrint('❤️ Toggling like for reel: $reelId');

      final result = await post(
        '/api/v1/reels/$reelId/like',
        {},
        requiresAuth: true,
      );

      debugPrint('✅ Like reel response: $result');
      return result;
    } catch (e) {
      debugPrint('❌ Error liking reel: $e');
      return {'success': false, 'message': 'Failed to like reel'};
    }
  }

  /// Add comment to a reel
  static Future<Map<String, dynamic>> addReelComment({
    required String reelId,
    required String content,
  }) async {
    try {
      debugPrint('💬 Adding comment to reel: $reelId');

      final result = await post('/api/v1/reels/$reelId/comments', {
        'content': content,
      }, requiresAuth: true);

      debugPrint('✅ Comment added successfully');
      return result;
    } catch (e) {
      debugPrint('❌ Error adding reel comment: $e');
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
        '📥 Fetching reel comments (reelId: $reelId, page: $page, limit: $limit)',
      );

      final result = await get(
        '/api/v1/reels/$reelId/comments?page=$page&limit=$limit',
        requiresAuth: true,
      );

      debugPrint(
        '✅ Reel comments response: ${result['data']?['items']?.length ?? 0} comments',
      );
      return result;
    } catch (e) {
      debugPrint('❌ Error fetching reel comments: $e');
      return {
        'success': false,
        'message': 'Failed to fetch comments',
        'data': {'items': [], 'pagination': {}},
      };
    }
  }

  // ========================================
  // 📤 FILE UPLOAD APIs
  // ========================================

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
      debugPrint('📤 Uploading file: $filePath');

      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll(_getHeaders(requiresAuth: true));

      request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ File upload error: $e');
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
      debugPrint('📤 Uploading ${filePaths.length} files');

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
      debugPrint('❌ Multiple file upload error: $e');
      return {'success': false, 'message': _getErrorMessage(e)};
    }
  }

  // ========================================
  // 📝 UPDATED POST APIs
  // ========================================
  /// Like/Unlike Post - SINGLE METHOD
  static Future<Map<String, dynamic>> likePost(String postId) async {
    try {
      debugPrint('❤️ Toggling like for post: $postId');

      final response = await post(
        '/api/v1/posts/$postId/like',
        {},
        requiresAuth: true,
      );

      debugPrint('📥 Like response: $response');
      return response;
    } catch (e) {
      debugPrint('❌ Error liking post: $e');
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

  // ========================================
  // 🔧 HELPER METHODS
  // ========================================

  /// Response handler
  static Map<String, dynamic> _handleResponse(http.Response response) {
    debugPrint('📥 Status: ${response.statusCode}');

    // Safe substring for logging
    final bodyPreview = response.body.length > 500
        ? response.body.substring(0, 500)
        : response.body;
    debugPrint(
      '📥 Response Body: $bodyPreview${response.body.length > 500 ? "..." : ""}',
    );

    try {
      final data = json.decode(response.body) as Map<String, dynamic>;

      // Success response (200-299)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'statusCode': response.statusCode, ...data};
      }
      // Unauthorized (401) - Token invalid/expired
      else if (response.statusCode == 401) {
        debugPrint('⚠️ 401 Unauthorized - Clearing token');
        clearToken();
        return {
          'success': false,
          'message': data['message'] ?? 'Session expired. Please login again.',
          'requiresLogin': true,
          'statusCode': response.statusCode,
        };
      }
      // Forbidden (403)
      else if (response.statusCode == 403) {
        return {
          'success': false,
          'message': data['message'] ?? 'Access denied',
          'statusCode': response.statusCode,
        };
      }
      // Not Found (404)
      else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': data['message'] ?? 'Resource not found',
          'statusCode': response.statusCode,
        };
      }
      // Bad Request (400)
      else if (response.statusCode == 400) {
        return {
          'success': false,
          'message': data['message'] ?? 'Bad request',
          'statusCode': response.statusCode,
          'errors': data['errors'] ?? [],
        };
      }
      // Server Error (500+)
      else if (response.statusCode >= 500) {
        return {
          'success': false,
          'message': 'Server error. Please try again later.',
          'statusCode': response.statusCode,
        };
      }
      // Other errors
      else {
        return {
          'success': false,
          'message': data['message'] ?? 'Request failed',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      debugPrint('❌ Response parsing error: $e');
      return {
        'success': false,
        'message': 'Invalid response format',
        'statusCode': response.statusCode,
        'rawBody': response.body,
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
