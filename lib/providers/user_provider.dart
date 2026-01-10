import 'dart:io';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  /// Fetch user profile
  Future<bool> fetchUserProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('📥 Fetching user profile...');
      final response = await UserService.getUserProfile();

      if (response['success'] == true && response['data'] != null) {
        _user = UserModel.fromJson(response['data']);
        print('✅ User profile loaded: ${_user?.fullName}');
        print('✅ Profile image: ${_user?.profileImage}');
        print('✅ Specialty: ${_user?.specialty}');
        print('✅ Bio: ${_user?.bio}');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to fetch profile';
        print('❌ Profile fetch failed: $_error');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      print('❌ Exception: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update user profile (with image support)
  Future<bool> updateUserProfile({
    String? fullName,
    String? username,
    String? phone,
    String? bio,
    String? gender,
    String? dob,
    String? address,
    String? country,
    String? language,
    int? experienceYears,
    String? specialty,
    List<String>? specialties,
    List<Map<String, dynamic>>? degrees,
    Map<String, dynamic>? fees,
    List<Map<String, dynamic>>? weeklySchedule,
    String? visitingHoursText,
    String? medicalLicenseNumber,
    File? profileImage,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('📤 Updating profile...');
      print('   - fullName: $fullName');
      print('   - phone: $phone');
      print('   - address: $address');
      print('   - bio: $bio');
      print('   - specialty: $specialty');
      print('   - profileImage: ${profileImage != null ? "Yes" : "No"}');

      // ✅ Pass File directly to UserService
      final response = await UserService.updateUserProfile(
        fullName: fullName,
        username: username,
        phone: phone,
        bio: bio,
        gender: gender,
        dob: dob,
        address: address,
        country: country,
        language: language,
        experienceYears: experienceYears,
        specialty: specialty,
        specialties: specialties,
        degrees: degrees,
        fees: fees,
        weeklySchedule: weeklySchedule,
        visitingHoursText: visitingHoursText,
        medicalLicenseNumber: medicalLicenseNumber,
        profileImage: profileImage, // ✅ UserService will handle base64 conversion
      );

      if (response['success'] == true && response['data'] != null) {
        _user = UserModel.fromJson(response['data']);
        print('✅ Profile updated successfully!');
        print('   - Name: ${_user?.fullName}');
        print('   - Specialty: ${_user?.specialty}');
        print('   - Bio: ${_user?.bio}');
        print('   - Address: ${_user?.address}');
        print('   - New avatar: ${_user?.profileImage}');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to update profile';
        print('❌ Update failed: $_error');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      print('❌ Exception during update: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await UserService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      if (response['success'] == true) {
        print('✅ Password changed successfully');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to change password';
        print('❌ Password change failed: $_error');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      print('❌ Exception: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Set user (for login)
  void setUser(UserModel user) {
    _user = user;
    _error = null;
    print('👤 User set: ${user.fullName}');
    notifyListeners();
  }

  /// Clear user (for logout)
  void clearUser() {
    _user = null;
    _error = null;
    _isLoading = false;
    print('🚪 User cleared (logged out)');
    notifyListeners();
  }

  /// Update local user data without API call
  void updateLocalUser(UserModel updatedUser) {
    _user = updatedUser;
    print('🔄 Local user updated: ${updatedUser.fullName}');
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh user profile (pull-to-refresh)
  Future<void> refreshProfile() async {
    await fetchUserProfile();
  }
}