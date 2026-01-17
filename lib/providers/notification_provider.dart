import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_poller.dart';

class NotificationProvider extends ChangeNotifier {
  late final NotificationPoller _notificationPoller;

  NotificationProvider() {
    _notificationPoller = NotificationPoller();
  }

  // Expose unread counts ValueNotifiers
  ValueNotifier<int> get unreadCount => _notificationPoller.unreadCount;
  ValueNotifier<int> get generalUnreadCount =>
      _notificationPoller.generalUnreadCount;
  ValueNotifier<int> get messageUnreadCount =>
      _notificationPoller.messageUnreadCount;

  // Expose all notifications
  List<NotificationModel> get notifications =>
      _notificationPoller.allNotifications;

  // Listen to unread count changes
  void startListening() {
    _notificationPoller.unreadCount.addListener(_onUnreadCountChanged);
    _notificationPoller.generalUnreadCount.addListener(_onUnreadCountChanged);
    _notificationPoller.messageUnreadCount.addListener(_onUnreadCountChanged);
  }

  // Stop listening
  void stopListening() {
    _notificationPoller.unreadCount.removeListener(_onUnreadCountChanged);
    _notificationPoller.generalUnreadCount.removeListener(
      _onUnreadCountChanged,
    );
    _notificationPoller.messageUnreadCount.removeListener(
      _onUnreadCountChanged,
    );
  }

  // Handle unread count changes
  void _onUnreadCountChanged() {
    notifyListeners();
  }

  // Start notification polling
  Future<void> startPolling() async {
    try {
      await _notificationPoller.initialize();
      _notificationPoller.startPolling();
      startListening();
    } catch (e) {
      debugPrint('❌ Failed to start notification polling: $e');
      // Don't rethrow - allow app to continue without notifications
    }
  }

  // Stop notification polling
  Future<void> stopPolling() async {
    try {
      _notificationPoller.stopPolling();
      stopListening();
    } catch (e) {
      debugPrint('❌ Failed to stop notification polling: $e');
      // Don't rethrow - allow app to continue without notifications
    }
  }

  // Add a notification (manual/local)
  Future<void> addNotification({
    required String title,
    required String message,
    String type = 'general',
  }) async {
    final notification = NotificationModel(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      time: 'Just now', // Simplified for local
      type: type,
      isRead: false,
    );
    await _notificationPoller.addLocalNotification(notification);
    notifyListeners();
  }

  // Delete notification (local hide)
  Future<void> deleteNotification(String id) async {
    await _notificationPoller.deleteNotificationLocally(id);
    notifyListeners();
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationPoller.markAsRead(notificationId);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to mark notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await _notificationPoller.markAllAsRead();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to mark all notifications as read: $e');
    }
  }

  // Clear notifications (for testing or logout)
  Future<void> clearNotifications() async {
    try {
      await _notificationPoller.clearLastNotificationId();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to clear notifications: $e');
    }
  }

  @override
  void dispose() {
    stopPolling();
    _notificationPoller.dispose();
    super.dispose();
  }
}
