import 'package:flutter/material.dart';
import 'package:docmobi/screens/doctor/appointments/session_holder_screen.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  String selectedTab = "Confirmed";

  final List<Map<String, dynamic>> appointments = [
    {
      'name': 'Kristin Watson',
      'date': 'Nov25,2025',
      'time': '10:30 am',
      'duration': '30min',
      'type': 'Video',
      'price': '20 DZD',
      'image': 'assets/images/doctor1.png', 
    },
    {
      'name': 'Bessie Cooper',
      'date': 'Nov25,2025',
      'time': '10:30 am',
      'duration': '30min',
      'type': 'Physical',
      'price': '20 DZD',
      'image': 'assets/images/doctor2.png',
    },
    {
      'name': 'Kristin Watson',
      'date': 'Nov25,2025',
      'time': '10:30 am',
      'duration': '30min',
      'type': 'Physical',
      'price': '20 DZD',
      'image': 'assets/images/doctor1.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Appointment Management',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Manage your Video and physical\nConsultations",
              style: TextStyle(color: Colors.grey, fontSize: 15, height: 1.4),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTabButton("Pending"),
                _buildTabButton("Confirmed"),
                _buildTabButton("Completed"),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Divider()),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final data = appointments[index];
                if (selectedTab == "Pending") return _buildPendingCard(data);
                if (selectedTab == "Confirmed") return _buildConfirmedCard(data);
                return _buildCompletedCard(data);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title) {
    bool isSelected = selectedTab == title;
    return GestureDetector(
      onTap: () => setState(() => selectedTab = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1664CD) : const Color(0xFFE9F0FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF1B2C49),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Pending কার্ড ডিজাইন (নীল বক্স সহ)
  Widget _buildPendingCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(radius: 30, backgroundImage: AssetImage(data['image'])),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(data['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    _statusBadge("Pending", const Color(0xFFFFF7E6), const Color(0xFFFAAD14)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFE9F0FF), borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _smallIconText(Icons.calendar_today_outlined, data['date']),
                _smallIconText(Icons.access_time, data['time']),
                _smallIconText(data['type'] == "Video" ? Icons.videocam_outlined : Icons.location_on_outlined, data['type']),
                _smallIconText(Icons.payments_outlined, data['price']),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _actionBtn("Cancel", const Color(0xFFD93D57), Colors.white, null)),
              const SizedBox(width: 15),
              Expanded(child: _actionBtn("Accepted", const Color(0xFFC6F2D6), const Color(0xFF27AE60), null)),
            ],
          ),
        ],
      ),
    );
  }

  // Confirmed কার্ড ডিজাইন (Start Session বাটন সহ)
  Widget _buildConfirmedCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(radius: 30, backgroundImage: AssetImage(data['image'])),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Wrap(spacing: 8, runSpacing: 4, children: [
                      _smallIconText(data['type'] == "Video" ? Icons.videocam_outlined : Icons.location_on_outlined, data['type']),
                      _smallIconText(Icons.calendar_today_outlined, data['date']),
                      _smallIconText(Icons.access_time, "${data['time']}(${data['duration']})"),
                      _smallIconText(Icons.payments_outlined, data['price']),
                    ]),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _actionBtn("Reschedule", const Color(0xFFE9F0FF), Colors.black87, null)),
              const SizedBox(width: 15),
              Expanded(child: _actionBtn("Cancel", const Color(0xFFD93D57), Colors.white, null)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _actionBtn(
              data['type'] == "Video" ? "Start Session" : "Mark as Completed",
              const Color(0xFF0B3267),
              Colors.white,
              () {
                if (data['type'] == "Video") {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SessionHolderScreen()));
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // Completed কার্ড ডিজাইন (বাটন ছাড়া আগের মতো)
  Widget _buildCompletedCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 30, backgroundImage: AssetImage(data['image'])),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(data['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    _statusBadge("Completed", const Color(0xFFF6FFED), const Color(0xFF52C41A)),
                  ],
                ),
                const SizedBox(height: 5),
                Wrap(spacing: 10, runSpacing: 5, children: [
                  _smallIconText(data['type'] == "Video" ? Icons.videocam_outlined : Icons.location_on_outlined, data['type']),
                  _smallIconText(Icons.calendar_today_outlined, data['date']),
                  _smallIconText(Icons.access_time, "${data['time']}(${data['duration']})"),
                  _smallIconText(Icons.payments_outlined, data['price']),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String text, Color bg, Color txt) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
      child: Text(text, style: TextStyle(color: txt, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _smallIconText(IconData icon, String text) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: Colors.grey[600]),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
    ]);
  }

  Widget _actionBtn(String label, Color bg, Color txt, VoidCallback? onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg, elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(label, style: TextStyle(color: txt, fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }
}