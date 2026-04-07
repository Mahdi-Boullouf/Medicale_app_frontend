import 'package:flutter/material.dart';
import 'package:docmobi/l10n/app_localizations.dart';

class AppointmentTypeSelector extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onTypeSelected;
  final String title;
  final bool isVideoDisabled;

  const AppointmentTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
    required this.title,
    this.isVideoDisabled = false,
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
          Row(
            children: [
              _buildTypeOption(
                context,
                'assets/icons/physical_visit.png',
                "Physical Visit",
                l10n.physicalVisit,
                l10n.payAtClinic,
                false,
              ),
              const SizedBox(width: 15),
              _buildTypeOption(
                context,
                'assets/icons/video_call.png',
                "Video Call",
                l10n.videoCall,
                isVideoDisabled
                    ? "UNAVAILABLE"
                    : l10n.onlinePayment,
                isVideoDisabled,
              ),
            ],
          ),
          if (isVideoDisabled) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange.shade900),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Video consultations are currently unavailable for this doctor.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  Widget _buildTypeOption(
    BuildContext context,
    String image,
    String typeKey,
    String displayTitle,
    String displaySubtitle,
    bool isDisabled,
  ) {
    bool isSelected = selectedType == typeKey;
    return Expanded(
      child: GestureDetector(
        onTap: isDisabled
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("This consultation type is currently unavailable."),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            : () => onTypeSelected(typeKey),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isDisabled ? Colors.grey.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF0D53C1)
                  : (isDisabled ? Colors.grey.shade200 : Colors.grey.shade300),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Opacity(
            opacity: isDisabled ? 0.5 : 1.0,
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
                  displayTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? const Color(0xFF0D53C1) : Colors.black87,
                  ),
                ),
                Text(
                  displaySubtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDisabled ? Colors.red.shade700 : Colors.grey,
                    fontWeight: isDisabled ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
