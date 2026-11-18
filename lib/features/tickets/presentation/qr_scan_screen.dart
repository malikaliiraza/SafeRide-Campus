import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/app_theme.dart';
import '../data/ticket_repository.dart';
import '../domain/ticket_validator.dart';

/// Conductor mode: scan a student's QR ticket and check it.
///
/// The camera reads the code; if the camera is unavailable (no permission,
/// web without a camera) the code can be typed in by hand. The code is
/// checked against the tickets issued on this device — a valid ticket is
/// marked used so it cannot be scanned twice. Cross-device checks need a
/// shared backend and are roadmap.
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final TicketRepository _tickets = const TicketRepository();
  final TicketValidator _validator = TicketValidator();
  final TextEditingController _manualController = TextEditingController();

  String? _lastCode;
  TicketValidation? _result;
  IssuedTicket? _matched;
  bool _validating = false;

  Future<void> _checkCode(String code) async {
    if (_validating || code.trim().isEmpty || code == _lastCode) return;
    setState(() {
      _validating = true;
      _lastCode = code;
    });
    final issued = await _tickets.issuedTickets();
    final result = _validator.validate(code, issued);
    final matched = _validator.find(code, issued);
    if (result == TicketValidation.valid) {
      await _tickets.markUsed(code.trim());
    }
    if (!mounted) return;
    setState(() {
      _result = result;
      _matched = matched;
      _validating = false;
    });
  }

  void _scanAnother() {
    setState(() {
      _lastCode = null;
      _result = null;
      _matched = null;
      _manualController.clear();
    });
  }

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  Color _resultColor() {
    return switch (_result) {
      TicketValidation.valid => AppTheme.onTimeGreen,
      TicketValidation.alreadyUsed => AppTheme.alertAmber,
      TicketValidation.unknownCode => AppTheme.dangerRed,
      TicketValidation.badFormat => AppTheme.dangerRed,
      null => AppTheme.primaryTeal,
    };
  }

  String _resultText() {
    return switch (_result) {
      TicketValidation.valid =>
        'Valid ticket — ${_matched?.routeName ?? ''}, seat ${_matched?.seat ?? ''}. Marked used.',
      TicketValidation.alreadyUsed =>
        'Already used — this ticket was scanned before.',
      TicketValidation.unknownCode =>
        'Unknown code — no ticket with this code was issued on this phone.',
      TicketValidation.badFormat =>
        'Not a SafeRide ticket code — check the code and try again.',
      null => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan ticket')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacing),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radius),
            child: SizedBox(
              height: 280,
              child: MobileScanner(
                onDetect: (capture) {
                  final code = capture.barcodes.firstOrNull?.rawValue;
                  if (code != null) _checkCode(code);
                },
                errorBuilder: (context, error) {
                  return const ColoredBox(
                    color: Colors.black12,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Camera unavailable — enter the ticket code '
                          'below instead.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Point the camera at the student\'s QR code, or type the code:',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _manualController,
                  decoration: const InputDecoration(
                    labelText: 'Ticket code',
                    hintText: 'SR-16112026-RouteA-001',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _validating
                    ? null
                    : () => _checkCode(_manualController.text),
                child: const Text('Check'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_validating) const Center(child: CircularProgressIndicator()),
          if (_result != null && !_validating)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _lastCode ?? '',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _resultText(),
                      style: TextStyle(
                        color: _resultColor(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_matched != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${_matched!.from} → ${_matched!.to} · ${_matched!.dateLabel}',
                      ),
                    ],
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _scanAnother,
                      child: const Text('Scan another'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
