import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/app_constants.dart';

/// Parent safe-arrival alerts, v0.2.
///
/// This service composes the alert text and records each alert event
/// locally, so the app can show what was sent and when. Since v0.2 an
/// arrival also fires a real local notification on the phone
/// ([notifyArrival]) — that is the alert a parent actually sees.
///
/// Actually delivering the message to a parent's own phone (SMS/push)
/// needs a backend and the parent's opt-in consent, so delivery is
/// roadmap — [composeArrivalAlert] and [recordAlert] are the honest
/// on-device surface, and nothing here pretends a message left the phone.
///
/// Local notifications are Android/iOS only: `flutter_local_notifications`
/// has no web implementation, so on web the alert is composed and recorded
/// in-app and no notification is attempted.
class ParentAlertService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _notificationsReady = false;

  /// Prepares local notifications. Safe to call on web — it returns
  /// immediately there. Call once from `main` before the app starts.
  static Future<void> initNotifications() async {
    if (kIsWeb) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    try {
      await _plugin.initialize(settings);
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _notificationsReady = true;
    } catch (_) {
      // Notifications unavailable on this device; alerts still record.
      _notificationsReady = false;
    }
  }

  /// "Your child has arrived safely at Main Campus on Route A at 8:05 AM."
  String composeArrivalAlert({
    required String routeName,
    required String stopName,
    required String arrivalLabel,
  }) {
    return 'Your child has arrived safely at $stopName '
        'on $routeName at $arrivalLabel.';
  }

  /// "Your child's bus on Route A is delayed about 12 min."
  String composeDelayAlert({
    required String routeName,
    required int predictedDelayMinutes,
  }) {
    return "Your child's bus on $routeName is delayed "
        'about $predictedDelayMinutes min.';
  }

  /// Records the arrival alert and, on Android/iOS, shows it as a local
  /// notification on this phone. Returns true when a notification was
  /// actually shown; false on web or when notifications are unavailable
  /// (the alert is still recorded either way).
  Future<bool> notifyArrival({
    required String routeName,
    required String stopName,
    required String arrivalLabel,
  }) async {
    final message = composeArrivalAlert(
      routeName: routeName,
      stopName: stopName,
      arrivalLabel: arrivalLabel,
    );
    await recordAlert(message);
    if (!_notificationsReady) return false;
    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'saferide_arrival',
          'Safe arrival',
          channelDescription:
              'Notifies the parent when the student arrives safely',
          importance: Importance.high,
          priority: Priority.high,
        ),
      );
      await _plugin.show(0, 'Safe arrival', message, details);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Records that an alert was composed, with the time it was recorded.
  /// Stored locally in SharedPreferences; shown in the app's alert history.
  Future<void> recordAlert(String message) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('saferide_alert_history') ?? <String>[];
    history.add('${DateTime.now().toIso8601String()}|$message');
    await prefs.setStringList('saferide_alert_history', history);
  }

  Future<List<String>> alertHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('saferide_alert_history') ?? <String>[];
  }

  Future<bool> alertsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.alertsEnabledKey) ?? false;
  }

  Future<void> setAlertsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.alertsEnabledKey, enabled);
  }
}
