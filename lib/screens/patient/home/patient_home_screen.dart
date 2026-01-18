import 'dart:convert';

import 'package:docmobi/screens/patient/home/dialog/location_permission_dialog.dart';
import 'package:docmobi/screens/patient/home/upcoming_appointment_card.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:docmobi/models/doctor_model.dart';
import 'package:docmobi/providers/doctor_provider.dart';
import 'package:docmobi/providers/appointment_provider.dart';
import 'package:docmobi/providers/user_provider.dart';
import 'package:docmobi/providers/notification_provider.dart';
import 'package:docmobi/screens/patient/home/see_all_doctors_screen.dart';
import 'package:docmobi/screens/patient/doctor/doctor_detail_screen.dart';
import 'package:docmobi/screens/patient/doctor/book_appointment_screen.dart';
import 'package:docmobi/screens/patient/notification/notification_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../services/location_service.dart';
import '../../../utils/marker_factory.dart';
import 'package:docmobi/screens/patient/profile/patient_profile_screen.dart';
import '../../../widgets/custom_image.dart';
import 'dart:async'; // For Timer

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  final LocationService _locationService = LocationService();
  final MarkerFactory _markerFactory = MarkerFactory();
  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _mapController;
  Timer? _socketCheckTimer; // Timer for checking connection status

  static bool _hasShownLocationDialog = false;
  late bool _showLocationDialog;

  // Default location (Dhaka, Bangladesh)
  LatLng _currentPosition = const LatLng(23.8103, 90.4125);
  bool _isLoadingLocation = true;
  bool _locationPermissionGranted = false;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _showLocationDialog = !_hasShownLocationDialog;

    // Start periodic check for socket status
    _socketCheckTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  Future<void> _initializeScreen() async {
    try {
      await Future.wait([
        context.read<DoctorProvider>().fetchNearbyDoctors(),
        context.read<AppointmentProvider>().fetchAppointments(),
      ]);

      // Delay location request to avoid crash
      await Future.delayed(const Duration(milliseconds: 500));
      await _getCurrentLocation();
    } catch (e) {
      debugPrint('Error initializing screen: $e');
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  @override
  void dispose() {
    _socketCheckTimer?.cancel(); // Cancel timer
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _dismissDialog() {
    setState(() {
      _showLocationDialog = false;
      _hasShownLocationDialog = true;
    });
  }

  Future<void> _getCurrentLocation() async {
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
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
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
            content: Text('Unable to get your location: ${e.toString()}'),
            action: SnackBarAction(
              label: 'Retry',
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Services Disabled'),
          content: const Text(
            'Location services are disabled. Please enable them to see nearby doctors.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openLocationSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
            'Location permission is required to show nearby doctors. Please grant permission in app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  /// 🔥 Console এ location print করবে
  Future<void> _printCurrentLocation() async {
    if (!_locationPermissionGranted) {
      debugPrint('⚠️ Location permission নাই');
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

      debugPrint('');
      debugPrint('📍 ==========================================');
      debugPrint('📍 CURRENT LOCATION (প্রতি 10 সেকেন্ডে update)');
      debugPrint('📍 ==========================================');
      debugPrint('Latitude : ${position.latitude}');
      debugPrint('Longitude: ${position.longitude}');
      debugPrint('Timestamp: ${DateTime.now().toIso8601String()}');
      debugPrint('📍 ==========================================');
      debugPrint('📍 JSON FORMAT (Backend Developer এর জন্য):');
      debugPrint(json.encode(locationData));
      debugPrint('📍 ==========================================');
      debugPrint('');
    } catch (e) {
      debugPrint('❌ Location নিতে error: $e');
    }
  }

  // Get color based on distance (Green for near, Red for far)
  Color _getRouteColor(double distanceKm) {
    if (distanceKm <= 5) {
      return Colors.green; // Very close
    } else if (distanceKm <= 10) {
      return Colors.lightGreen; // Close
    } else if (distanceKm <= 15) {
      return Colors.orange; // Medium distance
    } else {
      return Colors.red; // Far
    }
  }

  void _addDoctorMarkers() {
    try {
      final doctors = context.read<DoctorProvider>().nearbyDoctors;
      Set<Marker> markers = {};
      Set<Polyline> polylines = {};

      // Add user location marker
      markers.add(_markerFactory.createUserMarker(_currentPosition));

      for (int i = 0; i < doctors.length; i++) {
        final doctor = doctors[i];
        LatLng doctorLocation;

        if (doctor.latitude != null && doctor.longitude != null) {
          doctorLocation = LatLng(doctor.latitude!, doctor.longitude!);
        } else {
          // Fallback: Generate random nearby location (for demo)
          final lat = _currentPosition.latitude + (i * 0.01);
          final lng = _currentPosition.longitude + (i * 0.01);
          doctorLocation = LatLng(lat, lng);
        }

        // Calculate distance via service
        double distanceKm = _locationService.calculateDistanceInKm(
          _currentPosition,
          doctorLocation,
        );

        // Only show doctors within 20 km
        if (distanceKm <= 20) {
          // Use MarkerFactory
          markers.add(
            _markerFactory.createDoctorMarker(
              doctor: doctor,
              distanceKm: distanceKm,
              onTap: () {
                _showDoctorRoute(doctor.id, doctorLocation, distanceKm);
              },
            ),
          );

          // Add polyline route from user to doctor
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

      if (mounted) {
        setState(() {
          _markers = markers;
          _polylines = polylines;
        });
      }
    } catch (e) {
      debugPrint('Error adding doctor markers: $e');
    }
  }

  void _showDoctorRoute(
    String doctorId,
    LatLng doctorLocation,
    double distance,
  ) {
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

    // Find doctor and navigate to details
    final doctor = context.read<DoctorProvider>().nearbyDoctors.firstWhere(
      (d) => d.id == doctorId,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DoctorDetailsScreen(doctor: doctor)),
    );
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      context.read<DoctorProvider>().fetchNearbyDoctors(),
      context.read<AppointmentProvider>().fetchAppointments(),
    ]);
    _addDoctorMarkers();
  }

  String _calculateDistance(Doctor doctor) {
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
        return 'N/A';
      }
    }
    return doctor.distance;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

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
                                      CustomImage(
                                        imageUrl:
                                            userProvider.user?.profileImage,
                                        width: 56,
                                        height: 56,
                                        shape: BoxShape.circle,
                                        placeholderAsset:
                                            'assets/images/profile.png',
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
                                      ValueListenableBuilder<int>(
                                        valueListenable: context
                                            .read<NotificationProvider>()
                                            .generalUnreadCount,
                                        builder: (context, count, child) {
                                          if (count == 0) {
                                            return const SizedBox.shrink();
                                          }
                                          return Positioned(
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
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.black.withValues(alpha: 0.1),
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: 'Search Doctor...',
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Colors.grey,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                              ),
                            ),
                          ),
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
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(height: 10),
                                      Text(
                                        'Loading map...',
                                        style: TextStyle(color: Colors.grey),
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
                                    polylines: _polylines,
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
                                        borderRadius: BorderRadius.circular(8),
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
                                          _buildLegendItem(
                                            Colors.green,
                                            '0-5 km',
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
                                            '15-20 km',
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
                                        // Zoom In Button
                                        Container(
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
                                        // Zoom Out Button
                                        Container(
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
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Upcoming Appointment
                    Consumer<AppointmentProvider>(
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
                              const Text(
                                "Upcoming Appointment",
                                style: TextStyle(
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
                          const Text(
                            "Nearby Doctors ",
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B2C49),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SeeAllDoctorsScreen(),
                              ),
                            ),
                            child: const Text(
                              'See All',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Doctors List
                    Consumer<DoctorProvider>(
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

                        // Filter doctors within 20km
                        final nearbyDoctors = doctorProvider.nearbyDoctors
                            .where((doctor) {
                              if (doctor.latitude != null &&
                                  doctor.longitude != null) {
                                final doctorLocation = LatLng(
                                  doctor.latitude!,
                                  doctor.longitude!,
                                );
                                final distance = _calculateDistanceInKm(
                                  _currentPosition,
                                  doctorLocation,
                                );
                                return distance <= 20;
                              }
                              return true; // Include doctors without location
                            })
                            .toList();

                        if (nearbyDoctors.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text('No doctors found within 20km'),
                            ),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: nearbyDoctors.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: 20,
                                left: 20,
                                right: 20,
                              ),
                              child: _buildCustomDoctorCard(
                                nearbyDoctors[index],
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
    print('❌ ${doctor.fullName}: No weeklySchedule');
    return false;
  }

  // Check if at least one day is active with slots
  for (var schedule in doctor.weeklySchedule!) {
    print('📅 ${doctor.fullName} - ${schedule.day}: active=${schedule.isActive}, slots=${schedule.slots.length}');
    
    if (schedule.isActive && schedule.slots.isNotEmpty) {
      print('✅ ${doctor.fullName}: Available on ${schedule.day}');
      return true;
    }
  }

  print('❌ ${doctor.fullName}: No active days with slots');
  return false;
}


Widget _buildCustomDoctorCard(Doctor doctor) {
  final bool isAvailable = _isDoctorAvailable(doctor);
  final bool hasVideoCall = doctor.isVideoCallAvailable; // ✅ This reads from model
  final String visitingHours = _getVisitingHours(doctor);

  // Debug log
  print('🏠 Home Card: ${doctor.fullName}');
  print('   - isVideoCallAvailable: $hasVideoCall');
  print('   - Raw data: ${doctor.toJson()}');

  return Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.blue.withOpacity(0.1)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
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
                          isAvailable ? 'Available' : 'No Schedule',
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

                  // ✅ Video Consultation Badge
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
                          const Text(
                            'Video Consultation',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF1565C0),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  if (hasVideoCall) const SizedBox(height: 6),

                  // Visiting hours
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
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

                  // Rating & Distance
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.orangeAccent,
                      ),
                      Text(
                        ' ${doctor.rating}',
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
                            builder: (_) => BookAppointmentScreen(doctor: doctor),
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
                  isAvailable ? 'Book Now' : 'Not Available',
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
    if (imageUrl != null &&
        imageUrl.isNotEmpty &&
        (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'))) {
      return Image.network(
        imageUrl,
        height: 80,
        width: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildImagePlaceholder();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 80,
            width: 80,
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      );
    }

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.asset(
        imageUrl,
        height: 80,
        width: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildImagePlaceholder();
        },
      );
    }

    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 80,
      width: 80,
      color: Colors.grey[200],
      child: const Icon(Icons.person, size: 40, color: Colors.grey),
    );
  }



/// ✅ Get visiting hours from doctor's schedule
  String _getVisitingHours(Doctor doctor) {
    if (doctor.weeklySchedule == null || doctor.weeklySchedule!.isEmpty) {
      return 'No schedule set';
    }

    List<String> activeDays = [];
    for (var schedule in doctor.weeklySchedule!) {
      if (schedule.isActive && schedule.slots.isNotEmpty) {
        // Get first 3 characters of day name
        String dayShort = schedule.day.length >= 3 
          ? schedule.day.substring(0, 3) 
          : schedule.day;
        activeDays.add(dayShort);
      }
    }

    if (activeDays.isEmpty) {
      return 'No schedule set';
    }

    // Show first and last day
    if (activeDays.length == 1) {
      return activeDays[0];
    } else if (activeDays.length <= 3) {
      return activeDays.join(', ');
    } else {
      return '${activeDays.first}-${activeDays.last}';
    }
  }

}