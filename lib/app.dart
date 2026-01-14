import 'package:docmobi/screens/patient/profile/add_dependents_screen.dart';
import 'package:docmobi/screens/patient/profile/edit_dependent_screen.dart';
import 'package:docmobi/screens/patient/profile/dependents_list_screen.dart';
import 'package:docmobi/services/call_manager_service.dart';
import 'package:docmobi/services/socket_service.dart';
import 'package:docmobi/screens/patient/notification/notification_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:docmobi/screens/patient/navigation/patient_main_navigation.dart';
import 'package:docmobi/screens/doctor/navigation/doctor_main_navigation.dart';
import 'package:docmobi/screens/splash/splash_screen.dart';
import 'package:docmobi/services/api_service.dart';
import 'package:docmobi/providers/notification_provider.dart';
import 'package:provider/provider.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoggedIn = false;
  bool _isLoading = true;
  String? _userRole;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>(); // ✅ ADDED

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      print('');
      print('═══════════════════════════════════════');
      print('🔍 Checking app login status...');
      print('═══════════════════════════════════════');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final role = prefs.getString('user_role');
      final userId = prefs.getString('user_id');

      final apiServiceLoggedIn = ApiService.isLoggedIn;

      print('📦 SharedPreferences Check:');
      print(
        '   • Token: ${token != null ? "✅ Found" : "❌ Not found"}',
      );
      print('   • Role: ${role ?? "❌ Not found"}');
      print('   • User ID: ${userId ?? "❌ Not found"}');
      print('');
      print('🔧 ApiService Check:');
      print(
        '   • Status: ${apiServiceLoggedIn ? "✅ Logged In" : "❌ Not Logged In"}',
      );
      print(
        '   • Token in memory: ${ApiService.token != null ? "✅ Loaded" : "❌ Not loaded"}',
      );
      print('');

      if (token != null && !apiServiceLoggedIn) {
        print('⚠️ Token exists but ApiService not initialized properly');
        print('🔄 Reinitializing ApiService...');
        await ApiService.init();
        print('✅ ApiService reinitialized');
      }

      // ✅ Initialize socket if logged in
      if (token != null && userId != null && userId.isNotEmpty) {
        if (!SocketService.instance.isConnected) {
          print('🔌 Initializing Socket Service...');
          try {
            await SocketService.instance.connect(userId);
            print('✅ Socket connected for user: $userId');
            
            // ✅ Initialize CallManager after socket connection
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_navigatorKey.currentContext != null) {
                CallManager.instance.initialize(_navigatorKey.currentContext!);
              }
            });
          } catch (e) {
            print('⚠️ Socket connection failed: $e');
          }
        } else {
          print('✅ Socket already connected');
        }
      }

      setState(() {
        _isLoggedIn = token != null && token.isNotEmpty;
        _userRole = role?.toLowerCase();
        _isLoading = false;
      });

      if (_isLoggedIn) {
        print('✅ User is logged in as: $_userRole');
        print(
          '🚀 Will navigate to: ${_userRole == "doctor" ? "Doctor Dashboard" : "Patient Dashboard"}',
        );
      } else {
        print('⚠️ User not logged in - Will show SplashScreen');
      }

      print('═══════════════════════════════════════');
      print('');
    } catch (e) {
      print('❌ Error checking login status: $e');
      print('Stack trace: ${StackTrace.current}');

      setState(() {
        _isLoading = false;
        _isLoggedIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey, // ✅ ADDED for CallManager
      title: 'Docmobi',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 16),
          bodyMedium: TextStyle(fontSize: 14),
        ),
      ),
      debugShowCheckedModeBanner: false,

      home: _buildHomeScreen(),

      // ✅ Named routes for navigation
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/patient-home': (context) => const PatientMainNavigation(),
        '/doctor-home': (context) => const DoctorMainNavigation(),
        '/dependents-list': (context) => const DependentsListScreen(),
        '/add-dependent': (context) => const AddDependentScreen(),
        '/edit-dependent': (context) => const EditDependentScreen(),
        '/notifications': (context) => const NotificationScreen(),
        // Add more routes as needed
      },

      // ✅ Route generator for dynamic routes
      onGenerateRoute: (settings) {
        print('🔗 Navigating to: ${settings.name}');

        if (settings.name == '/edit-dependent') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => const EditDependentScreen(),
            settings: settings,
          );
        }

        return null; // Let the routes table handle it
      },

      // ✅ Handle unknown routes
      onUnknownRoute: (settings) {
        print('⚠️ Unknown route: ${settings.name}');
        return MaterialPageRoute(builder: (context) => const SplashScreen());
      },
    );
  }

  Widget _buildHomeScreen() {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1664CD)),
              ),
              const SizedBox(height: 24),
              const Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Checking authentication',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isLoggedIn) {
      print('📱 Rendering: SplashScreen (Not logged in)');
      return const SplashScreen();
    }

    print('📱 Rendering: ${_userRole?.toUpperCase()} Dashboard');

    switch (_userRole) {
      case 'doctor':
        print('   → DoctorMainNavigation');
        return const DoctorMainNavigation();

      case 'patient':
        print('   → PatientMainNavigation');
        return const PatientMainNavigation();

      case 'admin':
        print('   → AdminMainNavigation (Fallback to Patient)');
        return const PatientMainNavigation();

      default:
        print('⚠️ Unknown role detected: $_userRole');
        print('🔄 Logging out and redirecting to splash...');

        // Logout in background
        _logout();

        return Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.orange[700]),
                const SizedBox(height: 24),
                const Text(
                  'Invalid Session',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B2C49),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your session is invalid.\nPlease login again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoggedIn = false;
                      _userRole = null;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1664CD),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Go to Login',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  Future<void> _logout() async {
    try {
      print('🔄 Logging out user...');

      // Stop notification polling
      final notificationProvider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );
      notificationProvider.stopPolling();
      await notificationProvider.clearNotifications();
      print('✅ Notification polling stopped');

      // ✅ Dispose CallManager
      CallManager.instance.dispose();
      
      // ✅ Disconnect socket
      SocketService.instance.disconnect();
      print('✅ Socket disconnected');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Clear ApiService token
      await ApiService.clearToken();

      print('✅ Logout successful - All data cleared');

      // Update state to show splash screen
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _userRole = null;
        });
      }
    } catch (e) {
      print('❌ Error during logout: $e');
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// 🔧 DEBUGGING HELPER WIDGET (Remove in production)
// ═══════════════════════════════════════════════════════════════

/// ✅ Optional: Debug overlay to check token status
class DebugTokenOverlay extends StatelessWidget {
  final Widget child;

  const DebugTokenOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,

        // Debug info in bottom-right corner
        Positioned(
          bottom: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      ApiService.isLoggedIn ? Icons.check_circle : Icons.cancel,
                      color: ApiService.isLoggedIn ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ApiService.isLoggedIn ? 'Logged In' : 'Not Logged In',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (ApiService.token != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Token: ${ApiService.token!.substring(0, 10)}...',
                    style: const TextStyle(color: Colors.white70, fontSize: 8),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
