import 'package:docmobi/screens/patient/doctor/book_appointment_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:docmobi/models/appointment_model.dart';
import 'package:docmobi/providers/appointment_provider.dart';
import 'package:docmobi/screens/patient/appointments/appointment_detail_screen.dart';
import 'package:docmobi/screens/patient/navigation/patient_main_navigation.dart';

class PatientAppointmentsScreen extends StatefulWidget {
  const PatientAppointmentsScreen({super.key});

  @override
  State<PatientAppointmentsScreen> createState() =>
      _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen> {
  bool isUpcoming = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppointmentProvider>().fetchAppointments();
    });
  }

  void _handleBackPress() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const PatientMainNavigation(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F8FF),
        body: Consumer<AppointmentProvider>(
          builder: (context, appointmentProvider, child) {
            return Column(
              children: [
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 20, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
                          onPressed: _handleBackPress,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'My Appointment',
                          style: TextStyle(
                            color: Color(0xFF1A1A1A),
                            fontWeight: FontWeight.w600,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildTab(
                        title: "Up Coming (${appointmentProvider.upcomingAppointments.length})",
                        active: isUpcoming,
                        onTap: () => setState(() => isUpcoming = true),
                      ),
                      const SizedBox(width: 15),
                      _buildTab(
                        title: "Completed",
                        active: !isUpcoming,
                        onTap: () => setState(() => isUpcoming = false),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: _buildContent(appointmentProvider),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(AppointmentProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                provider.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<AppointmentProvider>().fetchAppointments();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D53C1),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    final appointments = isUpcoming
        ? provider.upcomingAppointments
        : provider.completedAppointments;

    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? 'No upcoming appointments' : 'No completed appointments',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchAppointments(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          return _buildAppointmentCard(appointments[index], provider);
        },
      ),
    );
  }

  Widget _buildTab({
    required String title,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF0D53C1) : const Color(0xFFE8EEF9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? Colors.white : Colors.black54,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(
    AppointmentModel appointment,
    AppointmentProvider provider,
  ) {
    bool isCompleted = appointment.status.toLowerCase() == 'completed';
    bool isCancelled = appointment.status.toLowerCase() == 'cancelled';
    bool isAccepted = appointment.status.toLowerCase() == 'accepted';

    Color statusBg = isCompleted
        ? const Color(0xFFD4F4DD)
        : (isCancelled
            ? const Color(0xFFFFE5E5)
            : (isAccepted
                ? const Color(0xFFD4F4DD)
                : const Color(0xFFFFF4E5)));
    
    Color statusText = isCompleted
        ? const Color(0xFF27AE60)
        : (isCancelled
            ? Colors.red
            : (isAccepted
                ? const Color(0xFF27AE60)
                : const Color(0xFFFFA726)));
    
    String statusLabel = isCompleted
        ? 'Completed'
        : (isCancelled
            ? 'Cancelled'
            : (isAccepted ? 'Accepted' : 'Pending'));

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AppointmentDetailScreen(appointment: appointment),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _buildDoctorImage(appointment.doctorImage),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              appointment.doctorName ?? 'Doctor',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: statusText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        appointment.specialty ?? 'Specialist',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      
                      if (appointment.bookedFor != null && appointment.bookedFor!.type == 'dependent') ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF2196F3), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.person_outline,
                                size: 14,
                                color: Color(0xFF1976D2),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Booked for: ${appointment.bookedFor!.bookingLabel}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1565C0),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EEF9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _infoRow(Icons.calendar_month_outlined, appointment.formattedDate),
                  _infoRow(Icons.access_time, appointment.appointmentTime),
                  _infoRow(Icons.apartment, 'Physical'),
                ],
              ),
            ),

            // ✅ NEW: Direct Cancel & Reschedule buttons
            if (!isCompleted && !isCancelled) ...[
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _handleReschedule(context, appointment),
                      child: _buttonDesign(
                        'Reschedule',
                        const Color(0xFFF2F4F7),
                        Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _handleCancel(context, appointment, provider),
                      child: _buttonDesign(
                        'Cancel',
                        const Color(0xFFD93B41),
                        Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ✅ NEW: Direct Cancel Handler
  void _handleCancel(
    BuildContext context,
    AppointmentModel appointment,
    AppointmentProvider provider,
  ) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    try {
      // Call cancel API
      final success = await provider.cancelAppointment(appointment.id);

      // Close loading
      if (mounted) Navigator.pop(context);

      if (success) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Appointment cancelled successfully',
                      style: const TextStyle(fontWeight: FontWeight.w500),
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

          // Refresh appointments
          provider.fetchAppointments();
        }
      } else {
        // Show error message
        if (mounted) {
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
      }
    } catch (e) {
      // Close loading
      if (mounted) Navigator.pop(context);

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ NEW: Reschedule Handler
  void _handleReschedule(BuildContext context, AppointmentModel appointment) {
    // Navigate to book appointment screen with reschedule mode
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
      // Refresh appointments when coming back
      context.read<AppointmentProvider>().fetchAppointments();
    });
  }

  Widget _buildDoctorImage(String? imageUrl) {
    if (imageUrl != null &&
        imageUrl.isNotEmpty &&
        (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'))) {
      return Image.network(
        imageUrl,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 60,
            height: 60,
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        },
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Image.asset(
      'assets/images/doctor_booking.png',
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 60,
          height: 60,
          color: Colors.grey[200],
          child: const Icon(Icons.person, size: 30, color: Colors.grey),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.black87),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buttonDesign(String title, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        title,
        style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }
}