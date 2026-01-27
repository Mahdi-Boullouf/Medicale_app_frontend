// providers/user_provider.dart
// ✅ UPDATED with Video Call Toggle Support

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
      debugPrint('📥 Fetching user profile...');
      final response = await UserService.getUserProfile();

      if (response['success'] == true && response['data'] != null) {
        _user = UserModel.fromJson(response['data']);
        debugPrint('✅ User profile loaded: ${_user?.fullName}');
        debugPrint('✅ Profile image: ${_user?.profileImage}');
        debugPrint('✅ Specialty: ${_user?.specialty}');
        debugPrint('✅ Bio: ${_user?.bio}');
        print('✅ Video Call Available: ${_user?.isVideoCallAvailable}');
        debugPrint(
          '✅ Location: lat=${_user?.latitude}, lng=${_user?.longitude}',
        );
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
      debugPrint('❌ Exception: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// ✅ NEW: Update video call availability
  Future<bool> updateVideoCallAvailability(bool isAvailable) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('📤 Updating video call availability: $isAvailable');

      final response = await UserService.updateUserProfile(
        isVideoCallAvailable: isAvailable,
      );

      if (response['success'] == true && response['data'] != null) {
        _user = UserModel.fromJson(response['data']);
        print(
          '✅ Video call availability updated: ${_user?.isVideoCallAvailable}',
        );
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to update video call setting';
        print('❌ Update failed: $_error');
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

  /// Update user profile (with image and location support)
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
    double? latitude,
    double? longitude,
    bool? isVideoCallAvailable, // ✅ NEW
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('📤 Updating profile...');
      debugPrint('   - fullName: $fullName');
      debugPrint('   - phone: $phone');
      debugPrint('   - address: $address');
      debugPrint('   - bio: $bio');
      debugPrint('   - specialty: $specialty');
      debugPrint('   - latitude: $latitude');
      debugPrint('   - longitude: $longitude');
      debugPrint('   - isVideoCallAvailable: $isVideoCallAvailable'); // ✅ NEW
      debugPrint('   - profileImage: ${profileImage != null ? "Yes" : "No"}');

      // ✅ Pass all fields including video call to UserService
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
        profileImage: profileImage,
        latitude: latitude,
        longitude: longitude,
        isVideoCallAvailable: isVideoCallAvailable, // ✅ NEW
      );

      if (response['success'] == true && response['data'] != null) {
        var updatedUser = UserModel.fromJson(response['data']);

        // ⚠️ PATCH: The backend might return stale data for isVideoCallAvailable.
        // If we explicitly updated it and the server confirms success, we trust the intent.
        if (isVideoCallAvailable != null &&
            updatedUser.isVideoCallAvailable != isVideoCallAvailable) {
          debugPrint(
            '⚠️ Server returned stale video call data. Forcing local update to: $isVideoCallAvailable',
          );
          updatedUser = updatedUser.copyWith(
            isVideoCallAvailable: isVideoCallAvailable,
          );
        }

        _user = updatedUser;
        debugPrint('✅ Profile updated successfully!');
        debugPrint('   - Name: ${_user?.fullName}');
        debugPrint('   - Specialty: ${_user?.specialty}');
        debugPrint('   - Bio: ${_user?.bio}');
        debugPrint('   - Address: ${_user?.address}');
        debugPrint(
          '   - Location: lat=${_user?.latitude}, lng=${_user?.longitude}',
        );
        print('   - Video Call: ${_user?.isVideoCallAvailable}'); // ✅ NEW
        debugPrint('   - New avatar: ${_user?.profileImage}');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to update profile';
        debugPrint('❌ Update failed: $_error');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      debugPrint('❌ Exception during update: $e');
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
        debugPrint('✅ Password changed successfully');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to change password';
        debugPrint('❌ Password change failed: $_error');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      debugPrint('❌ Exception: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Set user (for login)
  void setUser(UserModel user) {
    _user = user;
    _error = null;
    debugPrint('👤 User set: ${user.fullName}');
    notifyListeners();
  }

  /// Clear user (for logout)
  void clearUser() {
    _user = null;
    _error = null;
    _isLoading = false;
    debugPrint('🚪 User cleared (logged out)');
    notifyListeners();
  }

  /// Update local user data without API call
  void updateLocalUser(UserModel updatedUser) {
    _user = updatedUser;
    debugPrint('🔄 Local user updated: ${updatedUser.fullName}');
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
