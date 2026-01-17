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
      print('📡 Fetching doctors from API...');
      final response = await _doctorService.getNearbyDoctors();

      print('📥 API Response:');
      print('   - Success: ${response['success']}');
      print('   - Data count: ${(response['data'] as List?)?.length ?? 0}');

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        
        // ✅ Debug each doctor BEFORE parsing
        print('\n🔍 Raw Doctor Data:');
        for (var json in data) {
          print('   Doctor: ${json['fullName']}');
          print('      - _id: ${json['_id']}');
          print('      - specialty: ${json['specialty']}');
          print('      - isVideoCallAvailable: ${json['isVideoCallAvailable']}');
          print('      - weeklySchedule: ${json['weeklySchedule']?.length ?? 0} days');
          print('      - avatar: ${json['avatar']}');
          print('---');
        }

        // Parse to Doctor objects
        _nearbyDoctors = data.map((json) => Doctor.fromJson(json)).toList();
        
        // ✅ Debug AFTER parsing
        print('\n✅ Parsed Doctors:');
        for (var doctor in _nearbyDoctors) {
          print('   ${doctor.fullName}:');
          print('      - ID: ${doctor.id}');
          print('      - Video Call: ${doctor.isVideoCallAvailable}');
          print('      - Has Schedule: ${doctor.weeklySchedule != null}');
          print('      - Schedule Days: ${doctor.weeklySchedule?.length ?? 0}');
          print('---');
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to fetch doctors';
        print('❌ API Error: $_error');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      _error = 'Error: $e';
      print('❌ Exception in fetchNearbyDoctors:');
      print('   Error: $e');
      print('   StackTrace: $stackTrace');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearDoctors() {
    print('🗑️ Clearing doctors list');
    _nearbyDoctors = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}