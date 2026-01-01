import 'package:flutter/material.dart';
import 'package:docmobi/models/appointment_model.dart';
import 'package:docmobi/screens/patient/appointments/appointment_detail_screen.dart';
import 'package:docmobi/screens/patient/doctor/book_appointment_screen.dart'; 
import 'package:docmobi/models/doctor_model.dart'; // Doctor মডেল ইমপোর্ট করুন

class PatientAppointmentsScreen extends StatefulWidget {
  const PatientAppointmentsScreen({super.key});

  @override
  State<PatientAppointmentsScreen> createState() => _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen> {
  bool isUpcoming = true;

  // Upcoming Data
  final List<Appointment> upcomingAppointments = [
    Appointment(
      id: '1',
      doctorName: 'Dr. Joynal Abedin',
      doctorImage: 'assets/images/doctor_booking.png',
      specialty: 'Podiatric Surgery',
      date: 'Nov 25, 2025',
      time: '10:30 am',
      status: 'confirmed',
      appointmentType: 'Physical',
    ),
     Appointment(
      id: '11',
      doctorName: 'Dr. Joynal Abedin',
      doctorImage: 'assets/images/doctor_booking.png',
      specialty: 'Podiatric Surgery',
      date: 'Nov 25, 2025',
      time: '10:30 am',
      status: 'confirmed',
      appointmentType: 'Physical',
    ),
     Appointment(
      id: '111',
      doctorName: 'Dr. Joynal Abedin',
      doctorImage: 'assets/images/doctor_booking.png',
      specialty: 'Podiatric Surgery',
      date: 'Nov 25, 2025',
      time: '10:30 am',
      status: 'confirmed',
      appointmentType: 'Physical',
    ),
     Appointment(
      id: '1111',
      doctorName: 'Dr. Joynal Abedin',
      doctorImage: 'assets/images/doctor_booking.png',
      specialty: 'Podiatric Surgery',
      date: 'Nov 25, 2025',
      time: '10:30 am',
      status: 'confirmed',
      appointmentType: 'Physical',
    ),
  ];
  

  // Completed Data (বাটন থাকবে না)
  final List<Appointment> completedAppointments = [
    Appointment(
      id: '2',
      doctorName: 'Dr. Joynal Abedin',
      doctorImage: 'assets/images/doctor_booking.png',
      specialty: 'Podiatric Surgery',
      date: 'Nov 25, 2025',
      time: '10:30 am',
      status: 'completed',
      appointmentType: 'Physical',
    ),
    Appointment(
      id: '22',
      doctorName: 'Dr. Joynal Abedin',
      doctorImage: 'assets/images/doctor_booking.png',
      specialty: 'Podiatric Surgery',
      date: 'Nov 25, 2025',
      time: '10:30 am',
      status: 'completed',
      appointmentType: 'Physical',
    ),
    Appointment(
      id: '222',
      doctorName: 'Dr. Joynal Abedin',
      doctorImage: 'assets/images/doctor_booking.png',
      specialty: 'Podiatric Surgery',
      date: 'Nov 25, 2025',
      time: '10:30 am',
      status: 'completed',
      appointmentType: 'Physical',
    ),
    Appointment(
      id: '2222',
      doctorName: 'Dr. Joynal Abedin',
      doctorImage: 'assets/images/doctor_booking.png',
      specialty: 'Podiatric Surgery',
      date: 'Nov 25, 2025',
      time: '10:30 am',
      status: 'completed',
      appointmentType: 'Physical',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF), 
      body: Column(
        children: [
          const SizedBox(height: 60),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'My Appointment',
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                ),
              ),
            ),
          ),
          const SizedBox(height: 25),
          
          // ট্যাব সুইচ ডিজাইন
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildTab(title: "Up Coming(02)", active: isUpcoming, onTap: () => setState(() => isUpcoming = true)),
                const SizedBox(width: 15),
                _buildTab(title: "Completed", active: !isUpcoming, onTap: () => setState(() => isUpcoming = false)),
              ],
            ),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: isUpcoming ? upcomingAppointments.length : completedAppointments.length,
              itemBuilder: (context, index) {
                final appointment = isUpcoming ? upcomingAppointments[index] : completedAppointments[index];
                return _buildAppointmentCard(appointment);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({required String title, required bool active, required VoidCallback onTap}) {
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

  Widget _buildAppointmentCard(Appointment appointment) {
    bool isCompleted = appointment.status == 'completed';
    
    // স্ট্যাটাস কালার লজিক
    Color statusBg = isCompleted ? const Color(0xFFD4F4DD) : (appointment.status == 'confirmed' ? const Color(0xFFD4F4DD) : const Color(0xFFFFF4E5));
    Color statusText = isCompleted ? const Color(0xFF27AE60) : (appointment.status == 'confirmed' ? const Color(0xFF27AE60) : const Color(0xFFFFA726));
    String statusLabel = isCompleted ? 'Completed' : (appointment.status == 'confirmed' ? 'Confirmed' : 'Pending');

    return GestureDetector(
      onTap: () {
        // পুরো কার্ডে ক্লিক করলে ডিটেইলস স্ক্রিন
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AppointmentDetailScreen(appointment: appointment)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset('assets/images/doctor_booking.png', width: 60, height: 60, fit: BoxFit.cover),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(appointment.doctorName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8)),
                            child: Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusText)),
                          ),
                        ],
                      ),
                      Text(appointment.specialty, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            
            // ইনফো স্ট্রিপ ডিজাইন
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EEF9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _infoRow(Icons.calendar_month_outlined, appointment.date),
                  _infoRow(Icons.access_time, appointment.time),
                  _infoRow(
                    appointment.appointmentType == 'Video' ? Icons.videocam_outlined : Icons.apartment,
                    appointment.appointmentType,
                  ),
                ],
              ),
            ),
            
            // শুধু Upcoming এ বাটন দেখাবে, Completed এ বাটন উধাও থাকবে
            if (!isCompleted) ...[
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        // এরর ফিক্স: এখানে ডক্টর ডাটা সরাসরি তৈরি করে পাঠানো হয়েছে
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (context) => BookAppointmentScreen(
                        //       doctor: Doctor(
                        //         name: appointment.doctorName,
                        //         specialty: appointment.specialty,
                        //         image: appointment.doctorImage,
                        //       ),
                        //     ),
                        //   ),
                        // );
                      },
                      child: _buttonDesign('Reschedule', const Color(0xFFF2F4F7), Colors.black),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _showCancelDialog(context),
                      child: _buttonDesign('Cancel', const Color(0xFFD93B41), Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
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
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      alignment: Alignment.center,
      child: Text(title, style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  // ক্যানসেল কনফার্মেশন পপআপ
  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Appointment"),
        content: const Text("Are you sure you want to cancel this appointment?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("No")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // ক্যানসেল লজিক এখানে হবে
            }, 
            child: const Text("Yes, Cancel", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }
}