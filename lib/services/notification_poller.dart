import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationPoller {
  static final NotificationPoller _instance = NotificationPoller._internal();
  factory NotificationPoller() => _instance;
  NotificationPoller._internal();

  Timer? _pollingTimer;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // ValueNotifiers for separate unread counts (Keep for now to support legacy, but Riverpod will take over)
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);
  final ValueNotifier<int> generalUnreadCount = ValueNotifier<int>(0);
  final ValueNotifier<int> messageUnreadCount = ValueNotifier<int>(0);

  // Callback to notify Riverpod provider when new notifications arrive
  VoidCallback? onNewNotifications;

  // Local storage for notifications and deleted IDs
  List<NotificationModel> _localNotifications = [];
  Set<String> _deletedIds = {};
  List<NotificationModel> _polledNotifications = [];

  // Constants
  static const Duration _pollingInterval = Duration(seconds: 30);
  static const String _lastNotificationIdKey = 'last_notification_id';
  static const String _localNotificationsKey = 'local_notifications';
  static const String _deletedNotificationsKey = 'deleted_notifications';

  // Initialize local notifications
  Future<void> initialize() async {
    try {
      if (kDebugMode) {
        debugPrint('🔔 Initializing local notifications...');
      }

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
            defaultPresentAlert: true,
            defaultPresentBadge: true,
            defaultPresentSound: true,
          );

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize with timeout to prevent hanging
      final initializationFuture = _notificationsPlugin
          .initialize(
            settings,
            onDidReceiveNotificationResponse: _onNotificationTapped,
          )
          .timeout(const Duration(seconds: 10));

      final bool? initialized = await initializationFuture;

      if (initialized == true) {
        debugPrint('✅ Notifications initialized successfully');
      } else {
        debugPrint('⚠️ Notifications initialization returned null or false');
      }

      // Request notification permissions for Android 13+
      await _requestPermissions();

      // Load persistent local data
      await _loadPersistentData();
    } catch (e) {
      debugPrint('❌ Error initializing notifications: $e');
      // Don't rethrow - allow app to continue without notifications
    }
  }

  // Load local notifications and deleted IDs from SharedPreferences
  Future<void> _loadPersistentData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load local notifications
      final String? localJson = prefs.getString(_localNotificationsKey);
      if (localJson != null) {
        final List<dynamic> decoded = jsonDecode(localJson);
        _localNotifications = decoded
            .map((j) => NotificationModel.fromJson(j))
            .toList();
      }

      // Load deleted IDs
      final List<String>? deletedList = prefs.getStringList(
        _deletedNotificationsKey,
      );
      if (deletedList != null) {
        _deletedIds = deletedList.toSet();
      }

      _notifyUpdate();
    } catch (e) {
      debugPrint('Error loading persistent notification data: $e');
    }
  }

  // Save local notifications and deleted IDs to SharedPreferences
  Future<void> _savePersistentData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save local notifications
      final String localJson = jsonEncode(
        _localNotifications.map((n) => n.toJson()).toList(),
      );
      await prefs.setString(_localNotificationsKey, localJson);

      // Save deleted IDs
      await prefs.setStringList(_deletedNotificationsKey, _deletedIds.toList());
    } catch (e) {
      debugPrint('Error saving persistent notification data: $e');
    }
  }

  // Request notification permissions
  Future<void> _requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  // Start polling for notifications
  void startPolling() {
    stopPolling(); // Stop any existing polling
    _pollingTimer = Timer.periodic(
      _pollingInterval,
      (_) => _checkForNewNotifications(),
    );
  }

  // Stop polling for notifications
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  // Check for new notifications
  Future<void> _checkForNewNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastNotificationId = prefs.getString(_lastNotificationIdKey);

      // Get notifications from API Service
      final notifications = await NotificationService.getNotifications();
      _polledNotifications = notifications;

      if (notifications.isNotEmpty) {
        final latestNotification = notifications.first;

        // Check if this is a new notification
        if (lastNotificationId == null ||
            (latestNotification.id.isNotEmpty &&
                latestNotification.id != lastNotificationId)) {
          // Show notification for each new notification
          final newNotifications = lastNotificationId == null
              ? notifications
              : notifications
                    .takeWhile((n) => n.id != lastNotificationId)
                    .toList();

          for (final notification in newNotifications.reversed) {
            if (!notification.isRead &&
                !_deletedIds.contains(notification.id)) {
              await _showLocalNotification(notification);
            }
          }

          // Update last notification ID
          await prefs.setString(_lastNotificationIdKey, latestNotification.id);
        }
      }
      _notifyUpdate();

      // Trigger Riverpod refresh if callback is set
      onNewNotifications?.call();
    } catch (e) {
      debugPrint('Error checking for new notifications: $e');
    }
  }

  // Show local notification
  Future<void> _showLocalNotification(NotificationModel notification) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'docmobi_notifications',
            'DocMobi Notifications',
            channelDescription: 'Notifications from DocMobi app',
            importance: Importance.max,
            priority: Priority.max,
            enableVibration: true,
            playSound: true,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.message,
        platformDetails,
        payload: jsonEncode({'id': notification.id, 'type': notification.type}),
      );
    } catch (e) {
      debugPrint('❌ Error showing local notification: $e');
    }
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      final payload = jsonDecode(response.payload!);
      final String? id = payload['id'];
      final String? type = payload['type'];

      // Navigate based on notification type
      _handleNotificationTap(id, type);
    }
  }

  // Handle notification navigation based on type
  void _handleNotificationTap(String? id, String? type) {
    debugPrint('Notification tapped: id=$id, type=$type');
  }

  // Combined list of notifications (filtered and merged)
  List<NotificationModel> get allNotifications {
    final combined = [..._localNotifications, ..._polledNotifications];
    return combined.where((n) => !_deletedIds.contains(n.id)).toList();
  }

  // Update unread counts
  void _notifyUpdate() {
    final all = allNotifications.where((n) => !n.isRead);
    unreadCount.value = all.length;

    // Separate by type
    generalUnreadCount.value = all
        .where((n) => n.type.toLowerCase() != 'message')
        .length;
    messageUnreadCount.value = all
        .where((n) => n.type.toLowerCase() == 'message')
        .length;
  }

  // Add a local notification (triggered from UI)
  Future<void> addLocalNotification(NotificationModel notification) async {
    _localNotifications.insert(0, notification);
    await _savePersistentData();
    await _showLocalNotification(notification);
    _notifyUpdate();
  }

  // Update polled notifications from external source (like Riverpod)
  void setPolledNotifications(List<NotificationModel> notifications) {
    _polledNotifications = notifications;
    _notifyUpdate();
  }

  // Delete notification (locally and backend if applicable)
  Future<void> deleteNotification(String id) async {
    try {
      // 1. Mark as deleted locally so it immediately disappears from UI
      _deletedIds.add(id);
      _localNotifications.removeWhere((n) => n.id == id);
      await _savePersistentData();
      _notifyUpdate();

      // 2. Try to delete from backend if it's not a local-only notification
      // (We check _polledNotifications to see if it came from backend)
      final isBackend = _polledNotifications.any((n) => n.id == id);
      if (isBackend) {
        await NotificationService.deleteNotification(id);
      }
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  // Manually refresh notifications
  Future<void> refreshNotifications() async {
    await _checkForNewNotifications();
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      // If it's a local notification
      final localIndex = _localNotifications.indexWhere(
        (n) => n.id == notificationId,
      );
      if (localIndex != -1) {
        final n = _localNotifications[localIndex];
        _localNotifications[localIndex] = NotificationModel(
          id: n.id,
          title: n.title,
          message: n.message,
          time: n.time,
          type: n.type,
          isRead: true,
        );
        await _savePersistentData();
        _notifyUpdate();
        return;
      }

      // If it's a backend notification
      await NotificationService.markAsRead(notificationId);
      await refreshNotifications(); // Refresh to update unread count
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      // Mark local ones as read
      for (int i = 0; i < _localNotifications.length; i++) {
        final n = _localNotifications[i];
        if (!n.isRead) {
          _localNotifications[i] = NotificationModel(
            id: n.id,
            title: n.title,
            message: n.message,
            time: n.time,
            type: n.type,
            isRead: true,
          );
        }
      }
      await _savePersistentData();

      // Mark backend ones as read
      await NotificationService.markAllAsRead();
      await refreshNotifications(); // Refresh to update unread count
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  // Clear the last notification ID (for testing or logout)
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastNotificationIdKey);
    await prefs.remove(_localNotificationsKey);
    await prefs.remove(_deletedNotificationsKey);
    _localNotifications = [];
    _deletedIds = {};
    unreadCount.value = 0;
  }

  // Get current unread count
  int get currentUnreadCount => unreadCount.value;

  // Dispose resources
  void dispose() {
    stopPolling();
    unreadCount.dispose();
    generalUnreadCount.dispose();
    messageUnreadCount.dispose();
  }
}
