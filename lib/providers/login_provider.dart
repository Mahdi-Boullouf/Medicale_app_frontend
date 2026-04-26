import 'package:docmobi/l10n/app_localizations.dart';
import 'package:docmobi/screens/doctor/navigation/doctor_main_navigation.dart';
import 'package:docmobi/screens/onboarding/profile/select_profile_screen.dart';
import 'package:docmobi/screens/patient/navigation/patient_main_navigation.dart';
import 'package:docmobi/services/agora_chat_service.dart';
import 'package:docmobi/services/api_service.dart';
import 'package:docmobi/services/push_notification_service.dart';
import 'package:docmobi/services/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginProvider extends ChangeNotifier {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool get obscurePassword => _obscurePassword;
  bool get isLoading => _isLoading;
  TextEditingController get emailController => _emailController;
  TextEditingController get passwordController => _passwordController;
  GlobalKey<FormState> get formKey => _formKey;
  String userType = "";
  void toggleObscurePassword() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void updateUserType(String type) {
    userType = type;
    notifyListeners();
  }

  void handleSignIn(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    _isLoading = true;
    notifyListeners();

    try {
      debugPrint(' Starting login process...');

      final result = await ApiService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      debugPrint('Login result: ${result['success']}');

      if (result['success'] == true) {
        final userData = result['data'];
        final userRole =
            userData?['user']?['role']?.toString().toLowerCase() ??
            userData?['role']?.toString().toLowerCase();
        final userName =
            userData?['user']?['fullName'] ?? userData?['fullName'] ?? 'User';

        final userId =
            userData?['user']?['_id']?.toString() ??
            userData?['_id']?.toString();

        if (userId != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_id', userId);

          await SocketService.instance.connect(userId);
          debugPrint('Socket connected after login');

          try {
            await AgoraChatService.instance.init();
            await AgoraChatService.instance.login(userId);
            debugPrint('Agora Chat initialized after login');
          } catch (e) {
            debugPrint(' Agora Chat init error: $e');
          }

          try {
            await PushNotificationService.init();
            debugPrint('FCM Token registered after login');
          } catch (e) {
            debugPrint('FCM registration error: $e');
          }
        }

        debugPrint('Login successful - Role: $userRole');

        if (userRole == userType.toLowerCase()) {
          final l10n = AppLocalizations.of(context)!;
          _showSnackBar(
            context,
            l10n.welcomeBackUser(userName),
            isError: false,
          );

          await Future.delayed(const Duration(milliseconds: 500));

          if (userRole == 'patient') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const PatientMainNavigation(),
              ),
              (route) => false,
            );
          } else if (userRole == 'doctor') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const DoctorMainNavigation(),
              ),
              (route) => false,
            );
          }
        } else {
          debugPrint('Role mismatch: Expected $userType, Got $userRole');
          _isLoading = false;
          notifyListeners();
          await ApiService.clearToken();
          final l10n = AppLocalizations.of(context)!;
          _showSnackBar(
            context,
            l10n.accountRegisteredAs(_capitalize(userRole ?? "user")),
            isError: true,
          );
        }
      } else {
        debugPrint('Login failed: ${result['message']}');
        _isLoading = false;
        notifyListeners();
        final l10n = AppLocalizations.of(context)!;
        _showSnackBar(
          context,
          result['message'] ?? l10n.loginFailed,
          isError: true,
        );
      }
    } catch (e) {
      debugPrint('Login error: $e');
      _isLoading = false;
      notifyListeners();
      final l10n = AppLocalizations.of(context)!;
      _showSnackBar(context, l10n.connectionError, isError: true);
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  void _showSnackBar(
    BuildContext context,
    String message, {
    required bool isError,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  void handleBackPress(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SelectProfileScreen()),
      (route) => false,
    );
  }
}
