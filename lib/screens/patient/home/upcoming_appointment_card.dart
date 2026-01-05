import 'package:docmobi/models/appointment_model.dart';
import 'package:docmobi/screens/patient/appointments/appointment_detail_screen.dart';
import 'package:flutter/material.dart';

class UpcomingAppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;

  const UpcomingAppointmentCard({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AppointmentDetailScreen(appointment: appointment)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Row(
          children: [
            // ✅ Safe Image Loading
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildDoctorImage(),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.doctorName ?? 'Doctor',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    appointment.specialty ?? '',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${appointment.formattedDate} at ${appointment.appointmentTime}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ✅ Safe image builder
  Widget _buildDoctorImage() {
    final imageUrl = appointment.doctorImage;
    
    // Check if URL is valid
    if (imageUrl != null && 
        imageUrl.isNotEmpty && 
        (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'))) {
      return Image.network(
        imageUrl,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingPlaceholder();
        },
      );
    }
    
    // Fallback to placeholder
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Image.asset(
      'assets/images/doctor_booking.png',
      width: 80,
      height: 80,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildIconPlaceholder();
      },
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildIconPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[200],
      child: const Icon(Icons.person, size: 40, color: Colors.grey),
    );
  }
}