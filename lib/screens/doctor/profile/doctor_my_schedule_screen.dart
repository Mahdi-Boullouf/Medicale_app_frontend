import 'package:flutter/material.dart';
import 'package:docmobi/services/doctor_schedule_service.dart';
import 'package:docmobi/l10n/app_localizations.dart';

class DoctorMyScheduleScreen extends StatefulWidget {
  const DoctorMyScheduleScreen({super.key});

  @override
  State<DoctorMyScheduleScreen> createState() => _DoctorMyScheduleScreenState();
}

class _DoctorMyScheduleScreenState extends State<DoctorMyScheduleScreen> {
  bool onlineAppointment = true;
  bool _initialOnlineAppointmentValue = true;
  bool _hasUnsavedChanges = false;
  final TextEditingController _feesController = TextEditingController();
  final DoctorScheduleService _scheduleService = DoctorScheduleService();

  bool _isSaving = false;
  String selectedSlotKey = "";
  int _sessionDurationMinutes = 10;
  final TextEditingController _durationController = TextEditingController(text: '10');

  final List<Map<String, dynamic>> scheduleData = [
    {'day': 'Monday', 'enabled': false, 'slots': []},
    {'day': 'Tuesday', 'enabled': false, 'slots': []},
    {'day': 'Wednesday', 'enabled': false, 'slots': []},
    {'day': 'Thursday', 'enabled': false, 'slots': []},
    {'day': 'Friday', 'enabled': false, 'slots': []},
    {'day': 'Saturday', 'enabled': false, 'slots': []},
    {'day': 'Sunday', 'enabled': false, 'slots': []},
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingSchedule();
  }

  /// Show time picker dialog to select time
  Future<String?> _selectTime(
    BuildContext context, {
    String? initialTime,
  }) async {
    TimeOfDay initialTimeOfDay;
    if (initialTime != null) {
      // Parse initial time if provided
      final parts = initialTime.trim().split(' ');
      if (parts.length == 2) {
        final time = parts[0];
        final period = parts[1].toLowerCase();
        final timeParts = time.split(':');
        if (timeParts.length == 2) {
          int hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          if (period == 'pm' && hour < 12) hour += 12;
          if (period == 'am' && hour == 12) hour = 0;
          initialTimeOfDay = TimeOfDay(hour: hour, minute: minute);
        } else {
          initialTimeOfDay = TimeOfDay.now();
        }
      } else {
        initialTimeOfDay = TimeOfDay.now();
      }
    } else {
      initialTimeOfDay = TimeOfDay.now();
    }
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTimeOfDay,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    if (picked != null) {
      // Convert TimeOfDay to 12-hour format
      int hour = picked.hour;
      final minute = picked.minute;
      final period = hour >= 12 ? 'Pm' : 'Am';

      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;

      return '$hour:${minute.toString().padLeft(2, '0')} $period';
    }

    return null;
  }

