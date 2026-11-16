/// An offline campus bus ticket.
///
/// The ticket lives entirely on the phone: [code] is the value encoded in
/// the QR code, so the ticket can be shown and checked with no network.
/// v0.1.0 issues one sample ticket per route on the device; buying or
/// reserving a real ticket through the university is roadmap.
class CampusTicket {
  const CampusTicket({
    required this.code,
    required this.routeName,
    required this.from,
    required this.to,
    required this.dateLabel,
    required this.seat,
  });

  /// Unique ticket code, encoded in the QR code (e.g. "SR-2026-11-16-A-042").
  final String code;
  final String routeName;
  final String from;
  final String to;

  /// Human-readable date, e.g. "Mon, 16 Nov 2026".
  final String dateLabel;
  final String seat;

  /// Builds a sample ticket for a route. The code embeds the date and route
  /// so a conductor can read it without any backend lookup.
  factory CampusTicket.sample({
    required String routeName,
    required String from,
    required String to,
    required String dateLabel,
    required String seat,
  }) {
    final compactDate = dateLabel.replaceAll(RegExp(r'[^0-9A-Za-z]'), '');
    final routeLetter = routeName.replaceAll(RegExp(r'[^A-Za-z]'), '');
    return CampusTicket(
      code: 'SR-$compactDate-$routeLetter-042',
      routeName: routeName,
      from: from,
      to: to,
      dateLabel: dateLabel,
      seat: seat,
    );
  }
}
