import 'package:flutter/material.dart';
import 'package:docmobi/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:docmobi/models/doctor_model.dart';
import 'package:docmobi/models/dependent_model.dart';
import 'package:docmobi/models/appointment_model.dart';
import 'package:docmobi/providers/appointment_provider.dart';
import 'package:docmobi/providers/dependent_provider.dart';
import 'package:docmobi/services/doctor_service.dart'; 
import 'package:docmobi/utils/api_config.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'dart:io';

import 'widgets/appointment_type_selector.dart';
import 'widgets/dependent_selector.dart';
import 'widgets/time_slot_grid.dart';
import 'widgets/medical_document_uploader.dart';
import 'widgets/symptoms_input.dart';
import 'widgets/date_selector.dart';

class BookAppointmentScreen extends StatefulWidget {
  final dynamic doctor;
  final bool isReschedule;
  final AppointmentModel? existingAppointment;

  const BookAppointmentScreen({
    super.key,
    required this.doctor,
    this.isReschedule = false,
    this.existingAppointment,
  });

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  String selectedType = "Physical Visit";
  DateTime? selectedDate;
  TimeSlot? selectedTimeSlot;
  DependentModel? selectedDependent;
  final TextEditingController _symptomsController = TextEditingController();

  final List<XFile> _medicalDocuments = [];
  XFile? _paymentScreenshot;

  bool _isLoading = false;
  bool _isLoadingSlots = false;
  List<TimeSlot> availableSlots = [];

  final ImagePicker _picker = ImagePicker();
  Doctor? _fetchedDoctor; 

  Doctor? get doctorObject {
    if (_fetchedDoctor != null) {
      return _fetchedDoctor; 
    }
    if (widget.doctor is Doctor) return widget.doctor as Doctor;
    if (widget.doctor is Map<String, dynamic>) {
      return Doctor.fromJson(widget.doctor as Map<String, dynamic>);
    }
    return null;
  }

