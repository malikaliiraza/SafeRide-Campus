import '../data/ticket_repository.dart';

/// Result of checking a scanned ticket code.
enum TicketValidation { valid, badFormat, unknownCode, alreadyUsed }

/// Pure validation of a scanned ticket code against the tickets issued on
/// this device. No network, no backend: a conductor scans the QR and the
/// app checks the code this phone issued.
///
/// Cross-device validation (conductor's phone checking a student's phone)
/// needs a shared backend and is roadmap — the format, the issue record,
/// and the used-flag are the honest on-device flow.
class TicketValidator {
  static final RegExp _codePattern =
      RegExp(r'^SR-[0-9A-Za-z]+-[A-Za-z]+-\d{3}$');

  TicketValidation validate(String code, List<IssuedTicket> issued) {
    final trimmed = code.trim();
    if (!_codePattern.hasMatch(trimmed)) {
      return TicketValidation.badFormat;
    }
    final match = find(trimmed, issued);
    if (match == null) return TicketValidation.unknownCode;
    if (match.used) return TicketValidation.alreadyUsed;
    return TicketValidation.valid;
  }

  IssuedTicket? find(String code, List<IssuedTicket> issued) {
    for (final ticket in issued) {
      if (ticket.code == code.trim()) return ticket;
    }
    return null;
  }
}
