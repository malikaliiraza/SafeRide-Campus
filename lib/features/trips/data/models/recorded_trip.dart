/// One trip actually completed on this device.
///
/// Recorded when the student marks arrival on the live-tracking screen:
/// [actualDelayMinutes] is how late the bus left compared with the
/// scheduled departure, so the delay predictor learns from real trips
/// instead of the sample delays bundled with the scaffold.
class RecordedTrip {
  const RecordedTrip({
    required this.routeId,
    required this.dateIso,
    required this.scheduledDepartureMinutes,
    required this.actualDelayMinutes,
    this.arrivalLabel,
  });

  final String routeId;

  /// Trip date as yyyy-MM-dd, local time.
  final String dateIso;

  final int scheduledDepartureMinutes;

  /// Minutes late vs the scheduled departure. 0 means the bus left on time.
  final int actualDelayMinutes;

  /// Human-readable arrival time, e.g. "8:05 AM", when recorded.
  final String? arrivalLabel;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'routeId': routeId,
      'dateIso': dateIso,
      'scheduledDepartureMinutes': scheduledDepartureMinutes,
      'actualDelayMinutes': actualDelayMinutes,
      'arrivalLabel': arrivalLabel,
    };
  }

  factory RecordedTrip.fromJson(Map<String, dynamic> json) {
    return RecordedTrip(
      routeId: json['routeId'] as String,
      dateIso: json['dateIso'] as String,
      scheduledDepartureMinutes: json['scheduledDepartureMinutes'] as int,
      actualDelayMinutes: json['actualDelayMinutes'] as int,
      arrivalLabel: json['arrivalLabel'] as String?,
    );
  }
}
