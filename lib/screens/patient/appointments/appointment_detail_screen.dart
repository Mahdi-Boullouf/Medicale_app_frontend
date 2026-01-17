import 'package:docmobi/screens/patient/doctor/book_appointment_screen.dart';
import 'package:docmobi/screens/patient/messages/patient_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:docmobi/models/appointment_model.dart';
import 'package:docmobi/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:docmobi/providers/appointment_provider.dart';

class AppointmentDetailScreen extends StatelessWidget {
  final AppointmentModel appointment;

  const AppointmentDetailScreen({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5EEFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0B3267)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Appointment Details',
          style: TextStyle(
            color: Color(0xFF0B3267),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Doctor Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  _buildDoctorAvatar(),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.doctorName ?? 'Doctor',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0B3267),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          appointment.specialty ?? 'Specialist',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  appointment.status,
                                ).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                appointment.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(appointment.status),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _navigateToChat(context),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF6C5CE7,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: const Color(0xFF6C5CE7),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.message_outlined,
                                  size: 16,
                                  color: Color(0xFF6C5CE7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Appointment Info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    Icons.calendar_today,
                    'Date',
                    appointment.formattedDate,
                  ),
                  const Divider(height: 30),
                  _buildInfoRow(
                    Icons.access_time,
                    'Time',
                    appointment.appointmentTime,
                  ),
                  const Divider(height: 30),
                    _buildInfoRow(
                    appointment.appointmentType == 'video' 
                      ? Icons.videocam 
                      : Icons.medical_services,
                    'Type',
                    appointment.appointmentType == 'video' ? 'Video' : 'Physical',
                  ),
                  if (appointment.notes != null) ...[
                    const Divider(height: 30),
                    _buildInfoRow(Icons.note, 'Notes', appointment.notes!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ✅ NEW: Action Buttons - Direct Cancel & Reschedule
            if (appointment.status.toLowerCase() == 'pending' ||
                appointment.status.toLowerCase() == 'accepted') ...[
              _buildButton(
                context,
                'Reschedule',
                Colors.blue,
                () => _handleReschedule(context),
              ),
              const SizedBox(height: 15),
              _buildButton(
                context,
                'Cancel Appointment',
                Colors.red,
                () => _handleCancel(context),
                isOutlined: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorAvatar() {
    final imageUrl = appointment.doctorImage;

    if (imageUrl != null &&
        imageUrl.isNotEmpty &&
        (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'))) {
      return CircleAvatar(
        radius: 40,
        backgroundImage: NetworkImage(imageUrl),
        onBackgroundImageError: (exception, stackTrace) {},
      );
    }

    return const CircleAvatar(
      radius: 40,
      backgroundImage: AssetImage('assets/images/doctor_booking.png'),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B3267), Color(0xFF1664CD)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B3267),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildButton(
    BuildContext context,
    String text,
    Color color,
    VoidCallback onPressed, {
    bool isOutlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined ? Colors.white : color,
          foregroundColor: isOutlined ? color : Colors.white,
          side: isOutlined ? BorderSide(color: color, width: 2) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ✅ NEW: Direct Cancel Handler
  void _handleCancel(BuildContext context) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      final provider = Provider.of<AppointmentProvider>(context, listen: false);

      // Call cancel API
      final success = await provider.cancelAppointment(appointment.id);

      // Close loading
      Navigator.pop(context);

      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Appointment cancelled successfully',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Go back to appointments list
        Navigator.pop(context);
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    provider.error ?? 'Failed to cancel appointment',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading
      Navigator.pop(context);

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ✅ NEW: Reschedule Handler
  void _handleReschedule(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookAppointmentScreen(
          doctor: {
            '_id': appointment.doctorId,
            'id': appointment.doctorId,
            'fullName': appointment.doctorName,
            'name': appointment.doctorName,
            'specialty': appointment.specialty,
            'avatar': appointment.doctorImage,
          },
          isReschedule: true,
          existingAppointment: appointment,
        ),
      ),
    ).then((_) {
      // Go back after reschedule
      Navigator.pop(context);
    });
  }

  // Navigate to chat screen
  void _navigateToChat(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final doctorId = appointment.doctorId;

      if (doctorId.isEmpty) {
        Navigator.pop(context);

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Text('Error'),
              ],
            ),
            content: const Text('Doctor ID not found in appointment'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      final result = await ApiService.createOrGetChat(userId: doctorId);

      Navigator.pop(context);

      if (result['success'] == true) {
        final chatId = result['data']['_id']?.toString();

        if (chatId == null || chatId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to get chat ID'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              chatId: chatId,
              doctorName: appointment.doctorName ?? 'Doctor',
              doctorAvatar: appointment.doctorImage,
              doctorId: appointment.doctorId,
            ),
          ),
        );
      } else {
        final errorMessage = result['message'] ?? 'Failed to open chat';

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Text('Chat Error'),
              ],
            ),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Error'),
            ],
          ),
          content: Text('$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
