import 'package:docmobi/services/callkit_service.dart';
import 'package:docmobi/services/push_notification_service.dart';
import 'package:docmobi/l10n/app_localizations.dart';
import 'package:docmobi/screens/patient/profile/add_dependents_screen.dart';
import 'package:docmobi/screens/patient/profile/edit_dependent_screen.dart';
import 'package:docmobi/screens/patient/profile/dependents_list_screen.dart';
import 'package:docmobi/services/call_manager_service.dart';
import 'package:docmobi/services/active_call_state.dart';
import 'package:docmobi/screens/common/calls/video_call_screen.dart';
import 'package:docmobi/screens/common/calls/audio_call_screen.dart';
import 'package:docmobi/services/socket_service.dart';
import 'package:docmobi/services/agora_chat_service.dart';
import 'package:docmobi/screens/patient/notification/patient_notification_screen.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:docmobi/screens/patient/navigation/patient_main_navigation.dart';
import 'package:docmobi/screens/doctor/navigation/doctor_main_navigation.dart';
import 'package:docmobi/screens/splash/splash_screen.dart';
import 'package:docmobi/services/api_service.dart';
import 'package:docmobi/services/notification_poller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:docmobi/providers/locale_provider.dart';

import 'services/auth_service.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  bool _isLoggedIn = false;
  bool _isLoading = true;
  String? _userRole;
  bool _launchingIntoCall = false;

  //  Throttle resume events to prevent excessive data reloads
  DateTime? _lastResumeTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLoginStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint(' [APP] Lifecycle State Change: $state');

    if (state == AppLifecycleState.resumed) {
      // ✅ PRIORITY 1: Check for pending CallKit calls (unlocked from lock screen)
      // Never throttle call-related navigation.
      if (CallKitService.consumePendingCallData()) {
        debugPrint(' [APP] Active call found and consumed on Resume');
        if (mounted) setState(() => _launchingIntoCall = false);
        return; // Don't proceed to general refresh if we just jumped into a call
      }

      //  Throttle general refresh — ignore rapid resume events within 30 seconds
      final now = DateTime.now();
      if (_lastResumeTime != null &&
          now.difference(_lastResumeTime!).inSeconds < 30) {
        debugPrint(
          '⏳ General Refresh throttled (${now.difference(_lastResumeTime!).inSeconds}s since last)',
        );
        return;
      }
      _lastResumeTime = now;
      debugPrint(' [APP] App resumed - General Refreshing...');

      if (_isLoggedIn) {
        NotificationPoller().refreshNotifications();

        SharedPreferences.getInstance().then((prefs) {
          final uid = prefs.getString('user_id');
          if (uid != null) {
            if (!SocketService.instance.isConnected) {
              SocketService.instance.connect(uid);
            }
            // Re-verify the Agora Chat session on resume. If the SDK dropped
            // its connection while backgrounded, this restores it so messages
            // sent while away are received instead of silently missed.
            AgoraChatService.instance.ensureLoggedIn(uid);
          }
        });

        _restoreActiveCallIfNeeded();
      }
    }
  }

  Future<void> _restoreActiveCallIfNeeded() async {
    try {
      final callData = await ActiveCallState.getActiveCall();
      if (callData == null) return;

      final navigator = navigatorKey.currentState;
      if (navigator == null) return;

      debugPrint(
        'Restoring active call: ${callData['callType']} with ${callData['userName']}',
      );

      final callType = callData['callType'] ?? 'audio';
      final chatId = callData['chatId'] ?? '';
      final userName = callData['userName'] ?? 'Unknown';
      final userAvatar = callData['userAvatar'];
      final otherUserId = callData['otherUserId'] ?? '';
      final isInitiator = callData['isInitiator'] ?? false;

      if (callType == 'video') {
        navigator.push(
          MaterialPageRoute(
            builder: (context) => VideoCallScreen(
              chatId: chatId,
              userName: userName,
              userAvatar: userAvatar,
              otherUserId: otherUserId,
              isInitiator: isInitiator,
            ),
          ),
        );
      } else {
        navigator.push(
          MaterialPageRoute(
            builder: (context) => AudioCallScreen(
              chatId: chatId,
              userName: userName,
              userAvatar: userAvatar,
              otherUserId: otherUserId,
              isInitiator: isInitiator,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint(' Failed to restore active call: $e');
      await ActiveCallState.clearActiveCall();
    }
  }

  Future<void> _checkLoginStatus() async {
    try {
      debugPrint(' Checking app login status...');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final role = prefs.getString('user_role');

      final isLoggedIn = token != null && token.isNotEmpty;

      if (isLoggedIn) {
        try {
          final activeCalls = await FlutterCallkitIncoming.activeCalls();
          if (activeCalls is List && activeCalls.isNotEmpty) {
            final firstCall = activeCalls.first;
            var extra = firstCall['extra'];

            if (extra != null) {
              Map<String, dynamic> data = {};
              if (extra is Map) {
                data = Map<String, dynamic>.from(extra);
              } else if (extra is String) {
                try {
                  data = Map<String, dynamic>.from(jsonDecode(extra));
                } catch (e) {
                  debugPrint(' [APP] Failed to parse extra JSON string: $e');
                }
              }

              final chatId = data['chatId']?.toString();
              if (chatId != null &&
                  chatId.isNotEmpty &&
                  data['timestamp'] != null) {
                final callTime = DateTime.parse(data['timestamp'].toString());
                final diff = DateTime.now().difference(callTime).inMinutes;

                if (diff <= 2) {
                  //  Valid active call — stay in "Connecting" UI
                  _launchingIntoCall = true;
                  CallKitService.pendingCallData = data;
                  debugPrint(
                    ' [APP] Found VALID active call on startup ($chatId)',
                  );
                } else {
                  await FlutterCallkitIncoming.endAllCalls();
                  debugPrint(' [APP] Stale call ($diff min old) — cleared');
                }
              }
            }
          }
        } catch (e) {
          debugPrint(' Error checking active calls: $e');
        }
      }

      setState(() {
        _isLoggedIn = isLoggedIn;
        _userRole = role?.toLowerCase();
        _isLoading = false;
      });

      if (_isLoggedIn) {
        debugPrint(' User logged in as: $_userRole');

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (navigatorKey.currentContext != null) {
            PushNotificationService.navigatorKey = navigatorKey;
            CallManager.instance.initialize(navigatorKey.currentContext!);

            // Try consuming pending call data.
            // If it succeeds, we reset _launchingIntoCall.
            // If it's still waiting for Resume/Navigator, we wait.
            bool callStarted = CallKitService.consumePendingCallData();

            if (callStarted) {
              debugPrint(' [APP] Active call consumed successfully');
              if (mounted) setState(() => _launchingIntoCall = false);
            } else {
              // Standard initial message check
              await PushNotificationService.checkInitialMessage();
              PushNotificationService.consumePendingPayload();

              // If we were expecting a call but nothing happened after 5 seconds, reset state
              if (_launchingIntoCall) {
                Future.delayed(const Duration(seconds: 5), () {
                  if (mounted && _launchingIntoCall) {
                    setState(() => _launchingIntoCall = false);
                  }
                });
              }
            }
          }
        });
      }
    } catch (e) {
      debugPrint(' Error checking login status: $e');
      setState(() {
        _isLoading = false;
        _isLoggedIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Docmobi',
      locale: currentLocale,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ar'), Locale('fr')],
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
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/patient-home': (context) => const PatientMainNavigation(),
        '/doctor-home': (context) => const DoctorMainNavigation(),
        '/dependents-list': (context) => const DependentsListScreen(),
        '/add-dependent': (context) => const AddDependentScreen(),
        '/edit-dependent': (context) => const EditDependentScreen(),
        '/notifications': (context) => const NotificationScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/edit-dependent') {
          return MaterialPageRoute(
            builder: (context) => const EditDependentScreen(),
            settings: settings,
          );
        }
        return null;
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(builder: (context) => const SplashScreen());
      },
    );
  }

  Widget _buildHomeScreen() {
    // Loading
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1664CD)),
          ),
        ),
      );
    }

    // Not logged in
    if (!_isLoggedIn) {
      return const SplashScreen();
    }

    if (_launchingIntoCall) {
      debugPrint('📞 Showing call connecting screen (no home screen flash)');
      return const Scaffold(
        backgroundColor: Color(0xFF1B2C49),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Connecting to call...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Normal navigation
    switch (_userRole) {
      case 'doctor':
        return const DoctorMainNavigation();
      case 'patient':
        return const PatientMainNavigation();
      case 'admin':
        return const PatientMainNavigation();
      default:
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
      try {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await ApiService.unregisterFCMToken(token: fcmToken);
          debugPrint(' FCM token deactivated on server');
        }
      } catch (e) {
        debugPrint(' FCM token deactivation failed: $e');
      }

      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _userRole = null;
          _isLoading = false;
        });
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await ApiService.clearToken();

      Future.wait([
        Future(() {
          NotificationPoller().stopPolling();
          return NotificationPoller().clearAllData();
        }),
        AuthService().logout(),
        Future(() {
          SocketService.instance.disconnect();
        }),
        Future(() {
          CallManager.instance.dispose();
        }),
      ]).catchError((e) {
        debugPrint(' Background logout error: $e');
        return <void>[];
      });
    } catch (e) {
      debugPrint(' Logout error: $e');
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _userRole = null;
        });
      }
    }
  }
}
