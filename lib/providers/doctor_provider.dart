import 'package:flutter/material.dart';
import '../models/doctor_model.dart';
import '../services/doctor_service.dart';

class DoctorProvider with ChangeNotifier {
  final DoctorService _doctorService = DoctorService();

  List<Doctor> _nearbyDoctors = [];
  bool _isLoading = false;
  String? _error;

  List<Doctor> get nearbyDoctors => _nearbyDoctors;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> fetchNearbyDoctors() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _doctorService.getNearbyDoctors();

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        _nearbyDoctors = data.map((json) => Doctor.fromJson(json)).toList();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to fetch doctors';
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

  void clearDoctors() {
    _nearbyDoctors = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}