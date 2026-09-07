import 'package:geolocator/geolocator.dart';

class LocationVerificationResult {
  final bool isVerified;
  final String? errorMessage;
  final double? latitude;
  final double? longitude;
  final double? distanceMeters;

  const LocationVerificationResult({
    required this.isVerified,
    this.errorMessage,
    this.latitude,
    this.longitude,
    this.distanceMeters,
  });

  const LocationVerificationResult.success({
    required double latitude,
    required double longitude,
    double? distanceMeters,
  }) : this(
          isVerified: true,
          latitude: latitude,
          longitude: longitude,
          distanceMeters: distanceMeters,
        );

  const LocationVerificationResult.failure(String errorMessage)
      : this(
          isVerified: false,
          errorMessage: errorMessage,
        );
}

class LocationService {
  /// Default radius for attendance verification (in meters).
  static const double attendanceAllowedRadiusMeters = 100.0;
  static const int maxStaleLocationSeconds = 30;

  /// Checks permissions and fetches the current device position.
  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// Verifies if device is within the target radius of target coordinates.
  Future<LocationVerificationResult> verifyLocation({
    required double targetLat,
    required double targetLng,
    required double allowedRadiusMeters,
  }) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationVerificationResult.failure(
        'Location services are disabled. Please enable GPS to continue.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return const LocationVerificationResult.failure(
          'Location permission is required for attendance verification.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationVerificationResult.failure(
        'Location permissions are permanently denied. Please enable them in app settings.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Security: Reject mocked locations (fake GPS apps)
      if (position.isMocked) {
        return const LocationVerificationResult.failure(
          'Mock/fake location detected. Please disable mock location and try again.',
        );
      }

      // Security: Reject stale locations (older than maxStaleLocationSeconds)
      final age = DateTime.now().difference(position.timestamp);
      if (age.inSeconds > maxStaleLocationSeconds) {
        return const LocationVerificationResult.failure(
          'Location data is stale. Please ensure GPS is active and try again.',
        );
      }

      // Security: Reject inaccurate locations
      if (position.accuracy > 100.0) {
        return const LocationVerificationResult.failure(
          'Location accuracy is too low. Please move to an area with better GPS reception.',
        );
      }

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        targetLat,
        targetLng,
      );

      if (distance <= allowedRadiusMeters) {
        return LocationVerificationResult.success(
          latitude: position.latitude,
          longitude: position.longitude,
          distanceMeters: distance,
        );
      } else {
        return LocationVerificationResult(
          isVerified: false,
          errorMessage:
              'You are approximately ${distance.toStringAsFixed(0)}m away (maximum allowed: ${allowedRadiusMeters.toStringAsFixed(0)}m).',
          latitude: position.latitude,
          longitude: position.longitude,
          distanceMeters: distance,
        );
      }
    } catch (e) {
      return LocationVerificationResult.failure(
        'Failed to acquire current location: $e',
      );
    }
  }
}