  /// Add new time slot with dynamic time selection
  Future<void> _addNewTimeSlot(Map<String, dynamic> dayData) async {
    final l10n = AppLocalizations.of(context)!;

    // Show info dialog and select start time
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            l10n.selectStartTime,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B2C49),
            ),
          ),
          content: Text(l10n.selectTimeFromPicker),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.ok,
                style: const TextStyle(color: Color(0xFF2D5AF0)),
              ),
            ),
          ],
        );
      },
    );
    if (!mounted) return;

    final startTime = await _selectTime(context);
    if (startTime == null) return;

    // Show info dialog and select end time
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            l10n.selectEndTime,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B2C49),
            ),
          ),
          content: Text(l10n.selectTimeFromPicker),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.ok,
                style: const TextStyle(color: Color(0xFF2D5AF0)),
              ),
            ),
          ],
        );
      },
    );
    if (!mounted) return;

    final endTime = await _selectTime(context, initialTime: startTime);
    if (endTime == null) return;

    // Validate if end time is after start time
    final start24 = _convertTo24Hour(startTime);
    final end24 = _convertTo24Hour(endTime);

    if (start24.compareTo(end24) >= 0) {
      _showSnackBar(l10n.endTimeError, Colors.red);
      return;
    }

    setState(() {
      dayData['slots'].add({'start': startTime, 'end': endTime});
    });
  }

  /// Add multiple slots by selecting a range (generates 10-min intervals)
  Future<void> _addHourSlots(Map<String, dynamic> dayData) async {
    final l10n = AppLocalizations.of(context)!;

    // Info dialog
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Add Hour Range",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B2C49),
            ),
          ),
          content: Text(
            "Select a start and end time. $_sessionDurationMinutes-minute slots will be generated automatically for this range.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.ok,
                style: const TextStyle(color: Color(0xFF2D5AF0)),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    final startTime = await _selectTime(context);
    if (startTime == null) return;

    if (!mounted) return;
    final endTime = await _selectTime(context, initialTime: startTime);
    if (endTime == null) return;

    final startMinutes = _timeToMinutes(startTime);
    final endMinutes = _timeToMinutes(endTime);

    if (startMinutes >= endMinutes) {
      _showSnackBar(l10n.endTimeError, Colors.red);
      return;
    }

    int current = startMinutes;
    int count = 0;

    setState(() {
      while (current + _sessionDurationMinutes <= endMinutes) {
        final s = _minutesToTime12(current);
        final e = _minutesToTime12(current + _sessionDurationMinutes);

        // Check if slot already exists to avoid duplicates
        bool exists = (dayData['slots'] as List).any(
          (slot) => slot['start'] == s && slot['end'] == e,
        );

        if (!exists) {
          dayData['slots'].add({'start': s, 'end': e});
          count++;
        }
        current += _sessionDurationMinutes;
      }

      // Sort slots chronologically
      if (count > 0) {
        (dayData['slots'] as List).sort((a, b) {
          final aMin = _timeToMinutes(a['start']);
          final bMin = _timeToMinutes(b['start']);
          return aMin.compareTo(bMin);
        });
      }
    });

    if (count > 0) {
      _showSnackBar("Generated $count new slots", Colors.green);
    } else {
      _showSnackBar("No new slots added (already exist)", Colors.orange);
    }
  }

  int _timeToMinutes(String time12) {
    try {
      final parts = time12.trim().split(' ');
      if (parts.length != 2) return 0;
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      final period = parts[1].toLowerCase();

      if (period == 'pm' && hour < 12) hour += 12;
      if (period == 'am' && hour == 12) hour = 0;

      return hour * 60 + minute;
    } catch (e) {
      return 0;
    }
  }

  String _minutesToTime12(int totalMinutes) {
    int hour = (totalMinutes ~/ 60) % 24;
    int minute = totalMinutes % 60;
    final period = hour >= 12 ? 'Pm' : 'Am';

    int displayHour = hour;
    if (displayHour > 12) displayHour -= 12;
    if (displayHour == 0) displayHour = 12;

    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  /// Load doctor's existing schedule from backend
  Future<void> _loadExistingSchedule() async {
    try {
      final response = await _scheduleService.getMySchedule();

      if (response['success'] == true && response['data'] != null) {
        final userData = response['data'];

        // Load fees
        if (userData['fees'] != null && userData['fees']['amount'] != null) {
          setState(() {
            _feesController.text = userData['fees']['amount'].toString();
          });
        }

        //  Load video call availability (onlineAppointment)
        bool? isOnlineAppt =
            userData['isOnlineAppointmentAvailable'] ??
            userData['isVideoCallAvailable'] ??
            userData['isVideoAvailable'] ??
            userData['isAvailable'] ??
            (userData['video']?['isAvailable']);

        if (isOnlineAppt != null) {
          setState(() {
            onlineAppointment = isOnlineAppt;
            _initialOnlineAppointmentValue = isOnlineAppt;
          });
          debugPrint(
            'Loaded online appointment availability: $onlineAppointment',
          );
        }

        // Load weeklySchedule
        if (userData['weeklySchedule'] != null) {
          final backendSchedule = userData['weeklySchedule'] as List;

          setState(() {
            for (var i = 0; i < scheduleData.length; i++) {
              final dayName = scheduleData[i]['day'].toString().toLowerCase();

              final backendDay = backendSchedule.firstWhere(
                (day) => day['day'].toString().toLowerCase() == dayName,
                orElse: () => null,
              );

              if (backendDay != null) {
                scheduleData[i]['enabled'] = backendDay['isActive'] ?? false;

                if (backendDay['slots'] != null &&
                    (backendDay['slots'] as List).isNotEmpty) {
                  scheduleData[i]['slots'] = (backendDay['slots'] as List)
                      .map(
                        (slot) => {
                          'start': _convert24To12Hour(slot['start']),
                          'end': _convert24To12Hour(slot['end']),
                        },
                      )
                      .toList();
                }
              }
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading schedule: $e');
    }
  }

  /// Save schedule to backend
  Future<void> _saveSchedule() async {
    if (_feesController.text.isEmpty) {
      _showSnackBar(
        AppLocalizations.of(context)!.enterConsultationFees,
        Colors.orange,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      debugPrint(' Saving doctor schedule...');
      debugPrint('   - Video Call Available: $onlineAppointment');

      final List<Map<String, dynamic>> formattedSchedule = scheduleData.map((
        dayData,
      ) {
        final dayName = (dayData['day'] as String).toLowerCase();
        final isActive = dayData['enabled'] as bool;

        return {
          'day': dayName,
          'isActive': isActive,
          'slots': (dayData['slots'] as List).map((slot) {
            final start24 = _convertTo24Hour(slot['start']);
            final end24 = _convertTo24Hour(slot['end']);
            return {'start': start24, 'end': end24};
          }).toList(),
        };
      }).toList();

      final fees = {
        'amount': double.tryParse(_feesController.text) ?? 0,
        'currency': 'USD',
      };

      //  IMPORTANT: Pass isOnlineAppointmentAvailable
      final response = await _scheduleService.saveWeeklySchedule(
        weeklySchedule: formattedSchedule,
        fees: fees,
        isVideoCallAvailable:
            true, // Keep video calls enabled by default when saving schedule?
        // Actually we should fetch current value.
        isOnlineAppointmentAvailable: onlineAppointment,
      );

      if (mounted) {
        if (response['success'] == true) {
          debugPrint(' Schedule saved successfully!');
          debugPrint('   - isVideoCallAvailable saved as: $onlineAppointment');
          debugPrint('   - Response data: ${response['data']}');

          //  Enhanced success message with online appointment status
          final statusText = onlineAppointment ? 'Enabled ✓' : 'Disabled ✗';
          _showSnackBar(
            '${AppLocalizations.of(context)!.scheduleSavedSuccess}\nOnline Appointment: $statusText',
            Colors.green,
            duration: const Duration(seconds: 4),
          );

          // Reset unsaved changes flag
          setState(() {
            _hasUnsavedChanges = false;
            _initialOnlineAppointmentValue = onlineAppointment;
          });
        } else {
          debugPrint('❌ Save failed: ${response['message']}');
          _showSnackBar(response['message'] ?? 'Failed to save', Colors.red);
        }
      }
    } catch (e) {
      debugPrint('❌ Error saving schedule: $e');
      if (mounted) {
        _showSnackBar('Error: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnackBar(
    String message,
    Color color, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: duration,
      ),
    );
  }

  /// Convert 12-hour format to 24-hour format
  String _convertTo24Hour(String time12) {
    try {
      final cleaned = time12.trim();
      final parts = cleaned.split(' ');
      if (parts.length != 2) return "00:00";

      final time = parts[0];
      final period = parts[1].toLowerCase();

      final timeParts = time.split(':');
      if (timeParts.length != 2) return "00:00";

      int hour = int.parse(timeParts[0]);
      final minute = timeParts[1];

      if (period == 'pm' && hour < 12) hour += 12;
      if (period == 'am' && hour == 12) hour = 0;

      return "${hour.toString().padLeft(2, '0')}:$minute";
    } catch (e) {
      debugPrint('Error converting to 24h: $time12 - $e');
      return "00:00";
    }
  }

  /// Convert 24-hour to 12-hour format
  String _convert24To12Hour(String time24) {
    try {
      final parts = time24.split(':');
      int hour = int.parse(parts[0]);
      final minute = parts[1];

      final period = hour >= 12 ? 'Pm' : 'Am';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;

      return '$hour:$minute $period';
    } catch (e) {
      return time24;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(0, 255, 255, 255),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B2C49)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.appointmentSetting,
          style: const TextStyle(
            color: Color(0xFF1B2C49),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.manageConsultations,
              style: const TextStyle(
                color: Color.fromARGB(255, 0, 0, 0),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),

            // Online Appointment Toggle
            // Container(
            //   padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            //   decoration: BoxDecoration(
            //     color: const Color(0xFFE9F0FF),
            //     borderRadius: BorderRadius.circular(15),
            //   ),
            //   child: Row(
            //     children: [
            //       Container(
            //         padding: const EdgeInsets.all(8),
            //         decoration: const BoxDecoration(
            //           color: Colors.white,
            //           shape: BoxShape.circle,
            //         ),
            //         child: const Icon(
            //           Icons.video_call_outlined,
            //           color: Color(0xFF1B2C49),
            //         ),
            //       ),
            //       const SizedBox(width: 15),
            //       Expanded(
            //         child: Column(
            //           crossAxisAlignment: CrossAxisAlignment.start,
            //           children: [
            //             Text(
            //               AppLocalizations.of(context)!.onlineAppointment,
            //               style: const TextStyle(
            //                 fontSize: 16,
            //                 fontWeight: FontWeight.bold,
            //                 color: Color(0xFF1B2C49),
            //               ),
            //             ),
            //             const Text(
            //               'If disabled, patients cannot book video appointments.',
            //               style: TextStyle(fontSize: 11, color: Colors.grey),
            //             ),
            //           ],
            //         ),
            //       ),
            //       Switch(
            //         value: onlineAppointment,
            //         activeThumbColor: const Color(0xFF6C63FF),
            //         onChanged: (val) {
            //           setState(() {
            //             onlineAppointment = val;
            //             //  Mark as unsaved if value changed from initial
            //             _hasUnsavedChanges =
            //                 (val != _initialOnlineAppointmentValue) ||
            //                 _feesController.text.isNotEmpty;
            //           });
            //           debugPrint(
            //             ' Online appointment changed to: $val (unsaved)',
            //           );
            //         },
            //       ),
            //     ],
            //   ),
            // ),
            // const SizedBox(height: 20),

            // Fees Input
            Text(
              AppLocalizations.of(context)!.consultationFees,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B2C49),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _feesController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'e.g. 50',
                prefixIcon: Image.asset(
                  'assets/images/dzd.png',
                  width: 10,
                  height: 10,
                ),
                suffixText: 'DZD',
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE9F0FF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF6C63FF),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),

            // Session Duration
            Text(
              'Session Duration',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B2C49),
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final preset in [10, 15, 20, 30, 45, 60])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('${preset}m'),
                        selected: _sessionDurationMinutes == preset,
                        selectedColor: const Color(0xFF1664CD),
                        labelStyle: TextStyle(
                          color: _sessionDurationMinutes == preset
                              ? Colors.white
                              : const Color(0xFF1B2C49),
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) {
                          setState(() {
                            _sessionDurationMinutes = preset;
                            _durationController.text = preset.toString();
                          });
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '1–60',
                      suffixText: 'min',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE9F0FF)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF6C63FF),
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (val) {
                      final parsed = int.tryParse(val);
                      if (parsed != null && parsed >= 1 && parsed <= 60) {
                        setState(() => _sessionDurationMinutes = parsed);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Used when auto-generating slots',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 25),

            Row(
              children: [
                const Icon(Icons.access_time_filled, color: Color(0xFF3B71FE)),
                const SizedBox(width: 10),
                Text(
                  AppLocalizations.of(context)!.weeklySchedule,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B2C49),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Schedule List
            ...scheduleData.asMap().entries.map(
              (entry) => _buildDayItem(entry.value, entry.key),
            ),

            const SizedBox(height: 20),

            // Save Changes Button
            // Unsaved changes indicator
            if (_hasUnsavedChanges)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You have unsaved changes. Don\'t forget to save!',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveSchedule,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1664CD),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        AppLocalizations.of(context)!.saveChanges,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayItem(Map<String, dynamic> data, int dayIndex) {
    bool isEnabled = data['enabled'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isEnabled
            ? const Color.fromARGB(255, 255, 255, 255)
            : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isEnabled ? const Color(0xFF3B71FE) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          // Day Selection
          InkWell(
            onTap: () {
              setState(() {
                scheduleData[dayIndex]['enabled'] =
                    !scheduleData[dayIndex]['enabled'];
              });
            },
            borderRadius: BorderRadius.circular(15),
            child: ListTile(
              horizontalTitleGap: 0,
              leading: Checkbox(
                value: isEnabled,
                activeColor: const Color(0xFF1B2C49),
                onChanged: (val) {
                  setState(() {
                    scheduleData[dayIndex]['enabled'] = val ?? false;
                  });
                },
              ),
              title: Text(
                data['day'],
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1B2C49),
                ),
              ),
            ),
          ),

          if (isEnabled) ...[
            const Divider(height: 1, color: Color(0xFFE9F0FF)),
            const SizedBox(height: 12),
            // Time Slots - Now scrollable with height limit
            if ((data['slots'] as List).isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: (data['slots'] as List).length,
                  padding: EdgeInsets.zero,
                  itemBuilder: (context, slotIndex) {
                    var slot = data['slots'][slotIndex];
                    String slotKey = "${data['day']}_$slotIndex";
                    bool isSelected = selectedSlotKey == slotKey;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 5,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  selectedSlotKey = slotKey;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF1664CD)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF1664CD)
                                        : const Color(0xFFE9F0FF),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      slot['start'],
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF1B2C49),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 15,
                                      ),
                                      child: Text(
                                        AppLocalizations.of(context)!.to,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white70
                                              : Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      slot['end'],
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF1B2C49),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            onPressed: () {
                              setState(() {
                                data['slots'].removeAt(slotIndex);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            Column(
              children: [
                TextButton.icon(
                  onPressed: () => _addNewTimeSlot(data),
                  icon: const Icon(
                    Icons.add_circle_outline,
                    size: 20,
                    color: Color(0xFF3B71FE),
                  ),
                  label: Text(
                    AppLocalizations.of(context)!.addNewSlot,
                    style: const TextStyle(
                      color: Color(0xFF3B71FE),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _addHourSlots(data),
                  icon: const Icon(
                    Icons.auto_awesome_outlined,
                    size: 20,
                    color: Color(0xFF1664CD),
                  ),
                  label: const Text(
                    "Add Hour",
                    style: TextStyle(
                      color: Color(0xFF1664CD),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _feesController.dispose();
    _durationController.dispose();
    super.dispose();
  }
}
