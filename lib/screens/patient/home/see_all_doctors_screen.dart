// screens/patient/home/see_all_doctors_screen.dart
// ✅ COMPLETE CODE with Real-time Availability & Video Badge & Visiting Hours

import 'package:flutter/material.dart';
import 'package:docmobi/services/api_service.dart';
import 'package:docmobi/models/doctor_model.dart';
import 'package:docmobi/screens/patient/doctor/doctor_detail_screen.dart';

class SeeAllDoctorsScreen extends StatefulWidget {
  const SeeAllDoctorsScreen({super.key});

  @override
  State<SeeAllDoctorsScreen> createState() => _SeeAllDoctorsScreenState();
}

class _SeeAllDoctorsScreenState extends State<SeeAllDoctorsScreen> {
  List<Doctor> _doctors = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.get(
        '/api/v1/user/role/doctor',
        requiresAuth: true,
      );

      debugPrint('📥 Doctors API Response: $result');

      if (result['success'] == true) {
        final doctorsData = result['data'] as List? ?? [];

        setState(() {
          _doctors = doctorsData.map((json) {
            // Debug log
            print('🔍 Doctor: ${json['fullName']}');
            print('   - isVideoCallAvailable: ${json['isVideoCallAvailable']}');
            print('   - weeklySchedule: ${json['weeklySchedule']}');
            
            return Doctor.fromJson(json);
          }).toList();
          _isLoading = false;
        });

        debugPrint('✅ Loaded ${_doctors.length} doctors');
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load doctors';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading doctors: $e');
      setState(() {
        _errorMessage = 'Failed to load doctors: $e';
        _isLoading = false;
      });
    }
  }

  /// ✅ Check if doctor has schedule (is available)
  bool _isDoctorAvailable(Doctor doctor) {
    if (doctor.weeklySchedule == null || doctor.weeklySchedule!.isEmpty) {
      print('❌ ${doctor.fullName}: No weeklySchedule');
      return false;
    }

    // Check if at least one day is active with slots
    for (var schedule in doctor.weeklySchedule!) {
      print('📅 ${doctor.fullName} - ${schedule.day}: active=${schedule.isActive}, slots=${schedule.slots.length}');
      
      if (schedule.isActive && schedule.slots.isNotEmpty) {
        print('✅ ${doctor.fullName}: Available on ${schedule.day}');
        return true;
      }
    }

    print('❌ ${doctor.fullName}: No active days with slots');
    return false;
  }

  /// ✅ Get visiting hours from doctor's schedule
  String _getVisitingHours(Doctor doctor) {
    if (doctor.weeklySchedule == null || doctor.weeklySchedule!.isEmpty) {
      return 'No schedule set';
    }

    List<String> activeDays = [];
    for (var schedule in doctor.weeklySchedule!) {
      if (schedule.isActive && schedule.slots.isNotEmpty) {
        // Get first 3 characters of day name
        String dayShort = schedule.day.length >= 3 
          ? schedule.day.substring(0, 3) 
          : schedule.day;
        activeDays.add(dayShort);
      }
    }

    if (activeDays.isEmpty) {
      return 'No schedule set';
    }

    // Show first and last day
    if (activeDays.length == 1) {
      return activeDays[0];
    } else if (activeDays.length <= 3) {
      return activeDays.join(', ');
    } else {
      return '${activeDays.first}-${activeDays.last}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "All Doctor's",
          style: TextStyle(
            color: Color(0xFF1B2C49),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadDoctors,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1664CD),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_doctors.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medical_services_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No doctors available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDoctors,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _doctors.length,
        itemBuilder: (context, index) {
          final doctor = _doctors[index];
          return _buildDoctorCard(doctor);
        },
      ),
    );
  }

  Widget _buildDoctorCard(Doctor doctor) {
  final bool isAvailable = _isDoctorAvailable(doctor);
  final bool hasVideoCall = doctor.isVideoCallAvailable; // ✅ Read from model
  final String visitingHours = _getVisitingHours(doctor);

  // Debug
  print('📋 See All: ${doctor.fullName}');
  print('   - hasVideoCall: $hasVideoCall');

  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DoctorDetailsScreen(doctor: doctor),
        ),
      );
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: doctor.image.startsWith('http')
                    ? Image.network(
                        doctor.image,
                        height: 70,
                        width: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 70,
                          width: 70,
                          color: Colors.grey[200],
                          child: const Icon(Icons.person, size: 40),
                        ),
                      )
                    : Image.asset(
                        doctor.image,
                        height: 70,
                        width: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 70,
                          width: 70,
                          color: Colors.grey[200],
                          child: const Icon(Icons.person, size: 40),
                        ),
                      ),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            doctor.fullName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B2C49),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isAvailable
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isAvailable ? 'Available' : 'No Schedule',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isAvailable
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    Text(
                      doctor.specialty,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // ✅ Video Consultation Badge
                    if (hasVideoCall)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF2196F3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.videocam,
                              size: 14,
                              color: Color(0xFF1976D2),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Video Consultation',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF1565C0),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    if (hasVideoCall) const SizedBox(height: 6),

                    // Visiting Hours
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            visitingHours,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Rating & Distance
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          doctor.rating.toString(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          doctor.distance,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isAvailable
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DoctorDetailsScreen(doctor: doctor),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAvailable
                        ? const Color(0xFF0D47A1)
                        : Colors.grey[300],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isAvailable ? 'Book Now' : 'Not Available',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isAvailable ? Colors.white : Colors.grey[600],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFE3F2FD),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.info_outline,
                    color: Color(0xFF0D47A1),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DoctorDetailsScreen(doctor: doctor),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
}