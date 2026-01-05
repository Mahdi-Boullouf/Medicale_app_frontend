import 'package:flutter/material.dart';
import '../models/appointment_model.dart';
import '../services/appointment_service.dart';

class AppointmentProvider with ChangeNotifier {
  final AppointmentService _appointmentService = AppointmentService();

  List<AppointmentModel> _appointments = [];
  bool _isLoading = false;
  String? _error;

  List<AppointmentModel> get appointments => _appointments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasAppointments => _appointments.isNotEmpty;

  List<AppointmentModel> get upcomingAppointments => _appointments
      .where((apt) =>
          apt.status.toLowerCase() == 'pending' ||
          apt.status.toLowerCase() == 'accepted' ||
          apt.status.toLowerCase() == 'confirmed')
      .toList();

  List<AppointmentModel> get completedAppointments => _appointments
      .where((apt) => apt.status.toLowerCase() == 'completed')
      .toList();

  List<AppointmentModel> get cancelledAppointments => _appointments
      .where((apt) => apt.status.toLowerCase() == 'cancelled')
      .toList();

  Future<bool> fetchAppointments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _appointmentService.getMyAppointments();

      if (response['success'] == true) {
        // ✅ Safely handle data field
        final data = response['data'];
        
        if (data == null) {
          _appointments = [];
        } else if (data is List) {
          _appointments = data
              .map((json) {
                try {
                  return AppointmentModel.fromJson(json as Map<String, dynamic>);
                } catch (e) {
                  print('⚠️ Error parsing appointment: $e');
                  print('📦 JSON data: $json');
                  return null;
                }
              })
              .whereType<AppointmentModel>() // Remove nulls
              .toList();
        } else {
          print('⚠️ Unexpected data type: ${data.runtimeType}');
          _appointments = [];
        }

        // Sort by date (newest first)
        _appointments.sort((a, b) => 
            b.appointmentDate.compareTo(a.appointmentDate));

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to fetch appointments';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ Fetch Appointments Error: $e');
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> createAppointment({
    required String doctorId,
    required DateTime appointmentDate,
    required String appointmentTime,
    String? symptoms,
    String? appointmentType,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _appointmentService.createAppointment(
        doctorId: doctorId,
        appointmentDate: appointmentDate.toIso8601String().split('T')[0],
        appointmentTime: appointmentTime,
        symptoms: symptoms,
        appointmentType: appointmentType ?? 'physical',
      );

      if (response['success'] == true) {
        // Refresh appointments list
        await fetchAppointments();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to create appointment';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ Create Appointment Error: $e');
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelAppointment(String appointmentId) async {
    try {
      final response = await _appointmentService.cancelAppointment(appointmentId);

      if (response['success'] == true) {
        // ✅ Update using copyWith method
        final index = _appointments.indexWhere((apt) => apt.id == appointmentId);
        if (index != -1) {
          _appointments[index] = _appointments[index].copyWith(
            status: 'cancelled',
          );
        }
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to cancel appointment';
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ Cancel Appointment Error: $e');
      _error = 'Error: $e';
      notifyListeners();
      return false;
    }
  }

  void clearAppointments() {
    _appointments = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  // ✅ Additional helper method
  AppointmentModel? getAppointmentById(String id) {
    try {
      return _appointments.firstWhere((apt) => apt.id == id);
    } catch (e) {
      return null;
    }
  }
}