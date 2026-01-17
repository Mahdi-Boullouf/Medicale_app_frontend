import 'package:docmobi/screens/onboarding/profile/select_profile_screen.dart';
import 'package:docmobi/services/socket_service.dart';
import 'package:docmobi/providers/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:docmobi/screens/patient/navigation/patient_main_navigation.dart';
import 'package:docmobi/screens/doctor/navigation/doctor_main_navigation.dart';
import 'package:docmobi/screens/auth/sign_up_screen.dart';
import 'package:docmobi/screens/auth/forgot_password_screen.dart';
import 'package:docmobi/widgets/custom_button.dart';
import 'package:docmobi/widgets/custom_text_field.dart';
import 'package:docmobi/services/api_service.dart';
import 'package:docmobi/services/agora_chat_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

class SignInScreen extends StatefulWidget {
  final String userType;

  const SignInScreen({super.key, required this.userType});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _isLoading = false;
  NotificationProvider? _notificationProvider;

  @override
  void initState() {
    super.initState();
    // Initialize notification provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _notificationProvider = Provider.of<NotificationProvider>(
          context,
          listen: false,
        );
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      debugPrint('🔄 Starting login process...');

      // ✅ Use ApiService.login() instead of AuthService.login()
      final result = await ApiService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      debugPrint('📥 Login result: ${result['success']}');

      if (result['success'] == true) {
        // ✅ Get role from response
        final userData = result['data'];
        final userRole =
            userData?['user']?['role']?.toString().toLowerCase() ??
            userData?['role']?.toString().toLowerCase();
        final userName =
            userData?['user']?['fullName'] ?? userData?['fullName'] ?? 'User';

        // ✅ ADD THIS SECTION:
        final userId =
            userData?['user']?['_id']?.toString() ??
            userData?['_id']?.toString();

        if (userId != null) {
          // Save user ID
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_id', userId);

          // ✅ Connect socket
          await SocketService.instance.connect(userId);
          debugPrint('✅ Socket connected after login');

          // ✅ Start notification polling
          if (_notificationProvider != null) {
            await _notificationProvider!.startPolling();
            debugPrint('✅ Notification polling started after login');
          }

          // ✅ Initialize and login to Agora Chat
          try {
            await AgoraChatService.instance.init();
            await AgoraChatService.instance.login(userId);
            debugPrint('✅ Agora Chat initialized after login');
          } catch (e) {
            debugPrint('❌ Agora Chat init error: $e');
          }
        }

        debugPrint('✅ Login successful - Role: $userRole');
        debugPrint('   Expected role: ${widget.userType.toLowerCase()}');

        // ✅ Check if role matches expected type
        if (userRole == widget.userType.toLowerCase()) {
          _showSnackBar('Welcome back, $userName!', isError: false);

          // Small delay for better UX
          await Future.delayed(const Duration(milliseconds: 500));

          if (!mounted) return;

          // ✅ Navigate based on actual role
          if (userRole == 'patient') {
            debugPrint('🚀 Navigating to Patient screen');
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const PatientMainNavigation(),
              ),
              (route) => false,
            );
          } else if (userRole == 'doctor') {
            debugPrint('🚀 Navigating to Doctor screen');
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const DoctorMainNavigation(),
              ),
              (route) => false,
            );
          } else {
            // Unknown role
            debugPrint('⚠️ Unknown role: $userRole');
            _showSnackBar('Invalid account type', isError: true);
            await ApiService.clearToken();
          }
        } else {
          // Wrong login type
          debugPrint(
            '⚠️ Role mismatch: Expected ${widget.userType}, Got $userRole',
          );
          await ApiService.clearToken();
          _showSnackBar(
            'This account is registered as ${_capitalize(userRole ?? "user")}. '
            'Please use the correct login option.',
            isError: true,
          );
        }
      } else {
        // Login failed
        debugPrint('❌ Login failed: ${result['message']}');
        _showSnackBar(
          result['message'] ?? 'Login failed. Please check your credentials.',
          isError: true,
        );
      }
    } catch (e) {
      debugPrint('❌ Login error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);

      String errorMessage = 'Connection error. ';
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection')) {
        errorMessage +=
            'Please check if the server is running at http://localhost:5000';
      } else {
        errorMessage += e.toString();
      }

      _showSnackBar(errorMessage, isError: true);
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  void _handleBackPress() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SelectProfileScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF0B3267)),
            onPressed: _handleBackPress,
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Logo
                  Center(
                    child: Image.asset(
                      'assets/images/icon.png',
                      height: 200,
                      width: 200,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.medical_services,
                        size: 100,
                        color: Color(0xFF1664CD),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// Welcome Text
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          'Welcome back',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0B3267),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please Login to your Account as ${widget.userType}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  /// Email Field
                  const Text(
                    "Email Address",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0B3267),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    hintText: 'you@gmail.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: Color(0xFF1664CD),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// Password Field
                  const Text(
                    "Password",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0B3267),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    hintText: '****************',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: Color(0xFF1664CD),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Color(0xFF1664CD),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// Sign In Button
                  _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF1664CD),
                          ),
                        )
                      : CustomButton(text: 'Sign in', onPressed: _handleSignIn),

                  const SizedBox(height: 30),

                  /// Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? "),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SignUpScreen(userType: widget.userType),
                            ),
                          );
                        },
                        child: const Text(
                          'Signup',
                          style: TextStyle(
                            color: Color(0xFF1664CD),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
