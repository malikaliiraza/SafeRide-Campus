import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/routes/data/repositories/route_repository.dart';

void main() {
  runApp(const SafeRideCampusApp());
}

/// SafeRide Campus v0.1.0 — scaffold entry point.
///
/// The app runs fully offline on sample data: no backend, account, or API
/// key is needed. [RouteRepository] holds the sample routes; the delay
/// predictor, QR ticket, and parent alerts are wired from the home screen.
class SafeRideCampusApp extends StatelessWidget {
  const SafeRideCampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RouteRepository(),
      child: MaterialApp(
        title: 'SafeRide Campus',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const HomeScreen(),
      ),
    );
  }
}
