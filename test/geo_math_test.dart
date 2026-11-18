import 'package:flutter_test/flutter_test.dart';
import 'package:saferide_campus/features/tracking/geo_math.dart';

void main() {
  test('one degree of longitude at the equator is about 111.2 km', () {
    final distance = GeoMath.distanceMeters(
      const GeoPoint(0, 0),
      const GeoPoint(0, 1),
    );
    expect(distance, closeTo(111195, 50));
  });

  test('same point is zero distance', () {
    expect(
      GeoMath.distanceMeters(
        const GeoPoint(31.5, 74.3),
        const GeoPoint(31.5, 74.3),
      ),
      0,
    );
  });

  test('radius check', () {
    const target = GeoPoint(31.5, 74.3);
    expect(
      GeoMath.isWithinRadius(const GeoPoint(31.5001, 74.3), target, 50),
      isTrue,
    );
    expect(
      GeoMath.isWithinRadius(const GeoPoint(31.6, 74.3), target, 50),
      isFalse,
    );
  });

  test('distance formatting', () {
    expect(GeoMath.formatDistance(850), '850 m');
    expect(GeoMath.formatDistance(2300), '2.3 km');
  });

  test('speed from distance and time', () {
    expect(
      GeoMath.speedKmh(1000, const Duration(seconds: 60)),
      closeTo(60, 0.01),
    );
    expect(GeoMath.speedKmh(1000, Duration.zero), 0);
  });
}
