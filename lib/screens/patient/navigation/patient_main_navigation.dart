import 'package:flutter/material.dart';
import 'package:docmobi/screens/patient/home/patient_home_screen.dart';
import 'package:docmobi/screens/patient/appointments/patient_appointments_screen.dart';
import 'package:docmobi/screens/patient/reels/patient_reels_screen.dart';
import 'package:docmobi/screens/patient/messages/patient_messages_list_screen.dart';
import 'package:docmobi/screens/patient/profile/patient_profile_screen.dart';
import 'package:docmobi/providers/notification_provider.dart';
import 'package:provider/provider.dart';

import 'package:docmobi/services/call_manager_service.dart';

class PatientMainNavigation extends StatefulWidget {
  const PatientMainNavigation({super.key});

  @override
  State<PatientMainNavigation> createState() => _PatientMainNavigationState();
}

class _PatientMainNavigationState extends State<PatientMainNavigation> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize CallManager when dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🏥 Patient Dashboard Loaded - Initializing CallManager');
      CallManager.instance.initialize(context);
    });
  }

  final List<Widget> _screens = const [
    PatientHomeScreen(),
    PatientAppointmentsScreen(),
    PatientReelsScreen(),
    PatientMessagesListScreen(),
    PatientProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF1664CD),
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: [
            const BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Icon(Icons.home_outlined, size: 28),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Icon(Icons.home, size: 28),
              ),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Icon(Icons.calendar_today_outlined, size: 26),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Icon(Icons.calendar_today, size: 26),
              ),
              label: 'Appointments',
            ),
            const BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Icon(Icons.video_library_outlined, size: 26),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Icon(Icons.video_library, size: 26),
              ),
              label: 'Reels',
            ),
            BottomNavigationBarItem(
              icon: _buildNotificationIcon(
                Icons.mail_outline,
              ), // Inactive state
              activeIcon: _buildNotificationIcon(Icons.mail), // Active state
              label: 'Messages',
            ),
            const BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Icon(Icons.person_outline, size: 28),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Icon(Icons.person, size: 28),
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildNotificationIcon(IconData iconData) {
  return Consumer<NotificationProvider>(
    builder: (context, notificationProvider, child) {
      final unreadCount = notificationProvider.messageUnreadCount.value;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          // This applies your specific styling (padding & size) to whatever icon is passed in
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Icon(iconData, size: 26),
          ),
          if (unreadCount > 0)
            Positioned(
              right: -8,
              top: -8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      );
    },
  );
}
