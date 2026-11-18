import 'package:flutter/foundation.dart';

import '../models/bus_route.dart';
import '../../domain/delay_predictor.dart';
import '../../../trips/data/models/recorded_trip.dart';
import '../../../trips/data/trip_history_service.dart';

/// Holds the routes shown on the home screen and their delay predictions.
///
/// v0.1.0 shipped with clearly marked sample routes only — no real
/// university timetable is bundled. Since v0.2, trips actually completed
/// on this device ([TripHistoryService]) replace the bundled sample delays
/// for that route, so predictions learn from real history. A backend feed
/// replacing [sampleRoutes] is roadmap.
class RouteRepository extends ChangeNotifier {
  RouteRepository({List<BusRoute>? routes, TripHistoryService? history})
      : _routes = routes ?? sampleRoutes,
        _history = history ?? const TripHistoryService();

  List<BusRoute> _routes;

  final TripHistoryService _history;

  /// Routes whose predictions now come from trips recorded on this device
  /// rather than the bundled sample delays.
  final Set<String> _recordedRouteIds = <String>{};

  List<BusRoute> get routes => List.unmodifiable(_routes);

  static const List<BusRoute> sampleRoutes = <BusRoute>[
    BusRoute(
      id: 'route-a',
      name: 'Route A',
      from: 'City Centre',
      to: 'Main Campus',
      departureMinutes: 450, // 7:30 AM
      observedDelaysMinutes: <int>[4, 6, 5, 9, 7],
    ),
    BusRoute(
      id: 'route-b',
      name: 'Route B',
      from: 'Railway Station',
      to: 'Main Campus',
      departureMinutes: 480, // 8:00 AM
      observedDelaysMinutes: <int>[0, 1, 0, 2, 1],
    ),
    BusRoute(
      id: 'route-c',
      name: 'Route C',
      from: 'Main Campus',
      to: 'City Centre',
      departureMinutes: 1020, // 5:00 PM
      observedDelaysMinutes: <int>[12, 15, 11, 14],
    ),
  ];

  /// True when this route's delays come from trips recorded on the device.
  bool usesRecordedHistory(String routeId) {
    return _recordedRouteIds.contains(routeId);
  }

  /// Loads trips recorded on this device and replaces the bundled sample
  /// delays with the real recorded delays for any route that has them.
  Future<void> loadRecordedHistory() async {
    var changed = false;
    for (final route in _routes) {
      final delays = await _history.delaysFor(route.id);
      if (delays.isEmpty) continue;
      _routes = _routes
          .map(
            (current) => current.id == route.id
                ? current.copyWith(observedDelaysMinutes: delays)
                : current,
          )
          .toList();
      _recordedRouteIds.add(route.id);
      changed = true;
    }
    if (changed) notifyListeners();
  }

  /// Records a trip completed on this device: persists it, then folds its
  /// delay into the route's history so the next prediction learns from it.
  Future<void> recordCompletedTrip(RecordedTrip trip) async {
    await _history.recordTrip(trip);
    recordDelay(trip.routeId, trip.actualDelayMinutes);
    _recordedRouteIds.add(trip.routeId);
  }

  DelayPrediction predictionFor(BusRoute route) {
    return const DelayPredictor().predict(route);
  }

  /// Records a newly observed delay for a route (newest last), keeping at
  /// most the last 30 observations.
  void recordDelay(String routeId, int delayMinutes) {
    _routes = _routes.map((route) {
      if (route.id != routeId) return route;
      final updated = <int>[
        ...route.observedDelaysMinutes,
        delayMinutes,
      ];
      if (updated.length > 30) {
        updated.removeRange(0, updated.length - 30);
      }
      return route.copyWith(observedDelaysMinutes: updated);
    }).toList();
    notifyListeners();
  }
}
