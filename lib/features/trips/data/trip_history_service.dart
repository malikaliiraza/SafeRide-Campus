import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/recorded_trip.dart';

/// Persists trips actually completed on this device, so the delay
/// predictor can learn from real history instead of the sample delays
/// bundled with the v0.1.0 scaffold.
///
/// Storage is a JSON string list in SharedPreferences — fully offline,
/// no account or backend. A corrupt entry is skipped, never fatal.
class TripHistoryService {
  const TripHistoryService();

  static const String _storageKey = 'saferide_trip_history_v1';

  /// Records one completed trip (newest last).
  Future<void> recordTrip(RecordedTrip trip) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_storageKey) ?? <String>[];
    stored.add(jsonEncode(trip.toJson()));
    await prefs.setStringList(_storageKey, stored);
  }

  Future<List<RecordedTrip>> allTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_storageKey) ?? <String>[];
    final trips = <RecordedTrip>[];
    for (final raw in stored) {
      try {
        trips.add(
          RecordedTrip.fromJson(jsonDecode(raw) as Map<String, dynamic>),
        );
      } catch (_) {
        // A corrupt entry must not wipe the rest of the history.
        continue;
      }
    }
    return trips;
  }

  Future<List<RecordedTrip>> tripsFor(String routeId) async {
    final trips = await allTrips();
    return trips.where((trip) => trip.routeId == routeId).toList();
  }

  /// The recorded delays for a route, newest last — the predictor's input.
  Future<List<int>> delaysFor(String routeId) async {
    final trips = await tripsFor(routeId);
    return trips.map((trip) => trip.actualDelayMinutes).toList();
  }

  Future<int> tripCount() async => (await allTrips()).length;

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
