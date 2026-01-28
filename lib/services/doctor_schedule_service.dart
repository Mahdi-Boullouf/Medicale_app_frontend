import 'package:flutter/material.dart';

import 'api_service.dart';

class DoctorScheduleService {
  /// Save doctor's weekly schedule with video call availability
  Future<Map<String, dynamic>> saveWeeklySchedule({
    required List<Map<String, dynamic>> weeklySchedule,
    required Map<String, dynamic> fees,
    required bool isVideoCallAvailable,
    bool isAvailable = true, // ✅ New optional parameter
  }) async {
    try {
      // ✅ Data is already formatted correctly from screen
      // Screen sends: { day: 'monday', isActive: true, slots: [{ start: '10:00', end: '10:30' }] }

      final body = {
        'weeklySchedule': weeklySchedule,
        'fees': fees,
        'isVideoCallAvailable': isVideoCallAvailable, // ✅ Primary key
        'isVideoAvailable': isVideoCallAvailable, // ✅ Redundant key 1
        'isAvailable': isAvailable, // ✅ Redundant key 2
      };

      print('📤 Sending to backend:');
      print('   - weeklySchedule: ${weeklySchedule.length} days');
      print('   - fees: $fees');
      print('   - isVideoCallAvailable: $isVideoCallAvailable');
      print('   - isAvailable: $isAvailable');

      final response = await ApiService.put(
        '/api/v1/user/profile',
        body,
        requiresAuth: true,
      );

      return response;
    } catch (e) {
      debugPrint('❌ Save Schedule Error: $e');
      return {'success': false, 'message': 'Failed to save schedule: $e'};
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
      debugPrint('❌ Get Schedule Error: $e');
      return {'success': false, 'message': 'Failed to fetch schedule: $e'};
    }
  }
}
