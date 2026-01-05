import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:docmobi/models/doctor_model.dart';
import 'package:docmobi/providers/appointment_provider.dart';
import 'package:docmobi/utils/api_config.dart';

class BookAppointmentScreen extends StatefulWidget {
  final dynamic doctor;

  const BookAppointmentScreen({super.key, required this.doctor});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  String selectedType = "Physical Visit";
  DateTime? selectedDate;
  TimeSlot? selectedTimeSlot;
  final TextEditingController _symptomsController = TextEditingController();

  List<XFile> _medicalDocuments = [];
  XFile? _paymentScreenshot;

  bool _isLoading = false;
  bool _isLoadingSlots = false;
  List<TimeSlot> availableSlots = [];

  final ImagePicker _picker = ImagePicker();

  // Safe doctor extraction
  Doctor? get doctorObject {
    if (widget.doctor is Doctor) return widget.doctor as Doctor;
    if (widget.doctor is Map<String, dynamic>) {
      return Doctor.fromJson(widget.doctor as Map<String, dynamic>);
    }
    return null;
  }

  String get doctorId {
    if (widget.doctor is Map<String, dynamic>) {
      final map = widget.doctor as Map<String, dynamic>;
      return (map['_id'] ?? map['id'] ?? '').toString();
    }
    if (widget.doctor is Doctor) {
      return (widget.doctor as Doctor).id;
    }
    return '';
  }

  String get doctorName {
    if (widget.doctor is Map<String, dynamic>) {
      final map = widget.doctor as Map<String, dynamic>;
      return (map['fullName'] ?? map['name'] ?? 'Dr. Unknown').toString();
    }
    if (widget.doctor is Doctor) {
      return (widget.doctor as Doctor).name;
    }
    return 'Dr. Unknown';
  }

