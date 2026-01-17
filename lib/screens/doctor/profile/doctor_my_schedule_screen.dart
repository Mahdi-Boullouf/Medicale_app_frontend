import 'package:flutter/material.dart';
import 'package:docmobi/services/doctor_schedule_service.dart';

class DoctorMyScheduleScreen extends StatefulWidget {
  const DoctorMyScheduleScreen({super.key});

  @override
  State<DoctorMyScheduleScreen> createState() => _DoctorMyScheduleScreenState();
}

class _DoctorMyScheduleScreenState extends State<DoctorMyScheduleScreen> {
  bool onlineAppointment = true;
  final TextEditingController _feesController = TextEditingController();
  final DoctorScheduleService _scheduleService = DoctorScheduleService();

  bool _isSaving = false;
  String selectedSlotKey = "";

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

  /// Generate next available time slot
  Map<String, String> _generateNextSlot(List slots) {
    if (slots.isEmpty) {
      return {'start': '10:00 Am', 'end': '10:30 Am'};
    }

    // Get last slot's end time
    final lastSlot = slots.last;
    final lastEndTime = lastSlot['end'];

    // Parse the time
    final parts = lastEndTime.split(' ');
    final time = parts[0];
    final period = parts[1];

    final timeParts = time.split(':');
    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1]);

    // Add 1 minute to get next start time
    minute += 1;
    if (minute >= 60) {
      minute = 0;
      hour += 1;
      if (hour > 12) {
        hour = 1;
      }
    }

    String nextStartTime = '$hour:${minute.toString().padLeft(2, '0')} $period';

    // Calculate end time (30 minutes later)
    int endMinute = minute + 29;
    int endHour = hour;
    if (endMinute >= 60) {
      endMinute -= 60;
      endHour += 1;
      if (endHour > 12) {
        endHour = 1;
      }
    }

    String nextEndTime = '$endHour:${endMinute.toString().padLeft(2, '0')} $period';

    return {'start': nextStartTime, 'end': nextEndTime};
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
                
                if (backendDay['slots'] != null && (backendDay['slots'] as List).isNotEmpty) {
                  scheduleData[i]['slots'] = (backendDay['slots'] as List)
                      .map((slot) => {
                            'start': _convert24To12Hour(slot['start']),
                            'end': _convert24To12Hour(slot['end']),
                          })
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
    _showSnackBar('Please enter consultation fees', Colors.orange);
    return;
  }

  setState(() => _isSaving = true);

  try {
    print('📤 Saving doctor schedule...');
    print('   - Video Call Available: $onlineAppointment'); // ✅ Log this
    
    final List<Map<String, dynamic>> formattedSchedule = scheduleData.map((dayData) {
      final dayName = (dayData['day'] as String).toLowerCase();
      final isActive = dayData['enabled'] as bool;
      
      return {
        'day': dayName,  
        'isActive': isActive,
        'slots': (dayData['slots'] as List).map((slot) {
          final start24 = _convertTo24Hour(slot['start']);
          final end24 = _convertTo24Hour(slot['end']);
          return {
            'start': start24,
            'end': end24,
          };
        }).toList(),
      };
    }).toList();

    final fees = {
      'amount': double.tryParse(_feesController.text) ?? 0,
      'currency': 'USD',
    };

    // ✅ IMPORTANT: Pass isVideoCallAvailable
    final response = await _scheduleService.saveWeeklySchedule(
      weeklySchedule: formattedSchedule,
      fees: fees,
      isVideoCallAvailable: onlineAppointment, // ✅ This is the fix!
    );

    if (mounted) {
      if (response['success'] == true) {
        print('✅ Schedule saved successfully!');
        print('   - isVideoCallAvailable saved as: $onlineAppointment');
        _showSnackBar('Schedule saved successfully!', Colors.green);
      } else {
        print('❌ Save failed: ${response['message']}');
        _showSnackBar(response['message'] ?? 'Failed to save', Colors.red);
      }
    }
  } catch (e) {
    print('❌ Error saving schedule: $e');
    if (mounted) {
      _showSnackBar('Error: $e', Colors.red);
    }
  } finally {
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }
}
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
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
      print('Error converting to 24h: $time12 - $e');
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
        title: const Text(
          'Appointment Setting',
          style: TextStyle(
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
            const Text(
              'Manage your Video and physical\nConsultations',
              style: TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 14),
            ),
            const SizedBox(height: 20),

            // Online Appointment Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE9F0FF),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.video_call_outlined,
                      color: Color(0xFF1B2C49),
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Expanded(
                    child: Text(
                      'Online Appointment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1B2C49),
                      ),
                    ),
                  ),
                  Switch(
                    value: onlineAppointment,
                    activeThumbColor: const Color(0xFF6C63FF),
                    onChanged: (val) => setState(() => onlineAppointment = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Fees Input
            const Text(
              'Consultation Fees (USD)',
              style: TextStyle(
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
                prefixText: '\$ ',
                suffixText: 'USD',
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

            Row(
              children: const [
                Icon(Icons.access_time_filled, color: Color(0xFF3B71FE)),
                SizedBox(width: 10),
                Text(
                  'Weekly Schedule',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B2C49),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Schedule List
            ...scheduleData
                .asMap()
                .entries
                .map((entry) => _buildDayItem(entry.value, entry.key)),

            const SizedBox(height: 20),

            // Save Changes Button
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
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
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
            // Time Slots
            ...data['slots'].asMap().entries.map<Widget>((slotEntry) {
              int slotIndex = slotEntry.key;
              var slot = slotEntry.value;
              String slotKey = "${data['day']}_$slotIndex";
              bool isSelected = selectedSlotKey == slotKey;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
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
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF1664CD) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF1664CD) : const Color(0xFFE9F0FF),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                slot['start'],
                                style: TextStyle(
                                  color: isSelected ? Colors.white : const Color(0xFF1B2C49),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                child: Text(
                                  'To',
                                  style: TextStyle(
                                    color: isSelected ? Colors.white70 : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                slot['end'],
                                style: TextStyle(
                                  color: isSelected ? Colors.white : const Color(0xFF1B2C49),
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
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () {
                        setState(() {
                          data['slots'].removeAt(slotIndex);
                        });
                      },
                    ),
                  ],
                ),
              );
            }).toList(),

            TextButton.icon(
              onPressed: () {
                setState(() {
                  final nextSlot = _generateNextSlot(data['slots']);
                  data['slots'].add(nextSlot);
                });
              },
              icon: const Icon(
                Icons.add_circle_outline,
                size: 20,
                color: Color(0xFF3B71FE),
              ),
              label: const Text(
                'Add New Slot',
                style: TextStyle(
                  color: Color(0xFF3B71FE),
                  fontWeight: FontWeight.bold,
                ),
              ),
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
    super.dispose();
  }
}