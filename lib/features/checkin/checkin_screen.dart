import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/config.dart';
import '../../core/swahili_time.dart';
import '../../core/theme.dart';
import '../../data/guests_repository.dart';
import '../../widgets/async_view.dart';
import '../../widgets/ui.dart';

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
    final raw = capture.barcodes.map((b) => b.rawValue).whereType<String>().firstOrNull;
    if (raw != null) await _handle(raw);
  }

  /// Demo: kuiga kuskani kadi ya mwalikwa yeyote wa tukio hili.
  Future<void> _simulateScan() async {
    final guests = await _repo.list(widget.eventId);
    if (guests.isEmpty) return;
    final g = guests[Random().nextInt(guests.length)];
    await _handle(g.qrData);
  }

  Future<void> _handle(String raw) async {
    if (_busy) return;
    _busy = true;
    try {
      if (!raw.startsWith('MWALIKO:')) {
        await _result(icon: Icons.help_outline, color: MwalikoColors.warning, title: 'Si kadi ya Mwaliko');
        return;
      }
      final guest = await _repo.findByToken(widget.eventId, raw.substring('MWALIKO:'.length));
      if (guest == null) {
        await _result(
          icon: Icons.block,
          color: MwalikoColors.danger,
          title: 'Kadi haitambuliki',
          body: 'Kadi hii si ya tukio hili.',
        );
      } else if (guest.checkedInAt != null) {
        await _result(
          icon: Icons.warning_amber_rounded,
          color: MwalikoColors.warning,
          title: '${guest.name} ameshaingia',
          body: 'Aliingia ${swahiliTime(guest.checkedInAt!)}. Kadi hii imeshatumika.',
        );
      } else {
        final admit = await _result(
          icon: Icons.verified,
          color: MwalikoColors.success,
          title: guest.name,
          body:
              'Watu ${guest.rsvpSeats ?? guest.seats}${guest.category != null ? ' · ${guest.category}' : ''}\n'
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
  }) => showDialog<bool>(
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
          if (!(AppConfig.demo && kIsWeb))
            IconButton(onPressed: () => _controller.toggleTorch(), icon: const Icon(Icons.flashlight_on_outlined)),
        ],
      ),
      body: Stack(
        children: [
          if (AppConfig.demo && kIsWeb)
            const ColoredBox(
              color: Color(0xFF222222),
              child: Center(child: Icon(Icons.qr_code_2, size: 120, color: Colors.white24)),
            )
          else
            MobileScanner(controller: _controller, onDetect: _onDetect),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: MwalikoColors.accent, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: SoftCard(
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Elekeza kamera kwenye QR ya kadi.\nWalioingia kwenye kifaa hiki: $_count',
                      textAlign: TextAlign.center,
                    ),
                    if (AppConfig.demo) ...[
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed: _simulateScan,
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Jaribu: skani kadi ya mfano'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
