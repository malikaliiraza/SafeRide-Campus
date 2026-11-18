import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A ticket issued on this device, so the conductor's scan can be checked
/// against tickets this phone actually issued — no backend needed.
class IssuedTicket {
  const IssuedTicket({
    required this.code,
    required this.routeName,
    required this.from,
    required this.to,
    required this.dateLabel,
    required this.seat,
    this.used = false,
  });

  final String code;
  final String routeName;
  final String from;
  final String to;
  final String dateLabel;
  final String seat;

  /// True once the ticket has been scanned and accepted.
  final bool used;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'code': code,
      'routeName': routeName,
      'from': from,
      'to': to,
      'dateLabel': dateLabel,
      'seat': seat,
      'used': used,
    };
  }

  factory IssuedTicket.fromJson(Map<String, dynamic> json) {
    return IssuedTicket(
      code: json['code'] as String,
      routeName: json['routeName'] as String,
      from: json['from'] as String,
      to: json['to'] as String,
      dateLabel: json['dateLabel'] as String,
      seat: json['seat'] as String,
      used: json['used'] as bool? ?? false,
    );
  }

  IssuedTicket copyWith({bool? used}) {
    return IssuedTicket(
      code: code,
      routeName: routeName,
      from: from,
      to: to,
      dateLabel: dateLabel,
      seat: seat,
      used: used ?? this.used,
    );
  }
}

class TicketRepository {
  const TicketRepository();

  static const String _storageKey = 'saferide_issued_tickets_v1';

  Future<List<IssuedTicket>> issuedTickets() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_storageKey) ?? <String>[];
    final tickets = <IssuedTicket>[];
    for (final raw in stored) {
      try {
        tickets.add(
          IssuedTicket.fromJson(jsonDecode(raw) as Map<String, dynamic>),
        );
      } catch (_) {
        continue;
      }
    }
    return tickets;
  }

  /// Next serial for a newly issued ticket, so every ticket code is unique.
  Future<int> nextSerial() async => (await issuedTickets()).length + 1;

  Future<void> issueTicket(IssuedTicket ticket) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_storageKey) ?? <String>[];
    stored.add(jsonEncode(ticket.toJson()));
    await prefs.setStringList(_storageKey, stored);
  }

  Future<bool> isUsed(String code) async {
    final tickets = await issuedTickets();
    for (final ticket in tickets) {
      if (ticket.code == code) return ticket.used;
    }
    return false;
  }

  /// Marks a ticket used after a successful scan, so it cannot be reused.
  Future<void> markUsed(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final tickets = await issuedTickets();
    final updated = tickets
        .map((ticket) =>
            ticket.code == code ? ticket.copyWith(used: true) : ticket)
        .toList();
    await prefs.setStringList(
      _storageKey,
      updated.map((ticket) => jsonEncode(ticket.toJson())).toList(),
    );
  }
}
