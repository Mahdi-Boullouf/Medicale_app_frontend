import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:docmobi/utils/api_config.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:docmobi/services/api_service.dart';
import 'package:docmobi/services/notification_poller.dart';

class AuthService {
  // Use ApiConfig for base URL
  static String get baseUrl => ApiConfig.baseUrl;

  static String? _cachedToken;
  static String? _cachedRole;

  /// Initialize - Load token from SharedPreferences
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedToken = prefs.getString('auth_token');
      _cachedRole = prefs.getString('user_role');

      debugPrint(' AuthService initialized');
      debugPrint('   Token: ${_cachedToken != null ? "Found" : "Not found"}');
      debugPrint('   Role: $_cachedRole');
    } catch (e) {
      debugPrint(' Error initializing AuthService: $e');
    }
  }

  ///  Get token (from memory cache first)
  Future<String?> getToken() async {
    if (_cachedToken != null) {
      return _cachedToken;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedToken = prefs.getString('auth_token');
      return _cachedToken;
    } catch (e) {
      debugPrint('Error getting token: $e');
      return null;
    }
  }

  /// Save token
  Future<void> saveToken(String token) async {
    try {
      _cachedToken = token;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      debugPrint('Token saved: ${token.substring(0, 20)}...');
    } catch (e) {
      debugPrint(' Error saving token: $e');
    }
  }

  /// Save user role
  Future<void> saveUserRole(String role) async {
    try {
      _cachedRole = role;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', role);
      debugPrint(' User role saved: $role');
    } catch (e) {
      debugPrint(' Error saving role: $e');
    }
  }

  ///  Get headers
  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      debugPrint('🔐 Token added to headers');
    }

    return headers;
  }

  ///  LOGIN
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('POST: $baseUrl${ApiConfig.login}');
      debugPrint(' Email: $email');

      final response = await http
          .post(
            Uri.parse('$baseUrl${ApiConfig.login}'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('Status: ${response.statusCode}');
      debugPrint(' Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        final token =
            data['data']?['token'] ??
            data['token'] ??
            data['data']?['accessToken'] ??
            data['accessToken'];

        final userRole =
            data['data']?['user']?['role'] ??
            data['user']?['role'] ??
            data['data']?['role'] ??
            data['role'];

        if (token != null) {
          await saveToken(token);

          if (userRole != null) {
            await saveUserRole(userRole.toString().toLowerCase());
          }

          debugPrint(' Login successful - Token and role saved');
        }

        return {
          'success': true,
          'data': data['data'] ?? data,
          'message': data['message'] ?? 'Login successful',
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      debugPrint('❌ Login error: $e');
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  /// REGISTER - Updated to match your backend
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required String userType,
    String? medicalLicenseNumber,
    String? specialty,
    String? experienceYears,
  }) async {
    try {
      debugPrint('📤 POST: $baseUrl${ApiConfig.register}');

      // Build request body matching your backend
      final Map<String, dynamic> body = {
        'fullName': name, // Your backend expects 'fullName'
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword, // Your backend expects this
        'role': userType.toLowerCase(), // 'doctor' or 'patient'
      };

      // Add doctor-specific fields if registering as doctor
      if (userType.toLowerCase() == 'doctor') {
        if (medicalLicenseNumber != null && medicalLicenseNumber.isNotEmpty) {
          body['medicalLicenseNumber'] = medicalLicenseNumber;
        }
        if (specialty != null && specialty.isNotEmpty) {
          body['specialty'] = specialty;
        }
        if (experienceYears != null && experienceYears.isNotEmpty) {
          body['experienceYears'] = experienceYears;
        }
      }

      debugPrint('Body: $body');

      final response = await http
          .post(
            Uri.parse('$baseUrl${ApiConfig.register}'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint(' Status: ${response.statusCode}');
      debugPrint('Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        // ome APIs return token on registration
        final token =
            data['data']?['token'] ??
            data['token'] ??
            data['data']?['accessToken'];

        if (token != null) {
          await saveToken(token);
          await saveUserRole(userType.toLowerCase());
          debugPrint(' Registration successful - Token saved');
        }

        return {
          'success': true,
          'data': data['data'] ?? data,
          'message': data['message'] ?? 'Registration successful',
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Registration failed',
          'errors': errorData['errors'] ?? [],
        };
      }
    } catch (e) {
      debugPrint('❌ Registration error: $e');
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }


  Future<Map<String, dynamic>> logout() async {
    try {
      debugPrint('Initiating logout cleanup...');
      
      // 1. Stop background polling
      try {
        NotificationPoller().stopPolling();
        await NotificationPoller().clearAllData();
        debugPrint(' ✅ Notification polling stopped and data cleared');
      } catch (e) {
        debugPrint(' ⚠️ Error clearing notification poller: $e');
      }

      // 2. Unregister FCM Token before logging out
      try {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await ApiService.unregisterFCMToken(token: fcmToken);
          debugPrint(' ✅ FCM Token unregistered during logout');
        }
      } catch (e) {
        debugPrint(' ⚠️ Failed to unregister FCM Token: $e');
      }

      // 3. Notify backend
      final headers = await _getHeaders();
      try {
        await http
            .post(Uri.parse('$baseUrl${ApiConfig.logout}'), headers: headers)
            .timeout(const Duration(seconds: 3));
        debugPrint(' ✅ Backend logout called');
      } catch (e) {
        debugPrint(' ⚠️ Backend logout request failed: $e');
      }

      // 4. Clear local storage last
      _cachedToken = null;
      _cachedRole = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_role');
      await prefs.remove('user_id');
      await prefs.remove('user_full_name');
      await prefs.remove('user_avatar');

      debugPrint(' ✅ Logout successful - Local data cleared');

      return {'success': true, 'message': 'Logged out successfully'};
    } catch (e) {
      debugPrint(' ❌ Error during logout: $e');
      return {'success': false, 'message': 'Error logging out'};
    }
  }

  /// CHECK IF LOGGED IN
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// GET USER ROLE
  Future<String?> getUserRole() async {
    if (_cachedRole != null) {
      return _cachedRole;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedRole = prefs.getString('user_role');
      return _cachedRole;
    } catch (e) {
      debugPrint('❌ Error getting role: $e');
      return null;
    }
  }

  /// VERIFY TOKEN
  Future<Map<String, dynamic>> verifyToken() async {
    try {
      final headers = await _getHeaders();

      final response = await http
          .get(
            Uri.parse('$baseUrl/api/v1/user/profile'),
            headers: headers,
          ) // Using profile endpoint to verify token
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Token is valid'};
      } else {
        // await logout(); // Don't logout immediately, maybe just connection issue
        if (response.statusCode == 401) {
          await logout();
          return {
            'success': false,
            'message': 'Token expired or invalid',
            'requiresLogin': true,
          };
        }
        return {
          'success': false,
          'message':
              'Token verification failed with status ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint(' Token verification error: $e');
      return {'success': false, 'message': 'Could not verify token'};
    }
  }



  /// Forgot Password (Send OTP)
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      debugPrint(' POST: $baseUrl${ApiConfig.forgotPassword}');
      debugPrint(' Email: $email');

      final response = await http
          .post(
            Uri.parse('$baseUrl${ApiConfig.forgotPassword}'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode({'email': email}),
          )
          .timeout(const Duration(seconds: 20));

      debugPrint('Status: ${response.statusCode}');
      debugPrint('Response: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'OTP sent successfully',
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to send OTP',
        };
      }
    } catch (e) {
      debugPrint('❌ Forgot password error: $e');
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  /// Verify OTP (Might not be needed separately if Reset Password includes OTP, but good to have)
  Future<Map<String, dynamic>> verifyOTP(String email, String otp) async {
 

    try {
      debugPrint('📤 POST: $baseUrl${ApiConfig.verifyOTP}');

      final response = await http
          .post(
            Uri.parse('$baseUrl${ApiConfig.verifyOTP}'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode({'email': email, 'otp': otp}),
          )
          .timeout(const Duration(seconds: 20));

      debugPrint(' Status: ${response.statusCode}');
      debugPrint(' Response: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'OTP Verified'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Invalid OTP'};
      }
    } catch (e) {
      // If endpoint doesn't exist, we might just return true to proceed to reset screen
      // IF the backend does the check at reset-password time.
      // But user request specifically said "verify otp".
      // I'll leave this implemented assuming there is an endpoint or we can skip if not.
      // For now let's try to hit it.
      debugPrint(' Verify OTP error: $e');
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  ///  Reset Password
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      debugPrint(' POST: $baseUrl${ApiConfig.resetPassword}');

      final response = await http
          .post(
            Uri.parse('$baseUrl${ApiConfig.resetPassword}'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode({
              'email': email,
              'otp': otp,
              'password':
                  newPassword, // Changed from newPassword to password based on typical APIs
            }),
          )
          .timeout(const Duration(seconds: 20));

      debugPrint(' Status: ${response.statusCode}');
      debugPrint(' Response: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Password reset successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to reset password',
        };
      }
    } catch (e) {
      debugPrint(' Reset password error: $e');
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  /// ✅ Delete Account
  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final headers = await _getHeaders();
      debugPrint('🗑️ DELETE: $baseUrl${ApiConfig.deleteAccount}');

      final response = await http
          .delete(
            Uri.parse('$baseUrl${ApiConfig.deleteAccount}'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      debugPrint(' Status: ${response.statusCode}');
      debugPrint(' Response: ${response.body}');

      if (response.statusCode == 200) {
        // After successful deletion on backend, clear local data
        await logout();
        return {'success': true, 'message': 'Account deleted successfully'};
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete account',
        };
      }
    } catch (e) {
      debugPrint('❌ Delete account error: $e');
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // ✅ Block a user (UGC Safety - Apple Guideline 1.2)
  Future<Map<String, dynamic>> blockUser(String targetUserId) async {
    try {
      final headers = await _getHeaders();
      debugPrint('🚫 POST: $baseUrl${ApiConfig.blockUser}/$targetUserId');

      final response = await http
          .post(
            Uri.parse('$baseUrl${ApiConfig.blockUser}/$targetUserId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'User blocked',
      };
    } catch (e) {
      debugPrint('❌ Block user error: $e');
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // ✅ Unblock a user
  Future<Map<String, dynamic>> unblockUser(String targetUserId) async {
    try {
      final headers = await _getHeaders();
      debugPrint('✅ DELETE: $baseUrl${ApiConfig.blockUser}/$targetUserId');

      final response = await http
          .delete(
            Uri.parse('$baseUrl${ApiConfig.blockUser}/$targetUserId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'User unblocked',
      };
    } catch (e) {
      debugPrint('❌ Unblock user error: $e');
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // ✅ Report content / user (UGC Safety - Apple Guideline 1.2)
  Future<Map<String, dynamic>> reportContent({
    required String reportedUserId,
    required String itemType, // "Post", "Reel", "Comment", "User"
    required String itemId,
    required String reason,
  }) async {
    try {
      final headers = await _getHeaders();
      debugPrint('⚠️ POST: $baseUrl${ApiConfig.reportContent}');

      final response = await http
          .post(
            Uri.parse('$baseUrl${ApiConfig.reportContent}'),
            headers: headers,
            body: json.encode({
              'reportedUserId': reportedUserId,
              'itemType': itemType,
              'itemId': itemId,
              'reason': reason,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);
      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'message': data['message'] ?? 'Report submitted',
      };
    } catch (e) {
      debugPrint('❌ Report content error: $e');
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }
}
