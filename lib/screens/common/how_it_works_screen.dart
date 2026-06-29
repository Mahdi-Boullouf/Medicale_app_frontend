import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:docmobi/l10n/app_localizations.dart';
import 'package:docmobi/services/api_service.dart';

class HowItWorksScreen extends StatefulWidget {
  const HowItWorksScreen({super.key});

  @override
  State<HowItWorksScreen> createState() => _HowItWorksScreenState();
}

class _HowItWorksScreenState extends State<HowItWorksScreen> {
  bool _loading = true;
  String _patientUrl = '';
  String _doctorUrl = '';

  @override
  void initState() {
    super.initState();
    _loadLinks();
  }

  Future<void> _loadLinks() async {
    try {
      final res = await ApiService.getYoutubeLinks();
      if (res['success'] == true && res['data'] != null) {
        final data = res['data'];
        if (mounted) {
          setState(() {
            _patientUrl = (data['patientVideo'] ?? '').toString();
            _doctorUrl = (data['doctorVideo'] ?? '').toString();
            _loading = false;
          });
        }
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('Failed to load youtube links: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Extract the YouTube video id from common URL shapes so we can build a
  /// thumbnail. Returns null if it can't be parsed.
  String? _extractYouTubeId(String url) {
    if (url.isEmpty) return null;
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return null;
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }
    if (uri.queryParameters['v'] != null &&
        uri.queryParameters['v']!.isNotEmpty) {
      return uri.queryParameters['v'];
    }
    final segs = uri.pathSegments;
    final idx = segs.indexWhere((s) => s == 'shorts' || s == 'embed');
    if (idx != -1 && idx + 1 < segs.length) return segs[idx + 1];
    return null;
  }

  Future<void> _openVideo(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Failed to open video: $e');
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
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1664CD)),
            )
          : SingleChildScrollView(
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
                    videoId: _extractYouTubeId(_doctorUrl),
                    title: l10n.doctorTutorialTitle,
                    description: l10n.doctorTutorialDesc,
                    accentColor: const Color(0xFF1664CD),
                    icon: Icons.medical_services_outlined,
                    onTap: _doctorUrl.isEmpty ? null : () => _openVideo(_doctorUrl),
                  ),
                  const SizedBox(height: 20),
                  _VideoCard(
                    videoId: _extractYouTubeId(_patientUrl),
                    title: l10n.patientTutorialTitle,
                    description: l10n.patientTutorialDesc,
                    accentColor: const Color(0xFF0B9B5E),
                    icon: Icons.person_outline,
                    onTap: _patientUrl.isEmpty ? null : () => _openVideo(_patientUrl),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final String? videoId;
  final String title;
  final String description;
  final Color accentColor;
  final IconData icon;
  final VoidCallback? onTap;

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
    final bool available = onTap != null;
    final thumbnailUrl = videoId != null
        ? 'https://img.youtube.com/vi/$videoId/hqdefault.jpg'
        : null;
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
                  if (thumbnailUrl != null)
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
                    )
                  else
                    Container(
                      height: 200,
                      width: double.infinity,
                      color: accentColor.withValues(alpha: 0.1),
                      child: Icon(
                        icon,
                        size: 60,
                        color: accentColor.withValues(alpha: 0.4),
                      ),
                    ),
                  if (available)
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
                          color: available
                              ? accentColor
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              available
                                  ? Icons.play_circle_outline
                                  : Icons.hourglass_empty,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              available ? l10n.watchVideo : l10n.videoComingSoon,
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
