import 'api_service.dart';

class DependentService {
  /// Get all dependents for current user
  Future<Map<String, dynamic>> getMyDependents() async {
    try {
      print('📤 Fetching dependents...');
      
      // ✅ FIXED: Correct endpoint
      final response = await ApiService.get(
        '/api/v1/user/me/dependents', // ← Fixed from /api/v1/user/profile/me/dependents
        requiresAuth: true,
      );

      if (response['success'] == true) {
        print('✅ Dependents fetched: ${(response['data'] as List?)?.length ?? 0}');
      } else {
        print('❌ Failed to fetch dependents: ${response['message']}');
      }

      return response;
    } catch (e) {
      print('❌ Get Dependents Error: $e');
      return {
        'success': false,
        'message': 'Failed to fetch dependents: $e',
        'data': [],
      };
    }
  }

  /// Create new dependent
  Future<Map<String, dynamic>> createDependent({
    required String fullName,
    required String relationship,
    required DateTime dob,
    required String gender,
    String? phone,
    String? notes,
  }) async {
    try {
      print('📤 Creating dependent...');

      final body = {
        'fullName': fullName,
        'relationship': relationship,
        'dob': dob.toIso8601String().split('T')[0], // "2020-05-15"
        'gender': gender,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      print('📦 Body: $body');

      final response = await ApiService.post(
        '/api/v1/user/me/dependents',
        body,
        requiresAuth: true,
      );

      if (response['success'] == true) {
        print('✅ Dependent created successfully');
      } else {
        print('❌ Failed to create dependent: ${response['message']}');
      }

      return response;
    } catch (e) {
      print('❌ Create Dependent Error: $e');
      return {
        'success': false,
        'message': 'Failed to create dependent: $e',
      };
    }
  }

  /// Update dependent
  Future<Map<String, dynamic>> updateDependent({
    required String dependentId,
    String? fullName,
    String? relationship,
    DateTime? dob,
    String? gender,
    String? phone,
    String? notes,
    bool? isActive,
  }) async {
    try {
      print('📤 Updating dependent: $dependentId');

      final body = <String, dynamic>{};
      if (fullName != null) body['fullName'] = fullName;
      if (relationship != null) body['relationship'] = relationship;
      if (dob != null) body['dob'] = dob.toIso8601String().split('T')[0];
      if (gender != null) body['gender'] = gender;
      if (phone != null) body['phone'] = phone;
      if (notes != null) body['notes'] = notes;
      if (isActive != null) body['isActive'] = isActive;

      print('📦 Body: $body');

      final response = await ApiService.patch(
        '/api/v1/user/me/dependents/$dependentId',
        body,
        requiresAuth: true,
      );

      if (response['success'] == true) {
        print('✅ Dependent updated successfully');
      } else {
        print('❌ Failed to update dependent: ${response['message']}');
      }

      return response;
    } catch (e) {
      print('❌ Update Dependent Error: $e');
      return {
        'success': false,
        'message': 'Failed to update dependent: $e',
      };
    }
  }

  /// Delete dependent
  Future<Map<String, dynamic>> deleteDependent(String dependentId) async {
    try {
      print('📤 Deleting dependent: $dependentId');

      final response = await ApiService.delete(
        '/api/v1/user/me/dependents/$dependentId',
        requiresAuth: true,
      );

      if (response['success'] == true) {
        print('✅ Dependent deleted successfully');
      } else {
        print('❌ Failed to delete dependent: ${response['message']}');
      }

      return response;
    } catch (e) {
      print('❌ Delete Dependent Error: $e');
      return {
        'success': false,
        'message': 'Failed to delete dependent: $e',
      };
    }
  }
}