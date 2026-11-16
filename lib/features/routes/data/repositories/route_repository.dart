import 'package:flutter/foundation.dart';

import '../models/bus_route.dart';
import '../../domain/delay_predictor.dart';

/// Holds the routes shown on the home screen and their delay predictions.
///
/// v0.1.0 ships with clearly marked sample routes only — no real university
/// timetable is bundled. A backend feed replacing [sampleRoutes] is roadmap.
class RouteRepository extends ChangeNotifier {
  RouteRepository({List<BusRoute>? routes}) : _routes = routes ?? sampleRoutes;

  List<BusRoute> _routes;

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
