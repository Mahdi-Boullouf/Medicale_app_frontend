import 'package:docmobi/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:docmobi/models/notification_model.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;

  // Removed const to ensure rebuilds during debugging
  const NotificationCard({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor;

    switch (notification.type) {
      case 'appointment':
      case 'appointment_booked':
      case 'appointment_confirmed':
      case 'appointment_cancelled':
      case 'appointment_completed':
        icon = Icons.calendar_today;
        iconColor = Colors.green;
        break;
      case 'message':
        icon = Icons.message;
        iconColor = Colors.blue;
        break;
      case 'post_liked':
      case 'reel_liked':
        icon = Icons.favorite;
        iconColor = Colors.red;
        break;
      case 'post_commented':
      case 'reel_commented':
        icon = Icons.comment;
        iconColor = Colors.amber;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.orange;
    }

    // Direct access to context's localization
    final loc = AppLocalizations.of(context);

    // Default fallback to backend text
    String title = notification.title;
    String body = notification.message;

    if (loc != null) {
      switch (notification.type) {
        case 'appointment_booked':
          title = loc.notif_appointment_booked_title;
          body = loc.notif_appointment_booked_body;
          break;
        case 'appointment_confirmed':
          title = loc.notif_appointment_confirmed_title;
          body = loc.notif_appointment_confirmed_body;
          break;
        case 'appointment_cancelled':
          title = loc.notif_appointment_cancelled_title;
          body = loc.notif_appointment_cancelled_body;
          break;
        case 'appointment_completed':
          title = loc.notif_appointment_completed_title;
          body = loc.notif_appointment_completed_body;
          break;
        case 'post_liked':
          title = loc.notif_post_liked_title;
          body = loc.notif_post_liked_body;
          break;
        case 'post_commented':
          title = loc.notif_post_commented_title;
          body = loc.notif_post_commented_body;
          break;
        case 'reel_liked':
          title = loc.notif_reel_liked_title;
          body = loc.notif_reel_liked_body;
          break;
        case 'reel_commented':
          title = loc.notif_reel_commented_title;
          body = loc.notif_reel_commented_body;
          break;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : Colors.blue[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B3267),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  notification.time,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
