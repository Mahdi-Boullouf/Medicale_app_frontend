import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/callkit_service.dart';
import '../screens/doctor/messages/doctor_chat_screen.dart';
import '../screens/patient/messages/patient_chat_screen.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  debugPrint(' [BACKGROUND ACTION] Action: ${notificationResponse.actionId}');
  if (notificationResponse.actionId == 'DECLINE_CALL') {
    debugPrint(' Call declined in background');
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('auth_token');

    if (authToken == null || authToken.isEmpty) {
      debugPrint(' [BACKGROUND] User not logged in — ignoring notification');
      return;
    }

    final data = message.data;
    debugPrint(' [BACKGROUND HANDLER] Raw Data: $data');

    if (data['type'] == 'incoming_call') {
      // ✅ iOS SAFETY CHECK: On iOS, VoIP pushes (APNs) natively handle CallKit UI.
      // Standard FCM data pushes for calls are redundant and cause "Ghost Screens" (Duplicate UI).
      if (Platform.isIOS) {
        debugPrint(' [BACKGROUND] Skipping FCM incoming call for iOS — VoIP (APNs) handles this.');
        return;
      }

      debugPrint(' [BACKGROUND] Incoming call detected!');
      try {
        await CallKitService.showCallKitIncoming(data);
        debugPrint('[BACKGROUND] CallKit displayed successfully');
      } catch (e) {
        debugPrint(' [BACKGROUND] CRITICAL Error showing CallKit: $e');
      }
      return;
    } else if (data['type'] == 'cancel_call') {
      debugPrint('[BACKGROUND] Call cancelled by caller.');
      try {
        final uuid = data['uuid'];
        if (uuid != null && uuid.toString().isNotEmpty) {
          await FlutterCallkitIncoming.endCall(uuid.toString());
        } else {
          await FlutterCallkitIncoming.endAllCalls();
        }
      } catch (e) {
        debugPrint('[BACKGROUND] Error ending calls: $e');
      }
      return;
    }
  } catch (e) {
    debugPrint('[BACKGROUND] Early parsing error: $e');
    return;
  }

  // Normal Priority: Standard notifications
  final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  await localNotifications.initialize(initializationSettings);

  final data = message.data;
  final String? title = message.notification?.title;
  final String? body = message.notification?.body;

  final String notificationTitle = title ?? data['userName'] ?? 'New Message';
  final String notificationBody = body ?? (data['type'] == 'image' ? '[Image]' : data['content'] ?? data['body'] ?? 'You have a new message');

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'docmobi_chat_notifications_v3',
    'Chat Notifications',
    channelDescription: 'Real-time message notifications',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
    playSound: true,
    enableVibration: true,
  );
  const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );
  const NotificationDetails details = NotificationDetails(android: androidDetails, iOS: iosDetails);

  try {
    await localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      notificationTitle,
      notificationBody,
      details,
      payload: jsonEncode(data),
    );
    debugPrint(' [BACKGROUND] Local notification displayed successfully');
  } catch (e) {
    debugPrint('[BACKGROUND] Failed to show notification: $e');
  }
}

class PushNotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static GlobalKey<NavigatorState>? get navigatorKey => CallKitService.navigatorKey;
  static set navigatorKey(GlobalKey<NavigatorState>? key) {
    CallKitService.navigatorKey = key;
  }

  static String? currentChatId;
  static String? pendingPayload;
  static String? _cachedVoipToken;
  static const String _deviceIdKey = 'docmobi_unique_device_id';

  static Future<void> init() async {
    debugPrint('[PUSH NOTIFICATION SERVICE] Starting initialization...');

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    try {
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint(' Notification permission status: \${settings.authorizationStatus}');
    } catch (e) {
      debugPrint(' Error requesting notification permissions: $e');
    }

    if (Platform.isAndroid) {
      try {
        await FlutterCallkitIncoming.requestNotificationPermission({
          "rationaleMessagePermission": "Notification permission is required to show incoming calls",
          "postNotificationMessageRequired": "Please allow notifications for incoming calls to work properly",
        });
      } catch (e) {
        debugPrint(' Error requesting CallKit permissions: $e');
      }
    }

    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      if (event == null) return;
      debugPrint(' [CallKit Event] \${event.event}');
      switch (event.event) {
        case Event.actionCallAccept:
          CallKitService.handleCallKitAction(event.body, accept: true);
          break;
        case Event.actionCallDecline:
        case Event.actionCallEnded:
        case Event.actionCallTimeout:
          CallKitService.handleCallKitAction(event.body, accept: false);
          break;
        default:
          break;
      }
    });

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) handleNotificationClick(details.payload!);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    try {
      const AndroidNotificationChannel chatChannel = AndroidNotificationChannel(
        'docmobi_chat_notifications_v3',
        'Chat Notifications',
        description: 'Real-time message notifications',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );
      const AndroidNotificationChannel callChannel = AndroidNotificationChannel(
        'incoming_call_channel',
        'Incoming Calls',
        description: 'Notifications for incoming audio and video calls',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: false,
      );

      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(chatChannel);
      await androidPlugin?.createNotificationChannel(callChannel);
    } catch (e) {
      debugPrint(' Error creating Android notification channels: $e');
    }

    try {
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint(' Error setting iOS foreground options: $e');
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('[FOREGROUND] FCM Message received');
      if (message.data['type'] == 'incoming_call') {
        // ✅ iOS SAFETY CHECK: On iOS, VoIP pushes (APNs) natively handle CallKit UI.
        // Standard FCM data pushes for calls are redundant and cause "Ghost Screens" (Duplicate UI).
        if (Platform.isIOS) {
          debugPrint(' [FOREGROUND] Skipping FCM incoming call for iOS — VoIP (APNs) handles this.');
          return;
        }

        await _localNotifications.cancelAll();
        await CallKitService.showCallKitIncoming(message.data);
      } else if (message.data['type'] == 'cancel_call' || 
                 message.data['status'] == 'cancelled' || 
                 message.data['type'] == 'call_log') {
        // ✅ SMART DETECTION: Even if it's a call_log or a general notification,
        // if status is 'cancelled', we immediately tell CallKit to stop ringing.
        debugPrint(' 📴 [FCM] Call cancel signal matched via smart detection');
        final uuid = message.data['uuid'] ?? message.data['id'];
        if (uuid != null && uuid.toString().isNotEmpty) {
          await FlutterCallkitIncoming.endCall(uuid.toString());
        } else {
          await FlutterCallkitIncoming.endAllCalls();
        }
      } else {
        await _showLocalNotification(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      handleNotificationClick(message.data);
    });

    await registerUserDevice();

    _fcm.onTokenRefresh.listen((token) => registerUserDevice());

    if (Platform.isIOS) {
      const MethodChannel voipChannel = MethodChannel('com.docmobi.app/voip');
      voipChannel.setMethodCallHandler((call) async {
        if (call.method == 'onVoIPTokenUpdate') {
          _cachedVoipToken = call.arguments?.toString();
          debugPrint('📞 [VoIP] Native VoIP token update signaled');
          await registerUserDevice();
        }
      });
    }

    // ✅ GLOBAL SOCKET LISTENERS for Call Cancellation
    // This handles the foreground case where the user is not yet on the call screen
    SocketService.instance.on('call:ended', (data) async {
      debugPrint(' 📴 [GLOBAL SOCKET] Call ended signal received');
      final uuid = data != null ? (data['uuid'] ?? data['id']) : null;
      final status = data != null ? data['status'] : null;

      if (uuid != null && uuid.toString().isNotEmpty) {
        await FlutterCallkitIncoming.endCall(uuid.toString());
      } else if (status == 'cancelled' || status == 'ended' || status == 'rejected') {
        await FlutterCallkitIncoming.endAllCalls();
      } else {
        await FlutterCallkitIncoming.endAllCalls(); // Fallback for all ended signals
      }
    });

    SocketService.instance.on('call:end', (data) async {
      debugPrint(' 📴 [GLOBAL SOCKET] Call end signal received');
      final uuid = data != null ? (data['uuid'] ?? data['id']) : null;
      final status = data != null ? data['status'] : null;

      if (uuid != null && uuid.toString().isNotEmpty) {
        await FlutterCallkitIncoming.endCall(uuid.toString());
      } else if (status == 'cancelled' || status == 'ended') {
        await FlutterCallkitIncoming.endAllCalls();
      } else {
        await FlutterCallkitIncoming.endAllCalls();
      }
    });

    SocketService.instance.on('call:cancel', (data) async {
      debugPrint(' 📴 [GLOBAL SOCKET] Call cancel signal received');
      final uuid = data != null ? (data['uuid'] ?? data['id']) : null;
      final status = data != null ? data['status'] : null;

      if (uuid != null && uuid.toString().isNotEmpty) {
        await FlutterCallkitIncoming.endCall(uuid.toString());
      } else if (status == 'cancelled' || status == 'ended') {
        await FlutterCallkitIncoming.endAllCalls();
      } else {
        await FlutterCallkitIncoming.endAllCalls();
      }
    });

    SocketService.instance.on('call:rejected', (data) async {
      debugPrint(' 📴 [GLOBAL SOCKET] Call reject signal received');
      await FlutterCallkitIncoming.endAllCalls();
    });

    debugPrint('[PUSH NOTIFICATION SERVICE] Initialization complete');
  }

  static Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString(_deviceIdKey, deviceId);
      debugPrint(' [NOTIF] Generated new unique deviceId: $deviceId');
    }
    return deviceId;
  }

  static Future<void> registerUserDevice() async {
    try {
      if (!ApiService.isLoggedIn) {
        debugPrint(' [NOTIF] User not logged in — skipping device registration');
        return;
      }
      debugPrint(' [NOTIF] Synchronizing device tokens (Multi-Device)...');

      final deviceId = await _getDeviceId();

      String? fcmToken;
      try {
        fcmToken = await _fcm.getToken().timeout(const Duration(seconds: 10));
      } catch (e) {
        debugPrint(' [NOTIF] ❌ Error fetching FCM token: $e');
      }

      String? voipToken;
      if (Platform.isIOS) {
        try {
          voipToken = _cachedVoipToken ?? await FlutterCallkitIncoming.getDevicePushTokenVoIP().timeout(const Duration(seconds: 10));
        } catch (e) {
          debugPrint(' [NOTIF] ❌ Error fetching VoIP token: $e');
        }
      }

      final platform = Platform.isAndroid ? 'android' : 'ios';
      
      final result = await ApiService.registerDeviceTokens(
        fcmToken: fcmToken,
        voipToken: voipToken,
        platform: platform,
        deviceId: deviceId,
      );

      if (result['success'] == true) {
        debugPrint(' ✅ Device tokens registered successfully (Device: $deviceId)');
      } else {
        debugPrint(" ❌ Device registration failed: ${result['message']}");
      }
    } catch (e) {
      debugPrint(' ❌ Error in registerUserDevice: $e');
    }
  }

  static Future<void> checkInitialMessage() async {
    try {
      final NotificationAppLaunchDetails? notificationAppLaunchDetails = await _localNotifications.getNotificationAppLaunchDetails();
      if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
        final payload = notificationAppLaunchDetails!.notificationResponse?.payload;
        if (payload != null) handleNotificationClick(payload);
        return;
      }

      RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        handleNotificationClick(initialMessage.data);
      }

      await CallKitService.checkActiveCalls();
    } catch (e) {
      debugPrint(' Error checking initial message: $e');
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final msgChatId = message.data['chatId']?.toString();
    if (msgChatId != null && msgChatId == currentChatId) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'docmobi_chat_notifications_v3',
      'Chat Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: 1,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await _localNotifications.show(
        msgChatId?.hashCode ?? DateTime.now().millisecondsSinceEpoch.hashCode,
        message.notification?.title,
        message.notification?.body,
        details,
        payload: jsonEncode(message.data),
      );
    } catch (e) {
      debugPrint(' Error showing local notification: $e');
    }
  }

  static Future<void> showLocalNotificationForChat({
    required String senderName,
    required String content,
    required String chatId,
    required String otherUserId,
    String? avatar,
  }) async {
    await _showLocalNotification(
      RemoteMessage(
        notification: RemoteNotification(title: 'New message from $senderName', body: content),
        data: {
          'type': 'chat',
          'chatId': chatId,
          'otherUserId': otherUserId,
          'userName': senderName,
          'userAvatar': avatar ?? '',
        },
      ),
    );
  }

  static void handleNotificationClick(dynamic payload) async {
    if (navigatorKey?.currentState == null) {
      pendingPayload = payload is String ? payload : jsonEncode(payload);
      return;
    }
    try {
      Map<String, dynamic> data = (payload is String) ? jsonDecode(payload) : Map<String, dynamic>.from(payload);
      // Calls handled via checkActiveCalls/CallKit
      if (data['type'] == 'incoming_call') return;

      if (data['type'] == 'chat' || data['chatId'] != null) {
        final String? chatId = data['chatId']?.toString();
        final String userName = data['userName']?.toString() ?? 'User';
        final String otherUserId = data['otherUserId']?.toString() ?? '';
        final String? userAvatar = data['userAvatar']?.toString();

        if (chatId != null) {
          final prefs = await SharedPreferences.getInstance();
          final userRole = prefs.getString('user_role')?.toLowerCase();

          if (userRole == 'doctor') {
            navigatorKey!.currentState?.push(MaterialPageRoute(
              builder: (context) => DoctorChatDetailScreen(
                chatId: chatId,
                userName: userName,
                userAvatar: userAvatar,
                userRole: 'patient',
                otherUserId: otherUserId,
              ),
            ));
          } else {
            navigatorKey!.currentState?.push(MaterialPageRoute(
              builder: (context) => ChatDetailScreen(
                chatId: chatId,
                doctorName: userName,
                doctorAvatar: userAvatar,
                doctorId: otherUserId,
              ),
            ));
          }
        }
      }
    } catch (e) {
      debugPrint(' Error handling notification click: $e');
    }
  }

  static void consumePendingPayload() {
    if (pendingPayload != null) {
      handleNotificationClick(pendingPayload);
      pendingPayload = null;
    }
  }

  static Future<void> clearBadge() async {
    try {
      await _localNotifications.cancelAll();
    } catch (e) {
      debugPrint(' Error clearing badge: $e');
    }
  }

  static Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }
}
