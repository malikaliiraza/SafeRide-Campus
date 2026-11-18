import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_theme.dart';
import '../../alerts/domain/parent_alert_service.dart';
import '../../routes/data/models/bus_route.dart';
import '../../routes/data/repositories/route_repository.dart';
import '../../trips/data/models/recorded_trip.dart';
import '../../trips/data/trip_history_service.dart';
import '../geo_math.dart';
import '../location_service.dart';

/// Live trip tracking for one route.
///
/// The student taps "Start trip" on the home screen and this screen opens:
/// it streams the phone's GPS, shows distance travelled, current speed and
/// elapsed time, and when the student taps "I've arrived" it records the
/// trip on the device — the delay (how late the bus left vs the scheduled
/// departure) feeds the delay predictor, and the parent alert fires.
///
/// No destination coordinates are bundled: the sample routes have no real
/// university attached, so arrival is marked by the student, not by a
/// geofence around an invented place. When GPS is unavailable the screen
/// still works in manual mode and says so.
class TripTrackingScreen extends StatefulWidget {
  const TripTrackingScreen({required this.route, super.key});

  final BusRoute route;

  @override
  State<TripTrackingScreen> createState() => _TripTrackingScreenState();
}

class _TripTrackingScreenState extends State<TripTrackingScreen> {
  final LocationService _location = const LocationService();
  final TripHistoryService _history = const TripHistoryService();
  final ParentAlertService _alerts = ParentAlertService();

  LocationStatus? _status;
  StreamSubscription<LiveLocation>? _subscription;
  Timer? _clock;

  DateTime? _boardedAt;
  GeoPoint? _lastPoint;
  double _distanceTravelledMeters = 0;
  int _fixes = 0;
  Duration _elapsed = Duration.zero;

  bool _finished = false;
  bool _saving = false;
  int? _recordedDelayMinutes;
  String? _arrivalLabel;
  bool _parentNotified = false;

  @override
  void initState() {
    super.initState();
    _begin();
  }

  Future<void> _begin() async {
    final status = await _location.ensurePermission();
    if (!mounted) return;
    setState(() {
      _status = status;
      _boardedAt = DateTime.now();
    });
    if (status != LocationStatus.granted) return;
    final first = await _location.currentPosition();
    if (first != null && mounted) _onFix(first);
    _subscription = _location.positionStream().listen(
      _onFix,
      onError: (_) {},
    );
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _boardedAt == null) return;
      setState(() {
        _elapsed = DateTime.now().difference(_boardedAt!);
      });
    });
  }

  void _onFix(LiveLocation fix) {
    final point = GeoPoint(fix.latitude, fix.longitude);
    setState(() {
      if (_lastPoint != null) {
        _distanceTravelledMeters += GeoMath.distanceMeters(_lastPoint!, point);
      }
      _lastPoint = point;
      _fixes++;
    });
  }

  String _formatTime(DateTime time) {
    final hour24 = time.hour;
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '$hour12:${time.minute.toString().padLeft(2, '0')} $period';
  }

  String _formatElapsed(Duration elapsed) {
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _arrive() async {
    if (_saving || _boardedAt == null) return;
    setState(() => _saving = true);
    await _subscription?.cancel();
    _clock?.cancel();

    final now = DateTime.now();
    final boardedMinutes = _boardedAt!.hour * 60 + _boardedAt!.minute;
    final delay = boardedMinutes - widget.route.departureMinutes;
    final arrivalLabel = _formatTime(now);
    final trip = RecordedTrip(
      routeId: widget.route.id,
      dateIso:
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      scheduledDepartureMinutes: widget.route.departureMinutes,
      actualDelayMinutes: delay < 0 ? 0 : delay,
      arrivalLabel: arrivalLabel,
    );
    if (mounted) {
      await context.read<RouteRepository>().recordCompletedTrip(trip);
    } else {
      await _history.recordTrip(trip);
    }

    var notified = false;
    if (await _alerts.alertsEnabled()) {
      notified = await _alerts.notifyArrival(
        routeName: widget.route.name,
        stopName: widget.route.to,
        arrivalLabel: arrivalLabel,
      );
    }

    if (!mounted) return;
    setState(() {
      _finished = true;
      _saving = false;
      _recordedDelayMinutes = trip.actualDelayMinutes;
      _arrivalLabel = arrivalLabel;
      _parentNotified = notified;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _clock?.cancel();
    super.dispose();
  }

  String get _statusText {
    return switch (_status) {
      LocationStatus.granted => 'GPS live — tracking your trip.',
      LocationStatus.denied =>
        'Location permission denied — manual mode: the trip is still recorded, without a location trail.',
      LocationStatus.deniedForever =>
        'Location permission is off for this app — manual mode: the trip is still recorded, without a location trail.',
      LocationStatus.serviceDisabled =>
        'Location services are off — manual mode: the trip is still recorded, without a location trail.',
      LocationStatus.unavailable =>
        'GPS unavailable on this device — manual mode: the trip is still recorded, without a location trail.',
      null => 'Starting GPS…',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Live trip — ${widget.route.name}')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacing),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.route.from} → ${widget.route.to}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Scheduled departure ${widget.route.departureLabel}',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        _status == LocationStatus.granted
                            ? Icons.location_on
                            : Icons.location_off,
                        color: _status == LocationStatus.granted
                            ? AppTheme.onTimeGreen
                            : AppTheme.alertAmber,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_statusText)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!_finished) ...[
            _StatRow(
              label: 'Distance travelled',
              value: GeoMath.formatDistance(_distanceTravelledMeters),
            ),
            _StatRow(label: 'GPS fixes', value: '$_fixes'),
            _StatRow(label: 'Elapsed', value: _formatElapsed(_elapsed)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _saving ? null : _arrive,
              icon: const Icon(Icons.flag),
              label: Text(_saving ? 'Recording…' : "I've arrived"),
            ),
            const SizedBox(height: 8),
            const Text(
              'Arrival records how late the bus left vs the scheduled '
              'departure, so the next delay prediction learns from this trip.',
              textAlign: TextAlign.center,
            ),
          ],
          if (_finished) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Arrived safely',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Arrived at ${_arrivalLabel ?? ''}.'),
                    Text(
                      'Delay recorded: '
                      '${_recordedDelayMinutes ?? 0} min late vs the '
                      '${widget.route.departureLabel} schedule.',
                    ),
                    Text(
                      'Distance travelled: '
                      '${GeoMath.formatDistance(_distanceTravelledMeters)} '
                      'over $_fixes GPS fixes.',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _parentNotified
                          ? 'Parent alert sent as a notification on this phone.'
                          : 'Parent alert recorded (notifications need '
                              'alerts on, and Android/iOS — on web it is '
                              'recorded in-app).',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
