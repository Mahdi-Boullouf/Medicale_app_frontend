import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/doctor_model.dart';

class MarkerFactory {
  // Singleton pattern
  static final MarkerFactory _instance = MarkerFactory._internal();
  factory MarkerFactory() => _instance;
  MarkerFactory._internal();

  /// Create a marker for the user's location
  Marker createUserMarker(LatLng position) {
    return Marker(
      markerId: const MarkerId('user_location'),
      position: position,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: const InfoWindow(
        title: 'Your Location',
        snippet: 'You are here',
      ),
    );
  }

  /// Create a marker for a doctor
  Marker createDoctorMarker({
    required Doctor doctor,
    required double distanceKm,
    required VoidCallback onTap,
  }) {
    LatLng position;
    if (doctor.latitude != null && doctor.longitude != null) {
      position = LatLng(doctor.latitude!, doctor.longitude!);
    } else {
      // Should not happen if filtered correctly before calling this,
      // but safe fallback prevents crash
      position = const LatLng(0, 0);
    }

    return Marker(
      markerId: MarkerId(doctor.id),
      position: position,
      infoWindow: InfoWindow(
        title: doctor.fullName,
        snippet:
            '${doctor.specialty} - ${distanceKm.toStringAsFixed(1)} km away',
      ),
      // Using color codes for availability for now
      // In a real app we would load network images here which is more complex
      icon: BitmapDescriptor.defaultMarkerWithHue(
        doctor.isAvailable
            ? BitmapDescriptor.hueGreen
            : BitmapDescriptor.hueRed,
      ),
      onTap: onTap,
    );
  }

  /// Create a generic marker for selection
  Marker createSelectedMarker(LatLng position) {
    return Marker(
      markerId: const MarkerId('selected'),
      position: position,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );
  }
}
