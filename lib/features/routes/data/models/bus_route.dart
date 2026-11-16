/// A campus bus route.
///
/// Times are minutes after midnight, local time. [observedDelaysMinutes]
/// holds the most recent observed delays for this route, newest last — the
/// delay predictor reads them. In v0.1.0 these are sample values; real
/// timetables per university are roadmap.
class BusRoute {
  const BusRoute({
    required this.id,
    required this.name,
    required this.from,
    required this.to,
    required this.departureMinutes,
    this.observedDelaysMinutes = const <int>[],
  });

  final String id;
  final String name;
  final String from;
  final String to;

  /// Scheduled departure, minutes after midnight (e.g. 7:30 AM = 450).
  final int departureMinutes;

  /// Recent observed delays in minutes, newest last. Empty = no history yet.
  final List<int> observedDelaysMinutes;

  /// "7:30 AM" style label for [departureMinutes].
  String get departureLabel {
    final hour24 = departureMinutes ~/ 60;
    final minute = departureMinutes % 60;
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '$hour12:${minute.toString().padLeft(2, '0')} $period';
  }

  BusRoute copyWith({List<int>? observedDelaysMinutes}) {
    return BusRoute(
      id: id,
      name: name,
      from: from,
      to: to,
      departureMinutes: departureMinutes,
      observedDelaysMinutes:
          observedDelaysMinutes ?? this.observedDelaysMinutes,
    );
  }
}
