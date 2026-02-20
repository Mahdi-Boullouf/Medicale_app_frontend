import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';
import '../utils/api_config.dart';
import 'package:flutter/material.dart';
import '../screens/doctor/messages/doctor_chat_screen.dart';
import '../screens/patient/messages/patient_chat_screen.dart';
import '../screens/common/calls/incoming_call_screen.dart';
import '../screens/common/calls/video_call_screen.dart';
import '../screens/common/calls/audio_call_screen.dart';
import 'socket_service.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ Top-level background notification action handler
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  debugPrint('🌙 [BACKGROUND ACTION] Action: ${notificationResponse.actionId}');

  if (notificationResponse.actionId == 'DECLINE_CALL') {
    debugPrint('❌ Call declined in background');
  }
}

// ✅ Top-level background handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    // ✅ FIX 1: Login check — not logged in হলে call দেখাবো না
    await Firebase.initializeApp();
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('auth_token');

    if (authToken == null || authToken.isEmpty) {
      debugPrint('⚠️ [BACKGROUND] User not logged in — ignoring notification');
      return;
    }

    final data = message.data;
    debugPrint('🌙 [BACKGROUND HANDLER] Raw Data: $data');

    // 🚀 CRITICAL: Handle incoming calls IMMEDIATELY
    if (data['type'] == 'incoming_call') {
      debugPrint('📞 [BACKGROUND] Incoming call detected!');
      try {
        await NotificationService._showCallKitIncoming(data);
        debugPrint('✅ [BACKGROUND] CallKit displayed successfully');
      } catch (e) {
        debugPrint('❌ [BACKGROUND] CRITICAL Error showing CallKit: $e');
      }
      return;
    } else if (data['type'] == 'cancel_call') {
      debugPrint('📴 [BACKGROUND] Call cancelled by caller.');
      try {
        final uuid = data['uuid'];
        if (uuid != null && uuid.toString().isNotEmpty) {
          await FlutterCallkitIncoming.endCall(uuid.toString());
          debugPrint('✅ [BACKGROUND] Ended specific call: $uuid');
        } else {
          await FlutterCallkitIncoming.endAllCalls();
          debugPrint('✅ [BACKGROUND] Ended all calls (no UUID)');
        }
      } catch (e) {
        debugPrint('❌ [BACKGROUND] Error ending calls: $e');
      }
      return;
    }
  } catch (e) {
    debugPrint('❌ [BACKGROUND] Early parsing error: $e');
    return;
  }

  // 🐢 Normal Priority: Standard notifications
  final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
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
  final String notificationBody = body ??
      (data['type'] == 'image'
          ? '[Image]'
          : data['content'] ?? data['body'] ?? 'You have a new message');

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

  const NotificationDetails details = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  try {
    await localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      notificationTitle,
      notificationBody,
      details,
      payload: jsonEncode(data),
    );
    debugPrint('✅ [BACKGROUND] Local notification displayed successfully');
  } catch (e) {
    debugPrint('❌ [BACKGROUND] Failed to show notification: $e');
  }
}

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static GlobalKey<NavigatorState>? navigatorKey;
  static String? currentChatId;
  static String? pendingPayload;

  /// ✅ Stores accepted call data when app cold-starts from CallKit
  static Map<String, dynamic>? pendingCallData;

  // ✅ FIX 2: Agora token pre-fetch cache — timeout fix এর জন্য
  static String? _cachedAgoraToken;
  static String? _cachedChannelName;

  /// ✅ Call screen এ এই method দিয়ে cached token নেবে
  static String? consumeCachedAgoraToken() {
    final token = _cachedAgoraToken;
    _cachedAgoraToken = null;
    _cachedChannelName = null;
    debugPrint(
        token != null
            ? '✅ Consumed pre-fetched Agora token'
            : '⚠️ No cached Agora token found');
    return token;
  }

  /// Initialize Firebase and Local Notifications
  static Future<void> init() async {
    debugPrint('🔔 [NOTIFICATION SERVICE] Starting initialization...');

    // 0. Register Background Handler FIRST
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    debugPrint('✅ Background message handler registered');

    // 1. Request Permissions
    try {
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ User granted notification permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('⚠️ User granted provisional notification permission');
      } else {
        debugPrint('❌ User denied notification permission');
      }
    } catch (e) {
      debugPrint('❌ Error requesting notification permissions: $e');
    }

    // ✅ Request additional Android permissions for CallKit
    if (Platform.isAndroid) {
      try {
        await FlutterCallkitIncoming.requestNotificationPermission({
          "rationaleMessagePermission":
              "Notification permission is required to show incoming calls",
          "postNotificationMessageRequired":
              "Please allow notifications for incoming calls to work properly"
        });
        debugPrint('✅ Android CallKit permissions requested');
      } catch (e) {
        debugPrint('⚠️ Error requesting CallKit permissions: $e');
      }
    }

    // ✅ Listen for CallKit events
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      if (event == null) return;

      debugPrint('📞 [CallKit Event] ${event.event}');

      switch (event.event) {
        case Event.actionCallAccept:
          debugPrint('✅ [CallKit] Call Accepted');
          _handleCallKitAction(event.body, accept: true);
          break;
        case Event.actionCallDecline:
          debugPrint('❌ [CallKit] Call Declined');
          _handleCallKitAction(event.body, accept: false);
          break;
        case Event.actionCallEnded:
          debugPrint('📴 [CallKit] Call Ended');
          _handleCallKitAction(event.body, accept: false);
          break;
        case Event.actionCallTimeout:
          debugPrint('⏱️ [CallKit] Call Timeout');
          _handleCallKitAction(event.body, accept: false);
          break;
        default:
          debugPrint('📞 [CallKit] Other Event: ${event.event}');
          break;
      }
    });

    // 2. Local Notifications Setup
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('🔔 Notification clicked: ${details.payload}');

        if (details.payload != null) {
          handleNotificationClick(details.payload!);
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    debugPrint('✅ Local notifications initialized');

    // 3. Create Android notification channels
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

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(chatChannel);
      await androidPlugin?.createNotificationChannel(callChannel);

      debugPrint(
          '✅ Android notification channels created (chat + incoming_call)');
    } catch (e) {
      debugPrint('❌ Error creating Android notification channels: $e');
    }

    // 4. iOS Foreground Notification Presentation
    try {
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('✅ iOS foreground notification options set');
    } catch (e) {
      debugPrint('❌ Error setting iOS foreground options: $e');
    }

    // 5. Foreground Listeners
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('📩 [FOREGROUND] FCM Message received');
      debugPrint('   - Type: ${message.data['type']}');

      if (message.data['type'] == 'incoming_call') {
        debugPrint('📞 [FOREGROUND] Showing CallKit for incoming call');
        await _localNotifications.cancelAll();
        await _showCallKitIncoming(message.data);
      } else if (message.data['type'] == 'cancel_call') {
        debugPrint('📴 [FOREGROUND] Call cancelled by caller.');
        final uuid = message.data['uuid'];
        if (uuid != null && uuid.toString().isNotEmpty) {
          await FlutterCallkitIncoming.endCall(uuid.toString());
        } else {
          await FlutterCallkitIncoming.endAllCalls();
        }
      } else {
        await _showLocalNotification(message);
      }
    });

    // 6. Background/Terminated Click Listeners
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 [BACKGROUND CLICK] App opened from notification');
      handleNotificationClick(message.data);
    });

    // 7. Get Initial Token
    await _saveToken();

    // 8. Token Refresh Listener
    _fcm.onTokenRefresh.listen((token) => _saveToken(token));

    debugPrint('✅ [NOTIFICATION SERVICE] Initialization complete');
  }

  static Future<void> checkInitialMessage() async {
    try {
      debugPrint('🔍 Checking initial message (Terminated State Check)...');

      // 1. Check for Local Notification Launch
      final NotificationAppLaunchDetails? notificationAppLaunchDetails =
          await _localNotifications.getNotificationAppLaunchDetails();

      if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
        final payload =
            notificationAppLaunchDetails!.notificationResponse?.payload;

        debugPrint('🏁 [TERMINATED CLICK] App launched from LOCAL Notification');
        debugPrint('   - Payload: $payload');

        if (payload != null) {
          handleNotificationClick(payload);
        }
        return;
      }

      // 2. Fallback: Check for FCM Initial Message
      RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('🏁 [TERMINATED CLICK] App launched from FCM Notification');
        handleNotificationClick(initialMessage.data);
      } else {
        debugPrint('ℹ️ No initial message found (Normal Launch)');
      }

      // 3. Check for Active Calls (CallKit) - Handle cold start from Call Accept
      try {
        final activeCalls = await FlutterCallkitIncoming.activeCalls();
        if (activeCalls is List && activeCalls.isNotEmpty) {
          debugPrint(
              '📞 [STARTUP] Found active call(s): ${activeCalls.length}');
          final firstCall = activeCalls.first;
          final extra = firstCall['extra'];

          if (extra != null) {
            Map<String, dynamic> data = {};
            if (extra is Map) {
              data = Map<String, dynamic>.from(extra);
            } else {
              data = jsonDecode(jsonEncode(extra));
            }

            // ✅ TIMESTAMP CHECK: Prevent Ghost Calls
            if (data['timestamp'] != null) {
              final callTime = DateTime.parse(data['timestamp']);
              final diff = DateTime.now().difference(callTime).inMinutes;

              if (diff > 2) {
                debugPrint(
                    '⚠️ [STARTUP] Found STALE call (Age: $diff min) - Clearing it.');
                await FlutterCallkitIncoming.endAllCalls();
                return;
              }
            }

            debugPrint(
                '✅ [STARTUP] Found VALID active call - Navigating to call screen');
            _handleCallKitAction({'extra': data}, accept: true);
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error checking active calls: $e');
      }
    } catch (e) {
      debugPrint('⚠️ Error checking initial message: $e');
    }
  }

  /// Get and save FCM Token to Backend
  static Future<void> _saveToken([String? token]) async {
    try {
      final fcmToken = token ?? await _fcm.getToken();
      if (fcmToken != null) {
        debugPrint('🔑 FCM Token: $fcmToken');

        if (ApiService.isLoggedIn) {
          final platform = Platform.isAndroid ? 'android' : 'ios';
          await ApiService.registerFCMToken(
            token: fcmToken,
            platform: platform,
          );
          debugPrint('✅ FCM Token registered with backend');
        }
      }
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }

  /// Show Local Notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final msgChatId = message.data['chatId']?.toString();

    if (msgChatId != null && msgChatId == currentChatId) {
      debugPrint('🔕 Suppressing notification for active chat: $msgChatId');
      return;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
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
      badgeNumber: 1,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _localNotifications.show(
        msgChatId?.hashCode ?? DateTime.now().millisecondsSinceEpoch.hashCode,
        message.notification?.title,
        message.notification?.body,
        details,
        payload: jsonEncode(message.data),
      );
      debugPrint('✅ Local notification shown successfully');
    } catch (e) {
      debugPrint('❌ Error showing local notification: $e');
    }
  }

  /// Show notification for message received via Agora
  static Future<void> showLocalNotificationForChat({
    required String senderName,
    required String content,
    required String chatId,
    required String otherUserId,
    String? avatar,
  }) async {
    await _showLocalNotification(
      RemoteMessage(
        notification: RemoteNotification(
          title: 'New message from $senderName',
          body: content,
        ),
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

  /// Handle navigation when notification is clicked
  static void handleNotificationClick(dynamic payload) async {
    debugPrint(
        '🚀 Handling notification click. Payload type: ${payload.runtimeType}');

    if (navigatorKey?.currentState == null) {
      debugPrint('⚠️ Navigator not ready. Storing payload as pending.');
      if (payload is String) {
        pendingPayload = payload;
      } else if (payload is Map) {
        pendingPayload = jsonEncode(payload);
      }
      return;
    }

    try {
      Map<String, dynamic> data = {};

      if (payload is Map<String, dynamic>) {
        data = payload;
      } else if (payload is String) {
        data = jsonDecode(payload);
      }

      debugPrint('📍 Parsing navigation data: $data');

      // Handle incoming call notifications
      if (data['type'] == 'incoming_call') {
        debugPrint('📞 Navigating to incoming call screen');

        navigatorKey!.currentState?.push(
          MaterialPageRoute(
            builder: (context) => IncomingCallScreen(
              chatId: data['chatId'] ?? '',
              callerName: data['callerName'] ?? 'Unknown',
              callerAvatar: data['callerAvatar'],
              callerId: data['callerId'] ?? '',
              isVideoCall: data['isVideo'] == 'true',
            ),
          ),
        );
        return;
      }

      // Handle chat notifications
      if (data['type'] == 'chat' || data['chatId'] != null) {
        final String? chatId = data['chatId']?.toString();
        final String? userName =
            data['userName']?.toString() ?? 'User';
        final String otherUserId =
            data['otherUserId']?.toString() ?? '';
        final String? userAvatar = data['userAvatar']?.toString();

        if (chatId != null) {
          final prefs = await SharedPreferences.getInstance();
          final userRole = prefs.getString('user_role')?.toLowerCase();

          debugPrint('📍 Navigating to chat: $chatId for role: $userRole');

          if (userRole == 'doctor') {
            navigatorKey!.currentState?.push(
              MaterialPageRoute(
                builder: (context) => DoctorChatDetailScreen(
                  chatId: chatId,
                  userName: userName ?? 'User',
                  userAvatar: userAvatar,
                  userRole: 'patient',
                  otherUserId: otherUserId,
                ),
              ),
            );
          } else {
            navigatorKey!.currentState?.push(
              MaterialPageRoute(
                builder: (context) => ChatDetailScreen(
                  chatId: chatId,
                  doctorName: userName ?? 'Doctor',
                  doctorAvatar: userAvatar,
                  doctorId: otherUserId,
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error handling notification click: $e');
    }
  }

  /// Consume any pending payload once navigator is ready
  static void consumePendingPayload() {
    if (pendingPayload != null) {
      debugPrint('🚀 Consuming pending notification payload...');
      handleNotificationClick(pendingPayload);
      pendingPayload = null;
    }
  }

  /// ✅ Consume pending call data and navigate directly to call screen
  static bool consumePendingCallData() {
    if (pendingCallData != null && navigatorKey?.currentState != null) {
      debugPrint(
          '📞 Consuming pending call data — navigating directly to call screen');
      final data = pendingCallData!;
      pendingCallData = null;
      _handleCallKitAction({'extra': data}, accept: true);
      return true;
    }
    return false;
  }

  // ========================================
  // ✅ CALLKIT IMPLEMENTATION
  // ========================================

  /// ✅ Public Helper for Background Handler in main.dart
  static Future<void> showIncomingCall(Map<String, dynamic> data) async {
    await _showCallKitIncoming(data);
  }

  /// ✅ Show CallKit Incoming UI
  static Future<void> _showCallKitIncoming(
      Map<String, dynamic> data) async {
    // ✅ FIX 1: Login check — not logged in হলে call দেখাবো না
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');
      if (authToken == null || authToken.isEmpty) {
        debugPrint(
            '⚠️ [CallKit] User not logged in — skipping incoming call UI');
        return;
      }
    } catch (e) {
      debugPrint('⚠️ [CallKit] Could not check auth status: $e');
      // Auth check fail হলে call দেখাবো না — safety first
      return;
    }

    try {
      final uuid = data['uuid'] ?? const Uuid().v4();
      final String callerName = data['callerName'] ?? 'Unknown';
      final String? rawCallerId = data['callerId']?.toString();
      final String? callerId = rawCallerId?.split('/').first;
      final String callerAvatar = data['callerAvatar'] ?? '';
      final bool isVideo =
          data['isVideo'] == 'true' || data['isVideo'] == true;

      debugPrint('📞 [CallKit] Preparing to show call screen');
      debugPrint('   - Caller: $callerName');
      debugPrint('   - Video: $isVideo');
      debugPrint('   - Chat ID: ${data['chatId']}');
      debugPrint('   - Caller ID: $callerId');

      final CallKitParams params = CallKitParams(
        id: uuid,
        nameCaller: callerName,
        appName: 'Docmobi',
        avatar: callerAvatar,
        handle: callerId,
        type: isVideo ? 1 : 0,
        textAccept: 'Accept',
        textDecline: 'Decline',
        missedCallNotification: const NotificationParams(
          showNotification: true,
          isShowCallback: true,
          subtitle: 'Missed Call',
          callbackText: 'Call back',
        ),
        duration: 30000,
        extra: data,
        headers: <String, dynamic>{'platform': 'flutter'},
        android: AndroidParams(
          isCustomNotification: true,
          isShowLogo: false,
          ringtonePath: 'system_ringtone_default',
          backgroundColor: '#0955fa',
          backgroundUrl: callerAvatar.isNotEmpty ? callerAvatar : '',
          actionColor: '#4CAF50',
          incomingCallNotificationChannelName: 'Incoming Call',
          missedCallNotificationChannelName: 'Missed Call',
        ),
        ios: const IOSParams(
          iconName: 'CallKitLogo',
          handleType: 'generic',
          supportsVideo: true,
          maximumCallGroups: 2,
          maximumCallsPerCallGroup: 1,
          audioSessionMode: 'default',
          audioSessionActive: true,
          audioSessionPreferredSampleRate: 44100.0,
          audioSessionPreferredIOBufferDuration: 0.005,
          supportsDTMF: true,
          supportsHolding: true,
          supportsGrouping: false,
          supportsUngrouping: false,
          ringtonePath: 'system_ringtone_default',
        ),
      );

      await FlutterCallkitIncoming.showCallkitIncoming(params);
      debugPrint('✅ [CallKit] Call screen displayed with UUID: $uuid');
    } catch (e) {
      debugPrint('❌ Error showing CallKit incoming: $e');
    }
  }

  // ========================================
  // REST API Methods
  // ========================================

  static Future<List<NotificationModel>> getNotifications() async {
    final response = await ApiService.get(ApiConfig.notifications);

    if (response['success'] == true && response['data'] != null) {
      List<dynamic> data = [];
      if (response['data'] is Map && response['data']['items'] is List) {
        data = response['data']['items'];
      } else if (response['data'] is List) {
        data = response['data'];
      }

      return data.map((json) => NotificationModel.fromJson(json)).toList();
    }
    return [];
  }

  static Future<int> getUnreadCount() async {
    final response = await ApiService.get(ApiConfig.unreadCount);
    if (response['success'] == true && response['data'] != null) {
      return (response['data']['count'] ?? 0) as int;
    }
    return 0;
  }

  static Future<bool> markAsRead(String id) async {
    final response = await ApiService.patch(ApiConfig.getMarkAsReadUrl(id), {});
    return response['success'] == true;
  }

  static Future<bool> markAllAsRead() async {
    final response = await ApiService.patch(ApiConfig.markAllAsRead, {});
    return response['success'] == true;
  }

  static Future<bool> deleteNotification(String id) async {
    final response = await ApiService.delete(
      '${ApiConfig.deleteNotification}/$id',
    );
    return response['success'] == true;
  }

  static Future<void> clearBadge() async {
    try {
      await _localNotifications.cancelAll();
      debugPrint('🔔 Badge cleared');
    } catch (e) {
      debugPrint('⚠️ Error clearing badge: $e');
    }
  }

  static Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// ✅ Handle CallKit Action (Accept/Decline)
  static void _handleCallKitAction(Map<String, dynamic> data,
      {required bool accept}) async {
    try {
      // ✅ Ensure API Service is initialized for Cold Start
      if (!ApiService.isLoggedIn) {
        debugPrint(
            '⚠️ ApiService not initialized in handleCallKitAction - initializing now...');
        await ApiService.init();
      }

      // ✅ FIX 1: Login check before doing anything
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');
      if (authToken == null || authToken.isEmpty) {
        debugPrint('⚠️ [CallKit Action] User not logged in — ignoring action');
        // End the CallKit call UI since user is not logged in
        await FlutterCallkitIncoming.endAllCalls();
        return;
      }

      // 🔄 Normalize data: Extract from 'extra' if needed
      Map<String, dynamic> finalData = Map.from(data);
      if (finalData['chatId'] == null && finalData['extra'] != null) {
        if (finalData['extra'] is Map) {
          finalData.addAll(Map<String, dynamic>.from(finalData['extra']));
        } else if (finalData['extra'] is String) {
          try {
            finalData.addAll(jsonDecode(finalData['extra']));
          } catch (e) {
            debugPrint('⚠️ Failed to parse extra data string: $e');
          }
        }
      }

      final chatId = finalData['chatId'];
      final rawCallerId = finalData['callerId']?.toString();
      final callerId = rawCallerId?.split('/').first;
      final callerName = finalData['callerName'] ?? 'Unknown';
      final isVideo =
          finalData['isVideo'] == 'true' || finalData['isVideo'] == true;

      debugPrint('📞 [CallKit Action] ${accept ? 'ACCEPT' : 'DECLINE'}');
      debugPrint('   - Chat ID: $chatId');
      debugPrint('   - Caller ID: $callerId');

      if (accept) {
        debugPrint(
            '✅ Call accepted from CallKit, navigating directly to call screen...');

        if (chatId != null && callerId != null) {
          // ✅ FIX 2: Agora token pre-fetch করো BEFORE navigation — timeout fix
          try {
            final channelName = 'call_$chatId';
            debugPrint('🔄 Pre-fetching Agora token for: $channelName');
            final tokenResponse =
                await ApiService.get('/call/token?channelName=$channelName');
            final fetchedToken = tokenResponse['data']?['token'];
            if (fetchedToken != null) {
              _cachedAgoraToken = fetchedToken;
              _cachedChannelName = channelName;
              debugPrint('✅ Agora token pre-fetched and cached!');
            }
          } catch (e) {
            debugPrint(
                '⚠️ Token pre-fetch failed (will retry in call screen): $e');
            // Continue anyway — call screen এ retry করবে
          }

          // 🚀 1. Send via REST API
          ApiService.acceptCall({
            'chatId': chatId,
            'fromUserId': callerId,
          })
              .then((_) => debugPrint('✅ API: Call accepted signal sent'))
              .catchError(
                  (e) => debugPrint('❌ API: Call accept failed: $e'));

          // 🚀 2. Socket emit
          SocketService.instance.ensureConnected().then((connected) {
            if (connected) {
              SocketService.instance.emit('call:accept', {
                'chatId': chatId,
                'fromUserId': callerId,
              });
              debugPrint('✅ SOCKET: call:accept event sent');
            }
          });
        }

        if (navigatorKey?.currentState != null) {
          if (isVideo) {
            navigatorKey!.currentState?.push(
              MaterialPageRoute(
                builder: (context) => VideoCallScreen(
                  chatId: chatId ?? '',
                  userName: callerName,
                  userAvatar: finalData['callerAvatar'],
                  otherUserId: callerId ?? '',
                  isInitiator: false,
                ),
              ),
            );
          } else {
            navigatorKey!.currentState?.push(
              MaterialPageRoute(
                builder: (context) => AudioCallScreen(
                  chatId: chatId ?? '',
                  userName: callerName,
                  userAvatar: finalData['callerAvatar'],
                  otherUserId: callerId ?? '',
                  isInitiator: false,
                ),
              ),
            );
          }
        } else {
          debugPrint(
              '⚠️ Navigator not ready, storing pending CALL data for direct navigation');
          pendingCallData = finalData;
        }
      } else {
        // ✅ Decline call
        debugPrint('❌ Call declined, sending rejection to caller...');

        if (chatId != null && callerId != null) {
          SocketService.instance.emit('call:reject', {
            'chatId': chatId,
            'toUserId': callerId,
          });
          debugPrint('✅ Call rejection sent successfully');
        } else {
          debugPrint('⚠️ Cannot reject call: Missing chatId or callerId');
        }

        if (finalData['id'] != null) {
          await FlutterCallkitIncoming.endCall(finalData['id'] as String);
        }
      }
    } catch (e) {
      debugPrint('❌ Error handling CallKit action: $e');
    }
  }
}