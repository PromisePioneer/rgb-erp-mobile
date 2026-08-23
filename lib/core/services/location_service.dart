import 'package:geolocator/geolocator.dart';
import '../constants/app_constants.dart';

/// Location data model
class LocationData {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final DateTime timestamp;

  const LocationData({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    required this.timestamp,
  });

  String get coordinatesString =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'altitude': altitude,
        'speed': speed,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Service for location/GPS functionality
class LocationService {
  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission;
  }

  /// Check current permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Get current location
  Future<LocationData> getCurrentLocation() async {
    // Check if location services are enabled
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException('Location services are disabled');
    }

    // Check permission
    var permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException('Location permission denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        'Location permission permanently denied. Please enable in settings.',
      );
    }

    // Get current position
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: AppConstants.locationTimeout,
    );

    return LocationData(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      altitude: position.altitude,
      speed: position.speed,
      timestamp: position.timestamp,
    );
  }

  /// Get last known location (faster but may be stale)
  Future<LocationData?> getLastKnownLocation() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position == null) return null;

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        speed: position.speed,
        timestamp: position.timestamp,
      );
    } catch (e) {
      return null;
    }
  }

  /// Open location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app settings (for permission)
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }
}

/// Custom exception for location errors
class LocationException implements Exception {
  final String message;

  LocationException(this.message);

  @override
  String toString() => message;
}
