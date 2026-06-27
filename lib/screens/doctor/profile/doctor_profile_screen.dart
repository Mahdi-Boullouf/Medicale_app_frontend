import 'package:docmobi/l10n/app_localizations.dart';
import 'package:docmobi/screens/doctor/navigation/doctor_main_navigation.dart';
import 'package:docmobi/screens/common/help_support_screen.dart';
import 'package:docmobi/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:docmobi/screens/doctor/profile/doctor_personal_info_screen.dart';
import 'package:docmobi/screens/doctor/profile/doctor_my_schedule_screen.dart';
import 'package:docmobi/screens/doctor/profile/doctor_earnigs.dart';
import 'package:docmobi/screens/patient/profile/change_password_screen.dart';
import 'package:provider/provider.dart' as legacy_provider;
import '../../../providers/user_provider.dart';
import '../../../services/auth_service.dart';
import 'package:docmobi/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/sign_in_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docmobi/providers/locale_provider.dart';
import 'package:docmobi/screens/doctor/profile/doctor_vacation_screen.dart';
import 'package:docmobi/screens/common/how_it_works_screen.dart';
import 'package:docmobi/screens/doctor/profile/doctor_reviews_screen.dart';
import 'package:docmobi/screens/doctor/patients/mes_patients_screen.dart';

