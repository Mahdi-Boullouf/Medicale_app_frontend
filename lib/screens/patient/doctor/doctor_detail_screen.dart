import 'package:flutter/material.dart';
import 'package:docmobi/models/doctor_model.dart';
import 'book_appointment_screen.dart';

class DoctorDetailsScreen extends StatelessWidget {
  final Doctor doctor;

  const DoctorDetailsScreen({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    print('DoctorDetailsScreen - ID: ${doctor.id} | Name: ${doctor.fullName}');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: doctor.image.startsWith('http')
                        ? Image.network(doctor.image, height: 80, width: 80, fit: BoxFit.cover)
                        : Image.asset(doctor.image, height: 80, width: 80, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doctor.fullName, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                        Text(doctor.specialty, style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 4),
                        const Row(children: [Icon(Icons.videocam_outlined), SizedBox(width: 5), Text("Video Consultation")]),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 20, color: Colors.orange),
                            Text(" ${doctor.rating} (${doctor.reviews} reviews)"),
                            const SizedBox(width: 10),
                            const Icon(Icons.location_on),
                            Text(" ${doctor.distance}"),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close, size: 35), onPressed: () => Navigator.pop(context)),
                ],
              ),

              const SizedBox(height: 25),
              const Text("Bio", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("${doctor.fullName} is a senior ${doctor.specialty} at ${doctor.location} with ${doctor.experience} of experience."),

              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Specialty", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      _buildBulletItem(doctor.specialty),
                      _buildBulletItem("General Medicine"),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Degree", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      // তোমার model-এ degree নেই → dummy বা skip
                      _buildBulletItem("MBBS, FCPS"),
                      _buildBulletItem("MD"),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 35),
              Text("Fees: ${doctor.fees?['amount'] ?? 500} ${doctor.fees?['currency'] ?? 'BDT'}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              const Text("Visiting Hours: Sun-Thu", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 65,
                child: ElevatedButton(
                  onPressed: () {
                    if (doctor.id.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Doctor')));
                      return;
                    }
                    Navigator.push(context, MaterialPageRoute(builder: (_) => BookAppointmentScreen(doctor: doctor)));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D53C1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  child: const Text("Book Now", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("• ", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(text, style: const TextStyle(fontSize: 17)),
        ],
      ),
    );
  }
}