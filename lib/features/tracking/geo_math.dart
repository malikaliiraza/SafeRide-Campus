import 'dart:math' as math;

/// Pure-Dart geography helpers for live trip tracking.
///
/// Kept free of any plugin so the maths is unit-testable; [LocationService]
/// supplies the real GPS fixes.
class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

class GeoMath {
  GeoMath._();

  static const double earthRadiusMeters = 6371000;

  /// Great-circle distance in metres (haversine formula).
  static double distanceMeters(GeoPoint a, GeoPoint b) {
    final lat1 = a.latitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLng = (b.longitude - a.longitude) * math.pi / 180;
    final h =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return 2 * earthRadiusMeters * math.asin(math.sqrt(h));
  }

  static bool isWithinRadius(
    GeoPoint point,
    GeoPoint target,
    double radiusMeters,
  ) {
    return distanceMeters(point, target) <= radiusMeters;
  }

  /// "850 m" below 1 km, "2.3 km" above it.
  static String formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  /// km/h from a leg of [meters] covered in [elapsed].
  static double speedKmh(double meters, Duration elapsed) {
    if (elapsed.inSeconds <= 0) return 0;
    return meters / elapsed.inSeconds * 3.6;
  }
}
