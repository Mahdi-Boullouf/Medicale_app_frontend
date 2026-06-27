import 'dart:convert';
import 'package:docmobi/l10n/app_localizations.dart';

import 'package:docmobi/screens/patient/home/full_map_screen.dart';
import 'package:docmobi/screens/patient/home/upcoming_appointment_card.dart';
import 'package:docmobi/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docmobi/models/doctor_model.dart';
import 'package:docmobi/providers/doctor_provider.dart';
import 'package:docmobi/providers/appointment_provider.dart';
import 'package:docmobi/providers/user_provider.dart';
import 'package:docmobi/providers/notification_provider.dart';
import 'package:docmobi/screens/patient/home/see_all_doctors_screen.dart';
import 'package:docmobi/screens/patient/home/search_doctor_screen.dart';
import 'package:docmobi/screens/patient/doctor/doctor_detail_screen.dart';
import 'package:docmobi/screens/patient/doctor/book_appointment_screen.dart';
import 'package:docmobi/screens/patient/notification/patient_notification_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../services/location_service.dart';
import '../../../services/directions_service.dart';
import '../../../utils/marker_factory.dart';
import 'package:docmobi/screens/patient/profile/patient_profile_screen.dart';
import 'package:docmobi/screens/location/location_picker_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../widgets/custom_image.dart';
import 'dart:async';

class PatientHomeScreen extends ConsumerStatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  ConsumerState<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends ConsumerState<PatientHomeScreen> {
  // When true, skips the 50 km distance filter so all doctors are shown regardless of location
  static const bool testingMode = false;

  final LocationService _locationService = LocationService();
  final MarkerFactory _markerFactory = MarkerFactory();
  final DirectionsService _directionsService = DirectionsService();

  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _mapController;

  // Specialty options (Fetched from backend)
  List<String> specialties = [];
  bool isLoadingCategories = true;

  LatLng _currentPosition = const LatLng(23.8103, 90.4125);
  bool _isLoadingLocation = true;
  bool _locationPermissionGranted = false;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  final Set<Polyline> _directionPolylines = {};