  String get doctorId {
    debugPrint('🔍 Getting doctorId from: ${widget.doctor}');
    if (widget.doctor is Map<String, dynamic>) {
      final map = widget.doctor as Map<String, dynamic>;
      final id = (map['_id'] ?? map['id'] ?? '').toString();
      debugPrint('   -> Extracted ID (Map): $id');
      return id;
    }
    if (widget.doctor is Doctor) {
      final id = (widget.doctor as Doctor).id;
      debugPrint('   -> Extracted ID (Object): $id');
      return id;
    }
    debugPrint('   -> Extracted ID (Empty): Doctor type unknown');
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

    // ✅ Pre-fill data if reschedule mode
    if (widget.isReschedule && widget.existingAppointment != null) {
      // Chain the operations: Prefill -> [Fetch Doctor] -> Fetch Slots
      _initializeRescheduleFlow();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DependentProvider>().fetchDependents();
    });
  }

 
  Future<void> _initializeRescheduleFlow() async {
   
    _prefillStaticData();

    
    await _fetchFullDoctorDetails();

  
    if (selectedDate != null && mounted) {
      _fetchAvailableSlots(selectedDate!);
    }
  }


  void _prefillStaticData() {
    final appt = widget.existingAppointment!;

    // 1. Appointment Type
    if (appt.appointmentType?.toLowerCase() == 'video') {
      selectedType = "Video Call";
    } else {
      selectedType = "Physical Visit";
    }

    // 2. Symptoms
    if (appt.symptoms != null && appt.symptoms!.isNotEmpty) {
      _symptomsController.text = appt.symptoms!;
    }

    // 3. Date & Time Selection Logic
    selectedDate = appt.appointmentDate;

    // 4. Validate Video Selection against Doctor Settings
    final doc = doctorObject;
    if (doc != null &&
        !doc.isOnlineAppointmentAvailable &&
        selectedType == "Video Call") {
      debugPrint(
        '⚠️ Reschedule: Video Call disabled by doctor. Resetting to Physical Visit.',
      );
      selectedType = "Physical Visit";
    }

    debugPrint('   Date set to: $selectedDate');
  }

 
  Future<void> _fetchFullDoctorDetails() async {
    try {
      debugPrint(' Fetching full doctor details for: $doctorId');
      final service = DoctorService();
      final response = await service.getDoctorById(doctorId);

      if (response['success'] == true && mounted) {
        setState(() {
          _fetchedDoctor = Doctor.fromJson(response['data']);
          
          // NEW: If we just fetched settings and video is disabled, enforce it
          if (_fetchedDoctor != null && 
              !_fetchedDoctor!.isOnlineAppointmentAvailable && 
              selectedType == "Video Call") {
            selectedType = "Physical Visit";
          }
        });
        debugPrint(
          ' Full doctor details fetched. Has Schedule: ${_fetchedDoctor?.weeklySchedule?.isNotEmpty}',
        );
      }
    } catch (e) {
      debugPrint(' Failed to fetch full doctor details: $e');
    }
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
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
      await _fetchAvailableSlots(picked);
    }
  }

  Future<void> _fetchAvailableSlots(DateTime date) async {
    setState(() => _isLoadingSlots = true);

    try {
      final response = await _fetchFromBackend(date);

      if (response != null && response['success'] == true) {
        final slotsData = response['data']['slots'] as List;
        final unbookedSlots = slotsData
            .map((slot) => TimeSlot.fromJson(slot))
            .where((slot) => slot.isBooked != true)
            .toList();

        if (unbookedSlots.isEmpty) {
          debugPrint(
            ' Backend returned no slots, falling back to Weekly Schedule...',
          );
          _loadFromWeeklySchedule(date);
        } else {
          setState(() {
            availableSlots = unbookedSlots;
          });
        }
      } else {
        _loadFromWeeklySchedule(date);
      }
    } catch (e) {
      _loadFromWeeklySchedule(date);
    } finally {
      setState(() => _isLoadingSlots = false);
    }
  }

  Future<Map<String, dynamic>?> _fetchFromBackend(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http
          .post(
            Uri.parse(
              '${ApiConfig.baseUrl}${ApiConfig.appointments}/available',
            ),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: json.encode({
              'doctorId': doctorId,
              'date': DateFormat('yyyy-MM-dd').format(date),
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('Backend exception: $e');
    }
    return null;
  }

  void _loadFromWeeklySchedule(DateTime date) {
    final doctor = doctorObject;

    if (doctor == null ||
        doctor.weeklySchedule == null ||
        doctor.weeklySchedule!.isEmpty) {
      setState(() => availableSlots = []);
      return;
    }

    final dayName = _getDayName(date);
    WeeklySchedule? daySchedule;

    for (var schedule in doctor.weeklySchedule!) {
      if (schedule.day.toLowerCase() == dayName.toLowerCase() &&
          schedule.isActive) {
        daySchedule = schedule;
        break;
      }
    }

    if (daySchedule == null) {
      setState(() => availableSlots = []);
      return;
    }

    setState(() {
      availableSlots = daySchedule!.slots;
    });
  }

  String _getDayName(DateTime date) {
    const dayNames = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    return dayNames[date.weekday - 1];
  }

  Future<void> _pickMedicalDocuments() async {
    final List<XFile> picked = await _picker.pickMultiImage();
    if (picked.isNotEmpty && mounted) {
      setState(() => _medicalDocuments.addAll(picked));
    }
  }

  Future<void> _pickPaymentScreenshot() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      setState(() => _paymentScreenshot = picked);
    }
  }

  //  Handle both create and reschedule
  Future<void> _submitAppointment() async {
    if (doctorId.isEmpty || doctorId.length < 10) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.invalidDoctorBooking),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedDate == null || selectedTimeSlot == null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.selectDateTime)));
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (widget.isReschedule) {
        await _handleReschedule();
      } else {
        await _handleNewAppointment();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  //  Internal method to create appointment (Returns success status)
  Future<bool> _createAppointmentInternal() async {
    try {
      //  Prepare Request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.appointments}'),
      );

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      //  Prepare Data Payload
      String backendType = selectedType == "Physical Visit"
          ? "physical"
          : "video";

      Map<String, dynamic> bookedForPayload;
      if (selectedDependent == null) {
        bookedForPayload = {'type': 'self'};
      } else {
        bookedForPayload = {
          'type': 'dependent',
          'dependentId': selectedDependent!.id,
          'dependentName': selectedDependent!.fullName,
          'relationship': selectedDependent!.relationship,
        };
      }

      // Add Fields
      final fields = {
        'doctorId': doctorId,
        'appointmentType': backendType,
        'date': DateFormat('yyyy-MM-dd').format(selectedDate!),
        'time': selectedTimeSlot!.start,
        'symptoms': _symptomsController.text.trim(),
        'bookedFor': json.encode(bookedForPayload),
      };

      request.fields.addAll(fields);
      debugPrint('📤 Sending Appointment Fields: $fields');

      //  Compress & Add Medical Documents
      if (_medicalDocuments.isNotEmpty) {
        debugPrint(
          'Compressing ${_medicalDocuments.length} medical documents in parallel...',
        );

        final compressionFutures = _medicalDocuments.map(
          (file) => _compressImage(file.path),
        );
        final compressedFiles = await Future.wait(compressionFutures);

        for (var compressedFile in compressedFiles) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'medicalDocuments',
              compressedFile.path,
              filename: '${DateTime.now().millisecondsSinceEpoch}.jpg',
            ),
          );
        }
      }

      //  Compress & Add Payment Screenshot
      if (selectedType == "Video Call" && _paymentScreenshot != null) {
        debugPrint(' Compressing payment screenshot...');
        final compressedFile = await _compressImage(_paymentScreenshot!.path);
        request.files.add(
          await http.MultipartFile.fromPath(
            'paymentScreenshot',
            compressedFile.path,
            filename: 'payment_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );
      }

      // 6. Send Request
      debugPrint(' Sending Multipart Request...');
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );

      final response = await http.Response.fromStream(streamedResponse);
      debugPrint(' Response Code: ${response.statusCode}');
      debugPrint(' Response Body: ${response.body}');

      final jsonResponse = response.body.isNotEmpty
          ? json.decode(response.body)
          : {};

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Optimization: Trigger appointment fetch
        if (mounted) {
          context.read<AppointmentProvider>().fetchAppointments();
        }
        return true;
      } else {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          String msg =
              jsonResponse['message'] ??
              l10n?.bookingFailed ??
              'Booking failed';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.red),
          );
        }
        return false;
      }
    } catch (e) {
      debugPrint(' Booking Exception: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.rescheduleFailed(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  // Wrapper for New Appointment (original behavior)
  Future<void> _handleNewAppointment() async {
    final success = await _createAppointmentInternal();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.bookingSuccess),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  //  Reschedule Logic (Create NEW first, THEN Cancel old)
  Future<void> _handleReschedule() async {
    try {
      //  Create New Appointment First
      debugPrint(' Attempting to create new appointment for reschedule...');
      final success = await _createAppointmentInternal();

      if (!success) {
        debugPrint(
          'New appointment creation failed. Aborting cancel of old one.',
        );
        return; // Stop here. Old appointment remains active.
      }

      debugPrint(
        'New appointment created. Now cancelling old appointment...',
      );

      //  Cancel Old Appointment
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final cancelResponse = await http.patch(
        Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.appointments}/${widget.existingAppointment!.id}/status',
        ),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({'status': 'cancelled'}),
      );

      if (cancelResponse.statusCode < 200 || cancelResponse.statusCode >= 300) {
        debugPrint(
          ' Failed to cancel old appointment: ${cancelResponse.body}',
        );

        // Show WARNING message to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'New appointment booked, but failed to cancel the old one. Please cancel it manually.',
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          // Delay pop slightly so they see the message
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) Navigator.pop(context);
        }
        return;
      }

      // Success Path
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.bookingSuccess),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint(' Reschedule Exception: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.rescheduleFailed(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  //  Helper to compress images
  Future<File> _compressImage(String path) async {
    try {
      final String targetPath = '${path}_compressed.jpg';
      final XFile? result = await FlutterImageCompress.compressAndGetFile(
        path,
        targetPath,
        quality: 88, 
        minWidth: 2048, 
        minHeight: 2048,
      );

      if (result != null) {
        debugPrint(
          'Compressed: ${(await File(path).length()) / 1024}KB -> ${(await File(result.path).length()) / 1024}KB',
        );
        return File(result.path);
      }
    } catch (e) {
      debugPrint(' Compression failed: $e');
    }
    return File(path); // Fallback to original
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(0, 255, 255, 255),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isReschedule
              ? l10n.rescheduleAppointment
              : l10n.bookAppointment,
          style: const TextStyle(
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
            // Show reschedule info banner
            if (widget.isReschedule) ...[
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.rescheduleBanner,
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (selectedType == "Video Call")
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Center(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: "* ",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        TextSpan(
                          text: l10n.videoUploadWarning,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const TextSpan(
                          text: " *",
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

            AppointmentTypeSelector(
              title: l10n.appointmentTypeLabel,
              selectedType: selectedType,
              isVideoDisabled: doctorObject?.isOnlineAppointmentAvailable == false,
              onTypeSelected: (type) => setState(() => selectedType = type),
            ),
            const SizedBox(height: 16),

            Consumer<DependentProvider>(
              builder: (context, provider, child) {
                return DependentSelector(
                  title: l10n.bookAppointmentFor,
                  selectedDependent: selectedDependent,
                  dependents: provider.activeDependents,
                  onDependentSelected: (dep) =>
                      setState(() => selectedDependent = dep),
                  onAddNewDependent: () {
                    final provider = context.read<DependentProvider>();
                    Navigator.pushNamed(context, '/add-dependent').then((_) {
                      if (mounted) {
                        provider.fetchDependents();
                      }
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            DateSelector(selectedDate: selectedDate, onTap: _selectDate),
            const SizedBox(height: 16),

            if (selectedDate != null)
              TimeSlotGrid(
                title: l10n.availableTime,
                availableSlots: availableSlots,
                selectedTimeSlot: selectedTimeSlot,
                isLoading: _isLoadingSlots,
                onSlotSelected: (slot) =>
                    setState(() => selectedTimeSlot = slot),
              ),
            const SizedBox(height: 16),

            SymptomsInput(controller: _symptomsController),
            const SizedBox(height: 16),

            MedicalDocumentUploader(
              documents: _medicalDocuments,
              onPickDocuments: _pickMedicalDocuments,
              paymentScreenshot: _paymentScreenshot,
              onPickPayment: _pickPaymentScreenshot,
              showPaymentUpload: selectedType == "Video Call",
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? () {} : _submitAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D53C1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        widget.isReschedule
                            ? l10n.confirmReschedule
                            : l10n.submitAppointmentRequest,
                        style: const TextStyle(
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
}
