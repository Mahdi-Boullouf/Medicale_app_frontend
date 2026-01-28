import 'package:flutter/material.dart';
import 'package:docmobi/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primaryColor = const Color(0xFF0B3267);
    final accentColor = const Color(0xFF1664CD);
    final bgColor = const Color(0xFFF8FAFF);

    final faqs = [
      {
        'question': '1. How do I create an account?',
        'answer':
            'You can sign up as a patient or doctor by choosing your role and completing the registration steps in the app.',
      },
      {
        'question': '2. I forgot my password. What should I do?',
        'answer':
            'Go to the login screen and tap on “Forgot Password”. Follow the instructions to reset your password securely.',
      },
      {
        'question': '3. How can I book an appointment with a doctor?',
        'answer':
            'Search for a doctor or specialty, select an available time slot, and confirm your appointment.',
      },
      {
        'question': '4. Can I cancel or reschedule my appointment?',
        'answer':
            'Yes, you can cancel or reschedule appointments from the “My Appointments” section, depending on the appointment status.',
      },
      {
        'question': '5. How do online audio/video consultations work?',
        'answer':
            'Once your appointment is confirmed, you can start an audio or video call directly from the chat at the scheduled time (if enabled by the doctor).',
      },
      {
        'question': '6. Why can’t I start a call with the doctor?',
        'answer':
            'The doctor may have disabled audio/video calls temporarily. Please try again later or contact support.',
      },
      {
        'question': '7. How do I change the app language?',
        'answer':
            'You can change the language from the app settings at any time.',
      },
      {
        'question': '8. How can doctors manage their profile information?',
        'answer':
            'Doctors can edit their personal and professional information from the profile settings.',
      },
      {
        'question': '9. How does the referral system work?',
        'answer':
            'If referral codes are enabled, doctors can register using a valid referral code provided by the admin.',
      },
    ];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.helpSupport,
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Frequently Asked Questions (FAQ)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 15),
            ...faqs.map(
              (faq) => _buildFaqItem(
                faq['question']!,
                faq['answer']!,
                accentColor,
                primaryColor,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Still need help?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 15),
            _buildContactCard(
              icon: Icons.email_outlined,
              title: 'Email Us',
              subtitle: 'mydoctoralgerie@gmail.com',
              color: accentColor,
              onTap: () => _launchEmail('mydoctoralgerie@gmail.com'),
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              icon: Icons.phone_outlined,
              title: 'Call Us',
              subtitle: '0558585400',
              color: Colors.green,
              onTap: () => _launchPhone('0558585400'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(
    String question,
    String answer,
    Color accentColor,
    Color primaryColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
          iconColor: accentColor,
          collapsedIconColor: Colors.grey,
          childrenPadding: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16,
          ),
          children: [
            Text(
              answer,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B3267),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri params = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Help & Support Request',
    );
    if (await canLaunchUrl(params)) {
      await launchUrl(params);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri params = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(params)) {
      await launchUrl(params);
    }
  }
}
