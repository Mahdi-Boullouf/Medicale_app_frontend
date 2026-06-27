import 'package:docmobi/l10n/app_localizations.dart';
import 'package:docmobi/screens/patient/appointments/patient_appointments_screen.dart';
import 'package:docmobi/screens/patient/profile/dependents_list_screen.dart';
import 'package:docmobi/screens/common/help_support_screen.dart';
import 'package:docmobi/screens/common/how_it_works_screen.dart';
import 'package:flutter/material.dart';
import 'package:docmobi/screens/patient/profile/personal_info_screen.dart';
import 'package:docmobi/screens/patient/profile/change_password_screen.dart';
import 'package:docmobi/screens/patient/navigation/patient_main_navigation.dart';

import 'package:provider/provider.dart' as legacy_provider;
import '../../../providers/user_provider.dart';
import '../../../services/auth_service.dart';
import 'package:docmobi/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../screens/auth/sign_in_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docmobi/providers/locale_provider.dart';

class PatientProfileScreen extends ConsumerStatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  ConsumerState<PatientProfileScreen> createState() =>
      _PatientProfileScreenState();
}

class _PatientProfileScreenState extends ConsumerState<PatientProfileScreen> {
  String selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      legacy_provider.Provider.of<UserProvider>(
        context,
        listen: false,
      ).fetchUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0B3267)),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const PatientMainNavigation(),
                ),
                (route) => false,
              );
            }
          },
        ),
        title: Text(
          l10n.appTitle,
          style: const TextStyle(
            color: Color(0xFF0B3267),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: legacy_provider.Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final l10n = AppLocalizations.of(context)!;
          // Get user data
          final user = userProvider.user;
          final userName = user?.fullName ?? 'The king';
          // final userLocation = 'Keim - Germany'; // Static for now
          final userLocation = user?.address ?? 'Location not set';

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),

                /// Profile Picture Section
                Stack(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Color(0xFF1664CD),
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 52,
                      ),
                    ),
                    if (userProvider.isLoading)
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black26,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 15),

                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B3267),
                  ),
                ),
                const SizedBox(height: 5),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, size: 14),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        userLocation,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                /// Menu Items
                _buildMenuItem(
                  icon: Icons.person_outline,
                  title: l10n.personalInfo,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PersonalInfoScreen(),
                      ),
                    );
                  },
                ),

                _buildMenuItem(
                  icon: Icons.calendar_today_outlined,
                  title: l10n.myAppointment,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PatientAppointmentsScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.group_add_outlined,
                  title: l10n.myDependents,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DependentsListScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.lock_outline,
                  title: l10n.changePasswordLabel,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChangePasswordScreen(),
                      ),
                    );
                  },
                ),

                // Language Selector
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.language, color: Color(0xFF1664CD)),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            l10n.changeLanguage,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF0B3267),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        // Replaced DropdownButton with an InkWell to show a custom dialog
                        InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text(l10n.selectLanguage),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.abc),
                                        title: Text(l10n.english),
                                        selected:
                                            currentLocale.languageCode == 'en',
                                        onTap: () {
                                          ref
                                              .read(localeProvider.notifier)
                                              .setLocale(const Locale('en'));
                                          Navigator.pop(context);
                                        },
                                      ),
                                      ListTile(
                                        leading: const Text(
                                          'ع',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        title: Text(l10n.arabic),
                                        selected:
                                            currentLocale.languageCode == 'ar',
                                        onTap: () {
                                          ref
                                              .read(localeProvider.notifier)
                                              .setLocale(const Locale('ar'));
                                          Navigator.pop(context);
                                        },
                                      ),
                                      ListTile(
                                        leading: const Text(
                                          'Fr',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        title: Text(l10n.french),
                                        selected:
                                            currentLocale.languageCode == 'fr',
                                        onTap: () {
                                          ref
                                              .read(localeProvider.notifier)
                                              .setLocale(const Locale('fr'));
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                          child: Row(
                            children: [
                              Text(
                                currentLocale.languageCode == 'en'
                                    ? l10n.english
                                    : currentLocale.languageCode == 'ar'
                                    ? l10n.arabic
                                    : l10n.french, // Display current language
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF0B3267),
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                _buildMenuItem(
                  icon: Icons.play_circle_outline,
                  title: l10n.howItWorks,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HowItWorksScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.help_outline,
                  title: l10n.helpSupport,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HelpSupportScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                /// Logout Button with API Integration
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: InkWell(
                    onTap: () => _showLogoutConfirmationDialog(context),
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.red, Colors.redAccent],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout, color: Colors.white),
                          const SizedBox(width: 10),
                          Text(
                            AppLocalizations.of(context)!.logOut,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // Logout Dialog with API Integration
  // Logout Dialog with API Integration
  void _showLogoutConfirmationDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(l10n.logOut),
        content: Text(l10n.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Pop confirmation dialog

              // Optimistic Logout Logic
              try {
                // 1. Clear local state immediately
                legacy_provider.Provider.of<UserProvider>(
                  context,
                  listen: false,
                ).clearUser();

                // 2. Navigate immediately
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) =>
                        const SignInScreen(userType: 'patient'),
                  ),
                  (route) => false,
                );

                // 3. Perform background cleanup (Fire and Forget)
                Future.wait([
                      AuthService().logout(),
                      ApiService.clearToken(),
                      SharedPreferences.getInstance().then(
                        (prefs) => prefs.clear(),
                      ),
                    ])
                    .then((_) {
                      debugPrint(' Background logout tasks completed');
                    })
                    .catchError((e) {
                      debugPrint(' Background logout tasks warning: $e');
                    });
              } catch (e) {
                debugPrint(' Error during optimistic logout: $e');
                // Even on error, we force navigation to login
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) =>
                        const SignInScreen(userType: 'patient'),
                  ),
                  (route) => false,
                );
              }
            },
            child: Text(l10n.logOut, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF1664CD)),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF0B3267),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
