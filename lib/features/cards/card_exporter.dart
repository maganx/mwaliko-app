import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';

import '../../data/cards_repository.dart';
import '../../models/event.dart';
import '../../models/guest.dart';
import 'invitation_card.dart';

/// Inatengeneza PNG ya kadi binafsi ya kila mwalikwa (jina lake + QR yake)
/// na kuipakia kwenye storage, ili itumwe kwa WhatsApp/email au ishirikiwe.
class CardExporter {
  CardExporter({this.cards = const CardsRepository()});

  final CardsRepository cards;
  final _shot = ScreenshotController();

  /// Upana wa PNG kwa pixels = 540 * [pixelRatio].
  static const pixelRatio = 2.0;

  Future<int> exportAll({
    required EventModel event,
    required List<Guest> guests,
    void Function(int done, int total)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final config = event.cardConfig;
    ui.Image? custom;
    if (config.isCustom) {
      final bytes = await cards.download(config.customImagePath!);
      custom = await decodeImageFromList(bytes);
    }

    final size = InvitationCard.designSizeFor(config);
    var done = 0;
    for (final g in guests) {
      if (isCancelled?.call() ?? false) break;
      final png = await _shot.captureFromWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox.fromSize(
            size: size,
            child: InvitationCard(
              event: event,
              config: config,
              guestName: g.name,
              seats: g.seats,
              qrData: g.qrData,
              customImage: custom,
            ),
          ),
        ),
        targetSize: size,
        pixelRatio: pixelRatio,
        delay: const Duration(milliseconds: 30),
      );
      await cards.uploadGuestCard(event.id!, g.id!, png);
      done++;
      onProgress?.call(done, guests.length);
    }
    custom?.dispose();
    return done;
  }
}
