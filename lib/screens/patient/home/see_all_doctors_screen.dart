import 'package:docmobi/screens/patient/doctor/book_appointment_screen.dart';
import 'package:flutter/material.dart';

class DoctorListScreen extends StatelessWidget {
  const DoctorListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "All Doctors",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: 6,
        itemBuilder: (context, index) {
          // ডেটা ম্যাপ হিসেবে তৈরি করা হয়েছে
          final Map<String, dynamic> mockDoctor = {
            "fullName": index % 2 == 0 ? "Dr. Joynal Abedin" : "Dr. Jaynor Abedin",
            "specialty": "Podiatric Surgery",
            "email": "joynal@example.com",
            "fees": "10.50\$",
            "image": "assets/doctor.jpg",
          };
          return _DoctorCard(doctor: mockDoctor);
        },
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final dynamic doctor; // ✅ dynamic দেওয়ার ফলে যে কোনো টাইপ ডেটা গ্রহণ করবে

  const _DoctorCard({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  "assets/images/doctor.png",
                  height: 80, width: 80, fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 80, width: 80, color: Colors.grey[300],
                    child: const Icon(Icons.person),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor["fullName"] ?? "No Name",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      doctor["specialty"] ?? "General",
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 18),
                        SizedBox(width: 4),
                        Text("4.9", style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(width: 12),
                        Icon(Icons.location_on, size: 16, color: Colors.grey),
                        SizedBox(width: 2),
                        Text("2.5km", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(colors: [Color(0xFF0D53C1), Color(0xFF1976D2)]),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookAppointmentScreen(doctor: doctor),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Book Now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _showDoctorDetails(context),
                child: Container(
                  height: 52, width: 52,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF1F5FF)),
                  child: const Icon(Icons.info_outline, color: Color(0xFF0D53C1)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDoctorDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset("assets/images/doctor.png", height: 70, width: 70, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doctor["fullName"], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      Text(doctor["specialty"], style: const TextStyle(color: Colors.black54, fontSize: 16)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text("Bio", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Text(
                "Senior specialist at xyz Hospital with extensive experience in modern medicine.",
                style: TextStyle(color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookAppointmentScreen(doctor: doctor),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D53C1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Confirm Booking", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}