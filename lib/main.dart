import 'package:docmobi/app.dart';
import 'package:docmobi/providers/user_provider.dart';
import 'package:docmobi/providers/dependent_provider.dart';
import 'package:docmobi/services/api_service.dart';
import 'package:docmobi/services/socket_service.dart';
import 'package:docmobi/services/agora_chat_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:docmobi/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:docmobi/providers/appointment_provider.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:docmobi/providers/doctor_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docmobi/providers/locale_provider.dart';

// ✅ CRITICAL: This MUST be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  // ✅ FIX: Login check — not logged in হলে call দেখাবো না
  final prefs = await SharedPreferences.getInstance();
  final authToken = prefs.getString('auth_token');

  if (authToken == null || authToken.isEmpty) {
    debugPrint(
        '⚠️ [BACKGROUND] User not logged in — ignoring FCM notification');
    return;
  }

  debugPrint('');
  debugPrint('═══════════════════════════════════════════════════════');
  debugPrint('🌙 [MAIN.DART BACKGROUND] FCM Message Received');
  debugPrint('═══════════════════════════════════════════════════════');
  debugPrint('📩 Message ID: ${message.messageId}');
  debugPrint('📩 Data: ${message.data}');
  debugPrint('═══════════════════════════════════════════════════════');
  debugPrint('');

  if (message.data['type'] == 'incoming_call') {
    debugPrint('📞 [BACKGROUND] Triggering CallKit for incoming call...');
    try {
      final FlutterLocalNotificationsPlugin localNotifications =
          FlutterLocalNotificationsPlugin();
      const AndroidInitializationSettings initAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initSettings =
          InitializationSettings(android: initAndroid);
      await localNotifications.initialize(initSettings);
      await localNotifications.cancelAll();
      debugPrint('✅ [BACKGROUND] System notification cancelled');
    } catch (e) {
      debugPrint('⚠️ [BACKGROUND] Could not cancel system notification: $e');
    }

    await NotificationService.showIncomingCall(message.data);
  } else if (message.data['type'] == 'cancel_call') {
    debugPrint('📴 [BACKGROUND] Call cancelled by caller');
    try {
      final uuid = message.data['uuid'];
      if (uuid != null && uuid.toString().isNotEmpty) {
        await FlutterCallkitIncoming.endCall(uuid.toString());
      } else {
        await FlutterCallkitIncoming.endAllCalls();
      }
      debugPrint('✅ [BACKGROUND] CallKit dismissed');
    } catch (e) {
      debugPrint('⚠️ [BACKGROUND] Error dismissing CallKit: $e');
    }
  }
}

bool _chatSocketInitializing = false;
bool _chatSocketInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('');
  debugPrint('╔═══════════════════════════════════════════════════════╗');
  debugPrint('║          🚀 DOCMOBI APP STARTING                      ║');
  debugPrint('╚═══════════════════════════════════════════════════════╝');
  debugPrint('');

  // 1. Initialize Firebase FIRST
  try {
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized');

    // 2. Register background handler IMMEDIATELY after Firebase init
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    debugPrint('✅ Background message handler registered');
  } catch (e) {
    debugPrint('❌ Firebase Init Error: $e');
  }

  // 3. Load saved locale
  final savedLocaleCode = await getSavedLocaleCode();
  final initialLocale = Locale(savedLocaleCode ?? 'en');

  // 4. Load token
  await ApiService.init();
  final isLoggedIn = ApiService.isLoggedIn;
  debugPrint('🔍 Token status: ${isLoggedIn ? "Logged In" : "Not Logged In"}');

  debugPrint('✅ Critical initialization complete - Starting app');
  debugPrint('');

  runApp(
    ProviderScope(
      overrides: [
        localeProvider.overrideWith(
          () => LocaleNotifier()..setInitialLocale(initialLocale),
        ),
      ],
      child: legacy_provider.MultiProvider(
        providers: [
          legacy_provider.ChangeNotifierProvider(
              create: (_) => UserProvider()),
          legacy_provider.ChangeNotifierProvider(
              create: (_) => AppointmentProvider()),
          legacy_provider.ChangeNotifierProvider(
              create: (_) => DoctorProvider()),
          legacy_provider.ChangeNotifierProvider(
              create: (_) => DependentProvider()),
        ],
        child: const MyApp(),
      ),
    ),
  );

  // Deferred initialization
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    debugPrint('🔄 Starting deferred service initialization...');

    await Future.wait([
      _initNotificationService(),
      _syncUserSession(),
      if (isLoggedIn) _initChatAndSocketServices(),
    ]);

    debugPrint('✅ All deferred services initialized');
  });
}

Future<void> _initNotificationService() async {
  try {
    await NotificationService.init();
    debugPrint('✅ Notification Service ready');
  } catch (e) {
    debugPrint('❌ Notification Service Error: $e');
  }
}

Future<void> _syncUserSession() async {
  try {
    await ApiService.syncUserSession();
  } catch (e) {
    debugPrint('⚠️ User session sync failed: $e');
  }
}

Future<void> _initChatAndSocketServices() async {
  if (_chatSocketInitialized) {
    debugPrint('⏭️ Chat/Socket services already initialized, skipping');
    return;
  }

  if (_chatSocketInitializing) {
    debugPrint('⏳ Chat/Socket services initialization in progress, skipping');
    return;
  }

  _chatSocketInitializing = true;

  try {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId != null && userId.isNotEmpty) {
      try {
        await AgoraChatService.instance.init();
        await AgoraChatService.instance.login(userId);
        debugPrint('✅ Agora Chat initialized for user: $userId');
      } catch (e) {
        debugPrint('⚠️ Agora Chat initialization failed: $e');
      }

      try {
        await SocketService.instance.connect(userId);
        debugPrint('✅ Socket initialized for user: $userId');
      } catch (e) {
        debugPrint('⚠️ Socket initialization failed: $e');
      }

      _chatSocketInitialized = true;
    } else {
      debugPrint('⚠️ User ID not found - Socket & Agora Chat not connected');
    }
  } catch (e) {
    debugPrint('❌ Chat/Socket initialization error: $e');
  } finally {
    _chatSocketInitializing = false;
  }
}