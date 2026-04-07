import 'dart:convert'; 
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/doctor_schedule_service.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  ///  Load user from local cache immediately on app start
  Future<void> loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('cached_user_profile');
      if (userJson != null) {
        debugPrint(' Loading user profile from CACHE...');
        final Map<String, dynamic> data = jsonDecode(userJson);
        _user = UserModel.fromJson(data);
        notifyListeners(); // Update UI immediately
      }
    } catch (e) {
      debugPrint(' Error loading cached profile: $e');
    }
  }

  ///  Save user to local cache
  Future<void> _saveToCache(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_user_profile', jsonEncode(data));
      debugPrint('User profile cached locally');
    } catch (e) {
      debugPrint('Error caching profile: $e');
    }
  }

  /// Fetch user profile with Caching & Silent Refresh
  Future<bool> fetchUserProfile({bool forceRefresh = false}) async {
    // 1. Silent Refresh: If we already have data, don't show loading spinner
    // unless explicitly forced.
    if (_user == null || forceRefresh) {
      _isLoading = true;
      notifyListeners();
    }
    
    _error = null;

    try {
      debugPrint(' Fetching user profile...');
      final response = await UserService.getUserProfile();

      if (response['success'] == true && response['data'] != null) {
        _user = UserModel.fromJson(response['data']);
        
        //  Cache the fresh data
        _saveToCache(response['data']);

        debugPrint('User profile loaded: ${_user?.fullName}');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to fetch profile';
        // Only stop loading if we were loading
        if (_isLoading) {
           _isLoading = false;
           notifyListeners();
        }
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      if (_isLoading) {
         _isLoading = false;
         notifyListeners();
      }
      return false;
    }
  }

  /// Update video call availability
  Future<bool> updateVideoCallAvailability(bool isAvailable) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint(
        'Updating video call availability via Schedule Service: $isAvailable',
      );

      //  ENSURE PERSISTENCE: Use DoctorScheduleService which is known to work
      // with this specific combination of fields.
      final scheduleService = DoctorScheduleService();

      final currentFees = _user?.fees ?? {'amount': 0, 'currency': 'USD'};
      final currentSchedule =
          _user?.weeklySchedule?.map((d) => d.toJson()).toList() ?? [];

      final response = await scheduleService.saveWeeklySchedule(
        weeklySchedule: currentSchedule,
        fees: currentFees,
        isVideoCallAvailable: isAvailable,
        isAvailable: isAvailable, 
      );

      if (response['success'] == true) {
        debugPrint('Server confirmed update. Refreshing profile...');

        // Patch locally immediately so the UI reflects it even if refresh returns stale data
        if (_user != null) {
          _user = _user!.copyWith(isVideoCallAvailable: isAvailable);
          notifyListeners();
        }

        // Force refresh from server to see what it actually stored
        await fetchUserProfile();

        // FINAL PATCH: If server STILL returned stale data, force our intent
        if (_user != null && _user!.isVideoCallAvailable != isAvailable) {
          debugPrint(
            ' Server returned stale data after refresh. Forcing local patch again.',
          );
          _user = _user!.copyWith(isVideoCallAvailable: isAvailable);
          notifyListeners();
        }

        _isLoading = false;
        return true;
      } else {
        _error = response['message'] ?? 'Failed to update availability';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      debugPrint(' Exception during availability update: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update online appointment availability
  Future<bool> updateOnlineAppointmentAvailability(bool isAvailable) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint(
        'Updating online appointment availability via Schedule Service: $isAvailable',
      );

      final scheduleService = DoctorScheduleService();

      final currentFees = _user?.fees ?? {'amount': 0, 'currency': 'USD'};
      final currentSchedule =
          _user?.weeklySchedule?.map((d) => d.toJson()).toList() ?? [];

      final response = await scheduleService.saveWeeklySchedule(
        weeklySchedule: currentSchedule,
        fees: currentFees,
        isVideoCallAvailable: _user?.isVideoCallAvailable ?? true,
        isOnlineAppointmentAvailable: isAvailable,
      );

      if (response['success'] == true) {
        debugPrint('Server confirmed update. Refreshing profile...');

        if (_user != null) {
          _user = _user!.copyWith(isOnlineAppointmentAvailable: isAvailable);
          notifyListeners();
        }

        await fetchUserProfile();

        if (_user != null && _user!.isOnlineAppointmentAvailable != isAvailable) {
          _user = _user!.copyWith(isOnlineAppointmentAvailable: isAvailable);
          notifyListeners();
        }

        _isLoading = false;
        return true;
      } else {
        _error = response['message'] ?? 'Failed to update appointment setting';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
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
    bool? isVideoCallAvailable, 
    bool? isOnlineAppointmentAvailable, 
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint(' Updating profile...');
      debugPrint('   - fullName: $fullName');
      debugPrint('   - phone: $phone');
      debugPrint('   - address: $address');
      debugPrint('   - bio: $bio');
      debugPrint('   - specialty: $specialty');
      debugPrint('   - latitude: $latitude');
      debugPrint('   - longitude: $longitude');
      debugPrint(' Adding isVideoCallAvailable: $isVideoCallAvailable');
      debugPrint(' Adding isOnlineAppointmentAvailable: $isOnlineAppointmentAvailable');

      debugPrint('   - profileImage: ${profileImage != null ? "Yes" : "No"}');

      
      final currentFees =
          fees ?? (_user?.role == 'doctor' ? _user?.fees : null);
      final currentSchedule =
          weeklySchedule ??
          (_user?.role == 'doctor'
              ? _user?.weeklySchedule?.map((d) => d.toJson()).toList()
              : null);
      final currentSpecialty =
          specialty ?? (_user?.role == 'doctor' ? _user?.specialty : null);
      final currentExperience =
          experienceYears ??
          (_user?.role == 'doctor' ? _user?.experienceYears : null);
      final currentBio = bio ?? (_user?.role == 'doctor' ? _user?.bio : null);
      final currentLicense =
          medicalLicenseNumber ??
          (_user?.role == 'doctor' ? _user?.medicalLicenseNumber : null);

      //  Location handling - persist if not explicitly updated
      final currentLat = latitude ?? (_user?.latitude);
      final currentLng = longitude ?? (_user?.longitude);

      //  Pass ONLY provided fields (plus required doctor fields for persistence)
      final response = await UserService.updateUserProfile(
        fullName: fullName,
        username: username,
        phone: phone,
        bio: currentBio, // Use persisted bio for doctors
        gender: gender,
        dob: dob,
        address: address,
        country: country,
        language: language,
        experienceYears:
            currentExperience, // Use persisted experience for doctors
        specialty: currentSpecialty, // Use persisted specialty for doctors
        specialties: specialties,
        degrees: degrees,
        fees: currentFees, // Use persisted fees for doctors
        weeklySchedule: currentSchedule, // Use persisted schedule for doctors
        visitingHoursText: visitingHoursText,
        medicalLicenseNumber:
            currentLicense, // Use persisted license for doctors
        profileImage: profileImage,
        latitude: currentLat, // Use persisted latitude
        longitude: currentLng, // Use persisted longitude
        isVideoCallAvailable: isVideoCallAvailable,
        isOnlineAppointmentAvailable: isOnlineAppointmentAvailable,
      );

      if (response['success'] == true && response['data'] != null) {
        var updatedUser = UserModel.fromJson(response['data']);

        //  PATCH: The backend might return stale data for isVideoCallAvailable.
        // If we explicitly updated it and the server confirms success, we trust the intent.
        if (isVideoCallAvailable != null &&
            updatedUser.isVideoCallAvailable != isVideoCallAvailable) {
          debugPrint(
            ' Server returned stale video call data. Forcing local update to: $isVideoCallAvailable',
          );
          updatedUser = updatedUser.copyWith(
            isVideoCallAvailable: isVideoCallAvailable,
          );
        }

        if (isOnlineAppointmentAvailable != null &&
            updatedUser.isOnlineAppointmentAvailable !=
                isOnlineAppointmentAvailable) {
          updatedUser = updatedUser.copyWith(
            isOnlineAppointmentAvailable: isOnlineAppointmentAvailable,
          );
        }

        _user = updatedUser;
        debugPrint('Profile updated successfully!');
        debugPrint('   - Name: ${_user?.fullName}');
        debugPrint('   - Specialty: ${_user?.specialty}');
        debugPrint('   - Bio: ${_user?.bio}');
        debugPrint('   - Address: ${_user?.address}');
        debugPrint(
          '   - Location: lat=${_user?.latitude}, lng=${_user?.longitude}',
        );
        debugPrint('   - Video Call: ${_user?.isVideoCallAvailable}');
        debugPrint('   - New avatar: ${_user?.profileImage}');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to update profile';
        debugPrint(' Update failed: $_error');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      debugPrint(' Exception during update: $e');
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
        debugPrint(' Password changed successfully');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to change password';
        debugPrint(' Password change failed: $_error');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      debugPrint(' Exception: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Set user (for login)
  void setUser(UserModel user) {
    _user = user;
    _error = null;
    debugPrint(' User set: ${user.fullName}');
    notifyListeners();
  }

  /// Clear user (for logout)
  void clearUser() {
    _user = null;
    _error = null;
    _isLoading = false;
    debugPrint(' User cleared (logged out)');
    notifyListeners();
  }

  /// Update local user data without API call
  void updateLocalUser(UserModel updatedUser) {
    _user = updatedUser;
    debugPrint(' Local user updated: ${updatedUser.fullName}');
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
