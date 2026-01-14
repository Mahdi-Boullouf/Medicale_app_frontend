import 'package:docmobi/screens/patient/home/dialog/location_permission_dialog.dart';
import 'package:docmobi/screens/patient/home/upcoming_appointment_card.dart';
import 'package:docmobi/screens/patient/profile/patient_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:docmobi/models/doctor_model.dart';
import 'package:docmobi/providers/doctor_provider.dart';
import 'package:docmobi/providers/appointment_provider.dart';
import 'package:docmobi/providers/user_provider.dart';
import 'package:docmobi/providers/notification_provider.dart';
import 'package:docmobi/screens/patient/home/see_all_doctors_screen.dart';
import 'package:docmobi/screens/patient/doctor/doctor_detail_screen.dart';
import 'package:docmobi/screens/patient/doctor/book_appointment_screen.dart';
import 'package:docmobi/screens/patient/notification/notification_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  static bool _hasShownLocationDialog = false;
  late bool _showLocationDialog;

  @override
  void initState() {
    super.initState();
    _showLocationDialog = !_hasShownLocationDialog;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoctorProvider>().fetchNearbyDoctors();
      context.read<AppointmentProvider>().fetchAppointments();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _dismissDialog() {
    setState(() {
      _showLocationDialog = false;
      _hasShownLocationDialog = true;
    });
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      context.read<DoctorProvider>().fetchNearbyDoctors(),
      context.read<AppointmentProvider>().fetchAppointments(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F6FF),
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header & Search
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Line 85-118 replace করো এই code দিয়ে
                          Row(
                            children: [
                              _buildProfileAvatar(
                                userProvider.user?.profileImage,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userProvider.user?.fullName ?? 'The King',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1B2C49),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            userProvider.user?.address ??
                                                'Location not set',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const NotificationScreen(),
                                  ),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      const Icon(
                                        Icons.notifications_none_rounded,
                                        size: 28,
                                        color: Colors.black87,
                                      ),
                                      ValueListenableBuilder<int>(
                                        valueListenable: context
                                            .read<NotificationProvider>()
                                            .generalUnreadCount,
                                        builder: (context, count, child) {
                                          if (count == 0) {
                                            return const SizedBox.shrink();
                                          }
                                          return Positioned(
                                            top: 0,
                                            right: 0,
                                            child: Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.black.withValues(alpha: 0.1),
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: 'Search Doctor...',
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Colors.grey,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Map
                    Container(
                      height: 160,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/map.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Upcoming Appointment
                    Consumer<AppointmentProvider>(
                      builder: (context, aptProvider, child) {
                        final now = DateTime.now();
                        final today = DateTime(now.year, now.month, now.day);

                        final upcoming =
                            aptProvider.upcomingAppointments.where((a) {
                              final appointmentDay = DateTime(
                                a.appointmentDate.year,
                                a.appointmentDate.month,
                                a.appointmentDate.day,
                              );
                              return appointmentDay.isAtSameMomentAs(today) ||
                                  appointmentDay.isAfter(today);
                            }).toList()..sort(
                              (a, b) => a.appointmentDate.compareTo(
                                b.appointmentDate,
                              ),
                            );

                        if (upcoming.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Upcoming Appointment",
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B2C49),
                                ),
                              ),
                              const SizedBox(height: 15),
                              UpcomingAppointmentCard(
                                appointment: upcoming.first,
                              ),
                              const SizedBox(height: 25),
                            ],
                          ),
                        );
                      },
                    ),

                    // Nearby Doctors
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Nearby Doctors",
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B2C49),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SeeAllDoctorsScreen(),
                              ),
                            ),
                            child: const Text(
                              'See All',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Doctors List
                    Consumer<DoctorProvider>(
                      builder: (context, doctorProvider, child) {
                        if (doctorProvider.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (doctorProvider.error != null) {
                          return Center(
                            child: Text('Error: ${doctorProvider.error}'),
                          );
                        }

                        if (doctorProvider.nearbyDoctors.isEmpty) {
                          return const Center(
                            child: Text('No nearby doctors found'),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: doctorProvider.nearbyDoctors.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: 20,
                                left: 20,
                                right: 20,
                              ),
                              child: _buildCustomDoctorCard(
                                doctorProvider.nearbyDoctors[index],
                              ),
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            if (_showLocationDialog)
              Container(
                color: Colors.black54,
                child: LocationPermissionDialog(onDismiss: _dismissDialog),
              ),
          ],
        ),
      ),
    );
  }

  // ✅ Profile Avatar Builder
  Widget _buildProfileAvatar(String? imageUrl) {
    if (imageUrl != null &&
        imageUrl.isNotEmpty &&
        (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'))) {
      return CircleAvatar(
        radius: 25,
        backgroundImage: NetworkImage(imageUrl),
        onBackgroundImageError: (exception, stackTrace) {},
        child: null,
      );
    }

    return const CircleAvatar(
      radius: 25,
      backgroundImage: AssetImage('assets/images/profile.png'),
    );
  }

  // ✅ Fixed Doctor Card
  Widget _buildCustomDoctorCard(Doctor doctor) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: _buildDoctorImage(doctor.image),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            doctor.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (doctor.isAvailable)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Available',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor.specialty,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.orangeAccent,
                        ),
                        Text(
                          ' ${doctor.rating}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 15),
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey,
                        ),
                        Text(
                          ' ${doctor.distance}',
                          style: const TextStyle(color: Colors.grey),
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
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookAppointmentScreen(doctor: doctor),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Book Now',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DoctorDetailsScreen(doctor: doctor),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Color(0xFF0D47A1),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ Safe Doctor Image Builder
  Widget _buildDoctorImage(String? imageUrl) {
    if (imageUrl != null &&
        imageUrl.isNotEmpty &&
        (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'))) {
      return Image.network(
        imageUrl,
        height: 80,
        width: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildImagePlaceholder();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 80,
            width: 80,
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      );
    }

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.asset(
        imageUrl,
        height: 80,
        width: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildImagePlaceholder();
        },
      );
    }

    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 80,
      width: 80,
      color: Colors.grey[200],
      child: const Icon(Icons.person, size: 40, color: Colors.grey),
    );
  }
}
