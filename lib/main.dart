import 'package:docmobi/app.dart';
import 'package:docmobi/providers/user_provider.dart';
import 'package:docmobi/providers/dependent_provider.dart';
import 'package:docmobi/services/api_service.dart';
// ✅ Import ApiConfig
import 'package:flutter/material.dart';
import 'package:docmobi/providers/appointment_provider.dart';
import 'package:provider/provider.dart';
import 'package:docmobi/providers/doctor_provider.dart';

void main() async {
  // ✅ CRITICAL: Initialize Flutter bindings first
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 Starting app initialization...');
  
  // // ✅ Print API configuration
  // ApiConfig.printConfig();
  
  // ✅ Load token from SharedPreferences into memory BEFORE app starts
  await ApiService.init();
  
  // ✅ Debug: Check if token is loaded
  final isLoggedIn = ApiService.isLoggedIn;
  print('🔍 Token status: ${isLoggedIn ? "✅ Logged In" : "❌ Not Logged In"}');
  
  if (isLoggedIn && ApiService.token != null) {
    final tokenPreview = ApiService.token!.substring(0, 20);
    print('🔑 Token preview: $tokenPreview...');
  }
  
  print('✅ Initialization complete - Starting app');
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => DoctorProvider()),
        ChangeNotifierProvider(create: (_) => DependentProvider()),
      ],
      child: const MyApp(),
    ),
  );
}