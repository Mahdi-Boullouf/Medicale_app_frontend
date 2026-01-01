import 'package:flutter/material.dart';

class BookAppointmentScreen extends StatefulWidget {
  // ✅ dynamic type যা Map এবং Doctor model উভয়ই support করবে
  final dynamic doctor;

  const BookAppointmentScreen({super.key, required this.doctor});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  String selectedType = "Physical Visit";
  String selectedTime = "11:01 Am To 11:30 Am";

  // ✅ Helper method - safely extract doctor data
  String _getDoctorField(String key, {String defaultValue = "Unknown"}) {
    if (widget.doctor is Map) {
      return widget.doctor[key]?.toString() ?? defaultValue;
    }
    // যদি Doctor model হয়, তাহলে reflection বা getter দিয়ে access করুন
    try {
      return widget.doctor.toJson()[key]?.toString() ?? defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

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
          "Book Appointment",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          children: [
            // Video Call Warning
            if (selectedType == "Video Call")
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Center(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: '*',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const TextSpan(
                          text: " Video appointments- patient must\nupload BaridiMob payment screenshot ",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const TextSpan(
                          text: '*',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // Appointment Type Section
            _buildWhiteCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Appointment Type",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      _buildTypeOption(
                        Icons.local_hospital_outlined,
                        "Physical Visit",
                        "Pay at Clinic",
                      ),
                      const SizedBox(width: 15),
                      _buildTypeOption(
                        Icons.videocam_outlined,
                        "Video Call",
                        "Online Payment",
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Select Date Section
            _buildWhiteCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Select Date",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black, width: 1.2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          "dd/mm/yyyy",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        Icon(
                          Icons.calendar_month_outlined,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Available Time Section
            _buildWhiteCard(
              child: Column(
                children: [
                  const Text(
                    "Available Time",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  _buildTimeSlots(),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Symptoms Section
            _buildWhiteCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Describe your Symptoms",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildDashedInput(
                    "Please describe your symptoms in detail.....",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Medical Documents Section
            _buildWhiteCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Upload Medical Documents",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildUploadBox(
                    Icons.cloud_upload_outlined,
                    "Tap to Upload image or PDF",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payment Screenshot Upload (Video Call only)
            if (selectedType == "Video Call")
              _buildWhiteCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Upload Payment Screenshot",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildUploadBox(
                      Icons.cloud_upload_outlined,
                      "Tap to Upload Your Payment Screenshot",
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // ✅ Doctor data safely access করুন
                  final doctorName = _getDoctorField("fullName", defaultValue: "Doctor");
                  final specialty = _getDoctorField("specialty", defaultValue: "General");
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Appointment requested with $doctorName ($specialty)"),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  // TODO: Backend API call করুন
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D53C1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Submit Appointment Request",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildWhiteCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTypeOption(IconData icon, String title, String subtitle) {
    bool isSelected = selectedType == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedType = title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF0D53C1) : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF0D53C1) : Colors.black54,
                size: 30,
              ),
              const SizedBox(height: 5),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? const Color(0xFF0D53C1) : Colors.black87,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSlots() {
    List<String> slots = [
      "10:00 Am To 10:30 Am",
      "10:31 Am To 11:00 Am",
      "11:01 Am To 11:30 Am",
      "11:31 Am To 12:00 Am",
      "12:10 Am To 12:40 Am",
    ];

    return Column(
      children: slots.map((time) {
        List<String> parts = time.split(" To ");
        bool isSelected = selectedTime == time;

        return GestureDetector(
          onTap: () => setState(() => selectedTime = time),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF0D53C1) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSingleTimeBox(parts[0], isSelected),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    "To",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                _buildSingleTimeBox(parts[1], isSelected),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSingleTimeBox(String time, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? Colors.white : Colors.black,
          width: 1.2,
        ),
      ),
      child: Text(
        time,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDashedInput(String hint) {
    return Container(
      width: double.infinity,
      height: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.shade200,
          style: BorderStyle.solid,
        ),
      ),
      child: TextField(
        maxLines: null,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildUploadBox(IconData icon, String label) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 25),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.black, size: 30),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}