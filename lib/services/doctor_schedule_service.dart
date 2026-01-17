import 'api_service.dart';

class DoctorScheduleService {
  /// Save doctor's weekly schedule with video call availability
  Future<Map<String, dynamic>> saveWeeklySchedule({
    required List<Map<String, dynamic>> weeklySchedule,
    required Map<String, dynamic> fees,
    required bool isVideoCallAvailable, // ✅ Added parameter
  }) async {
    try {
      final body = {
        'weeklySchedule': weeklySchedule,
        'fees': fees,
        'isVideoCallAvailable': isVideoCallAvailable, // ✅ Send to backend
      };

      print('📤 Sending to backend:');
      print('   - weeklySchedule: ${weeklySchedule.length} days');
      print('   - fees: $fees');
      print('   - isVideoCallAvailable: $isVideoCallAvailable');

      final response = await ApiService.put(
        '/api/v1/user/profile',
        body,
        requiresAuth: true,
      );

      return response;
    } catch (e) {
      print('❌ Save Schedule Error: $e');
      return {
        'success': false,
        'message': 'Failed to save schedule: $e',
      };
    }
  }

  /// Get doctor's current schedule
  Future<Map<String, dynamic>> getMySchedule() async {
    try {
      final response = await ApiService.get(
        '/api/v1/user/profile',
        requiresAuth: true,
      );

      return response;
    } catch (e) {
      print('❌ Get Schedule Error: $e');
      return {
        'success': false,
        'message': 'Failed to fetch schedule: $e',
      };
    }
  }
}