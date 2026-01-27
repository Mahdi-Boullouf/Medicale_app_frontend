import 'package:docmobi/app.dart';
import 'package:docmobi/providers/user_provider.dart';
import 'package:docmobi/providers/dependent_provider.dart';
import 'package:docmobi/services/api_service.dart';
import 'package:docmobi/services/socket_service.dart';
import 'package:docmobi/services/agora_chat_service.dart';
import 'package:flutter/material.dart';
import 'package:docmobi/providers/appointment_provider.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:docmobi/providers/doctor_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docmobi/providers/locale_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('Starting app initialization...');

  // Load saved locale for immediate application startup
  final savedLocaleCode = await getSavedLocaleCode();
  final initialLocale = Locale(savedLocaleCode ?? 'en');

  // Load token
  await ApiService.init();

  final isLoggedIn = ApiService.isLoggedIn;
  debugPrint(
    '🔍 Token status: ${isLoggedIn ? "Logged In" : "Not Logged In"}',
  );

  debugPrint('Local Notification System ready (will start after login)');

  // Initialize Agora Chat if logged in
  if (isLoggedIn) {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId != null && userId.isNotEmpty) {
        await AgoraChatService.instance.init();
        await AgoraChatService.instance.login(userId);
        debugPrint('✅ Agora Chat initialized for user: $userId');

        await SocketService.instance.connect(userId);
        debugPrint('✅ Socket initialized for user: $userId');
      } else {
        debugPrint('⚠️ User ID not found - Socket & Agora Chat not connected');
      }
    } catch (e) {
      debugPrint('❌ Initialization error: $e');
    }
  }

  debugPrint('✅ Initialization complete - Starting app');

  runApp(
    ProviderScope(
      overrides: [
        // We initialize the localeProvider with the saved locale to avoid flicker
        localeProvider.overrideWith(
          () => LocaleNotifier()..setInitialLocale(initialLocale),
        ),
      ],
      child: legacy_provider.MultiProvider(
        providers: [
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
}