  @override
  void initState() {
    super.initState();
    // If doctor has weeklySchedule, we can show slots when date is selected
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF0D53C1)),
        ),
        child: child!,
      ),
    );

    if (picked != null && mounted) {
      setState(() {
        selectedDate = picked;
        selectedTimeSlot = null;
        availableSlots = [];
      });

      // Fetch available slots for selected date
      await _fetchAvailableSlots(picked);
    }
  }

  /// Fetch available time slots from backend or doctor's weeklySchedule
  Future<void> _fetchAvailableSlots(DateTime date) async {
    setState(() => _isLoadingSlots = true);

    try {
      // Option 1: Try backend API endpoint
      final response = await _fetchFromBackend(date);
      
      if (response != null && response['success'] == true) {
        final slotsData = response['data']['slots'] as List;
        setState(() {
          availableSlots = slotsData
              .map((slot) => TimeSlot.fromJson(slot))
              .toList();
        });
      } else {
        // Option 2: Fallback to doctor's weeklySchedule
        _loadFromWeeklySchedule(date);
      }
    } catch (e) {
      print('Error fetching slots: $e');
      // Fallback to weeklySchedule
      _loadFromWeeklySchedule(date);
    } finally {
      setState(() => _isLoadingSlots = false);
    }
  }

  /// Try to fetch from backend /available endpoint
  Future<Map<String, dynamic>?> _fetchFromBackend(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.appointments}/available'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'doctorId': doctorId,
          'date': DateFormat('yyyy-MM-dd').format(date),
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('Backend fetch error: $e');
    }
    return null;
  }

  /// Load slots from doctor's weeklySchedule
  void _loadFromWeeklySchedule(DateTime date) {
    final doctor = doctorObject;
    if (doctor?.weeklySchedule == null) {
      setState(() => availableSlots = []);
      return;
    }

    // Get day name (e.g., "monday", "tuesday")
    final dayNames = [
      'sunday',
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday'
    ];
    final dayName = dayNames[date.weekday % 7];

    // Find schedule for this day
    final daySchedule = doctor!.weeklySchedule!.firstWhere(
      (schedule) => schedule.day.toLowerCase() == dayName && schedule.isActive,
      orElse: () => WeeklySchedule(day: '', isActive: false, slots: []),
    );

    setState(() {
      availableSlots = daySchedule.slots;
    });
  }

  Future<void> _pickMedicalDocuments() async {
    final List<XFile>? picked = await _picker.pickMultiImage();
    if (picked != null && picked.isNotEmpty && mounted) {
      setState(() => _medicalDocuments.addAll(picked));
    }
  }

  Future<void> _pickPaymentScreenshot() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      setState(() => _paymentScreenshot = picked);
    }
  }

  Future<void> _submitAppointment() async {
    if (doctorId.isEmpty || doctorId.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid Doctor – Cannot book appointment'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedDate == null || selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.appointments}'),
      );

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      String backendType = selectedType == "Physical Visit" ? "physical" : "video";

      request.fields.addAll({
        'doctorId': doctorId,
        'appointmentType': backendType,
        'date': DateFormat('yyyy-MM-dd').format(selectedDate!),
        'time': selectedTimeSlot!.start, // Send start time
        'symptoms': _symptomsController.text.trim(),
      });

      for (var file in _medicalDocuments) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'medicalDocuments',
            file.path,
            filename: file.name,
          ),
        );
      }

      if (selectedType == "Video Call") {
        if (_paymentScreenshot == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment screenshot required for Video Call'),
            ),
          );
          setState(() => _isLoading = false);
          return;
        }
        request.files.add(
          await http.MultipartFile.fromPath(
            'paymentScreenshot',
            _paymentScreenshot!.path,
            filename: _paymentScreenshot!.name,
          ),
        );
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);
      final jsonResponse =
          response.body.isNotEmpty ? json.decode(response.body) : {};

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Appointment booked with Dr. $doctorName!'),
              backgroundColor: Colors.green,
            ),
          );
          context.read<AppointmentProvider>().fetchAppointments();
          Navigator.pop(context);
        }
      } else {
        String msg = jsonResponse['message'] ?? 'Booking failed';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

            // Appointment Type
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
                        'assets/icons/physical_visit.png',
                        "Physical Visit",
                        "Pay at Clinic",
                      ),
                      const SizedBox(width: 15),
                      _buildTypeOption(
                        'assets/icons/video_call.png',
                        "Video Call",
                        "Online Payment",
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Select Date
            _buildWhiteCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Select Date",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _selectDate,
                    child: Container(
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
                        children: [
                          Text(
                            selectedDate == null
                                ? "dd/mm/yyyy"
                                : DateFormat('dd/MM/yyyy').format(selectedDate!),
                            style: TextStyle(
                              color: selectedDate == null
                                  ? Colors.grey
                                  : Colors.black,
                              fontSize: 16,
                            ),
                          ),
                          const Icon(
                            Icons.calendar_month_outlined,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Available Time Slots
            if (selectedDate != null)
              _buildWhiteCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Available Time",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildTimeSlots(),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Symptoms
            _buildWhiteCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Describe your Symptoms",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildDashedInput(_symptomsController),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Medical Documents
            _buildWhiteCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Upload Medical Documents",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickMedicalDocuments,
                    child: _buildUploadBox(
                      Icons.cloud_upload_outlined,
                      "Tap to Upload image or PDF",
                    ),
                  ),
                  if (_medicalDocuments.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Wrap(
                        spacing: 8,
                        children: _medicalDocuments
                            .map((f) => Chip(label: Text(f.name)))
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payment Screenshot
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
                    GestureDetector(
                      onTap: _pickPaymentScreenshot,
                      child: _buildUploadBox(
                        Icons.cloud_upload_outlined,
                        "Tap to Upload Your Payment Screenshot",
                      ),
                    ),
                    if (_paymentScreenshot != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Chip(label: Text(_paymentScreenshot!.name)),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 30),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D53C1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
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

  Widget _buildWhiteCard({required Widget child}) => Container(
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
            )
          ],
        ),
        child: child,
      );

  Widget _buildTypeOption(String image, String title, String subtitle) {
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
              color: isSelected
                  ? const Color(0xFF0D53C1)
                  : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Image.asset(
                image,
                color: isSelected ? const Color(0xFF0D53C1) : Colors.black54,
                width: 30,
                height: 30,
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

  /// Time Slots Widget - Range-based design
  Widget _buildTimeSlots() {
    if (_isLoadingSlots) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (availableSlots.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.event_busy, size: 50, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'No available time slots for this date',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: availableSlots.map((slot) {
        return _buildTimeSlotCard(slot);
      }).toList(),
    );
  }

  Widget _buildTimeSlotCard(TimeSlot slot) {
    final isSelected = selectedTimeSlot?.start == slot.start &&
        selectedTimeSlot?.end == slot.end;
    final isDisabled = slot.isBooked == true;

    return GestureDetector(
      onTap: isDisabled ? null : () => setState(() => selectedTimeSlot = slot),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.grey[200]
              : (isSelected ? const Color(0xFF0D53C1) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDisabled
                ? Colors.grey[300]!
                : (isSelected ? const Color(0xFF0D53C1) : Colors.grey[300]!),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Start Time
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0D53C1)
                      : Colors.grey[400]!,
                ),
              ),
              child: Text(
                _format24To12Hour(slot.start),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDisabled
                      ? Colors.grey
                      : (isSelected ? const Color(0xFF0D53C1) : Colors.black),
                ),
              ),
            ),

            // "To" Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'To',
                style: TextStyle(
                  fontSize: 13,
                  color: isDisabled
                      ? Colors.grey
                      : (isSelected ? Colors.white : Colors.black54),
                ),
              ),
            ),

            // End Time
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0D53C1)
                      : Colors.grey[400]!,
                ),
              ),
              child: Text(
                _format24To12Hour(slot.end),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDisabled
                      ? Colors.grey
                      : (isSelected ? const Color(0xFF0D53C1) : Colors.black),
                ),
              ),
            ),

            // Booked Badge
            if (isDisabled) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Booked',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _format24To12Hour(String time24) {
    try {
      final parts = time24.split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);

      String period = hour >= 12 ? 'PM' : 'AM';
      int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return time24;
    }
  }

  Widget _buildDashedInput(TextEditingController controller) => Container(
        width: double.infinity,
        height: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FBFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: TextField(
          controller: controller,
          maxLines: null,
          decoration: const InputDecoration(
            hintText: "Please describe your symptoms in detail.....",
            hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
            border: InputBorder.none,
          ),
        ),
      );

  Widget _buildUploadBox(IconData icon, String label) => Container(
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