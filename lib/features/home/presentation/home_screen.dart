import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_constants.dart';
import '../../../core/app_theme.dart';
import '../../alerts/domain/parent_alert_service.dart';
import '../../routes/data/models/bus_route.dart';
import '../../routes/data/repositories/route_repository.dart';
import '../../routes/domain/delay_predictor.dart';
import '../../tickets/data/models/campus_ticket.dart';
import '../../tickets/presentation/qr_ticket_screen.dart';

/// Home screen: the day's routes with predicted delays, the offline ticket,
/// and the parent-alerts toggle.
///
/// Sample routes only in v0.1.0. The alerts toggle stores the parent's
/// preference locally; message delivery itself is roadmap.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ParentAlertService _alerts = ParentAlertService();
  bool _alertsEnabled = false;

  @override
  void initState() {
    super.initState();
    _alerts.alertsEnabled().then((value) {
      if (mounted) setState(() => _alertsEnabled = value);
    });
  }

  Future<void> _toggleAlerts(bool value) async {
    await _alerts.setAlertsEnabled(value);
    setState(() => _alertsEnabled = value);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'Parent alerts on — arrival messages will be composed here.'
              : 'Parent alerts off.',
        ),
      ),
    );
  }

  void _openTicket(BusRoute route) {
    final ticket = CampusTicket.sample(
      routeName: route.name,
      from: route.from,
      to: route.to,
      dateLabel: 'Mon, 16 Nov 2026',
      seat: '12A',
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QrTicketScreen(ticket: ticket),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<RouteRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacing),
        children: [
          Card(
            child: SwitchListTile(
              title: const Text('Parent safe-arrival alerts'),
              subtitle: const Text(
                'Compose an alert when the bus arrives. SMS delivery is coming soon.',
              ),
              value: _alertsEnabled,
              onChanged: _toggleAlerts,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Today's routes",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Sample routes — predicted delays come from each route\'s recent history.',
          ),
          const SizedBox(height: 12),
          for (final route in repository.routes)
            _RouteCard(
              route: route,
              prediction: repository.predictionFor(route),
              onTicket: () => _openTicket(route),
            ),
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.route,
    required this.prediction,
    required this.onTicket,
  });

  final BusRoute route;
  final DelayPrediction prediction;
  final VoidCallback onTicket;

  Color _statusColor(BuildContext context) {
    if (prediction.isDelayed) return AppTheme.dangerRed;
    if (!prediction.isOnTime) return AppTheme.alertAmber;
    return AppTheme.onTimeGreen;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    route.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(context).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    prediction.label,
                    style: TextStyle(
                      color: _statusColor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${route.from} → ${route.to}'),
            Text('Departs ${route.departureLabel}'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onTicket,
                    icon: const Icon(Icons.qr_code_2),
                    label: const Text('Show my ticket'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
