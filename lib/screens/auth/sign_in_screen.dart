import 'package:docmobi/screens/onboarding/profile/select_profile_screen.dart';
import 'package:docmobi/services/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:docmobi/screens/patient/navigation/patient_main_navigation.dart';
import 'package:docmobi/screens/doctor/navigation/doctor_main_navigation.dart';
import 'package:docmobi/screens/auth/sign_up_screen.dart';
import 'package:docmobi/screens/auth/forgot_password_screen.dart';
import 'package:docmobi/widgets/custom_button.dart';
import 'package:docmobi/widgets/custom_text_field.dart';
import 'package:docmobi/services/api_service.dart';
import 'package:docmobi/services/agora_chat_service.dart';
import 'package:docmobi/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  @override
  void initState() {
    super.initState();
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

          // ✅ Socket connected after login
          await SocketService.instance.connect(userId);
          debugPrint('✅ Socket connected after login');

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
          final l10n = AppLocalizations.of(context)!;
          _showSnackBar(l10n.welcomeBackUser(userName), isError: false);

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
            if (mounted) setState(() => _isLoading = false);
            _showSnackBar('Invalid account type', isError: true);
            await ApiService.clearToken();
          }
        } else {
          // Wrong login type
          debugPrint(
            '⚠️ Role mismatch: Expected ${widget.userType}, Got $userRole',
          );
          if (mounted) setState(() => _isLoading = false);
          await ApiService.clearToken();
          final l10n = AppLocalizations.of(context)!;
          _showSnackBar(
            l10n.accountRegisteredAs(_capitalize(userRole ?? "user")),
            isError: true,
          );
        }
      } else {
        // Login failed
        debugPrint('❌ Login failed: ${result['message']}');
        if (mounted) setState(() => _isLoading = false);
        final l10n = AppLocalizations.of(context)!;
        _showSnackBar(result['message'] ?? l10n.loginFailed, isError: true);
      }
    } catch (e) {
      debugPrint('❌ Login error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);

      final l10n = AppLocalizations.of(context)!;
      _showSnackBar(l10n.connectionError, isError: true);
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
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(0, 255, 255, 255),
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
                        Text(
                          l10n.welcomeBack,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0B3267),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.loginToAccountAs(widget.userType),
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
                  Text(
                    l10n.emailAddress,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0B3267),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    hintText: l10n.emailHint,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: Color(0xFF1664CD),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// Password Field
                  Text(
                    l10n.password,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0B3267),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    hintText: l10n.passwordHint,
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
                      child: Text(
                        l10n.forgotPassword,
                        style: const TextStyle(
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
                      : CustomButton(
                          text: l10n.signIn,
                          onPressed: _handleSignIn,
                        ),

                  const SizedBox(height: 30),

                  /// Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l10n.dontHaveAccount),
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
                        child: Text(
                          l10n.signup,
                          style: const TextStyle(
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
