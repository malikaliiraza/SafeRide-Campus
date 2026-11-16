import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/app_constants.dart';

/// Parent safe-arrival alerts, v0.1.0.
///
/// This service composes the alert text and records each alert event
/// locally, so the app can show what was sent and when. Actually delivering
/// the message (SMS/push) needs a backend and the parent's opt-in consent,
/// so delivery is roadmap — [composeArrivalAlert] and [recordAlert] are the
/// honest v0.1.0 surface, and nothing here pretends a message left the phone.
class ParentAlertService {
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
