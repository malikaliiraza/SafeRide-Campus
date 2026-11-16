import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../data/models/campus_ticket.dart';

/// Shows one offline ticket as a QR code.
///
/// The QR encodes only the ticket code — no personal data — and the screen
/// works with no network, which is the point on routes where signal drops.
class QrTicketScreen extends StatelessWidget {
  const QrTicketScreen({required this.ticket, super.key});

  final CampusTicket ticket;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My ticket')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    QrImageView(
                      data: ticket.code,
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      ticket.code,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Show this code to the conductor. It works offline.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _TicketRow(label: 'Route', value: ticket.routeName),
            _TicketRow(
              label: 'Journey',
              value: '${ticket.from} → ${ticket.to}',
            ),
            _TicketRow(label: 'Date', value: ticket.dateLabel),
            _TicketRow(label: 'Seat', value: ticket.seat),
          ],
        ),
      ),
    );
  }
}

class _TicketRow extends StatelessWidget {
  const _TicketRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}
