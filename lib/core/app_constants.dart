/// App-wide constants for SafeRide Campus (v0.1.0 scaffold).
class AppConstants {
  AppConstants._();

  static const String appName = 'SafeRide Campus';

  /// How many recent delay observations the predictor looks at.
  static const int predictorHistorySize = 10;

  /// A predicted delay at or below this many minutes counts as "on time".
  static const int onTimeThresholdMinutes = 3;

  /// A predicted delay at or above this many minutes counts as "delayed".
  static const int delayedThresholdMinutes = 10;

  static const String alertsEnabledKey = 'saferide_parent_alerts_enabled';
  static const String ticketCodeKey = 'saferide_ticket_code';
}
