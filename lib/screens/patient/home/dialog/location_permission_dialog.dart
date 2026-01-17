import 'package:flutter/material.dart';

class LocationPermissionDialog extends StatelessWidget {
  // Add this variable
  final VoidCallback onDismiss;

  // Require it in the constructor
  const LocationPermissionDialog({super.key, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    const Color preciseBlue = Color(0xFF3366CC);
    const Color buttonBgColor = Color(0xFFD4E4F7);
    const Color buttonTextColor = Colors.black87;

    // Use Container instead of Dialog to fit your Stack implementation better
    return Center(
      child: Container(
        width: 319,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 32,
              color: preciseBlue,
            ),
            const SizedBox(height: 16),
            RichText(
              textAlign: TextAlign.center,
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 19,
                  color: Colors.black,
                  fontFamily: 'Roboto',
                  height: 1.3,
                ),
                children: [
                  TextSpan(text: 'Allow '),
                  TextSpan(
                    text: 'Maps',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: ' to access this device’s precise location?'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMapOption(
                  label: 'Precise',
                  isSelected: true,
                  color: preciseBlue,
                ),
                _buildMapOption(
                  label: 'Approximate',
                  isSelected: false,
                  color: Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Pass the onDismiss function to the buttons
            _buildActionButton(
              'While using the app',
              buttonBgColor,
              buttonTextColor,
            ),
            const SizedBox(height: 10),
            _buildActionButton(
              'Only this time',
              buttonBgColor,
              buttonTextColor,
            ),
            const SizedBox(height: 10),
            _buildActionButton('Don’t allow', buttonBgColor, buttonTextColor),
          ],
        ),
      ),
    );
  }

  // ... (Keep _buildMapOption helper same as before) ...
  Widget _buildMapOption({
    required String label,
    required bool isSelected,
    required Color color,
  }) {
    // ... same code ...
    return Column(
      children: [
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle,
            border: isSelected ? Border.all(color: color, width: 2) : null,
          ),
          child: isSelected
              ? Icon(Icons.location_on, color: color, size: 30)
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String text, Color bgColor, Color textColor) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        // CALL THE PASSED FUNCTION HERE INSTEAD OF NAVIGATOR
        onPressed: onDismiss,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
