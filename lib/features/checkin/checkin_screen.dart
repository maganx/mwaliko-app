import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/swahili_time.dart';
import '../../data/guests_repository.dart';
import '../../widgets/async_view.dart';

/// Kuskani QR ya kadi mlangoni na kumwandikisha mwalikwa kuwa ameingia.
class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key, required this.eventId});
  final String eventId;

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  final _repo = const GuestsRepository();
  final _controller = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
  bool _busy = false;
  int _count = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final raw = capture.barcodes.map((b) => b.rawValue).whereType<String>().firstOrNull;
    if (raw == null) return;
    _busy = true;
    try {
      if (!raw.startsWith('MWALIKO:')) {
        await _result(icon: Icons.help_outline, color: Colors.orange, title: 'Si kadi ya Mwaliko');
        return;
      }
      final guest = await _repo.findByToken(widget.eventId, raw.substring('MWALIKO:'.length));
      if (guest == null) {
        await _result(icon: Icons.block, color: Colors.red, title: 'Kadi haitambuliki', body: 'Kadi hii si ya tukio hili.');
      } else if (guest.checkedInAt != null) {
        await _result(
          icon: Icons.warning_amber_rounded,
          color: Colors.orange,
          title: '${guest.name} ameshaingia',
          body: 'Aliingia ${swahiliTime(guest.checkedInAt!)}. Kadi hii imeshatumika.',
        );
      } else {
        final admit = await _result(
          icon: Icons.verified,
          color: Colors.green,
          title: guest.name,
          body: 'Watu ${guest.rsvpSeats ?? guest.seats}${guest.category != null ? ' · ${guest.category}' : ''}\n'
              'RSVP: ${guest.rsvpStatus.label}',
          confirmLabel: 'Mruhusu kuingia',
        );
        if (admit == true) {
          await _repo.checkIn(guest.id!);
          if (mounted) setState(() => _count++);
        }
      }
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
    } finally {
      _busy = false;
    }
  }

  Future<bool?> _result({
    required IconData icon,
    required Color color,
    required String title,
    String? body,
    String? confirmLabel,
  }) =>
      showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          icon: Icon(icon, color: color, size: 48),
          title: Text(title, textAlign: TextAlign.center),
          content: body == null ? null : Text(body, textAlign: TextAlign.center),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(confirmLabel == null ? 'Sawa' : 'Hapana')),
            if (confirmLabel != null) FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(confirmLabel)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-in mlangoni'),
        actions: [
          IconButton(onPressed: () => _controller.toggleTorch(), icon: const Icon(Icons.flashlight_on_outlined)),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'Elekeza kamera kwenye QR ya kadi.\nWalioingia kwenye kifaa hiki: $_count',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
