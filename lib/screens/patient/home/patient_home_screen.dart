import 'package:flutter/material.dart';
import 'package:docmobi/models/doctor_model.dart';
import 'package:docmobi/widgets/doctor_card.dart';
import 'package:docmobi/screens/patient/home/see_all_doctors_screen.dart';
import '../../../screens/patient/doctor/doctor_detail_screen.dart';
import '../../../screens/patient/doctor/book_appointment_screen.dart';
import 'package:docmobi/screens/patient/notification/notification_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // static ভেরিয়েবল ব্যবহার করা হয়েছে যাতে এটি মেমোরিতে থেকে যায়
  static bool _hasShownLocationDialog = false; 
  late bool _showLocationDialog;

  final List<Doctor> nearbyDoctors = [
    Doctor(
      id: '1',
      name: 'Dr. Joynal Abedin',
      specialty: 'Podiatric Surgery',
      hospital: 'Salemn Hospital',
      image: 'assets/images/doctor_booking.png',
      rating: 4.9,
      distance: '2.5km',
      experience: 10,
      degree: "MBBS, FCPS (Medicine), MRCP (UK)",
      isAvailable: true,
    ),
    Doctor(
      id: '2',
      name: 'Dr. Jaynor Abedin',
      specialty: 'Pediatric Surgery',
      hospital: 'Salemn Hospital',
      image: 'assets/images/doctor_booking.png',
      rating: 4.8,
      distance: '3.1km',
      experience: 10,
      degree: 'MBBS, MD',
      isAvailable: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // যদি আগে দেখানো না হয়ে থাকে তবেই ডায়ালগটি শো করবে
    _showLocationDialog = !_hasShownLocationDialog;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ডায়ালগ বন্ধ করার এবং স্টেট সেভ করার মেথড
  void _dismissDialog() {
    setState(() {
      _showLocationDialog = false;
      _hasShownLocationDialog = true; // একবার ট্রু হয়ে গেলে এই সেশনে আর পপআপ আসবে না
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F6FF),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // --- Header & Search ---
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 25,
                            backgroundImage: AssetImage('assets/images/profile.png'),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'The king',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B2C49),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.location_on, size: 16, color: Colors.grey),
                                    SizedBox(width: 4),
                                    Text(
                                      'Koln - Germany',
                                      style: TextStyle(fontSize: 14, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const NotificationScreen()),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                              ),
                              child: const Icon(Icons.notifications_none_rounded, size: 28, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black.withOpacity(0.1)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search Doctor...',
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // --- Scrollable Body ---
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Nearby Doctor's",
                                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF1B2C49)),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => const DoctorListScreen()));
                                },
                                child: const Text('See All', style: TextStyle(color: Colors.grey, fontSize: 14)),
                              ),
                            ],
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: nearbyDoctors.length,
                          itemBuilder: (context, index) {
                            return _buildCustomDoctorCard(nearbyDoctors[index]);
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
       
            if (_showLocationDialog) _buildLocationDialog(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomDoctorCard(Doctor doctor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(doctor.image, height: 80, width: 80, fit: BoxFit.cover),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(doctor.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        if (doctor.isAvailable)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                            child: const Text('Available', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    Text(doctor.specialty, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.orangeAccent),
                        Text(' ${doctor.rating}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 15),
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        Text(' ${doctor.distance}', style: const TextStyle(color: Colors.grey)),
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookAppointmentScreen(doctor: doctor),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Book Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DoctorDetailsScreen(doctor: doctor),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.info_outline, color: Color(0xFF0D47A1)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLocationDialog() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(30),
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, size: 80, color: Color(0xFF1664CD)),
              const SizedBox(height: 20),
              const Text(
                'Allow Mapps to access this device\'s precise location?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B3267)),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _dismissDialog, // মেথড কল করা হয়েছে
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF1664CD)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Precise', style: TextStyle(color: Color(0xFF1664CD), fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF0B3267), Color(0xFF1664CD)]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ElevatedButton(
                        onPressed: _dismissDialog, // মেথড কল করা হয়েছে
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Approximate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...['While using the app', 'Only this time', 'Don\'t allow'].map((text) {
                return TextButton(
                  onPressed: _dismissDialog, // মেথড কল করা হয়েছে
                  child: Text(text, style: const TextStyle(color: Color(0xFF1664CD), decoration: TextDecoration.underline)),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}