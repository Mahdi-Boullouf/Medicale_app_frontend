import 'package:docmobi/screens/doctor/navigation/doctor_main_navigation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:docmobi/models/appointment_model.dart';
import 'package:docmobi/providers/appointment_provider.dart';
import 'package:docmobi/providers/notification_provider.dart';
import 'package:docmobi/screens/doctor/appointments/session_holder_screen.dart';
import 'package:docmobi/utils/api_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

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
              Expanded(child: _buildContent(provider)),
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
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage:
                    appointment.patientImage != null &&
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
                    if (appointment.bookedFor != null &&
                        appointment.bookedFor!.type == 'dependent') ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF4CAF50),
                            width: 1,
                          ),
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

          // ✅ NEW: See Details Button
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showAppointmentDetails(appointment),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF1664CD).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: const Color(0xFF1664CD),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'See Details',
                    style: TextStyle(
                      color: Color(0xFF1664CD),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
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
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage:
                    appointment.patientImage != null &&
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
                    if (appointment.bookedFor != null &&
                        appointment.bookedFor!.type == 'dependent') ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: const Color(0xFF4CAF50),
                            width: 1,
                          ),
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

          // ✅ NEW: See Details Button
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showAppointmentDetails(appointment),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF1664CD).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: const Color(0xFF1664CD),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'See Details',
                    style: TextStyle(
                      color: Color(0xFF1664CD),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
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
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage:
                appointment.patientImage != null &&
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
                if (appointment.bookedFor != null &&
                    appointment.bookedFor!.type == 'dependent') ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFF4CAF50),
                        width: 0.8,
                      ),
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

  // ✅ NEW: Show Appointment Details Bottom Sheet
  void _showAppointmentDetails(AppointmentModel appointment) {
    // ✅ Debug logs
    print('🔍 Showing details for appointment: ${appointment.id}');
    print('📋 Appointment Type: ${appointment.appointmentType}');
    print('📄 Medical Documents: ${appointment.medicalDocuments}');
    print('💳 Payment Screenshot: ${appointment.paymentScreenshot}');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF1664CD)),
                    const SizedBox(width: 10),
                    const Text(
                      'Appointment Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Content
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Patient Info
                    _detailSection(
                      icon: Icons.person,
                      title: 'Patient Information',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointment.patientName ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (appointment.bookedFor != null &&
                              appointment.bookedFor!.type == 'dependent')
                            Text(
                              'Booked for: ${appointment.bookedFor!.bookingLabel}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Symptoms Section
                    _detailSection(
                      icon: Icons.medical_information_outlined,
                      title: 'Symptoms',
                      child: Text(
                        appointment.symptoms != null &&
                                appointment.symptoms!.isNotEmpty
                            ? appointment.symptoms!
                            : 'No symptoms provided',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              appointment.symptoms != null &&
                                  appointment.symptoms!.isNotEmpty
                              ? Colors.black87
                              : Colors.grey,
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Medical Documents Section
                    _detailSection(
                      icon: Icons.attachment,
                      title: 'Medical Documents',
                      child:
                          appointment.medicalDocuments != null &&
                              appointment.medicalDocuments!.isNotEmpty
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${appointment.medicalDocuments!.length} document(s) uploaded',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ...appointment.medicalDocuments!.map((doc) {
                                  // ✅ FIXED: Extract clean filename from URL
                                  String displayName = doc.split('/').last;
                                  if (displayName.contains('{public_id:')) {
                                    final match = RegExp(
                                      r'([^/]+)\.(jpg|jpeg|png|pdf|gif)',
                                      caseSensitive: false,
                                    ).firstMatch(doc);
                                    if (match != null) {
                                      displayName = match.group(0)!;
                                    }
                                  }

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0F7FF),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(
                                          0xFF1664CD,
                                        ).withOpacity(0.2),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.insert_drive_file,
                                          color: Color(0xFF1664CD),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            displayName,
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.visibility,
                                            color: Color(0xFF1664CD),
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            // ✅ FIXED: Pass the original doc URL
                                            _viewDocument(doc);
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            )
                          : const Text(
                              'No medical documents uploaded',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                    ),

                    const SizedBox(height: 16),

                    // Payment Screenshot (if video call)
                    if (appointment.appointmentType?.toLowerCase() == "video")
                      _detailSection(
                        icon: Icons.payment,
                        title: 'Payment Screenshot',
                        child:
                            appointment.paymentScreenshot != null &&
                                appointment.paymentScreenshot!.isNotEmpty
                            ? GestureDetector(
                                onTap: () => _viewDocument(
                                  appointment.paymentScreenshot!,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0F7FF),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF1664CD,
                                      ).withOpacity(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.receipt_long,
                                        color: Color(0xFF1664CD),
                                      ),
                                      const SizedBox(width: 10),
                                      const Expanded(
                                        child: Text(
                                          'View Payment Screenshot',
                                          style: TextStyle(
                                            color: Color(0xFF1664CD),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.visibility,
                                        color: Color(0xFF1664CD),
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : const Text(
                                'No payment screenshot uploaded',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF1664CD)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1664CD),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  void _viewDocument(String url) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      // ✅ FIXED: Clean and fix URL format
      String cleanUrl = url.trim();

      print('📥 Original URL: $cleanUrl'); // Debug

      // ✅ NEW: Extract Cloudinary URL if it exists
      if (cleanUrl.contains('https://res.cloudinary.com')) {
        final cloudinaryMatch = RegExp(
          r'https://res\.cloudinary\.com[^\s,}]+',
        ).firstMatch(cleanUrl);
        if (cloudinaryMatch != null) {
          cleanUrl = cloudinaryMatch.group(0)!;
          print('☁️ Found Cloudinary URL: $cleanUrl');
        }
      }
      // If URL starts with {public_id:, extract the path
      else if (cleanUrl.contains('{public_id:')) {
        // Extract path from {public_id: docmobi/appointments/medicalDocs/...}
        final match = RegExp(r'\{public_id:\s*([^}]+)\}').firstMatch(cleanUrl);
        if (match != null) {
          String publicId = match.group(1)!.trim();
          // Build proper server URL
          cleanUrl = '${ApiConfig.baseUrl}/uploads/$publicId';
          print('📁 Built server URL: $cleanUrl');
        }
      }
      // If URL doesn't start with http, add base URL
      else if (!cleanUrl.startsWith('http')) {
        if (cleanUrl.startsWith('/')) {
          cleanUrl = '${ApiConfig.baseUrl}$cleanUrl';
        } else {
          cleanUrl = '${ApiConfig.baseUrl}/$cleanUrl';
        }
        print('🔧 Added base URL: $cleanUrl');
      }

      // URL decode if needed
      cleanUrl = Uri.decodeFull(cleanUrl);

      print('🔗 Final URL: $cleanUrl'); // Debug log

      // Check if it's an image or PDF
      final isImage =
          cleanUrl.toLowerCase().endsWith('.jpg') ||
          cleanUrl.toLowerCase().endsWith('.jpeg') ||
          cleanUrl.toLowerCase().endsWith('.png') ||
          cleanUrl.toLowerCase().endsWith('.gif');

      Navigator.pop(context); // Close loading dialog

      if (isImage) {
        // Show image in full screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => _ImageViewerScreen(imageUrl: cleanUrl),
          ),
        );
      } else {
        // For PDF or other files, try to open with external app
        final uri = Uri.parse(cleanUrl);
        // You can use url_launcher package here
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        // For now, show URL in a dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Document URL'),
            content: SelectableText(cleanUrl),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading if still open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening document: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
        style: TextStyle(color: txt, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _smallIconText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
      ],
    );
  }

  Widget _actionBtn(String label, Color bg, Color txt, VoidCallback? onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        label,
        style: TextStyle(color: txt, fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  void _handleAccept(String appointmentId, AppointmentProvider provider) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final success = await provider.acceptAppointment(appointmentId);

      if (mounted) {
        Navigator.pop(context); // Dismiss loading

        if (success) {
          context.read<NotificationProvider>().addNotification(
            title: 'Appointment Accepted',
            message: 'You have accepted the appointment request.',
            type: 'appointment_accepted',
          );
        }

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
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Ensure loading is dismissed on error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handleCancel(String appointmentId, AppointmentProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text(
          'Are you sure you want to cancel this appointment?',
        ),
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

              try {
                final success = await provider.cancelAppointment(appointmentId);

                if (mounted) {
                  Navigator.pop(context); // Dismiss loading

                  if (success) {
                    context.read<NotificationProvider>().addNotification(
                      title: 'Appointment Cancelled',
                      message: 'You have cancelled the appointment.',
                      type: 'appointment_cancel',
                    );
                  }

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
              } catch (e) {
                if (mounted) {
                  Navigator.pop(
                    context,
                  ); // Ensure loading is dismissed on error
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
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
        builder: (context) => SessionHolderScreen(appointment: appointment),
      ),
    ).then((result) {
      if (result == true) {
        context.read<AppointmentProvider>().fetchAppointments();
      }
    });
  }
}

// ✅ Image Viewer Screen for viewing uploaded documents
class _ImageViewerScreen extends StatefulWidget {
  final String imageUrl;

  const _ImageViewerScreen({required this.imageUrl});

  @override
  State<_ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<_ImageViewerScreen> {
  final TransformationController _transformationController =
      TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Medical Document',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          // ✅ Reset Zoom Button
          IconButton(
            icon: const Icon(Icons.zoom_out_map, color: Colors.white),
            tooltip: 'Reset Zoom',
            onPressed: _resetZoom,
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              transformationController: _transformationController,
              panEnabled: true,
              minScale: 0.5,
              maxScale: 5.0, // ✅ Increased max zoom
              child: Image.network(
                widget.imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading image...',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 60,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load image',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            error.toString(),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // ✅ Zoom Instructions (shows temporarily)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pinch, color: Colors.grey[400], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Pinch to zoom • Drag to pan',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
