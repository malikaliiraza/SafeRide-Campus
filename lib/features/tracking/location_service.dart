import 'package:geolocator/geolocator.dart';

/// Live GPS location, wrapped so the app degrades gracefully when
/// permission is denied or the device has no fix (web without permission,
/// emulator without a location set, ...).
///
/// The screen that uses this works in manual mode without GPS — the trip
/// is still recorded, just without a location trail.
enum LocationStatus {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
  unavailable,
}

class LiveLocation {
  const LiveLocation({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.speedMps,
  });

  factory LiveLocation.fromPosition(Position position) {
    return LiveLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: position.timestamp,
      speedMps: position.speed,
    );
  }

  final double latitude;
  final double longitude;
  final DateTime timestamp;

  /// Speed in metres per second, as reported by the device (may be 0).
  final double? speedMps;
}

class LocationService {
  const LocationService();

  Future<LocationStatus> ensurePermission() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return LocationStatus.serviceDisabled;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return LocationStatus.denied;
      }
      if (permission == LocationPermission.deniedForever) {
        return LocationStatus.deniedForever;
      }
      return LocationStatus.granted;
    } catch (_) {
      return LocationStatus.unavailable;
    }
  }

  Future<LiveLocation?> currentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      return LiveLocation.fromPosition(position);
    } catch (_) {
      return null;
    }
  }

  Stream<LiveLocation> positionStream() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    return Geolocator.getPositionStream(
      locationSettings: settings,
    ).map(LiveLocation.fromPosition);
  }
}
