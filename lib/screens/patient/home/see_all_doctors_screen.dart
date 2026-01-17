import 'package:docmobi/screens/doctor/messages/doctor_messages_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:docmobi/services/api_service.dart';

class SeeAllDoctorsScreen extends StatefulWidget {
  const SeeAllDoctorsScreen({super.key});

  @override
  State<SeeAllDoctorsScreen> createState() => _SeeAllDoctorsScreenState();
}

class _SeeAllDoctorsScreenState extends State<SeeAllDoctorsScreen> {
  List<Map<String, dynamic>> _doctors = [];
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
      // ✅ Use correct endpoint
      final result = await ApiService.get(
        '/api/v1/user/role/doctor',
        requiresAuth: true,
      );

      debugPrint('📥 Doctors API Response: $result');

      if (result['success'] == true) {
        final doctorsData = result['data'] as List? ?? [];

        setState(() {
          _doctors = List<Map<String, dynamic>>.from(doctorsData);
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

  void _showDoctorInfo(Map<String, dynamic> doctor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DoctorInfoBottomSheet(doctor: doctor),
    );
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
          'All Doctors',
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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _doctors.length,
      itemBuilder: (context, index) {
        final doctor = _doctors[index];
        return _buildDoctorCard(doctor);
      },
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    final String doctorName = doctor['fullName'] ?? 'Doctor';
    final String? doctorImage = doctor['avatar']?['url'];
    final String specialty = doctor['specialty'] ?? 'General Physician';
    final int experienceYears = doctor['experienceYears'] ?? 0;
    final String doctorId = doctor['_id'] ?? '';

    return InkWell(
      onTap: () => _showDoctorInfo(doctor),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: doctorImage != null
                  ? NetworkImage(doctorImage)
                  : const AssetImage('assets/images/doctor.png')
                        as ImageProvider,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctorName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B2C49),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    specialty,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  if (experienceYears > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '$experienceYears years experience',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1664CD),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.message_outlined,
                color: Color(0xFF1664CD),
              ),
              onPressed: () {
                // Navigate to message
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        DoctorMessagesListScreen(initialDoctorId: doctorId),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorInfoBottomSheet extends StatelessWidget {
  final Map<String, dynamic> doctor;

  const _DoctorInfoBottomSheet({required this.doctor});

  @override
  Widget build(BuildContext context) {
    final String doctorName = doctor['fullName'] ?? 'Doctor';
    final String? doctorImage = doctor['avatar']?['url'];
    final String doctorId = doctor['_id'] ?? '';
    final String specialty = doctor['specialty'] ?? 'General Physician';
    final String bio = doctor['bio'] ?? 'No bio available';
    final int experienceYears = doctor['experienceYears'] ?? 0;
    final List degrees = doctor['degrees'] ?? [];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          CircleAvatar(
            radius: 50,
            backgroundImage: doctorImage != null
                ? NetworkImage(doctorImage)
                : const AssetImage('assets/images/doctor.png') as ImageProvider,
          ),
          const SizedBox(height: 16),

          Text(
            doctorName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B2C49),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          Text(
            specialty,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),

          if (experienceYears > 0)
            Text(
              '$experienceYears years of experience',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1664CD),
                fontWeight: FontWeight.w500,
              ),
            ),
          const SizedBox(height: 16),

          if (bio != 'No bio available')
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F8FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                bio,
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 16),

          if (degrees.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: degrees.map<Widget>((degree) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F1FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    degree['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1664CD),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        DoctorMessagesListScreen(initialDoctorId: doctorId),
                  ),
                );
              },
              icon: const Icon(Icons.message_outlined),
              label: const Text(
                'Message',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1664CD),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