class DoctorProfileScreen extends ConsumerStatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  ConsumerState<DoctorProfileScreen> createState() =>
      _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends ConsumerState<DoctorProfileScreen> {
  bool _isSaving = false; // Track save state
  bool isVoiceVideoCallActive = false;
  String selectedLanguage = 'English';
  bool? _optimisticVideoCallValue; // Optimistic state for instant UI feedback

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    await legacy_provider.Provider.of<UserProvider>(
      context,
      listen: false,
    ).fetchUserProfile();
  }

  Future<void> _refreshProfile() async {
    await legacy_provider.Provider.of<UserProvider>(
      context,
      listen: false,
    ).fetchUserProfile();
  }

  Future<void> _toggleAppointments(bool disable) async {
    _isSaving = true;
    final userProvider = legacy_provider.Provider.of<UserProvider>(
      context,
      listen: false,
    );
    await userProvider.toggleAppointments(disable);
    _isSaving = false;
  }

  /// Save video call availability to backend with Optimistic UI
  Future<void> _toggleVideoCall(bool value) async {
    // 1. Optimistic Update: Update UI immediately
    setState(() {
      _optimisticVideoCallValue = value;
      _isSaving = true;
    });

    try {
      final userProvider = legacy_provider.Provider.of<UserProvider>(
        context,
        listen: false,
      );

      debugPrint(' Toggling video call to: $value');

      // 2. Perform API Call - Use the dedicated method which ensures fees/schedule are sent
      final success = await userProvider.updateVideoCallAvailability(value);

      if (success) {
        debugPrint(' Video call setting saved successfully');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    value ? Icons.check_circle : Icons.cancel,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    value ? 'Calls are now Enabled' : 'Calls are now Disabled',
                  ),
                ],
              ),
              duration: const Duration(seconds: 2), // Shorter duration
              backgroundColor: value ? Colors.green : Colors.red,
              behavior: SnackBarBehavior.floating, // Floating is better UX
              margin: const EdgeInsets.all(20),
            ),
          );
        }
      } else {
        throw Exception('Update failed');
      }
    } catch (e) {
      debugPrint('Error updating video call setting: $e');

      // 3. Rollback on Error
      if (mounted) {
        setState(() {
          _optimisticVideoCallValue = null; // Revert to provider value
        });

        // Refresh to ensure sync
        await _refreshProfile();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      // 4. Cleanup
      if (mounted) {
        setState(() {
          _isSaving = false;
          _optimisticVideoCallValue = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(0, 255, 255, 255),
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
                  builder: (context) => const DoctorMainNavigation(),
                ),
                (route) => false,
              );
            }
          },
        ),
        automaticallyImplyLeading: false,
        title: Text(
          l10n.appTitle, // Using localized title
          style: const TextStyle(
            color: Color(0xFF1B2C49),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: legacy_provider.Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final l10n = AppLocalizations.of(context)!;
          final user = userProvider.user;
          final isLoading = userProvider.isLoading;

          if (isLoading && user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final userName = user?.fullName ?? 'Doctor';
          final userRole = user?.role ?? 'doctor';
//  Use Optimistic Value if available, otherwise Provider value
          final appointementsDisabled = user?.appointmentsDisabled ?? false;
          final isVideoCallAvailable =
              _optimisticVideoCallValue ??
              (user?.isVideoCallAvailable ?? false);

          return RefreshIndicator(
            onRefresh: _refreshProfile,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Profile Picture Section
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            const CircleAvatar(
                              radius: 55,
                              backgroundColor: Color(0xFF1664CD),
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 58,
                              ),
                            ),
                            if (isLoading)
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
                        const SizedBox(height: 12),
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B2C49),
                          ),
                        ),
                        Text(
                          userRole.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        // Show Specialty
                        if (user?.specialty != null &&
                            user!.specialty!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            user.specialty!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1664CD),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],

                        // Show Bio
                        if (user?.bio != null && user!.bio!.isNotEmpty) ...[
                          const SizedBox(height: 15),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 25),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE9F0FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user.bio!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1B2C49),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Profile Menu Items
                  _buildProfileItem(
                    icon: Icons.person_outline,
                    title: l10n.personalInfo,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const DoctorPersonalInfoScreen(),
                        ),
                      );
                      if (result == true) {
                        _refreshProfile();
                      }
                    },
                  ),
                  _buildProfileItem(
                    icon: userProvider.isAppointmentsDisabled
                        ? Icons.disabled_by_default_outlined
                        : Icons.disabled_by_default_rounded,
                    title: "Disable all appointements",
                    onTap: null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: userProvider.isAppointmentsDisabled,
                          onChanged: _isSaving
                              ? null
                              : (value) => _toggleAppointments(value),
                          activeThumbColor: const Color(0xFF1664CD),
                          activeTrackColor: const Color(
                            0xFF1664CD,
                          ).withValues(alpha: 0.3),
                          inactiveThumbColor: Colors.grey.shade400,
                          inactiveTrackColor: Colors.grey.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildProfileItem(
                    icon: isVideoCallAvailable
                        ? Icons.videocam
                        : Icons.videocam_off,
                    title: l10n.audioVideoCalls,
                    onTap: _isSaving
                        ? null
                        : () => _toggleVideoCall(!isVideoCallAvailable),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isVideoCallAvailable
                                ? const Color(0xFF1664CD).withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isVideoCallAvailable
                                  ? const Color(0xFF1664CD)
                                  : Colors.red,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isVideoCallAvailable
                                    ? Icons.check_circle_outline
                                    : Icons.cancel_outlined,
                                size: 14,
                                color: isVideoCallAvailable
                                    ? const Color(0xFF1664CD)
                                    : Colors.red,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isVideoCallAvailable ? "Enabled" : "Disabled",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isVideoCallAvailable
                                      ? const Color(0xFF1664CD)
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Toggle switch
                        Switch(
                          value: isVideoCallAvailable,
                          onChanged: _isSaving ? null : _toggleVideoCall,
                          activeThumbColor: const Color(0xFF1664CD),
                          activeTrackColor: const Color(
                            0xFF1664CD,
                          ).withValues(alpha: 0.3),
                          inactiveThumbColor: Colors.grey.shade400,
                          inactiveTrackColor: Colors.grey.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildProfileItem(
                    icon: Icons.calendar_today_outlined,
                    title: l10n.appointmentSetting,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DoctorMyScheduleScreen(),
                        ),
                      );
                    },
                  ),
                  _buildProfileItem(
                    icon: Icons.beach_access_outlined,
                    title: "My Vacations",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DoctorVacationScreen(),
                        ),
                      );
                    },
                  ),


                  _buildProfileItem(
                    icon: Icons.people_outline,
                    title: l10n.mesPatients,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MesPatientsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildProfileItem(
                    icon: Icons.star_outline,
                    title: l10n.myReviews,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DoctorReviewsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildProfileItem(
                    assetIconPath: 'assets/images/algerian.png',
                    title: l10n.myEarning,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EarningOverviewScreen(),
                        ),
                      );
                    },
                  ),

                  // Language Selector
                  _buildProfileItem(
                    icon: Icons.language,
                    title: l10n.changeLanguage,
                    trailing: Text(
                      currentLocale.languageCode == 'en'
                          ? l10n.english
                          : currentLocale.languageCode == 'ar'
                          ? l10n.arabic
                          : l10n.french,
                      style: const TextStyle(
                        color: Color(0xFF1664CD),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(l10n.selectLanguage),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.abc),
                                title: Text(l10n.english),
                                selected: currentLocale.languageCode == 'en',
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
                                selected: currentLocale.languageCode == 'ar',
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
                                selected: currentLocale.languageCode == 'fr',
                                onTap: () {
                                  ref
                                      .read(localeProvider.notifier)
                                      .setLocale(const Locale('fr'));
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  _buildProfileItem(
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

                  _buildProfileItem(
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
                  _buildProfileItem(
                    assetIconPath: 'assets/icons/help&support.png',
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
                  const SizedBox(height: 25),

                  // Logout Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: () => _showLogoutConfirmationDialog(context),
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: Text(
                          l10n.logOut,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileItem({
    IconData? icon,
    String? assetIconPath,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F0FF),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: icon != null
              ? Icon(icon, color: const Color(0xFF1B2C49), size: 22)
              : Image.asset(
                  assetIconPath!,
                  width: 22,
                  height: 22,
                  fit: BoxFit.contain,
                ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF1B2C49),
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing:
            trailing ??
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF1B2C49),
            ),
      ),
    );
  }

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
            child: Text(l10n.cancel),
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
                        const SignInScreen(userType: 'doctor'),
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
                        const SignInScreen(userType: 'doctor'),
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
}
