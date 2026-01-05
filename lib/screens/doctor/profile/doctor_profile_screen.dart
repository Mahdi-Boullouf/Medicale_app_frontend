import 'package:flutter/material.dart';
import 'package:docmobi/screens/doctor/profile/doctor_personal_info_screen.dart';
import 'package:docmobi/screens/doctor/profile/doctor_my_schedule_screen.dart';
import 'package:docmobi/screens/doctor/profile/doctor_earnigs.dart';
import 'package:docmobi/screens/patient/profile/change_password_screen.dart';

import 'package:provider/provider.dart';
import '../../../providers/user_provider.dart';
import '../../../services/auth_service.dart';
import '../../auth/sign_in_screen.dart';  // ✅ Fixed - removed one ../

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  String selectedLanguage = 'English';
  bool isVoiceVideoCallActive = false;

  @override
  void initState() {
    super.initState();
    // Load profile data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Color(0xFF1B2C49),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final user = userProvider.user;
          final userName = user?.fullName ?? 'The king';
          final userRole = user?.role ?? 'Cardiologist';

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),
                // --- Profile Header ---
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 55,
                            backgroundImage: user?.profileImage != null
                                ? NetworkImage(user!.profileImage!)
                                : const AssetImage('assets/images/doctor_booking.png') as ImageProvider,
                          ),
                          if (userProvider.isLoading)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B2C49),
                        ),
                      ),
                      Text(
                        userRole,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                _buildProfileItem(
                  icon: Icons.person_outline,
                  title: 'Personal Info',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DoctorPersonalInfoScreen()),
                    );
                  },
                ),

                _buildProfileItem(
                  icon: Icons.calendar_today_outlined,
                  title: 'Appointment Setting',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DoctorMyScheduleScreen()),
                    );
                  },
                ),

                _buildProfileItem(
                  icon: Icons.phone_outlined,
                  title: 'Voice and Video call',
                  trailing: Switch(
                    value: isVoiceVideoCallActive,
                    activeColor: Colors.white,
                    activeTrackColor: const Color(0xFF1664CD),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.grey[300],
                    onChanged: (value) {
                      setState(() {
                        isVoiceVideoCallActive = value;
                      });
                    },
                  ),
                ),

                _buildLanguageDropdown(),

                _buildProfileItem(
                  icon: Icons.attach_money_outlined,
                  title: 'My Earning',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EarningOverviewScreen()),
                    );
                  },
                ),

                _buildProfileItem(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                    );
                  },
                ),

                _buildProfileItem(
                  icon: Icons.headphones_outlined,
                  title: 'Help & Support',
                  onTap: () {},
                ),

                const SizedBox(height: 25),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () => _showLogoutDialog(context),
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text(
                        'Log Out',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLanguageDropdown() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F0FF),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: const Icon(Icons.language_outlined, color: Color(0xFF1B2C49), size: 22),
        ),
        title: const Text('Language', style: TextStyle(fontSize: 16, color: Color(0xFF1B2C49), fontWeight: FontWeight.w600)),
        trailing: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedLanguage,
            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF1B2C49)),
            items: <String>['French', 'English', 'Arabic'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: const TextStyle(color: Color(0xFF1B2C49))),
              );
            }).toList(),
            onChanged: (val) => setState(() => selectedLanguage = val!),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F0FF),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: Icon(icon, color: const Color(0xFF1B2C49), size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, color: Color(0xFF1B2C49), fontWeight: FontWeight.w600),
        ),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF1B2C49)),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );

              await AuthService().logout();
              context.read<UserProvider>().clearUser();

              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                 MaterialPageRoute(builder: (context) => const SignInScreen(userType: 'doctor')),
                  (route) => false,
                );
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}