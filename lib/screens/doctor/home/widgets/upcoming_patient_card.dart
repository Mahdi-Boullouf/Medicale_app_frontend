import 'package:docmobi/widgets/custom_image.dart';
import 'package:docmobi/models/appointment_model.dart';
import 'package:flutter/material.dart';

class UpcomingPatientCard extends StatelessWidget {
  final AppointmentModel appointment;

  const UpcomingPatientCard({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          // Patient Image / Placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildPatientImage(),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Upcoming appointment with",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getDisplayName(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Color(0xFF1B2C49),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      appointment.formattedDate,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      appointment.appointmentTime,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getDisplayName() {
    if (appointment.bookedFor != null &&
        appointment.bookedFor!.type == 'dependent') {
      return appointment.bookedFor!.bookingLabel;
    }
    return appointment.patientName ?? 'Patient';
  }

  Widget _buildPatientImage() {
    return CustomImage(
      imageUrl: appointment.patientImage,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      placeholderAsset: 'assets/images/profile.png',
    );
  }
}
