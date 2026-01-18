import 'package:docmobi/app.dart';
import 'package:docmobi/providers/user_provider.dart';
import 'package:docmobi/providers/dependent_provider.dart';
import 'package:docmobi/providers/notification_provider.dart';
import 'package:docmobi/services/api_service.dart';
import 'package:docmobi/services/socket_service.dart';
import 'package:docmobi/services/agora_chat_service.dart';
import 'package:flutter/material.dart';
import 'package:docmobi/providers/appointment_provider.dart';
import 'package:provider/provider.dart';
import 'package:docmobi/providers/doctor_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('🚀 Starting app initialization...');

  // ✅ Load token
  await ApiService.init();

  final isLoggedIn = ApiService.isLoggedIn;
  debugPrint(
    '🔍 Token status: ${isLoggedIn ? "✅ Logged In" : "❌ Not Logged In"}',
  );

  debugPrint('✅ Local Notification System ready (will start after login)');

  // ✅ Initialize Agora Chat if logged in
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
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => DoctorProvider()),
        ChangeNotifierProvider(create: (_) => DependentProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
