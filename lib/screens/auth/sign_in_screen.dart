import 'package:docmobi/providers/login_provider.dart';

import 'package:flutter/material.dart';
import 'package:docmobi/screens/auth/sign_up_screen.dart';
import 'package:docmobi/screens/auth/forgot_password_screen.dart';
import 'package:docmobi/widgets/custom_button.dart';
import 'package:docmobi/widgets/custom_text_field.dart';
import 'package:docmobi/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class SignInScreen extends StatefulWidget {
  final String userType;

  const SignInScreen({super.key, required this.userType});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loginProvider = Provider.of<LoginProvider>(context, listen: false);
      loginProvider.updateUserType(widget.userType);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<LoginProvider>(
      builder: (context, loginProvider, child) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            loginProvider.handleBackPress(context);
          },
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: const Color.fromARGB(0, 255, 255, 255),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF0B3267)),
                onPressed: () => loginProvider.handleBackPress(context),
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: loginProvider.formKey,
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
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
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
                        controller: loginProvider.emailController,
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
                        controller: loginProvider.passwordController,
                        obscureText: loginProvider.obscurePassword,
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Color(0xFF1664CD),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            loginProvider.obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            loginProvider.toggleObscurePassword();
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
                                builder: (context) =>
                                    const ForgotPasswordScreen(),
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
                      loginProvider.isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF1664CD),
                              ),
                            )
                          : CustomButton(
                              text: l10n.signIn,
                              onPressed: () =>
                                  loginProvider.handleSignIn(context),
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
      },
    );
  }
}
