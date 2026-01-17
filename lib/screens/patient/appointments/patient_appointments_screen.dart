import 'package:docmobi/screens/patient/doctor/book_appointment_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:docmobi/models/appointment_model.dart';
import 'package:docmobi/providers/appointment_provider.dart';
import 'package:docmobi/screens/patient/appointments/appointment_detail_screen.dart';
import 'package:docmobi/screens/patient/navigation/patient_main_navigation.dart';
import 'package:docmobi/services/api_service.dart';

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
                  _infoRow(
                    appointment.appointmentType == 'video' 
                      ? Icons.videocam 
                      : Icons.apartment,
                    appointment.appointmentType == 'video' ? 'Video' : 'Physical',
                  ),
                ],
              ),
            ),

            // ✅ Actions for upcoming appointments
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

            // ✅ NEW: Review button for completed appointments
            if (isCompleted) ...[
              const SizedBox(height: 15),
              InkWell(
                onTap: () => _showReviewDialog(context, appointment),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0B3267), Color(0xFF1664CD)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.star_border, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Write Review',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleCancel(
    BuildContext context,
    AppointmentModel appointment,
    AppointmentProvider provider,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    try {
      final success = await provider.cancelAppointment(appointment.id);

      if (mounted) Navigator.pop(context);

      if (success) {
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
          provider.fetchAppointments();
        }
      } else {
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
      if (mounted) Navigator.pop(context);
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

  void _handleReschedule(BuildContext context, AppointmentModel appointment) {
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
      context.read<AppointmentProvider>().fetchAppointments();
    });
  }

  /// ✅ Show review dialog for completed appointments
  // ✅ FIXED: Review loading & editing
void _showReviewDialog(BuildContext context, AppointmentModel appointment) async {
  int selectedRating = 0;
  bool isLoadingExisting = true;
  
  // ✅ Fetch existing review if any
  try {
    final existingReview = await ApiService.get(
      '/api/v1/doctor-review/me',
    );
    
    if (existingReview['success'] == true) {
      final reviews = existingReview['data'] as List;
      
      // Find review for this appointment or doctor
      final thisReview = reviews.firstWhere(
        (r) => r['appointment']?['_id'] == appointment.id || 
               r['appointment'] == appointment.id ||
               (r['doctor']?['_id'] == appointment.doctorId && r['appointment'] == null),
        orElse: () => null,
      );
      
      if (thisReview != null) {
        selectedRating = thisReview['rating'] ?? 0;
        print('✅ Found existing review with rating: $selectedRating');
      }
    }
  } catch (e) {
    print('⚠️ No existing review found: $e');
  } finally {
    isLoadingExisting = false;
  }

  if (!context.mounted) return;

  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  selectedRating > 0 ? 'Update Your Review' : 'Rate Your Experience',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B2C49),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'with ${appointment.doctorName}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                
                // ✅ Star Rating with existing review support
                isLoadingExisting
                  ? const CircularProgressIndicator()
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedRating = index + 1;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              index < selectedRating ? Icons.star : Icons.star_border,
                              size: 40,
                              color: index < selectedRating 
                                ? Colors.amber 
                                : Colors.grey[400],
                            ),
                          ),
                        );
                      }),
                    ),
                
                const SizedBox(height: 32),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: selectedRating > 0
                          ? () async {
                              // ✅ Close dialog immediately
                              Navigator.pop(dialogContext);
                              
                              // ✅ Then submit review
                              await _submitReview(
                                context,
                                appointment,
                                selectedRating,
                              );
                            }
                          : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1664CD),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Submit',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

/// ✅ FIXED: Submit review with proper dialog handling
Future<void> _submitReview(
  BuildContext context,
  AppointmentModel appointment,
  int rating,
) async {
  // ✅ Show loading overlay
  final overlay = OverlayEntry(
    builder: (context) => Container(
      color: Colors.black54,
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    ),
  );
  
  Overlay.of(context).insert(overlay);

  try {
    print('📤 Submitting review:');
    print('   - Doctor ID: ${appointment.doctorId}');
    print('   - Appointment ID: ${appointment.id}');
    print('   - Rating: $rating');

    final response = await ApiService.post(
      '/api/v1/doctor-review',
      {
        'doctorId': appointment.doctorId,
        'appointmentId': appointment.id,
        'rating': rating,
      },
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Request timeout'),
    );

    print('📥 Review Response: $response');

    // ✅ Remove overlay
    overlay.remove();

    // ✅ Show result
    if (context.mounted) {
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Review submitted successfully! ⭐'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to submit review'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  } catch (e) {
    print('❌ Review submission error: $e');
    
    // ✅ Remove overlay on error
    overlay.remove();
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception:', '').trim()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
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