import 'package:docmobi/screens/doctor/navigation/doctor_main_navigation.dart';
import 'package:docmobi/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:docmobi/models/appointment_model.dart';
import 'package:docmobi/providers/appointment_provider.dart';
import 'package:docmobi/screens/doctor/appointments/session_holder_screen.dart';
import 'package:docmobi/services/pdf_service.dart';
import 'package:docmobi/providers/user_provider.dart';
import 'package:docmobi/utils/api_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:docmobi/widgets/full_screen_image_viewer.dart';

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
    final l10n = AppLocalizations.of(context)!;
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
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.indigo),
            tooltip: 'Export Report',
            onPressed: () async {
              final l10n = AppLocalizations.of(context)!;
              final provider = context.read<AppointmentProvider>();
              final allAppointments = [
                ...provider.pendingAppointments,
                ...provider.acceptedAppointments,
                ...provider.completedAppointments,
              ];

              if (allAppointments.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.noAppointmentsToExport)),
                );
                return;
              }
              // Capture context values before async operations
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final userProvider = context.read<UserProvider>();

           
              final pickedRange = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                helpText: l10n.selectAppointmentDateRange,
                confirmText: l10n.exportPdf,
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: Colors.indigo,
                        onPrimary: Colors.white,
                        onSurface: Colors.black,
                      ),
                    ),
                    child: child!,
                  );
                },
              );

              if (pickedRange == null) return; // User cancelled

              //  Filter Appointments
              final filteredAppointments = allAppointments.where((apt) {
                final aptDate = DateTime(
                  apt.appointmentDate.year,
                  apt.appointmentDate.month,
                  apt.appointmentDate.day,
                );
                return aptDate.isAtSameMomentAs(pickedRange.start) ||
                    aptDate.isAtSameMomentAs(pickedRange.end) ||
                    (aptDate.isAfter(pickedRange.start) &&
                        aptDate.isBefore(pickedRange.end));
              }).toList();

              if (filteredAppointments.isEmpty) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(l10n.noAppointmentsInRange),
                    ),
                  );
                }
                return;
              }

              String doctorName = 'Doctor';
              try {
                doctorName = userProvider.user?.fullName ?? 'Doctor';
              } catch (e) {
                debugPrint(' Error getting doctor name for export: $e');
              }

              await PdfService.generateAppointmentListPdf(
                filteredAppointments,
                doctorName,
                dateRange: pickedRange,
              );
            },
          ),
        ],
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

         
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTabButton(
                        l10n.pending,
                        provider.pendingAppointments.length,
                      ),
                      const SizedBox(width: 5),
                      _buildTabButton(
                        l10n.confirmed,
                        provider.acceptedAppointments.length,
                      ),
                      const SizedBox(width: 5),
                      _buildTabButton(
                        l10n.completed,
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
    final l10n = AppLocalizations.of(context)!;
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
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    List<AppointmentModel> appointments;
    if (selectedTab == l10n.pending) {
      appointments = provider.pendingAppointments;
    } else if (selectedTab == l10n.confirmed) {
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
              l10n.noAppointments(selectedTab),
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
          final l10n = AppLocalizations.of(context)!;
          if (selectedTab == l10n.pending) {
            return _buildPendingCard(appointment, provider);
          } else if (selectedTab == l10n.confirmed) {
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

  Widget _buildPendingCard(
    AppointmentModel appointment,
    AppointmentProvider provider,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
          ),
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
                          l10n.pending,
                          const Color(0xFFFFF7E6),
                          const Color(0xFFFAAD14),
                        ),
                      ],
                    ),

                    //  Changed isDependent to type == 'dependent' and displayText to bookingLabel
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
                              l10n.forDependent(
                                appointment.bookedFor!.bookingLabel,
                              ),
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
                  appointment.appointmentType?.toLowerCase() == "video"
                      ? Icons.videocam_outlined
                      : Icons.location_on_outlined,
                  appointment.appointmentType?.toLowerCase() == "video"
                      ? l10n.videoCall
                      : l10n.physical,
                ),
              ],
            ),
          ),

          //  See Details Button
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showAppointmentDetails(appointment),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF1664CD).withValues(alpha: 0.3),
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
                  Text(
                    AppLocalizations.of(context)!.seeDetails,
                    style: const TextStyle(
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
          SizedBox(
            width: double.infinity,
            child: _actionBtn(
              l10n.reschedule,
              const Color(0xFFEAF2FF),
              const Color(0xFF1664CD),
              () => _handleReschedule(appointment, provider),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _actionBtn(
                  l10n.cancel,
                  const Color(0xFFD93D57),
                  Colors.white,
                  () => _handleCancel(appointment.id, provider),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _actionBtn(
                  l10n.accept,
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

  Widget _buildConfirmedCard(
    AppointmentModel appointment,
    AppointmentProvider provider,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
          ),
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
                          appointment.appointmentType?.toLowerCase() == "video"
                              ? Icons.videocam_outlined
                              : Icons.location_on_outlined,
                          appointment.appointmentType?.toLowerCase() == "video"
                              ? l10n.videoCall
                              : l10n.physical,
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

          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showAppointmentDetails(appointment),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF1664CD).withValues(alpha: 0.3),
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
                  Text(
                    AppLocalizations.of(context)!.seeDetails,
                    style: const TextStyle(
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
                  l10n.reschedule,
                  const Color(0xFFEAF2FF),
                  const Color(0xFF1664CD),
                  () => _handleReschedule(appointment, provider),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _actionBtn(
                  l10n.cancel,
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
              l10n.startSession,
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
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
          ),
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
                      l10n.completed,
                      const Color(0xFFF6FFED),
                      const Color(0xFF52C41A),
                    ),
                  ],
                ),

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
                      appointment.appointmentType?.toLowerCase() == "video"
                          ? Icons.videocam_outlined
                          : Icons.location_on_outlined,
                      appointment.appointmentType?.toLowerCase() == "video"
                          ? l10n.videoCall
                          : l10n.physical,
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


  void _showAppointmentDetails(AppointmentModel appointment) {
    final l10n = AppLocalizations.of(context)!;
   
    debugPrint(' Showing details for appointment: ${appointment.id}');
    debugPrint('Appointment Type: ${appointment.appointmentType}');
    debugPrint('Medical Documents: ${appointment.medicalDocuments}');
    debugPrint('Payment Screenshot: ${appointment.paymentScreenshot}');

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
                    Text(
                      l10n.appointmentDetails,
                      style: const TextStyle(
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
                      title: l10n.patientInformation,
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
                              l10n.bookedFor(
                                appointment.bookedFor!.bookingLabel,
                              ),
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
                      title: l10n.symptoms,
                      child: Text(
                        appointment.symptoms != null &&
                                appointment.symptoms!.isNotEmpty
                            ? appointment.symptoms!
                            : l10n.noSymptoms,
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
                      title: l10n.medicalDocuments,
                      child:
                          appointment.medicalDocuments != null &&
                              appointment.medicalDocuments!.isNotEmpty
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.docsUploaded(
                                    appointment.medicalDocuments!.length,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ...appointment.medicalDocuments!.map((doc) {
                                  //Extract clean filename from URL
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
                                        ).withValues(alpha: 0.2),
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
                                            // Pass the original doc URL
                                            _viewDocument(doc);
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            )
                          : Text(
                              l10n.noDocsUploaded,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                    ),

                    const SizedBox(height: 16),

                    // Payment Screenshot (if video call)
                    _detailSection(
                      icon: Icons.payment,
                      title: l10n.paymentScreenshot,
                      child:
                          appointment.paymentScreenshot != null &&
                              appointment.paymentScreenshot!.isNotEmpty
                          ? GestureDetector(
                              onTap: () =>
                                  _viewDocument(appointment.paymentScreenshot!),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F7FF),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF1664CD,
                                    ).withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.receipt_long,
                                      color: Color(0xFF1664CD),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        l10n.viewPaymentScreenshot,
                                        style: const TextStyle(
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
                          : Text(
                              l10n.noPaymentScreenshot,
                              style: const TextStyle(
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
    final l10n = AppLocalizations.of(context)!;
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      // Clean and fix URL format
      String cleanUrl = url.trim();

      debugPrint(' Original URL: $cleanUrl'); 

      //  Extract Cloudinary URL if it exists
      if (cleanUrl.contains('https://res.cloudinary.com')) {
        final cloudinaryMatch = RegExp(
          r'https://res\.cloudinary\.com[^\s,}]+',
        ).firstMatch(cleanUrl);
        if (cloudinaryMatch != null) {
          cleanUrl = cloudinaryMatch.group(0)!;
          debugPrint(' Found Cloudinary URL: $cleanUrl');
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
          debugPrint(' Built server URL: $cleanUrl');
        }
      }
      // If URL doesn't start with http, add base URL
      else if (!cleanUrl.startsWith('http')) {
        if (cleanUrl.startsWith('/')) {
          cleanUrl = '${ApiConfig.baseUrl}$cleanUrl';
        } else {
          cleanUrl = '${ApiConfig.baseUrl}/$cleanUrl';
        }
        debugPrint('🔧 Added base URL: $cleanUrl');
      }

      // URL decode if needed
      cleanUrl = Uri.decodeFull(cleanUrl);

      debugPrint(' Final URL: $cleanUrl'); // Debug log

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
            builder: (context) => FullScreenImageViewer(imageUrls: [cleanUrl]),
          ),
        );
      } else {
        // For PDF or other files, try to open with external app
        final uri = Uri.parse(cleanUrl);
        // You can use url_launcher package here
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        // For now, show URL in a dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(AppLocalizations.of(context)!.documentUrl),
              content: SelectableText(cleanUrl),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.close),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading if still open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorOpeningDoc(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
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
    final l10n = AppLocalizations.of(context)!;
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
          debugPrint('Appointment accepted: $appointmentId');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? l10n.appointmentAccepted : l10n.failedAccept,
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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.cancelAppointment),
        content: Text(l10n.confirmCancel),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.no),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

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
                    debugPrint('Appointment cancelled: $appointmentId');
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success ? l10n.appointmentCancelled : l10n.failedCancel,
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
            child: Text(l10n.yes, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Parse a stored appointment time string into a TimeOfDay for the picker.
  /// Accepts "HH:MM" (24h) and "h:MM AM/PM" formats; falls back to now.
  TimeOfDay _parseTimeOfDay(String? raw) {
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final value = raw.trim();
        final isPm = value.toLowerCase().contains('pm');
        final isAm = value.toLowerCase().contains('am');
        final cleaned = value
            .toLowerCase()
            .replaceAll('am', '')
            .replaceAll('pm', '')
            .trim();
        final parts = cleaned.split(':');
        int hour = int.parse(parts[0].trim());
        final minute = parts.length > 1 ? int.parse(parts[1].trim()) : 0;
        if (isPm && hour < 12) hour += 12;
        if (isAm && hour == 12) hour = 0;
        return TimeOfDay(hour: hour % 24, minute: minute % 60);
      } catch (_) {
        // ignore and fall through to default
      }
    }
    return TimeOfDay.now();
  }

  void _handleReschedule(
    AppointmentModel appointment,
    AppointmentProvider provider,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    final now = DateTime.now();
    final initialDate = appointment.appointmentDate.isBefore(now)
        ? now
        : appointment.appointmentDate;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF0D53C1)),
        ),
        child: child!,
      ),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _parseTimeOfDay(appointment.appointmentTime),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (pickedTime == null || !mounted) return;

    final dateStr =
        '${pickedDate.year.toString().padLeft(4, '0')}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final success = await provider.rescheduleAppointment(
        appointmentId: appointment.id,
        date: dateStr,
        time: timeStr,
      );

      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? l10n.appointmentRescheduled
                  : (provider.error ?? l10n.failedReschedule),
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handleStartSession(AppointmentModel appointment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionHolderScreen(appointment: appointment),
      ),
    ).then((result) {
      if (result == true && mounted) {
        context.read<AppointmentProvider>().fetchAppointments();
      }
    });
  }
}
