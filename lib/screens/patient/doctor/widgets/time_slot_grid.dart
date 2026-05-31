import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:docmobi/l10n/app_localizations.dart';
import 'package:docmobi/models/doctor_model.dart'; // Suggesting TimeSlot is here or appointment_model

class TimeSlotGrid extends StatelessWidget {
  final List<TimeSlot> availableSlots;
  final TimeSlot? selectedTimeSlot;
  final bool isLoading;
  final ValueChanged<TimeSlot> onSlotSelected;
  final String title;

  const TimeSlotGrid({
    super.key,
    required this.availableSlots,
    required this.selectedTimeSlot,
    required this.isLoading,
    required this.onSlotSelected,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _buildWhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (availableSlots.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.event_busy, size: 50, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      l10n.noTimeSlots,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 250),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: availableSlots
                      .map((slot) => _buildTimeSlotCard(context, slot))
                      .toList(),
                ),
              ),
            ),
        ],
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
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );

  Widget _buildTimeSlotCard(BuildContext context, TimeSlot slot) {
    final isSelected =
        selectedTimeSlot?.start == slot.start &&
        selectedTimeSlot?.end == slot.end;
    final isDisabled = slot.isBooked == true;

    return GestureDetector(
      onTap: isDisabled ? null : () => onSlotSelected(slot),
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
                _format12Hour(slot.start),
                style: TextStyle(
                  color: isSelected ? const Color(0xFF0D53C1) : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
            ),
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
                _format12Hour(slot.end),
                style: TextStyle(
                  color: isSelected ? const Color(0xFF0D53C1) : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            if (isDisabled)
              const Text(
                "Booked",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              )
            else if (isSelected)
              const Icon(Icons.check_circle, color: Colors.white),
          ],
        ),
      ),
    );
  }

  String _format12Hour(String time24) {
    try {
      final inputFormat = DateFormat('HH:mm');
      final outputFormat = DateFormat('h:mm a');
      final date = inputFormat.parse(time24);
      return outputFormat.format(date);
    } catch (e) {
      return time24;
    }
  }
}
