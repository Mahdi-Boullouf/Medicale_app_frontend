import 'package:docmobi/services/notification_api_service.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import '../services/push_notification_service.dart';
import '../services/callkit_service.dart';
import '../services/notification_api_service.dart';

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
        debugPrint(' Initializing local notifications...');
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
          .timeout(const Duration(seconds: 40));

      final bool? initialized = await initializationFuture;

      if (initialized == true) {
        debugPrint(' Notifications initialized successfully');
      } else {
        debugPrint('Notifications initialization returned null or false');
      }

      // Request notification permissions for Android 13+
      await _requestPermissions();

      // Load persistent local data
      await _loadPersistentData();
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
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
      final notifications = await NotificationApiService.getNotifications();
      _polledNotifications = notifications;

      if (notifications.isNotEmpty) {
        // Find truly new notifications that we haven't shown yet
        // We check against:
        // 1. _deletedIds (user deleted them)
        // 2. _lastNotificationIdKey preference (persisted last seen ID)
        // 3. _polledNotifications previous state (in-memory check) - though we just overwrote it, we should check IDs.

        // Better approach:
        // Filter notifications that are:
        // - Newer than the saved lastNotificationId (if it exists)
        // - NOT read
        // - NOT deleted

        // If lastNotificationId is null, it might be first run.
        // But to avoid spamming ALL notifications on first login, maybe we only show the very latest one?
        // Or we trust the backend 'isRead' status.

        // Let's rely on 'isRead' and a local 'shown' tracking set to avoid re-alerting in the same session.
        // PROPOSAL: We iterate through unread notifications. If we haven't "seen" it in this session (or persisted "last alerted"), we show it.

        // HOWEVER, the current logic relies on `lastNotificationId`.
        // If the backend returns the SAME list, `latestNotification.id` will be the SAME as `lastNotificationId`.
        // So the `if` block `latestNotification.id != lastNotificationId` PREVENTS re-alerting for the same top notification.

        // ISSUE: User says "after a short while it comes again".
        // This implies `lastNotificationId` might be getting CLEARED or the ID is CHANGING.
        // Or maybe the list order flips?

        // Let's refine the logic to be more robust.

        final newUnreadNotifications = notifications.where((n) {
          // Must be unread
          if (n.isRead) return false;
          // Must not be deleted locally
          if (_deletedIds.contains(n.id)) return false;

          // Must not have been the 'latest' we already handled?
          // Actually, we want to know if we've explicitly notified for THIS specific ID.
          // The current code only tracks ONE 'lastNotificationId'.
          // If a newer one comes, we notify for all newer ones.
          // That seems okay, unless the "latest" one is somehow fluctuating or we are clearing prefs.

          return true;
        }).toList();

        if (newUnreadNotifications.isNotEmpty) {
          // Check if the VERY LATEST unread is different from what we last saw.
          // If it is the same, we do nothing (assuming we already notified for it and everything below it).

          // Exception: If the user explicitly wants to be nagged? Unlikely.

          final topNotification = newUnreadNotifications
              .first; // Assumes backend sorts by date desc

          if (lastNotificationId != topNotification.id) {
            // It's a new top notification!
            // BE CAREFUL: If the user has 5 unread, and we just started the app, `lastNotificationId` might be null.
            // We don't want to blast 5 notifications. Maybe just the newest one?

            if (lastNotificationId == null) {
              // First run (or cleared data). Just notify the newest one to be safe, or sync silently.
              // User complaint: "comes again and again".
              // Fix: Only notify if we are SURE it is new.

              // Let's just update the ID and NOT show notification on first load to avoid spam?
              // Or show only the first one.
              await _showLocalNotification(topNotification);
            } else {
              // We have a previous ID. Find all notifications newer than that ID.
              // This assumes we can just iterate until we hit the old ID.
              for (final n in newUnreadNotifications) {
                if (n.id == lastNotificationId)
                  break; // Found the old one, stop.
                await _showLocalNotification(n);
              }
            }

            // Update the last seen ID to the NEW top one
            await prefs.setString(_lastNotificationIdKey, topNotification.id);
          }
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
        await NotificationApiService.deleteNotification(id);
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
      await NotificationApiService.markAsRead(notificationId);
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
      await NotificationApiService.markAllAsRead();
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
