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

  // Filter by status
  List<AppointmentModel> get pendingAppointments => _appointments
      .where((apt) => apt.status.toLowerCase() == 'pending')
      .toList();

  List<AppointmentModel> get acceptedAppointments => _appointments
      .where((apt) => apt.status.toLowerCase() == 'accepted')
      .toList();

  List<AppointmentModel> get upcomingAppointments => _appointments
      .where(
        (apt) =>
            apt.status.toLowerCase() == 'pending' ||
            apt.status.toLowerCase() == 'accepted',
      )
      .toList();

  List<AppointmentModel> get completedAppointments => _appointments
      .where((apt) => apt.status.toLowerCase() == 'completed')
      .toList();

  List<AppointmentModel> get cancelledAppointments => _appointments
      .where((apt) => apt.status.toLowerCase() == 'cancelled')
      .toList();

  /// Fetch appointments
  Future<bool> fetchAppointments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _appointmentService.getMyAppointments();

      if (response['success'] == true) {
        final data = response['data'];

        if (data == null) {
          _appointments = [];
        } else if (data is List) {
          _appointments = data
              .map((json) {
                try {
                  return AppointmentModel.fromJson(
                    json as Map<String, dynamic>,
                  );
                } catch (e) {
                  debugPrint('Error parsing appointment: $e');
                  return null;
                }
              })
              .whereType<AppointmentModel>()
              .toList();
        } else {
          _appointments = [];
        }

        // Sort by date (newest first)
        _appointments.sort(
          (a, b) => b.appointmentDate.compareTo(a.appointmentDate),
        );

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
      debugPrint('Fetch Appointments Error: $e');
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Create appointment (Patient)
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
      debugPrint('Create Appointment Error: $e');
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Accept appointment (Doctor)
  Future<bool> acceptAppointment(String appointmentId) async {
    try {
      debugPrint('Accepting appointment: $appointmentId');

      final response = await _appointmentService.updateAppointmentStatus(
        appointmentId: appointmentId,
        status: 'accepted',
      );

      if (response['success'] == true) {
        // Update local state
        final index = _appointments.indexWhere(
          (apt) => apt.id == appointmentId,
        );
        if (index != -1) {
          _appointments[index] = _appointments[index].copyWith(
            status: 'accepted',
          );

          // Create and send appointment confirmation notification
          await _sendAppointmentConfirmationNotification(_appointments[index]);
        }
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to accept appointment';
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Accept Appointment Error: $e');
      _error = 'Error: $e';
      notifyListeners();
      return false;
    }
  }

  /// Cancel appointment (Doctor/Patient)
  Future<bool> cancelAppointment(String appointmentId) async {
    try {
      debugPrint('Cancelling appointment: $appointmentId');

      final response = await _appointmentService.updateAppointmentStatus(
        appointmentId: appointmentId,
        status: 'cancelled',
      );

      if (response['success'] == true) {
        final index = _appointments.indexWhere(
          (apt) => apt.id == appointmentId,
        );
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
      debugPrint('Cancel Appointment Error: $e');
      _error = 'Error: $e';
      notifyListeners();
      return false;
    }
  }

  /// Complete appointment (Doctor - from Session Holder)
  /// FIXED: এখন updateAppointmentStatus কেই call করছে সঠিক data দিয়ে
  Future<bool> completeAppointment({
    required String appointmentId,
    required String patientName,
    required double price,
  }) async {
    try {
      debugPrint('Completing appointment: $appointmentId');
      debugPrint('   Patient: $patientName, Price: $price');

      // গুরুত্বপূর্ণ ফিক্স: backend এর expected key গুলো পাঠানো হচ্ছে
      final response = await _appointmentService.updateAppointmentStatus(
        appointmentId: appointmentId,
        status: 'completed',
        patient: patientName, // backend validation এর জন্য দরকার
        price: price, // এটাই paidAmount হিসেবে save হবে
      );

      if (response['success'] == true) {
        // Update local state
        final index = _appointments.indexWhere(
          (apt) => apt.id == appointmentId,
        );
        if (index != -1) {
          _appointments[index] = _appointments[index].copyWith(
            status: 'completed',
            // যদি model এ paidAmount field থাকে তাহলে এখানে add করতে পারো
            // paidAmount: price,
          );
        }
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to complete appointment';
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Complete Appointment Error: $e');
      _error = 'Error: $e';
      notifyListeners();
      return false;
    }
  }

  /// Send appointment confirmation notification
  Future<void> _sendAppointmentConfirmationNotification(
    AppointmentModel appointment,
  ) async {
    try {
      debugPrint('✅ Appointment confirmed for appointment ${appointment.id}');
    } catch (e) {
      debugPrint('❌ Error sending appointment confirmation notification: $e');
    }
  }

  void clearAppointments() {
    _appointments = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  AppointmentModel? getAppointmentById(String id) {
    try {
      return _appointments.firstWhere((apt) => apt.id == id);
    } catch (e) {
      return null;
    }
  }
}
