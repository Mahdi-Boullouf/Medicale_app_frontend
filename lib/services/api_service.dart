import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String? _token;
  static const String _baseUrl = 'http://localhost:5000'; // Change this to your backend URL

  /// Initialize - Token load kora
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      print('✅ ApiService initialized. Token: ${_token != null ? "Found" : "Not found"}');
      
      if (_token != null) {
        print('🔍 Token status: ${isLoggedIn ? "Logged In" : "Not Logged In"}');
      }
    } catch (e) {
      print('❌ Error initializing ApiService: $e');
    }
  }

  /// Token save kora
  static Future<void> saveToken(String token) async {
    try {
      _token = token;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      print('✅ Token saved: ${token.substring(0, 20)}...');
    } catch (e) {
      print('❌ Error saving token: $e');
    }
  }

  /// Token clear kora
  static Future<void> clearToken() async {
    try {
      _token = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      print('✅ Token cleared');
    } catch (e) {
      print('❌ Error clearing token: $e');
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
      print('🔐 Token added to headers: Bearer ${_token!.substring(0, 20)}...');
    } else if (requiresAuth && (_token == null || _token!.isEmpty)) {
      print('⚠️ Auth required but no token available');
    }

    return headers;
  }

  /// GET Request
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    try {
      final url = '$_baseUrl$endpoint';
      print('📤 GET: $url');
      print('🔐 Auth Required: $requiresAuth');

      final headers = _getHeaders(requiresAuth: requiresAuth);
      print('📋 Headers: ${headers.keys.toList()}');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      print('❌ GET Error: $e');
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  /// POST Request
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    try {
      final url = '$_baseUrl$endpoint';
      print('📤 POST: $url');
      print('📦 Body: $body');
      print('🔐 Auth Required: $requiresAuth');

      final headers = _getHeaders(requiresAuth: requiresAuth);

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      ).timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      print('❌ POST Error: $e');
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  /// PUT Request
  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    try {
      final url = '$_baseUrl$endpoint';
      print('📤 PUT: $url');
      print('📦 Body: $body');
      print('🔐 Auth Required: $requiresAuth');

      final headers = _getHeaders(requiresAuth: requiresAuth);

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      ).timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      print('❌ PUT Error: $e');
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  /// PATCH Request
  static Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    try {
      final url = '$_baseUrl$endpoint';
      print('📤 PATCH: $url');
      print('📦 Body: $body');
      print('🔐 Auth Required: $requiresAuth');

      final headers = _getHeaders(requiresAuth: requiresAuth);

      final response = await http.patch(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      ).timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      print('❌ PATCH Error: $e');
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  /// DELETE Request
  static Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    try {
      final url = '$_baseUrl$endpoint';
      print('📤 DELETE: $url');
      print('🔐 Auth Required: $requiresAuth');

      final headers = _getHeaders(requiresAuth: requiresAuth);

      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      print('❌ DELETE Error: $e');
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  /// Response handler
  static Map<String, dynamic> _handleResponse(http.Response response) {
    print('📥 Status: ${response.statusCode}');
    print('📥 Response Body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');

    try {
      final data = json.decode(response.body) as Map<String, dynamic>;

      // Success response (200-299)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'statusCode': response.statusCode,
          ...data,
        };
      }
      // Unauthorized (401) - Token invalid/expired
      else if (response.statusCode == 401) {
        print('⚠️ 401 Unauthorized - Clearing token');
        clearToken();
        return {
          'success': false,
          'message': data['message'] ?? 'Session expired. Please login again.',
          'requiresLogin': true,
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
          'errors': data['errorSources'] ?? [],
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
      print('❌ Response parsing error: $e');
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

  /// Update base URL if needed (for different environments)
  static void setBaseUrl(String url) {
    // Remove this method if you're using ApiConfig
    print('⚠️ Base URL updated to: $url');
  }
}