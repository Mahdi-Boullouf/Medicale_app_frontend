// screens/patient/home/see_all_doctors_screen.dart
// ✅ COMPLETE CODE with Real-time Availability & Video Badge & Visiting Hours

import 'package:flutter/material.dart';
import 'package:docmobi/services/api_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' show cos, sqrt;
import 'package:docmobi/models/doctor_model.dart';
import 'package:docmobi/screens/patient/doctor/doctor_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:docmobi/providers/user_provider.dart';
import 'package:docmobi/screens/patient/messages/patient_chat_screen.dart';
import 'package:docmobi/l10n/app_localizations.dart';

class SeeAllDoctorsScreen extends StatefulWidget {
  final LatLng? userPosition;
  const SeeAllDoctorsScreen({super.key, this.userPosition});

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

      debugPrint(' Doctors API Response: $result');

      if (result['success'] == true) {
        final doctorsData = result['data'] as List? ?? [];

        final currentUser = Provider.of<UserProvider>(context, listen: false).user;
        List<Doctor> loadedDoctors = doctorsData.map((json) {
          return Doctor.fromJson(json);
        }).where((doctor) => doctor.id != currentUser?.id).toList();

        // If user position is provided, calculate distance and sort
        if (widget.userPosition != null) {
          loadedDoctors.sort((a, b) {
            if (a.latitude == null || a.longitude == null) return 1;
            if (b.latitude == null || b.longitude == null) return -1;

            final distA = _calculateDistanceInKm(
              widget.userPosition!,
              LatLng(a.latitude!, a.longitude!),
            );
            final distB = _calculateDistanceInKm(
              widget.userPosition!,
              LatLng(b.latitude!, b.longitude!),
            );
            return distA.compareTo(distB);
          });
        }

        setState(() {
          _doctors = loadedDoctors;
          _isLoading = false;
        });

        debugPrint(' Loaded ${_doctors.length} doctors');
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

  double _calculateDistanceInKm(LatLng p1, LatLng p2) {
    const double p = 0.017453292519943295; // Math.PI / 180
    final double a =
        0.5 -
        cos((p2.latitude - p1.latitude) * p) / 2 +
        cos(p1.latitude * p) *
            cos(p2.latitude * p) *
            (1 - cos((p2.longitude - p1.longitude) * p)) /
            2;
    return 12742 * sqrt(a); // 2 * R; R = 6371 km
  }

  String _getDistanceText(Doctor doctor) {
    if (widget.userPosition == null ||
        doctor.latitude == null ||
        doctor.longitude == null) {
      return doctor.distance;
    }

    final distance = _calculateDistanceInKm(
      widget.userPosition!,
      LatLng(doctor.latitude!, doctor.longitude!),
    );

    if (distance < 1) {
      return '${(distance * 1000).toInt()} m';
    }
    return '${distance.toStringAsFixed(1)} km';
  }

  ///  Check if doctor has schedule (is available)
  bool _isDoctorAvailable(Doctor doctor) {
    if (doctor.weeklySchedule == null || doctor.weeklySchedule!.isEmpty) {
      debugPrint('❌ ${doctor.fullName}: No weeklySchedule');
      return false;
    }

    // Check if at least one day is active with slots
    for (var schedule in doctor.weeklySchedule!) {
      debugPrint(
        '📅 ${doctor.fullName} - ${schedule.day}: active=${schedule.isActive}, slots=${schedule.slots.length}',
      );

      if (schedule.isActive && schedule.slots.isNotEmpty) {
        debugPrint(' ${doctor.fullName}: Available on ${schedule.day}');
        return true;
      }
    }

    debugPrint('❌ ${doctor.fullName}: No active days with slots');
    return false;
  }

  ///  Get visiting hours from doctor's schedule
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
    final bool hasVideoCall = doctor.isVideoCallAvailable; 
    final String visitingHours = _getVisitingHours(doctor);

    // Debug
    debugPrint(' See All: ${doctor.fullName}');
    debugPrint('   - hasVideoCall: $hasVideoCall');

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
              color: Colors.black.withValues(alpha: 0.05),
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
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
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
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
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

                      //  Video Consultation Badge
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
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[600],
                          ),
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
                            doctor.rating.toStringAsFixed(1),
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
                            _getDistanceText(doctor),
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
                if (Provider.of<UserProvider>(context, listen: false).user?.role !=
                    'doctor')
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isAvailable
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      DoctorDetailsScreen(doctor: doctor),
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
                  )
                else if (doctor.id != Provider.of<UserProvider>(context, listen: false).user?.id)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _openChatWithDoctor(context, doctor),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C5CE7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Message',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Your Profile',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
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

  void _openChatWithDoctor(BuildContext context, Doctor doctor) async {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) =>
          const Center(child: CircularProgressIndicator()),
    );

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final doctorId = doctor.id;

      if (doctorId.isEmpty) {
        if (mounted) navigator.pop();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(l10n.doctorIdNotFound),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final result = await ApiService.createOrGetChat(userId: doctorId);

      if (mounted) navigator.pop();

      if (result['success'] == true) {
        final chatData = result['data'];
        final chatId = chatData['_id']?.toString();

        if (chatId == null || chatId.isEmpty) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(l10n.failedCreateChat),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final participants = chatData['participants'] as List?;
        String? doctorAvatar;

        if (participants != null) {
          final doctorParticipant = participants.firstWhere(
            (p) => p['_id'] == doctorId,
            orElse: () => null,
          );

          if (doctorParticipant != null) {
            doctorAvatar = doctorParticipant['avatar']?['url'];
          }
        }

        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailScreen(
                chatId: chatId,
                doctorName: doctor.fullName,
                doctorAvatar:
                    doctorAvatar ??
                    (doctor.image.startsWith('http') ? doctor.image : null),
                doctorId: doctorId,
              ),
            ),
          );
        }
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ??
                  l10n.failedOpenChat ??
                  'Failed to open chat',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) navigator.pop();
      debugPrint(' Error opening chat: $e');
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
