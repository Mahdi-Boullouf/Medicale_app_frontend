import 'package:docmobi/providers/login_provider.dart';
import 'package:docmobi/services/push_notification_service.dart';
import 'package:docmobi/app.dart';
import 'package:docmobi/providers/user_provider.dart';
import 'package:docmobi/providers/dependent_provider.dart';
import 'package:docmobi/services/api_service.dart';
import 'package:docmobi/services/socket_service.dart';
import 'package:docmobi/services/agora_chat_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter/material.dart';
import 'package:docmobi/providers/appointment_provider.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:docmobi/providers/doctor_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docmobi/providers/locale_provider.dart';

bool _chatSocketInitializing = false;
bool _chatSocketInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('');
  debugPrint('╔═══════════════════════════════════════════════════════╗');
  debugPrint('║           DOCMOBI APP STARTING                      ║');
  debugPrint('╚═══════════════════════════════════════════════════════╝');
  debugPrint('');

  // 1. Initialize Firebase FIRST
  try {
    await Firebase.initializeApp();
    debugPrint('Firebase initialized');
    await FirebaseMessaging.instance.requestPermission(
      sound: true,
      alert: true,
      badge: true,
    );

    // 2. Register background handler IMMEDIATELY after Firebase init
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    debugPrint('Background message handler registered');
  } catch (e) {
    debugPrint('Firebase Init Error: $e');
  }

  // 3. Load saved locale
  final savedLocaleCode = await getSavedLocaleCode();
  final initialLocale = Locale(savedLocaleCode ?? 'en');

  // 4. Load token
  await ApiService.init();
  final isLoggedIn = ApiService.isLoggedIn;
  debugPrint(' Token status: ${isLoggedIn ? "Logged In" : "Not Logged In"}');

  debugPrint('Critical initialization complete - Starting app');
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
            create: (_) => LoginProvider(),
          ),

          legacy_provider.ChangeNotifierProvider(create: (_) => UserProvider()),
          legacy_provider.ChangeNotifierProvider(
            create: (_) => AppointmentProvider(),
          ),
          legacy_provider.ChangeNotifierProvider(
            create: (_) => DoctorProvider(),
          ),
          legacy_provider.ChangeNotifierProvider(
            create: (_) => DependentProvider(),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );

  // Deferred initialization
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    debugPrint(' Starting deferred service initialization...');

    await Future.wait([
      _initNotificationService(),
      _syncUserSession(),
      if (isLoggedIn) _initChatAndSocketServices(),
    ]);

    debugPrint(' All deferred services initialized');
  });
}

Future<void> _initNotificationService() async {
  try {
    await PushNotificationService.init();
    debugPrint(' Notification Service ready');
  } catch (e) {
    debugPrint(' Notification Service Error: $e');
  }
}

Future<void> _syncUserSession() async {
  try {
    await ApiService.syncUserSession();
  } catch (e) {
    debugPrint(' User session sync failed: $e');
  }
}

Future<void> _initChatAndSocketServices() async {
  if (_chatSocketInitialized) {
    debugPrint(' Chat/Socket services already initialized, skipping');
    return;
  }

  if (_chatSocketInitializing) {
    debugPrint(' Chat/Socket services initialization in progress, skipping');
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
        debugPrint(' Agora Chat initialized for user: $userId');
      } catch (e) {
        debugPrint(' Agora Chat initialization failed: $e');
      }

      try {
        await SocketService.instance.connect(userId);
        debugPrint(' Socket initialized for user: $userId');
      } catch (e) {
        debugPrint(' Socket initialization failed: $e');
      }

      _chatSocketInitialized = true;
    } else {
      debugPrint(' User ID not found - Socket & Agora Chat not connected');
    }
  } catch (e) {
    debugPrint(' Chat/Socket initialization error: $e');
  } finally {
    _chatSocketInitializing = false;
  }
}
