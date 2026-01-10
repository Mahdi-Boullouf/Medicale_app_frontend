import 'api_service.dart';

class DoctorScheduleService {
  /// Save doctor's weekly schedule
  Future<Map<String, dynamic>> saveWeeklySchedule({
    required List<Map<String, dynamic>> weeklySchedule,
    required Map<String, dynamic> fees,
  }) async {
    try {
      // ✅ Data is already formatted correctly from screen
      // Screen sends: { day: 'monday', isActive: true, slots: [{ start: '10:00', end: '10:30' }] }
      
      final body = {
        'weeklySchedule': weeklySchedule,  // ✅ Use as-is, no transformation needed
        'fees': fees,
      };

      // ✅ Correct endpoint: PUT /api/v1/user/profile
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
      // ✅ Correct endpoint: GET /api/v1/user/profile
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