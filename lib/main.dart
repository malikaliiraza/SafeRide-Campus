import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'features/alerts/domain/parent_alert_service.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/routes/data/repositories/route_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ParentAlertService.initNotifications();
  final repository = RouteRepository();
  await repository.loadRecordedHistory();
  runApp(SafeRideCampusApp(repository: repository));
}

/// SafeRide Campus v0.2.0 — entry point.
///
/// The app runs fully offline on the device: no backend, account, or API
/// key is needed. [RouteRepository] holds the routes (sample data, clearly
/// marked); trips recorded on this device replace the sample delays, live
/// GPS tracking runs on the trip screen, tickets are issued and validated
/// on the phone, and parent alerts fire as local notifications.
class SafeRideCampusApp extends StatelessWidget {
  const SafeRideCampusApp({required this.repository, super.key});

  final RouteRepository repository;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RouteRepository>.value(
      value: repository,
      child: MaterialApp(
        title: 'SafeRide Campus',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const HomeScreen(),
      ),
    );
  }
}
