import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl =
      'http://localhost:5000'; // ⚠️ Change this to your API URL
  static String? _cachedToken;
  static String? _cachedRole;

  /// ✅ Initialize - Load token from SharedPreferences
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedToken = prefs.getString('auth_token');
      _cachedRole = prefs.getString('user_role');

      debugPrint('✅ AuthService initialized');
      debugPrint('   Token: ${_cachedToken != null ? "Found" : "Not found"}');
      debugPrint('   Role: $_cachedRole');
    } catch (e) {
      debugPrint('❌ Error initializing AuthService: $e');
    }
  }

  /// ✅ Get token (from memory cache first)
  Future<String?> getToken() async {
    if (_cachedToken != null) {
      return _cachedToken;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedToken = prefs.getString('auth_token');
      return _cachedToken;
    } catch (e) {
      debugPrint('❌ Error getting token: $e');
      return null;
    }
  }

  /// ✅ Save token
  Future<void> saveToken(String token) async {
    try {
      _cachedToken = token;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      debugPrint('✅ Token saved: ${token.substring(0, 20)}...');
    } catch (e) {
      debugPrint('❌ Error saving token: $e');
    }
  }

  /// ✅ Save user role
  Future<void> saveUserRole(String role) async {
    try {
      _cachedRole = role;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', role);
      debugPrint('✅ User role saved: $role');
    } catch (e) {
      debugPrint('❌ Error saving role: $e');
    }
  }

  /// ✅ Get headers
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

  /// ✅ LOGIN
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('📤 POST: $baseUrl/api/v1/auth/login');
      debugPrint('📦 Email: $email');

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/v1/auth/login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('📥 Status: ${response.statusCode}');
      debugPrint('📥 Response: ${response.body}');

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

          debugPrint('✅ Login successful - Token and role saved');
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

  /// ✅ REGISTER - Updated to match your backend
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
      debugPrint('📤 POST: $baseUrl/api/v1/auth/register');

      // ✅ Build request body matching your backend
      final Map<String, dynamic> body = {
        'fullName': name, // Your backend expects 'fullName'
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword, // Your backend expects this
        'role': userType.toLowerCase(), // 'doctor' or 'patient'
      };

      // ✅ Add doctor-specific fields if registering as doctor
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

      debugPrint('📦 Body: $body');

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/v1/auth/register'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('📥 Status: ${response.statusCode}');
      debugPrint('📥 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        // ✅ Some APIs return token on registration
        final token =
            data['data']?['token'] ??
            data['token'] ??
            data['data']?['accessToken'];

        if (token != null) {
          await saveToken(token);
          await saveUserRole(userType.toLowerCase());
          debugPrint('✅ Registration successful - Token saved');
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

  /// ✅ LOGOUT
  Future<Map<String, dynamic>> logout() async {
    try {
      final headers = await _getHeaders();

      await http
          .post(Uri.parse('$baseUrl/api/v1/auth/logout'), headers: headers)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('⚠️ Logout request failed: $e');
    }

    try {
      _cachedToken = null;
      _cachedRole = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_role');

      debugPrint('✅ Logout successful - Token cleared');

      return {'success': true, 'message': 'Logged out successfully'};
    } catch (e) {
      debugPrint('❌ Error clearing token: $e');
      return {'success': false, 'message': 'Error logging out'};
    }
  }

  /// ✅ CHECK IF LOGGED IN
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// ✅ GET USER ROLE
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

  /// ✅ VERIFY TOKEN
  Future<Map<String, dynamic>> verifyToken() async {
    try {
      final headers = await _getHeaders();

      final response = await http
          .get(Uri.parse('$baseUrl/api/v1/auth/verify'), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Token is valid'};
      } else {
        await logout();
        return {
          'success': false,
          'message': 'Token expired or invalid',
          'requiresLogin': true,
        };
      }
    } catch (e) {
      debugPrint('❌ Token verification error: $e');
      return {'success': false, 'message': 'Could not verify token'};
    }
  }
}
