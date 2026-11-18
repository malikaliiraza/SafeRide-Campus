import 'package:flutter_test/flutter_test.dart';
import 'package:saferide_campus/features/trips/data/models/recorded_trip.dart';
import 'package:saferide_campus/features/trips/data/trip_history_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const service = TripHistoryService();

  RecordedTrip trip(String routeId, int delay) {
    return RecordedTrip(
      routeId: routeId,
      dateIso: '2026-11-18',
      scheduledDepartureMinutes: 450,
      actualDelayMinutes: delay,
      arrivalLabel: '8:05 AM',
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('starts empty', () async {
    expect(await service.allTrips(), isEmpty);
    expect(await service.tripCount(), 0);
  });

  test('recorded trips round-trip per route', () async {
    await service.recordTrip(trip('route-a', 4));
    await service.recordTrip(trip('route-a', 7));
    await service.recordTrip(trip('route-b', 1));

    expect(await service.tripCount(), 3);
    expect(await service.delaysFor('route-a'), <int>[4, 7]);
    expect(await service.delaysFor('route-b'), <int>[1]);
    expect(await service.delaysFor('route-c'), isEmpty);
  });

  test('corrupt entries are skipped, not fatal', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'saferide_trip_history_v1': <String>['not-json', '{"routeId": 1}'],
    });
    expect(await service.allTrips(), isEmpty);
    await service.recordTrip(trip('route-a', 3));
    expect(await service.tripCount(), 1);
  });
}
