import 'package:flutter/material.dart';
import 'package:docmobi/widgets/custom_button.dart';
import 'package:docmobi/widgets/custom_text_field.dart';
import 'package:docmobi/services/api_service.dart';

class SignUpScreen extends StatefulWidget {
  final String userType;
  const SignUpScreen({super.key, required this.userType});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Doctor Specific Controllers
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  String? _selectedSpecialty;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final List<String> _specialties = [
    'Cardiologists',
    'Orthopedic',
    'Dermatologists',
    'Nephrologists',
    'General Medicine',
    'Nutrition & Dietetics',
    'Psychiatry',
    'Pediatrics',
    'Gynecology',
    'ENT Specialist',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _licenseController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  /// ✅ Validate form
  bool _validateForm() {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    // Check password match
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Passwords do not match', isError: true);
      return false;
    }

    // Check password length
    if (_passwordController.text.length < 6) {
      _showSnackBar('Password must be at least 6 characters', isError: true);
      return false;
    }

    // Doctor-specific validation
    if (widget.userType.toLowerCase() == 'doctor') {
      if (_licenseController.text.trim().isEmpty) {
        _showSnackBar('Medical license number is required', isError: true);
        return false;
      }

      if (_selectedSpecialty == null || _selectedSpecialty!.isEmpty) {
        _showSnackBar('Please select a specialty', isError: true);
        return false;
      }

      if (_experienceController.text.trim().isEmpty) {
        _showSnackBar('Years of experience is required', isError: true);
        return false;
      }
    }

    return true;
  }

  /// ✅ Handle Sign Up
  void _handleSignUp() async {
    // Validate form
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      debugPrint('🔄 Starting registration...');
      debugPrint('   User Type: ${widget.userType}');
      debugPrint('   Name: ${_nameController.text.trim()}');
      debugPrint('   Email: ${_emailController.text.trim()}');

      // ✅ Call ApiService.register with correct parameters
      final result = await ApiService.register(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: widget.userType.toLowerCase(), // 'doctor' or 'patient'
        medicalLicenseNumber: widget.userType.toLowerCase() == 'doctor'
            ? _licenseController.text.trim()
            : null,
        specialty: widget.userType.toLowerCase() == 'doctor'
            ? _selectedSpecialty
            : null,
        experienceYears: widget.userType.toLowerCase() == 'doctor'
            ? _experienceController.text.trim()
            : null,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      debugPrint('📥 Registration result: ${result['success']}');

      if (result['success'] == true) {
        debugPrint('✅ Registration successful');

        _showSnackBar(
          result['message'] ?? 'Registration successful!',
          isError: false,
        );

        // Small delay for better UX
        await Future.delayed(const Duration(seconds: 1));

        if (!mounted) return;

        // Go back to login screen
        Navigator.pop(context);
      } else {
        debugPrint('❌ Registration failed: ${result['message']}');

        String errorMessage = result['message'] ?? 'Registration failed';

        // Handle validation errors
        if (result['errors'] != null && result['errors'] is List) {
          final errors = result['errors'] as List;
          if (errors.isNotEmpty) {
            errorMessage = errors.join(', ');
          }
        }

        _showSnackBar(errorMessage, isError: true);
      }
    } catch (e) {
      debugPrint('❌ Registration error: $e');

      if (!mounted) return;

      setState(() => _isLoading = false);

      String errorMessage = 'Connection error. ';
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection')) {
        errorMessage += 'Please check if the server is running';
      } else {
        errorMessage += e.toString();
      }

      _showSnackBar(errorMessage, isError: true);
    }
  }

  /// ✅ Show snackbar
  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDoctor = widget.userType.toLowerCase() == 'doctor';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0B3267)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Center(
                  child: Image.asset(
                    'assets/images/icon.png',
                    height: 150,
                    width: 150,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.medical_services,
                      size: 80,
                      color: Color(0xFF1664CD),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Title
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Create ${widget.userType} Account',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0B3267),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please fill in the details below',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Full Name
                const Text(
                  "Full Name *",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0B3267),
                  ),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  hintText: "Enter your full name",
                  controller: _nameController,
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: Color(0xFF1664CD),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 15),

                // Email
                const Text(
                  "Email Address *",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0B3267),
                  ),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  hintText: "you@example.com",
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: Color(0xFF1664CD),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),

                // Doctor-specific fields
                if (isDoctor) ...[
                  const SizedBox(height: 15),

                  // Medical License
                  const Text(
                    "Medical License Number *",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0B3267),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    hintText: "Enter License Number",
                    controller: _licenseController,
                    prefixIcon: const Icon(
                      Icons.badge_outlined,
                      color: Color(0xFF1664CD),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Specialty
                  const Text(
                    "Medical Specialty *",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0B3267),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedSpecialty,
                        hint: const Text("Select your specialty"),
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xFF1664CD),
                        ),
                        items: _specialties
                            .map(
                              (specialty) => DropdownMenuItem(
                                value: specialty,
                                child: Text(specialty),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSpecialty = value;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Experience
                  const Text(
                    "Years of Experience *",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0B3267),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    hintText: "e.g., 5",
                    controller: _experienceController,
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(
                      Icons.work_outline,
                      color: Color(0xFF1664CD),
                    ),
                  ),
                ],

                const SizedBox(height: 15),

                // Password
                const Text(
                  "Password *",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0B3267),
                  ),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  hintText: "At least 6 characters",
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 15),

                // Confirm Password
                const Text(
                  "Confirm Password *",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0B3267),
                  ),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  hintText: "Re-enter your password",
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Color(0xFF1664CD),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 30),

                // Sign Up Button
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1664CD),
                        ),
                      )
                    : CustomButton(
                        text: "Create Account",
                        onPressed: _handleSignUp,
                      ),

                const SizedBox(height: 20),

                // Sign In Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: Colors.grey),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1664CD),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
