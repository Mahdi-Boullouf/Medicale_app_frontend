import 'package:flutter/material.dart';
import 'package:docmobi/screens/auth/sign_in_screen.dart';
import 'package:docmobi/widgets/custom_button.dart';
// আপনার হোম স্ক্রিনটি ইম্পোর্ট করুন

class SelectProfileScreen extends StatefulWidget {
  const SelectProfileScreen({super.key});

  @override
  State<SelectProfileScreen> createState() => _SelectProfileScreenState();
}

class _SelectProfileScreenState extends State<SelectProfileScreen> {
  String? selectedProfile;

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(15),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back, color: Colors.black),
        //   onPressed: () {
        //     // ব্যাক বাটনে ক্লিক করলে সরাসরি হোম পেজে পাঠিয়ে দেবে
        //     Navigator.pushAndRemoveUntil(
        //       context,
        //       MaterialPageRoute(builder: (context) => const PatientHomeScreen()),
        //       (route) => false, // এটি পেছনের সব রুট ক্লিয়ার করে দেবে যাতে আর এরর না আসে
        //     );
        //   },
        // ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              const Text(
                'Select Profile',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B3267),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildProfileCard(
                    title: 'Patient',
                    imagePath: 'assets/images/patient.png',
                    isSelected: selectedProfile == 'Patient',
                    onTap: () => setState(() => selectedProfile = 'Patient'),
                  ),
                  _buildProfileCard(
                    title: 'Doctor',
                    imagePath: 'assets/images/doctor.png',
                    isSelected: selectedProfile == 'Doctor',
                    onTap: () => setState(() => selectedProfile = 'Doctor'),
                  ),
                ],
              ),
              const Spacer(),
              
              CustomButton(
                text: 'Continue',
                onPressed: selectedProfile != null
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SignInScreen(userType: selectedProfile!),
                          ),
                        );
                      }
                    : () {
                        _showSnackBar('Please select a profile');
                      },
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard({
    required String title,
    required String imagePath,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.42,
        height: 200,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1664CD).withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1664CD) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              height: 90,
              width: 90,
              errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.account_circle, size: 80, color: Colors.grey),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF1664CD) : const Color(0xFF0B3267),
              ),
            ),
          ],
        ),
      ),
    );
  }
}