  Timer? _refreshTimer;
  bool _isScreenInitialized = false;
  String? selectedSpeciality;
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isScreenInitialized) {
        _isScreenInitialized = true;
        _initializeScreen();
        _startAutoRefresh();
      }
    });
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      // Refresh every 5 minutes to avoid constant background activity
      if (mounted) {
        _onRefresh();
      }
    });
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await ApiService.getAllCategories();
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> categoryData = response['data'];
        setState(() {
          specialties = categoryData
              .map((c) => c['speciality_name'] as String)
              .toList();
          isLoadingCategories = false;
        });
      } else {
        setState(() => isLoadingCategories = false);
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      setState(() => isLoadingCategories = false);
    }
  }

  Future<void> _initializeScreen() async {
    try {
      final userProvider = legacy_provider.Provider.of<UserProvider>(
        context,
        listen: false,
      );
      final doctorProvider = legacy_provider.Provider.of<DoctorProvider>(
        context,
        listen: false,
      );
      final appointmentProvider = legacy_provider
          .Provider.of<AppointmentProvider>(context, listen: false);

      await Future.wait([
        if (userProvider.user == null) userProvider.loadFromCache(),
        if (appointmentProvider.appointments.isEmpty)
          appointmentProvider.loadFromCache(),
        if (doctorProvider.nearbyDoctors.isEmpty)
          doctorProvider.loadFromCache(),
      ]);

      // User profile
      userProvider.fetchUserProfile().then(
        (_) => debugPrint('✅ Fresh user profile loaded'),
        onError: (e) {
          debugPrint('Error fetching user profile: $e');
          return false;
        },
      );
      _fetchCategories();

      // Appointments
      appointmentProvider.fetchAppointments().then(
        (_) => debugPrint('✅ Appointments loaded'),
        onError: (e) {
          debugPrint('Error fetching appointments: $e');
          return false;
        },
      );

      _getCurrentLocation()
          .then((_) {
            if (mounted) {
              double? lat = _currentPosition.latitude;
              double? lng = _currentPosition.longitude;

              if (lat == 0 && lng == 0) {
                lat = null;
                lng = null;
              }

              doctorProvider
                  .fetchNearbyDoctors(lat: lat, lng: lng)
                  .then(
                    (_) => debugPrint('✅ Doctors loaded'),
                    onError: (e) {
                      debugPrint('Error fetching doctors: $e');
                      return false;
                    },
                  );
            }
          })
          .catchError((e) {
            debugPrint('Error getting location: $e');
            if (mounted) {
              setState(() => _isLoadingLocation = false);
            }
          });
    } catch (e) {
      debugPrint('Error initializing screen: $e');
      setState(() {
        _isLoadingLocation = false;
      });
    }
    _checkLocationAndPrompt();
  }

  Future<void> _checkLocationAndPrompt() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final alreadyShown = prefs.getBool('location_prompt_shown_patient') ?? false;
    if (alreadyShown) return;
    await prefs.setBool('location_prompt_shown_patient', true);
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) _showLocationBottomSheet();
  }

  void _showLocationBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1664CD).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: Color(0xFF1664CD),
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Définissez votre localisation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B2C49),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Partagez votre position pour trouver les médecins les plus proches de chez vous.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  final result = await Navigator.push<Map<String, dynamic>>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LocationPickerScreen(),
                    ),
                  );
                  if (result != null && mounted) {
                    await legacy_provider.Provider.of<UserProvider>(
                      context,
                      listen: false,
                    ).fetchUserProfile();
                  }
                },
                icon: const Icon(Icons.my_location_rounded, color: Colors.white),
                label: const Text(
                  'Définir ma localisation',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1664CD),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Plus tard',
                style: TextStyle(color: Colors.black45, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
            _locationPermissionGranted = false;
          });
          _showLocationServiceDialog();
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          if (mounted) {
            setState(() {
              _isLoadingLocation = false;
              _locationPermissionGranted = false;
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied');
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
            _locationPermissionGranted = false;
          });
          _showPermissionDeniedDialog();
        }
        return;
      }

      if (mounted) {
        setState(() {
          _locationPermissionGranted = true;
        });
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );

      debugPrint(
        'Location obtained: ${position.latitude}, ${position.longitude}',
      );

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });

        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_currentPosition, 14),
        );

        _printCurrentLocation();
        _addDoctorMarkers();
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _locationPermissionGranted = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.loading} : ${e.toString()}'),
            action: SnackBarAction(
              label: l10n.retry,
              onPressed: _getCurrentLocation,
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Calculate distance wrapper
  double _calculateDistanceInKm(LatLng from, LatLng to) {
    return _locationService.calculateDistanceInKm(from, to);
  }

  void _showLocationServiceDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.locationServicesDisabledTitle),
          content: Text(l10n.locationServicesDisabledMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openLocationSettings();
              },
              child: Text(l10n.openSettings),
            ),
          ],
        );
      },
    );
  }

  void _showPermissionDeniedDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.locationPermissionRequiredTitle),
          content: Text(l10n.locationPermissionRequiredMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openAppSettings();
              },
              child: Text(l10n.openSettings),
            ),
          ],
        );
      },
    );
  }

  Future<void> _printCurrentLocation() async {
    if (!_locationPermissionGranted) {
      debugPrint('Location permission নাই');
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      final locationData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': DateTime.now().toIso8601String(),
      };
      debugPrint('Latitude : ${position.latitude}');
      debugPrint('Longitude: ${position.longitude}');
      debugPrint('Timestamp: ${DateTime.now().toIso8601String()}');
      debugPrint(json.encode(locationData));
    } catch (e) {
      debugPrint(' Location নিতে error: $e');
    }
  }

  Color _getRouteColor(double distanceKm) {
    if (distanceKm <= 5) {
      return Colors.green;
    } else if (distanceKm <= 10) {
      return Colors.lightGreen;
    } else if (distanceKm <= 15) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Future<void> _addDoctorMarkers() async {
    try {
      final doctors = context.read<DoctorProvider>().nearbyDoctors;
      Set<Marker> markers = {};
      Set<Polyline> polylines = {};

      // Add user location marker
      markers.add(_markerFactory.createUserMarker(_currentPosition));
      debugPrint(' DOCTOR MARKERS');
      debugPrint(
        ' Patient Location: ${_currentPosition.latitude}, ${_currentPosition.longitude}',
      );
      debugPrint(' Total Doctors: ${doctors.length}');

      for (int i = 0; i < doctors.length; i++) {
        final doctor = doctors[i];

        if (doctor.latitude != null && doctor.longitude != null) {
          final doctorLocation = LatLng(doctor.latitude!, doctor.longitude!);

          double distanceKm = _locationService.calculateDistanceInKm(
            _currentPosition,
            doctorLocation,
          );

          final marker = await _markerFactory.createCustomDoctorMarker(
            doctor: doctor,
            distanceKm: distanceKm,
            onTap: () {
              _showDoctorRoute(doctor.id, doctorLocation, distanceKm);
            },
          );
          markers.add(marker);

          Color routeColor = _getRouteColor(distanceKm);

          polylines.add(
            Polyline(
              polylineId: PolylineId('route_${doctor.id}'),
              points: [_currentPosition, doctorLocation],
              color: routeColor,
              width: 4,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
              geodesic: true,
              patterns: distanceKm > 15
                  ? [PatternItem.dash(20), PatternItem.gap(10)]
                  : [],
            ),
          );
        }
      }
      debugPrint('📍 SUMMARY:');
      debugPrint('   - Total Markers: ${markers.length}');
      debugPrint('   - Total Routes: ${polylines.length}');

      if (mounted) {
        setState(() {
          _markers = markers;
          _polylines = polylines;
        });
      }
    } catch (e) {
      debugPrint(' Error adding doctor markers: $e');
    }
  }

  void _showDoctorRoute(
    String doctorId,
    LatLng doctorLocation,
    double distance,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    // Set selected doctor
    // if (mounted) {
    //   setState(() {
    //     // _selectedDoctorId = doctorId;
    //   });
    // }

    debugPrint('🗺️ Fetching street-level directions...');

    // Show loading snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text(l10n.loadingRoute),
          ],
        ),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.blue,
      ),
    );

    // Fetch directions from Google Maps Directions API
    final directions = await _directionsService.getDirections(
      origin: _currentPosition,
      destination: doctorLocation,
    );

    if (directions != null && mounted) {
      final polylinePoints = directions['polylinePoints'] as List<LatLng>;

      debugPrint('Street route loaded with ${polylinePoints.length} points');
      debugPrint(' Distance via road: ${directions['distance']}');
      debugPrint(' Estimated time: ${directions['duration']}');

      setState(() {
        // Clear old direction polylines
        _directionPolylines.clear();

        // Add new street-level direction polyline
        _directionPolylines.add(
          Polyline(
            polylineId: PolylineId('direction_$doctorId'),
            points: polylinePoints,
            color: Colors.blue,
            width: 6,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            geodesic: true,
            patterns: [],
          ),
        );
      });

      // Zoom to show both user and doctor location
      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(
          _currentPosition.latitude < doctorLocation.latitude
              ? _currentPosition.latitude
              : doctorLocation.latitude,
          _currentPosition.longitude < doctorLocation.longitude
              ? _currentPosition.longitude
              : doctorLocation.longitude,
        ),
        northeast: LatLng(
          _currentPosition.latitude > doctorLocation.latitude
              ? _currentPosition.latitude
              : doctorLocation.latitude,
          _currentPosition.longitude > doctorLocation.longitude
              ? _currentPosition.longitude
              : doctorLocation.longitude,
        ),
      );

      _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));

      // Show distance and duration info
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.directions_car, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                '${directions['distance']} • ${directions['duration']}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate to doctor details after showing route
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        final doctor = context.read<DoctorProvider>().nearbyDoctors.firstWhere(
          (d) => d.id == doctorId,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorDetailsScreen(doctor: doctor),
          ),
        );
      }
    } else {
      debugPrint(' Could not fetch street directions, using straight line');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.directionsApiDisabled,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Still zoom to location
        LatLngBounds bounds = LatLngBounds(
          southwest: LatLng(
            _currentPosition.latitude < doctorLocation.latitude
                ? _currentPosition.latitude
                : doctorLocation.latitude,
            _currentPosition.longitude < doctorLocation.longitude
                ? _currentPosition.longitude
                : doctorLocation.longitude,
          ),
          northeast: LatLng(
            _currentPosition.latitude > doctorLocation.latitude
                ? _currentPosition.latitude
                : doctorLocation.latitude,
            _currentPosition.longitude > doctorLocation.longitude
                ? _currentPosition.longitude
                : doctorLocation.longitude,
          ),
        );

        _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 100),
        );

        // Navigate to doctor details
        final doctor = context.read<DoctorProvider>().nearbyDoctors.firstWhere(
          (d) => d.id == doctorId,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorDetailsScreen(doctor: doctor),
          ),
        );
      }
    }
  }

  Future<void> _onRefresh() async {
    try {
      debugPrint(' Refreshing patient home screen...');

      // Get current location for doctor fetch
      double? lat = _currentPosition.latitude;
      double? lng = _currentPosition.longitude;

      // If location is default, don't pass it
      if (lat == 0 && lng == 0) {
        lat = null;
        lng = null;
      }

      await Future.wait([
        // Refresh user profile (name, avatar)
        legacy_provider.Provider.of<UserProvider>(
          context,
          listen: false,
        ).fetchUserProfile().catchError((e) {
          debugPrint('⚠️ Error refreshing user profile: $e');
          return false;
        }),
        // Refresh doctors with location
        legacy_provider.Provider.of<DoctorProvider>(
          context,
          listen: false,
        ).fetchNearbyDoctors(lat: lat, lng: lng).catchError((e) {
          debugPrint('⚠️ Error refreshing doctors: $e');
          return false;
        }),
        // Refresh appointments
        legacy_provider.Provider.of<AppointmentProvider>(
          context,
          listen: false,
        ).fetchAppointments().catchError((e) {
          debugPrint('⚠️ Error refreshing appointments: $e');
          return false;
        }),
      ]);

      // Only update markers if still mounted
      if (mounted) {
        await _addDoctorMarkers();
      }

      debugPrint('Refresh complete');
    } catch (e) {
      debugPrint(' Error during refresh: $e');
      // Don't rethrow - let the RefreshIndicator complete gracefully
    }
  }

  String _calculateDistance(Doctor doctor) {
    final l10n = AppLocalizations.of(context)!;
    if (doctor.latitude != null && doctor.longitude != null) {
      try {
        final latLngDoctor = LatLng(doctor.latitude!, doctor.longitude!);
        double distanceKm = _locationService.calculateDistanceInKm(
          _currentPosition,
          latLngDoctor,
        );

        if (distanceKm < 1) {
          return '${(distanceKm * 1000).round()} m';
        } else {
          return '${distanceKm.toStringAsFixed(1)} km';
        }
      } catch (e) {
        debugPrint('Error calculating distance: $e');
        return l10n.notAvailable;
      }
    }
    return doctor.distance;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userProvider = legacy_provider.Provider.of<UserProvider>(context);
    final generalUnreadCountValue = ref.watch(generalUnreadCountProvider);
    print(specialties);
    return Scaffold(
      backgroundColor: const Color(0xFFF1F6FF),
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header & Search
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const PatientProfileScreen(),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 28,
                                        backgroundColor: const Color(0xFF1664CD),
                                        child: const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                      ),

                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              userProvider.user?.fullName ??
                                                  'The King',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1B2C49),
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.location_on,
                                                  size: 16,
                                                  color: Colors.grey,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    userProvider
                                                            .user
                                                            ?.address ??
                                                        'Location not set',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Search Icon
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SearchDoctorScreen(
                                      userPosition: _currentPosition,
                                    ),
                                  ),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.search,
                                    size: 28,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Notification Icon
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const NotificationScreen(),
                                  ),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      const Icon(
                                        Icons.notifications_none_rounded,
                                        size: 28,
                                        color: Colors.black87,
                                      ),
                                      if (generalUnreadCountValue > 0)
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // const SizedBox(height: 20),
                          // Container(
                          //   decoration: BoxDecoration(
                          //     color: Colors.white,
                          //     borderRadius: BorderRadius.circular(12),
                          //     border: Border.all(
                          //       color: Colors.black.withValues(alpha: 0.1),
                          //     ),
                          //   ),
                          //   child: TextField(
                          //     controller: _searchController,
                          //     decoration: InputDecoration(
                          //       hintText: l10n.searchDoctorHint,
                          //       prefixIcon: const Icon(
                          //         Icons.search,
                          //         color: Colors.grey,
                          //       ),
                          //       border: InputBorder.none,
                          //       contentPadding: EdgeInsets.symmetric(
                          //         vertical: 15,
                          //       ),
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                    ),

                    // Google Map with Routes
                    Container(
                        height: 250,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: _isLoadingLocation
                              ? Container(
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(),
                                        SizedBox(height: 10),
                                        Text(
                                          l10n.loadingMap,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Stack(
                                  children: [
                                    GoogleMap(
                                      initialCameraPosition: CameraPosition(
                                        target: _currentPosition,
                                        zoom: 13,
                                      ),
                                      markers: _markers,
                                      polylines: {
                                        ..._polylines,
                                        ..._directionPolylines,
                                      },
                                      myLocationEnabled:
                                          _locationPermissionGranted,
                                      myLocationButtonEnabled: false,
                                      zoomControlsEnabled: true,
                                      zoomGesturesEnabled: true,
                                      scrollGesturesEnabled: true,
                                      tiltGesturesEnabled: true,
                                      rotateGesturesEnabled: true,
                                      mapType: MapType.normal,
                                      onMapCreated: (controller) {
                                        if (mounted) {
                                          _mapController = controller;
                                        }
                                      },
                                    ),
                                    // Map Legend
                                    Positioned(
                                      top: 10,
                                      right: 10,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.1,
                                              ),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              l10n.distance,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1B2C49),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            _buildLegendItem(
                                              Colors.green,
                                              '< 5 km',
                                            ),
                                            _buildLegendItem(
                                              Colors.lightGreen,
                                              '5-10 km',
                                            ),
                                            _buildLegendItem(
                                              Colors.orange,
                                              '10-15 km',
                                            ),
                                            _buildLegendItem(
                                              Colors.red,
                                              '> 15 km',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Zoom Controls
                                    Positioned(
                                      bottom: 10,
                                      left: 10,
                                      child: Column(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.1),
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.add,
                                                color: Color(0xFF0D47A1),
                                                size: 24,
                                              ),
                                              onPressed: () async {
                                                final currentZoom =
                                                    await _mapController
                                                        ?.getZoomLevel() ??
                                                    13;
                                                _mapController?.animateCamera(
                                                  CameraUpdate.zoomTo(
                                                    currentZoom + 1,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.1),
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.remove,
                                                color: Color(0xFF0D47A1),
                                                size: 24,
                                              ),
                                              onPressed: () async {
                                                final currentZoom =
                                                    await _mapController
                                                        ?.getZoomLevel() ??
                                                    13;
                                                _mapController?.animateCamera(
                                                  CameraUpdate.zoomTo(
                                                    currentZoom - 1,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Recenter Button
                                    if (_locationPermissionGranted)
                                      Positioned(
                                        bottom: 10,
                                        right: 10,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.1,
                                                ),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.my_location,
                                              color: Color(0xFF0D47A1),
                                              size: 24,
                                            ),
                                            onPressed: () async {
                                              if (!_locationPermissionGranted) {
                                                await _getCurrentLocation();
                                              } else {
                                                _mapController?.animateCamera(
                                                  CameraUpdate.newLatLngZoom(
                                                    _currentPosition,
                                                    14,
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    // Expand to Full Map Button
                                    Positioned(
                                      top: 10,
                                      left: 10,
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => FullMapScreen(
                                                currentPosition:
                                                    _currentPosition,
                                                markers: _markers,
                                                polylines: _polylines,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.15,
                                                ),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.fullscreen,
                                            color: Color(0xFF0D47A1),
                                            size: 22,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                    ),
                    const SizedBox(height: 25),

                    // Upcoming Appointment
                    legacy_provider.Consumer<AppointmentProvider>(
                      builder: (context, aptProvider, child) {
                        final now = DateTime.now();
                        final today = DateTime(now.year, now.month, now.day);

                        final upcoming =
                            aptProvider.upcomingAppointments.where((a) {
                              final appointmentDay = DateTime(
                                a.appointmentDate.year,
                                a.appointmentDate.month,
                                a.appointmentDate.day,
                              );
                              return appointmentDay.isAtSameMomentAs(today) ||
                                  appointmentDay.isAfter(today);
                            }).toList()..sort(
                              (a, b) => a.appointmentDate.compareTo(
                                b.appointmentDate,
                              ),
                            );

                        if (upcoming.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.upcomingAppointment,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B2C49),
                                ),
                              ),
                              const SizedBox(height: 15),
                              UpcomingAppointmentCard(
                                appointment: upcoming.first,
                              ),
                              const SizedBox(height: 25),
                            ],
                          ),
                        );
                      },
                    ),

                    // Nearby Doctors
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.nearbyDoctors,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B2C49),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SeeAllDoctorsScreen(
                                  userPosition: _currentPosition,
                                ),
                              ),
                            ),
                            child: Text(
                              l10n.seeAll,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 48,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: specialties.length + 1,
                        itemBuilder: (c, i) {
                          if (i == 0) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    selectedSpeciality = null;
                                  });
                                },
                                child: Chip(
                                  backgroundColor: selectedSpeciality == null
                                      ? Colors.blue
                                      : Colors.white,
                                  label: Text(
                                    "all",
                                    style: TextStyle(
                                      color: selectedSpeciality == null
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  selectedSpeciality = specialties[i - 1];
                                });
                              },
                              child: Chip(
                                backgroundColor:
                                    selectedSpeciality == specialties[i - 1]
                                    ? Colors.blue
                                    : Colors.white,
                                label: Text(
                                  specialties[i - 1],
                                  style: TextStyle(
                                    color:
                                        selectedSpeciality == specialties[i - 1]
                                        ? Colors.white
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        scrollDirection: Axis.horizontal,
                      ),
                    ),
                    // Doctors List
                    legacy_provider.Consumer<DoctorProvider>(
                      builder: (context, doctorProvider, child) {
                        if (doctorProvider.isLoading) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (doctorProvider.error != null) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text('Error: ${doctorProvider.error}'),
                            ),
                          );
                        }

                        //  Distance Filter: Only show doctors within 50 km
                        final nearbyDoctors = doctorProvider.nearbyDoctors
                            .where((doc) {
                              if (testingMode) return true;
                              if (doc.latitude == null ||
                                  doc.longitude == null) {
                                return false;
                              }
                              final distance = _calculateDistanceInKm(
                                _currentPosition,
                                LatLng(doc.latitude!, doc.longitude!),
                              );
                              return distance <= 50;
                            })
                            .toList();

                        if (nearbyDoctors.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text(l10n.noDoctorsFound),
                            ),
                          );
                        }
                        nearbyDoctors.sort((a, b) {
                          if (a.latitude == null || a.longitude == null) {
                            return 1;
                          }
                          if (b.latitude == null || b.longitude == null) {
                            return -1;
                          }

                          final distA = _calculateDistanceInKm(
                            _currentPosition,
                            LatLng(a.latitude!, a.longitude!),
                          );
                          final distB = _calculateDistanceInKm(
                            _currentPosition,
                            LatLng(b.latitude!, b.longitude!),
                          );

                          return distA.compareTo(distB);
                        });
                        final categorizedDoctors = nearbyDoctors.where((e) {
                          if (selectedSpeciality == null ||
                              selectedSpeciality!.isEmpty) {
                            return true;
                          }
                          return e.specialty == selectedSpeciality;
                        }).toList();
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: categorizedDoctors.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: 20,
                                left: 20,
                                right: 20,
                              ),
                              child: _buildCustomDoctorCard(
                                categorizedDoctors[index],
                              ),
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // if (_showLocationDialog)
            //   Container(
            //     color: Colors.black54,
            //     child: LocationPermissionDialog(onDismiss: _dismissDialog),
            //   ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  bool _isDoctorAvailable(Doctor doctor) {
    if (doctor.weeklySchedule == null || doctor.weeklySchedule!.isEmpty) {
      debugPrint(' ${doctor.fullName}: No weeklySchedule');
      return false;
    }

    for (var schedule in doctor.weeklySchedule!) {
      debugPrint(
        ' ${doctor.fullName} - ${schedule.day}: active=${schedule.isActive}, slots=${schedule.slots.length}',
      );

      if (schedule.isActive && schedule.slots.isNotEmpty) {
        debugPrint(' ${doctor.fullName}: Available on ${schedule.day}');
        return true;
      }
    }

    debugPrint(' ${doctor.fullName}: No active days with slots');
    return false;
  }

  Widget _buildCustomDoctorCard(Doctor doctor) {
    final l10n = AppLocalizations.of(context)!;
    final bool isAvailable = _isDoctorAvailable(doctor);
    final bool hasVideoCall = doctor.isVideoCallAvailable;
    final String visitingHours = _getVisitingHours(doctor);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: _buildDoctorImage(doctor.image),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            doctor.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isAvailable
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isAvailable ? l10n.available : l10n.noSchedule,
                            style: TextStyle(
                              color: isAvailable
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor.specialty,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 6),

                    if (hasVideoCall)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF2196F3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.videocam,
                              size: 14,
                              color: Color(0xFF1976D2),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.videoConsultation,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF1565C0),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (hasVideoCall) const SizedBox(height: 6),

                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            visitingHours,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.orangeAccent,
                        ),
                        Text(
                          ' ${doctor.rating.toStringAsFixed(1)} ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 15),
                        Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _calculateDistance(doctor),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isAvailable
                      ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                BookAppointmentScreen(doctor: doctor),
                          ),
                        )
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAvailable
                        ? const Color(0xFF0D47A1)
                        : Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isAvailable ? l10n.bookNow : l10n.notAvailable,
                    style: TextStyle(
                      color: isAvailable ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DoctorDetailsScreen(doctor: doctor),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Color(0xFF0D47A1),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorImage(String? imageUrl) {
    return CustomImage(
      imageUrl: imageUrl,
      width: 80,
      height: 80,
      fit: BoxFit.cover,
      placeholderAsset: 'assets/images/doctor_booking.png',
    );
  }

  String _getVisitingHours(Doctor doctor) {
    final l10n = AppLocalizations.of(context)!;
    if (doctor.weeklySchedule == null || doctor.weeklySchedule!.isEmpty) {
      return l10n.noScheduleSet;
    }

    List<String> activeDays = [];
    for (var schedule in doctor.weeklySchedule!) {
      if (schedule.isActive && schedule.slots.isNotEmpty) {
        String dayShort = schedule.day.length >= 3
            ? schedule.day.substring(0, 3)
            : schedule.day;
        activeDays.add(dayShort);
      }
    }

    if (activeDays.isEmpty) {
      return l10n.noScheduleSet;
    }

    if (activeDays.length == 1) {
      return activeDays[0];
    } else if (activeDays.length <= 3) {
      return activeDays.join(', ');
    } else {
      return '${activeDays.first}-${activeDays.last}';
    }
  }
}
