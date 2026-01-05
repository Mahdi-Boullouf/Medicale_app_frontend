import 'package:docmobi/app.dart';
import 'package:docmobi/providers/user_provider.dart';
import 'package:docmobi/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:docmobi/providers/appointment_provider.dart';
import 'package:provider/provider.dart';
import 'package:docmobi/providers/doctor_provider.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ Token load koro BEFORE app run
  await ApiService.init();
  
  // ✅ Debug: Check token loaded or not
  print('🔍 Token status: ${ApiService.isLoggedIn ? "Logged In" : "Not Logged In"}');
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => DoctorProvider()),
      ],
      child: const MyApp(),
    ),
  );
}