import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:docmobi/l10n/app_localizations.dart';

// Replace these IDs with real YouTube video IDs when available
const _doctorVideoId = 'DOCTOR_VIDEO_ID';
const _patientVideoId = 'PATIENT_VIDEO_ID';

class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});

  Future<void> _openYouTube(BuildContext context, String videoId) async {
    final appUrl = Uri.parse('youtube://www.youtube.com/watch?v=$videoId');
    final webUrl = Uri.parse('https://www.youtube.com/watch?v=$videoId');
    if (await canLaunchUrl(appUrl)) {
      await launchUrl(appUrl);
    } else {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.howItWorks,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.howItWorksSubtitle,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            _VideoCard(
              videoId: _doctorVideoId,
              title: l10n.doctorTutorialTitle,
              description: l10n.doctorTutorialDesc,
              accentColor: const Color(0xFF1664CD),
              icon: Icons.medical_services_outlined,
              onTap: () => _openYouTube(context, _doctorVideoId),
            ),
            const SizedBox(height: 20),
            _VideoCard(
              videoId: _patientVideoId,
              title: l10n.patientTutorialTitle,
              description: l10n.patientTutorialDesc,
              accentColor: const Color(0xFF0B9B5E),
              icon: Icons.person_outline,
              onTap: () => _openYouTube(context, _patientVideoId),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final String videoId;
  final String title;
  final String description;
  final Color accentColor;
  final IconData icon;
  final VoidCallback onTap;

  const _VideoCard({
    required this.videoId,
    required this.title,
    required this.description,
    required this.accentColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final thumbnailUrl =
        'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with play button overlay
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    thumbnailUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context2, error, stack) => Container(
                      height: 200,
                      color: accentColor.withValues(alpha: 0.1),
                      child: Icon(
                        icon,
                        size: 60,
                        color: accentColor.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ],
              ),
            ),
            // Info section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, size: 18, color: accentColor),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B2C49),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.play_circle_outline,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.watchVideo,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
