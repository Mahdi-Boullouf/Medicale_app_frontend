import 'package:docmobi/services/notification_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/push_notification_service.dart';
import '../services/callkit_service.dart';
import '../services/notification_api_service.dart';
import '../services/notification_poller.dart';

/// Notifier for the list of notifications
class NotificationListNotifier extends AsyncNotifier<List<NotificationModel>> {
  @override
  Future<List<NotificationModel>> build() async {
    // Register callback in poller to refresh this provider when new notifications arrive
    NotificationPoller().onNewNotifications = () {
      ref.invalidateSelf();
    };

    return _fetch();
  }

  Future<List<NotificationModel>> _fetch() async {
    // 1. Fetch latest from backend
    final backendNotifications = await NotificationApiService.getNotifications();

    // 2. Update the poller's internal state
    NotificationPoller().setPolledNotifications(backendNotifications);

    // 3. Return the filtered and merged results from the poller
    return NotificationPoller().allNotifications;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<void> markAsRead(String id) async {
    await NotificationPoller().markAsRead(id);
    await refresh();
  }

  Future<void> markAllAsRead() async {
    await NotificationPoller().markAllAsRead();
    await refresh();
  }

  Future<void> deleteNotification(String id) async {
    await NotificationPoller().deleteNotification(id);
    await refresh();
  }
}

/// Provider for the full list of notifications
final notificationListProvider =
    AsyncNotifierProvider<NotificationListNotifier, List<NotificationModel>>(
      () {
        return NotificationListNotifier();
      },
    );

/// Provider for the total unread count
final unreadCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationListProvider).value ?? [];
  return notifications.where((n) => !n.isRead).length;
});

/// Provider for general unread count (non-message)
final generalUnreadCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationListProvider).value ?? [];
  return notifications
      .where((n) => !n.isRead && n.type.toLowerCase() != 'message')
      .length;
});

/// Provider for message unread count
final messageUnreadCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationListProvider).value ?? [];
  return notifications
      .where((n) => !n.isRead && n.type.toLowerCase() == 'message')
      .length;
});

/// Provider for appointment unread count
final appointmentUnreadCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationListProvider).value ?? [];
  return notifications
      .where(
        (n) =>
            !n.isRead &&
            (n.type.toLowerCase().contains('appointment') ||
                n.type.toLowerCase() == 'doctor_signup' ||
                n.type.toLowerCase() == 'doctor_approved'),
      )
      .length;
});

// Logic to start polling - this can be called from main.dart or after login
final notificationPollingProvider = Provider<void>((ref) {
  final poller = NotificationPoller();

  // Start polling if not already started
  poller.startPolling();

  ref.onDispose(() {
    poller.stopPolling();
  });
});
