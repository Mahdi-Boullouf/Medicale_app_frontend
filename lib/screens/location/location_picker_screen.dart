import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:docmobi/l10n/app_localizations.dart';
import '../../services/location_service.dart';
import '../../utils/marker_factory.dart';

class LocationPickerScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const LocationPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final LocationService _locationService = LocationService();
  final MarkerFactory _markerFactory = MarkerFactory();

  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String _selectedAddress = 'Loading address...';
  bool _isLoadingLocation = false;
  bool _isLoadingAddress = false;

  // Permission dialog control
  bool _showPermissionDialog = true;
  String _selectedPermission = 'While using the app';
  String _selectedAccuracy = 'Precise';

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermission();
  }

  Future<void> _checkAndRequestPermission() async {
    // Check if location permission is already granted
    LocationPermission permission = await _locationService.checkPermission();

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      // Permission already granted, hide dialog and get location
      setState(() => _showPermissionDialog = false);
      _initializeLocation();
    } else {
      // Show permission dialog
      setState(() => _showPermissionDialog = true);
    }
  }

  Future<void> _initializeLocation() async {
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLocation = LatLng(
        widget.initialLatitude!,
        widget.initialLongitude!,
      );
      _getAddressFromLatLng(_selectedLocation!);
    } else {
      await _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // Check permission
      LocationPermission permission = await _locationService.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _locationService.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.locationPermissionDenied)),
          );
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Get current position
      Position position = await _locationService.getCurrentPosition();

      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      _getAddressFromLatLng(_selectedLocation!);
      _moveCamera(_selectedLocation!);
    } catch (e) {
      debugPrint(' Error getting location: $e');
      setState(() => _isLoadingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    setState(() => _isLoadingAddress = true);

    try {
      String address = await _locationService.getAddressFromLatLng(position);

      setState(() {
        _selectedAddress = address;
        _isLoadingAddress = false;
      });
    } catch (e) {
      debugPrint(' Error getting address: $e');
      setState(() {
        _selectedAddress = 'Address not found';
        _isLoadingAddress = false;
      });
    }
  }

  void _moveCamera(LatLng position) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: 16),
      ),
    );
  }

  void _onMapTapped(LatLng position) {
    setState(() => _selectedLocation = position);
    _getAddressFromLatLng(position);
  }

  void _confirmLocation() {
    if (_selectedLocation != null) {
      Navigator.pop(context, {
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
        'address': _selectedAddress,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          _selectedLocation == null
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation!,
                    zoom: 16,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  onTap: _onMapTapped,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  markers: {
                    _markerFactory.createSelectedMarker(_selectedLocation!),
                  },
                ),

          // Permission Dialog Overlay (Only show when needed)
          if (_showPermissionDialog)
            Positioned(
              top: 60,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFF1664CD),
                      size: 40,
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Allow Maps to access this\ndevice\'s precise location?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B2C49),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Accuracy Selection
                    Row(
                      children: [
                        Expanded(
                          child: _buildAccuracyOption(
                            'Precise',
                            Icons.location_on,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildAccuracyOption(
                            'Approximate',
                            Icons.location_searching,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Permission Options
                    _buildPermissionButton('While using the app'),
                    const SizedBox(height: 10),
                    _buildPermissionButton('Only this time'),
                    const SizedBox(height: 10),
                    _buildPermissionButton('Don\'t allow'),
                  ],
                ),
              ),
            ),

          // Address Info Card (Only show when permission granted)
          if (!_showPermissionDialog)
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFF1664CD),
                      size: 30,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selected Location',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isLoadingAddress ? 'Loading...' : _selectedAddress,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1B2C49),
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // My Location Button (Only show when permission granted)
          if (!_showPermissionDialog)
            Positioned(
              bottom: 180,
              right: 20,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.white,
                onPressed: _getCurrentLocation,
                child: _isLoadingLocation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location, color: Color(0xFF1664CD)),
              ),
            ),

          // Confirm Button (Only show when permission granted)
          if (!_showPermissionDialog)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: _confirmLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1664CD),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Confirm Location',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAccuracyOption(String title, IconData icon) {
    final isSelected = _selectedAccuracy == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedAccuracy = title),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE9F0FF) : Colors.grey[100],
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSelected ? const Color(0xFF1664CD) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF1664CD) : Colors.grey,
              size: 28,
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? const Color(0xFF1664CD) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionButton(String title) {
    final isSelected = _selectedPermission == title;
    return GestureDetector(
      onTap: () async {
        setState(() => _selectedPermission = title);

        // Handle permission based on selection
        if (title == "Don't allow") {
          // User denied permission
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.locationPermissionDenied)),
          );
        } else {
          // Request permission and proceed
          LocationPermission permission = await _locationService
              .requestPermission();

          if (permission == LocationPermission.denied ||
              permission == LocationPermission.deniedForever) {
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.locationPermissionDenied)),
              );
            }
          } else {
            // Permission granted - hide dialog and get location
            setState(() => _showPermissionDialog = false);
            await _initializeLocation();
          }
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE9F0FF) : const Color(0xFFF5F8FF),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? const Color(0xFF1664CD) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? const Color(0xFF1664CD)
                : const Color(0xFF1B2C49),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
