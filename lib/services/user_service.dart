import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_config.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class UserService {
  /// Get current user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await ApiService.get(
        ApiConfig.userProfile,
        requiresAuth: true,
      );

      if (response['success'] == true) {
        if (response['data'] != null) {
          await _saveUserInfo(response['data']);
        }
      }

      return response;
    } catch (e) {
      print('❌ Get Profile Error: $e');
      return {
        'success': false,
        'message': 'Failed to fetch profile: $e',
      };
    }
  }

  /// Get user by ID
  Future<Map<String, dynamic>> getUserById(String userId) async {
    try {
      final response = await ApiService.get(
        '${ApiConfig.getUserById}/$userId',
        requiresAuth: true,
      );

      return response;
    } catch (e) {
      print('❌ Get User By ID Error: $e');
      return {
        'success': false,
        'message': 'Failed to fetch user: $e',
      };
    }
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? phone,
    String? dateOfBirth,
    String? gender,
    String? bloodGroup,
    String? address,
    String? profileImage,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      
      if (fullName != null) body['fullName'] = fullName;
      if (phone != null) body['phone'] = phone;
      if (dateOfBirth != null) body['dateOfBirth'] = dateOfBirth;
      if (gender != null) body['gender'] = gender;
      if (bloodGroup != null) body['bloodGroup'] = bloodGroup;
      if (address != null) body['address'] = address;
      if (profileImage != null) body['profileImage'] = profileImage;

      final response = await ApiService.put(
        ApiConfig.updateProfile,
        body,
        requiresAuth: true,
      );

      if (response['success'] == true) {
        if (response['data'] != null) {
          await _saveUserInfo(response['data']);
        }
      }

      return response;
    } catch (e) {
      print('❌ Update Profile Error: $e');
      return {
        'success': false,
        'message': 'Failed to update profile: $e',
      };
    }
  }

  /// Get locally saved user info
  Future<Map<String, dynamic>> getLocalUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      return {
        'user_id': prefs.getString('user_id') ?? '',
        'user_name': prefs.getString('user_name') ?? '',
        'user_email': prefs.getString('user_email') ?? '',
        'user_role': prefs.getString('user_role') ?? '',
        'user_phone': prefs.getString('user_phone') ?? '',
      };
    } catch (e) {
      print('❌ Get Local User Info Error: $e');
      return {};
    }
  }

  /// Save user info locally
  Future<void> _saveUserInfo(Map<String, dynamic> user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString('user_id', user['_id'] ?? user['id'] ?? '');
      await prefs.setString('user_name', user['fullName'] ?? '');
      await prefs.setString('user_email', user['email'] ?? '');
      await prefs.setString('user_role', user['role'] ?? '');
      
      if (user['phone'] != null) {
        await prefs.setString('user_phone', user['phone']);
      }
      
      print('✅ User info saved locally');
    } catch (e) {
      print('❌ Save User Info Error: $e');
    }
  }

  /// Clear local user data
  Future<void> clearLocalUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('✅ Local user data cleared');
    } catch (e) {
      print('❌ Clear Local Data Error: $e');
    }
  }
}