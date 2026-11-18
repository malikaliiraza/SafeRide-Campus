import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_constants.dart';
import '../../../core/app_theme.dart';
import '../../alerts/domain/parent_alert_service.dart';
import '../../routes/data/models/bus_route.dart';
import '../../routes/data/repositories/route_repository.dart';
import '../../routes/domain/delay_predictor.dart';
import '../../tickets/data/models/campus_ticket.dart';
import '../../tickets/data/ticket_repository.dart';
import '../../tickets/presentation/qr_scan_screen.dart';
import '../../tickets/presentation/qr_ticket_screen.dart';
import '../../tracking/presentation/trip_tracking_screen.dart';
import '../../trips/data/trip_history_service.dart';

/// Home screen: the day's routes with predicted delays, the offline ticket,
/// live trip tracking, ticket scanning, and the parent-alerts toggle.
///
/// Sample routes only in v0.2.0. Predictions learn from trips actually
/// recorded on this device; the alerts toggle enables local notifications
/// on arrival (SMS delivery is still roadmap).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ParentAlertService _alerts = ParentAlertService();
  final TicketRepository _tickets = const TicketRepository();
  final TripHistoryService _history = const TripHistoryService();
  bool _alertsEnabled = false;
  int _recordedTrips = 0;

  @override
  void initState() {
    super.initState();
    _alerts.alertsEnabled().then((value) {
      if (mounted) setState(() => _alertsEnabled = value);
    });
    _refreshTripCount();
  }

  Future<void> _refreshTripCount() async {
    final count = await _history.tripCount();
    if (mounted) setState(() => _recordedTrips = count);
  }

  Future<void> _toggleAlerts(bool value) async {
    await _alerts.setAlertsEnabled(value);
    setState(() => _alertsEnabled = value);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'Parent alerts on — a notification fires on this phone when the bus arrives.'
              : 'Parent alerts off.',
        ),
      ),
    );
  }

  static const List<String> _weekdays = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  static const List<String> _months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _todayLabel() {
    final now = DateTime.now();
    return '${_weekdays[now.weekday - 1]}, ${now.day} '
        '${_months[now.month - 1]} ${now.year}';
  }

  Future<void> _openTicket(BusRoute route) async {
    final serial = await _tickets.nextSerial();
    final ticket = CampusTicket.sample(
      routeName: route.name,
      from: route.from,
      to: route.to,
      dateLabel: _todayLabel(),
      seat: '12A',
      serial: serial,
    );
    await _tickets.issueTicket(
      IssuedTicket(
        code: ticket.code,
        routeName: ticket.routeName,
        from: ticket.from,
        to: ticket.to,
        dateLabel: ticket.dateLabel,
        seat: ticket.seat,
      ),
    );
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QrTicketScreen(ticket: ticket),
      ),
    );
  }

  Future<void> _startTrip(BusRoute route) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TripTrackingScreen(route: route),
      ),
    );
    await _refreshTripCount();
  }

  void _openScanner() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const QrScanScreen()),
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
                'A notification fires on this phone when the bus arrives. SMS delivery is coming soon.',
              ),
              value: _alertsEnabled,
              onChanged: _toggleAlerts,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _openScanner,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan ticket (conductor)'),
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
          Text(
            _recordedTrips == 0
                ? 'No trips recorded on this device yet — predictions use the sample history for now.'
                : '$_recordedTrips trip${_recordedTrips == 1 ? '' : 's'} recorded on this device — predictions learn from them.',
          ),
          const SizedBox(height: 12),
          for (final route in repository.routes)
            _RouteCard(
              route: route,
              prediction: repository.predictionFor(route),
              usesRecordedHistory:
                  repository.usesRecordedHistory(route.id),
              onTicket: () => _openTicket(route),
              onStartTrip: () => _startTrip(route),
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
    required this.usesRecordedHistory,
    required this.onTicket,
    required this.onStartTrip,
  });

  final BusRoute route;
  final DelayPrediction prediction;
  final bool usesRecordedHistory;
  final VoidCallback onTicket;
  final VoidCallback onStartTrip;

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
            if (usesRecordedHistory)
              const Text(
                'Prediction from trips recorded on this device.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
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
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onStartTrip,
                    icon: const Icon(Icons.navigation),
                    label: const Text('Start trip'),
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
