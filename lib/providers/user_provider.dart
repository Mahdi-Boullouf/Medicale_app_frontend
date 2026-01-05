import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserProvider with ChangeNotifier {
  final UserService _userService = UserService();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasUser => _user != null;

  /// Fetch user profile from API
  Future<bool> fetchUserProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _userService.getUserProfile();

      if (response['success'] == true && response['data'] != null) {
        _user = UserModel.fromJson(response['data']);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to fetch profile';
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

  /// Update user profile
  Future<bool> updateProfile({
    String? fullName,
    String? phone,
    String? dateOfBirth,
    String? gender,
    String? bloodGroup,
    String? address,
    String? profileImage,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _userService.updateProfile(
        fullName: fullName,
        phone: phone,
        dateOfBirth: dateOfBirth,
        gender: gender,
        bloodGroup: bloodGroup,
        address: address,
        profileImage: profileImage,
      );

      if (response['success'] == true && response['data'] != null) {
        _user = UserModel.fromJson(response['data']);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to update profile';
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

  /// Load local user info
  Future<void> loadLocalUserInfo() async {
    try {
      final localInfo = await _userService.getLocalUserInfo();
      
      if (localInfo['user_id']?.isNotEmpty ?? false) {
        _user = UserModel(
          id: localInfo['user_id'] ?? '',
          fullName: localInfo['user_name'] ?? '',
          email: localInfo['user_email'] ?? '',
          role: localInfo['user_role'] ?? '',
          phone: localInfo['user_phone'],
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error loading local user info: $e');
    }
  }

  /// Clear user data
  void clearUser() {
    _user = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}