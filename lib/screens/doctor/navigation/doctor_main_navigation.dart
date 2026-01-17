import 'package:flutter/material.dart';
import 'package:docmobi/screens/doctor/home/doctor_home_screen.dart';
import 'package:docmobi/screens/doctor/appointments/doctor_appointments_screen.dart';
import 'package:docmobi/screens/doctor/reels/doctor_reels_screen.dart';
import 'package:docmobi/screens/doctor/profile/doctor_profile_screen.dart';
import 'package:docmobi/screens/doctor/messages/doctor_messages_list_screen.dart';

import 'package:docmobi/services/call_manager_service.dart';

class DoctorMainNavigation extends StatefulWidget {
  const DoctorMainNavigation({super.key});

  @override
  State<DoctorMainNavigation> createState() => _DoctorMainNavigationState();
}

class _DoctorMainNavigationState extends State<DoctorMainNavigation> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // ✅ Initialize CallManager when dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('👨‍⚕️ Doctor Dashboard Loaded - Initializing CallManager');
      CallManager.instance.initialize(context);
    });
  }

  final List<Widget> _screens = const [
    DoctorHomeScreen(),
    DoctorAppointmentsScreen(),
    DoctorReelsScreen(),
    DoctorMessagesListScreen(),
    DoctorProfileScreen(),
  ];

  // ✅ Public method to navigate to specific tab
  void navigateToTab(int index) {
    if (index >= 0 && index < _screens.length) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(top: 10, bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, -5),
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
          elevation: 0,
          selectedItemColor: const Color(0xFF1664CD),
          unselectedItemColor: const Color(0xFF4B5563),
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
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
            const BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Icon(Icons.mail_outline, size: 26),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Icon(Icons.mail, size: 26),
              ),
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
