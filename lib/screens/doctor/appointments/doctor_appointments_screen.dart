import 'package:docmobi/screens/doctor/navigation/doctor_main_navigation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:docmobi/models/appointment_model.dart';
import 'package:docmobi/providers/appointment_provider.dart';
import 'package:docmobi/screens/doctor/appointments/session_holder_screen.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  String selectedTab = "Pending";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppointmentProvider>().fetchAppointments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const DoctorMainNavigation(),
              ),
              (route) => false,
            );
          },
        ),
        title: const Text(
          'Appointment Management',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Consumer<AppointmentProvider>(
        builder: (context, provider, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Manage your Video and physical\nConsultations",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),

             // Tab Buttons - FIX OVERFLOW
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 15),
  child: SingleChildScrollView(
    scrollDirection: Axis.horizontal, 
    child: Row(
      children: [
        _buildTabButton(
          "Pending",
          provider.pendingAppointments.length,
        ),
        const SizedBox(width: 5), 
        _buildTabButton(
          "Confirmed",
          provider.acceptedAppointments.length,
        ),
        const SizedBox(width: 5), 
        _buildTabButton(
          "Completed",
          provider.completedAppointments.length,
        ),
      ],
    ),
  ),
),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(),
              ),

              // Content
              Expanded(
                child: _buildContent(provider),
              ),
            ],
          );
        },
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
            Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.fetchAppointments(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    List<AppointmentModel> appointments;
    if (selectedTab == "Pending") {
      appointments = provider.pendingAppointments;
    } else if (selectedTab == "Confirmed") {
      appointments = provider.acceptedAppointments;
    } else {
      appointments = provider.completedAppointments;
    }

    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No $selectedTab appointments',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchAppointments(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          if (selectedTab == "Pending") {
            return _buildPendingCard(appointment, provider);
          } else if (selectedTab == "Confirmed") {
            return _buildConfirmedCard(appointment, provider);
          } else {
            return _buildCompletedCard(appointment);
          }
        },
      ),
    );
  }

  Widget _buildTabButton(String title, int count) {
    bool isSelected = selectedTab == title;
    return GestureDetector(
      onTap: () => setState(() => selectedTab = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1664CD) : const Color(0xFFE9F0FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '$title ($count)',
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF1B2C49),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // Pending Card
  Widget _buildPendingCard(
    AppointmentModel appointment,
    AppointmentProvider provider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: appointment.patientImage != null &&
                        appointment.patientImage!.isNotEmpty
                    ? NetworkImage(appointment.patientImage!)
                    : const AssetImage('assets/images/doctor_booking.png')
                        as ImageProvider,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            appointment.patientName ?? 'Patient',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _statusBadge(
                          "Pending",
                          const Color(0xFFFFF7E6),
                          const Color(0xFFFAAD14),
                        ),
                      ],
                    ),
                    
                    // ✅ FIXED: Changed isDependent to type == 'dependent' and displayText to bookingLabel
                    if (appointment.bookedFor != null && appointment.bookedFor!.type == 'dependent') ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF4CAF50), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.person_outline,
                              size: 13,
                              color: Color(0xFF2E7D32),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'For: ${appointment.bookedFor!.bookingLabel}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E7D32),
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
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE9F0FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _smallIconText(
                  Icons.calendar_today_outlined,
                  appointment.formattedDate,
                ),
                _smallIconText(Icons.access_time, appointment.appointmentTime),
                _smallIconText(
                  appointment.appointmentType == "video"
                      ? Icons.videocam_outlined
                      : Icons.location_on_outlined,
                  appointment.appointmentType ?? 'Physical',
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _actionBtn(
                  "Cancel",
                  const Color(0xFFD93D57),
                  Colors.white,
                  () => _handleCancel(appointment.id, provider),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _actionBtn(
                  "Accept",
                  const Color(0xFFC6F2D6),
                  const Color(0xFF27AE60),
                  () => _handleAccept(appointment.id, provider),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Confirmed Card
  Widget _buildConfirmedCard(
    AppointmentModel appointment,
    AppointmentProvider provider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: appointment.patientImage != null &&
                        appointment.patientImage!.isNotEmpty
                    ? NetworkImage(appointment.patientImage!)
                    : const AssetImage('assets/images/doctor_booking.png')
                        as ImageProvider,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.patientName ?? 'Patient',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    // ✅ FIXED: Changed isDependent to type == 'dependent' and displayText to bookingLabel
                    if (appointment.bookedFor != null && appointment.bookedFor!.type == 'dependent') ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: const Color(0xFF4CAF50), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.person_outline,
                              size: 12,
                              color: Color(0xFF2E7D32),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'For: ${appointment.bookedFor!.bookingLabel}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _smallIconText(
                          appointment.appointmentType == "video"
                              ? Icons.videocam_outlined
                              : Icons.location_on_outlined,
                          appointment.appointmentType ?? 'Physical',
                        ),
                        _smallIconText(
                          Icons.calendar_today_outlined,
                          appointment.formattedDate,
                        ),
                        _smallIconText(
                          Icons.access_time,
                          appointment.appointmentTime,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _actionBtn(
                  "Cancel",
                  const Color(0xFFD93D57),
                  Colors.white,
                  () => _handleCancel(appointment.id, provider),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _actionBtn(
              "Start Session",
              const Color(0xFF0B3267),
              Colors.white,
              () => _handleStartSession(appointment),
            ),
          ),
        ],
      ),
    );
  }

  // Completed Card
  Widget _buildCompletedCard(AppointmentModel appointment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: appointment.patientImage != null &&
                    appointment.patientImage!.isNotEmpty
                ? NetworkImage(appointment.patientImage!)
                : const AssetImage('assets/images/doctor_booking.png')
                    as ImageProvider,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        appointment.patientName ?? 'Patient',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _statusBadge(
                      "Completed",
                      const Color(0xFFF6FFED),
                      const Color(0xFF52C41A),
                    ),
                  ],
                ),
                
                // ✅ FIXED: Changed isDependent to type == 'dependent' and displayText to bookingLabel
                if (appointment.bookedFor != null && appointment.bookedFor!.type == 'dependent') ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF4CAF50), width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 11,
                          color: Color(0xFF2E7D32),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'For: ${appointment.bookedFor!.bookingLabel}',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 5),
                Wrap(
                  spacing: 10,
                  runSpacing: 5,
                  children: [
                    _smallIconText(
                      appointment.appointmentType == "video"
                          ? Icons.videocam_outlined
                          : Icons.location_on_outlined,
                      appointment.appointmentType ?? 'Physical',
                    ),
                    _smallIconText(
                      Icons.calendar_today_outlined,
                      appointment.formattedDate,
                    ),
                    _smallIconText(
                      Icons.access_time,
                      appointment.appointmentTime,
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

  Widget _statusBadge(String text, Color bg, Color txt) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: txt,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _smallIconText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 11, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _actionBtn(String label, Color bg, Color txt, VoidCallback? onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: txt,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  void _handleAccept(String appointmentId, AppointmentProvider provider) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final success = await provider.acceptAppointment(appointmentId);

    if (mounted) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Appointment accepted successfully'
                : 'Failed to accept appointment',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _handleCancel(String appointmentId, AppointmentProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );

              final success = await provider.cancelAppointment(appointmentId);

              if (mounted) {
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Appointment cancelled'
                          : 'Failed to cancel appointment',
                    ),
                    backgroundColor: success ? Colors.orange : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _handleStartSession(AppointmentModel appointment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionHolderScreen(
          appointment: appointment,
        ),
      ),
    ).then((result) {
      if (result == true) {
        context.read<AppointmentProvider>().fetchAppointments();
      }
    });
  }
}