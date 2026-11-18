import 'package:flutter_test/flutter_test.dart';
import 'package:saferide_campus/features/tickets/data/ticket_repository.dart';
import 'package:saferide_campus/features/tickets/domain/ticket_validator.dart';

void main() {
  final validator = TicketValidator();
  const issued = <IssuedTicket>[
    IssuedTicket(
      code: 'SR-18112026-RouteA-001',
      routeName: 'Route A',
      from: 'City Centre',
      to: 'Main Campus',
      dateLabel: 'Wed, 18 Nov 2026',
      seat: '12A',
    ),
    IssuedTicket(
      code: 'SR-18112026-RouteA-002',
      routeName: 'Route A',
      from: 'City Centre',
      to: 'Main Campus',
      dateLabel: 'Wed, 18 Nov 2026',
      seat: '12B',
      used: true,
    ),
  ];

  test('issued ticket is valid', () {
    expect(
      validator.validate('SR-18112026-RouteA-001', issued),
      TicketValidation.valid,
    );
  });

  test('used ticket is rejected', () {
    expect(
      validator.validate('SR-18112026-RouteA-002', issued),
      TicketValidation.alreadyUsed,
    );
  });

  test('unknown code is rejected', () {
    expect(
      validator.validate('SR-18112026-RouteA-099', issued),
      TicketValidation.unknownCode,
    );
  });

  test('bad formats are rejected', () {
    expect(validator.validate('hello', issued), TicketValidation.badFormat);
    expect(
      validator.validate('SR-18112026', issued),
      TicketValidation.badFormat,
    );
    expect(validator.validate('', issued), TicketValidation.badFormat);
  });

  test('find returns the matching ticket', () {
    expect(
      validator.find('SR-18112026-RouteA-001', issued)?.seat,
      '12A',
    );
    expect(validator.find('SR-18112026-RouteA-099', issued), isNull);
  });
}
