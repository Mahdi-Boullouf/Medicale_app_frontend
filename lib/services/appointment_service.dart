import '../utils/api_config.dart';
import 'api_service.dart';

class AppointmentService {
  /// Get current user's appointments (patient or doctor)
  Future<Map<String, dynamic>> getMyAppointments() async {
    try {
      final response = await ApiService.get(
        ApiConfig.appointments,
        requiresAuth: true,
      );
      return response;
    } catch (e) {
      print('❌ Get My Appointments Error: $e');
      return {
        'success': false,
        'message': 'Failed to fetch appointments: $e',
      };
    }
  }

  /// Get single appointment by ID
  Future<Map<String, dynamic>> getAppointmentById(String id) async {
    try {
      final response = await ApiService.get(
        '${ApiConfig.appointments}/$id',
        requiresAuth: true,
      );
      return response;
    } catch (e) {
      print('❌ Get Appointment Error: $e');
      return {
        'success': false,
        'message': 'Failed to fetch appointment: $e',
      };
    }
  }

  /// Create new appointment
  Future<Map<String, dynamic>> createAppointment({
    required String doctorId,
    required String appointmentDate, // "2026-01-05"
    required String appointmentTime, // "10:30"
    String? symptoms,
    String? appointmentType, // "physical" or "video"
  }) async {
    try {
      final body = {
        'doctorId': doctorId,
        'appointmentType': appointmentType ?? 'physical',
        'date': appointmentDate,
        'time': appointmentTime,
        if (symptoms != null && symptoms.isNotEmpty) 'symptoms': symptoms,
      };

      print('📤 Creating appointment with body: $body');

      final response = await ApiService.post(
        ApiConfig.appointments,
        body,
        requiresAuth: true,
      );

      return response;
    } catch (e) {
      print('❌ Create Appointment Error: $e');
      return {
        'success': false,
        'message': 'Failed to create appointment: $e',
      };
    }
  }

  /// Update appointment status (for doctor/admin only)
  /// Patient cannot use this - will get 403 Forbidden
  Future<Map<String, dynamic>> updateAppointmentStatus({
    required String appointmentId,
    required String status, // "accepted" | "cancelled" | "completed"
    String? patient,
    double? price,
  }) async {
    try {
      final body = {
        'status': status,
        if (patient != null) 'patient': patient,
        if (price != null) 'price': price,
      };

      print('📤 Updating appointment status to: $status');

      final response = await ApiService.patch(
        '${ApiConfig.appointments}/$appointmentId/status',
        body,
        requiresAuth: true,
      );

      return response;
    } catch (e) {
      print('❌ Update Status Error: $e');
      return {
        'success': false,
        'message': 'Failed to update status: $e',
      };
    }
  }

  /// Get upcoming appointments
  Future<Map<String, dynamic>> getUpcomingAppointments() async {
    try {
      final response = await ApiService.get(
        '${ApiConfig.appointments}?status=pending,accepted',
        requiresAuth: true,
      );
      return response;
    } catch (e) {
      print('❌ Get Upcoming Appointments Error: $e');
      return {
        'success': false,
        'message': 'Failed to fetch upcoming appointments: $e',
      };
    }
  }

  /// Get past appointments
  Future<Map<String, dynamic>> getPastAppointments() async {
    try {
      final response = await ApiService.get(
        '${ApiConfig.appointments}?status=completed,cancelled',
        requiresAuth: true,
      );
      return response;
    } catch (e) {
      print('❌ Get Past Appointments Error: $e');
      return {
        'success': false,
        'message': 'Failed to fetch past appointments: $e',
      };
    }
  }

  /// Complete appointment (for doctor)
  Future<Map<String, dynamic>> completeAppointment({
    required String appointmentId,
    required String patientName,
    required double price,
    String? prescription,
    String? notes,
  }) async {
    try {
      final body = {
        'status': 'completed',
        'patient': patientName,
        'price': price,
        if (prescription != null) 'prescription': prescription,
        if (notes != null) 'notes': notes,
      };

      final response = await ApiService.patch(
        '${ApiConfig.appointments}/$appointmentId/status',
        body,
        requiresAuth: true,
      );

      return response;
    } catch (e) {
      print('❌ Complete Appointment Error: $e');
      return {
        'success': false,
        'message': 'Failed to complete appointment: $e',
      };
    }
  }

  /// Accept appointment (for doctor)
  Future<Map<String, dynamic>> acceptAppointment(String appointmentId) async {
    try {
      print('📤 Accepting appointment: $appointmentId');

      final response = await ApiService.patch(
        '${ApiConfig.appointments}/$appointmentId/status',
        {'status': 'accepted'},
        requiresAuth: true,
      );

      return response;
    } catch (e) {
      print('❌ Accept Appointment Error: $e');
      return {
        'success': false,
        'message': 'Failed to accept appointment: $e',
      };
    }
  }

  /// Cancel appointment (for doctor/admin only)
  Future<Map<String, dynamic>> cancelAppointment(String appointmentId) async {
    try {
      print('📤 Cancelling appointment: $appointmentId');

      final response = await ApiService.patch(
        '${ApiConfig.appointments}/$appointmentId/status',
        {'status': 'cancelled'},
        requiresAuth: true,
      );

      return response;
    } catch (e) {
      print('❌ Cancel Appointment Error: $e');
      return {
        'success': false,
        'message': 'Failed to cancel appointment: $e',
      };
    }
  }
}