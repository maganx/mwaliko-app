import 'dart:convert';
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

  /// Alama fupi ya kila kinachoonekana kwenye kadi ya mwalikwa: design, picha, maelezo ya tukio,
  /// jina, viti na QR. Inakuwa sehemu ya jina la PNG, kwa hiyo kitu kikibadilika kadi inatengenezwa upya.
  static String fingerprint(EventModel e, Guest g) {
    final config = e.cardConfig.toJson()..remove('chosen');
    final details = e.toJson()
      ..remove('card_config')
      ..remove('venue_map_url');
    final data = utf8.encode(jsonEncode([details, config, g.name, g.seats, g.qrData]));
    // Hash ya polynomial (inakaa chini ya 2^53, kwa hiyo inatoa jibu lilelile kwenye web na simu).
    var a = 7, b = 11;
    for (final c in data) {
      a = (a * 31 + c) % 2147483647;
      b = (b * 37 + c) % 2147483629;
    }
    return a.toRadixString(36) + b.toRadixString(36);
  }

  /// Kadi ya mwalikwa ipo na inalingana na design na maelezo ya sasa.
  static bool isCurrent(EventModel e, Guest g) => g.cardPath?.endsWith('-${fingerprint(e, g)}.png') ?? false;

  Future<int> exportAll({
    required EventModel event,
    required List<Guest> guests,
    void Function(int done, int total)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final images = await _images(event);
    var done = 0;
    try {
      for (final g in guests) {
        if (isCancelled?.call() ?? false) break;
        await _export(event, g, images);
        done++;
        onProgress?.call(done, guests.length);
      }
    } finally {
      images.$1?.dispose();
      images.$2?.dispose();
    }
    return done;
  }

  /// Kadi ya mwalikwa mmoja; inarudisha njia (path) yake kwenye storage.
  Future<String> exportOne(EventModel event, Guest guest) async {
    final images = await _images(event);
    try {
      return await _export(event, guest, images);
    } finally {
      images.$1?.dispose();
      images.$2?.dispose();
    }
  }

  /// Picha za design ya mteja na picha yake (zinapakuliwa mara moja tu kwa kadi zote).
  Future<(ui.Image?, ui.Image?)> _images(EventModel event) async {
    final config = event.cardConfig;
    ui.Image? custom;
    if (config.isCustom) custom = await decodeImageFromList(await cards.download(config.customImagePath!));
    ui.Image? photo;
    if (config.hasPhoto) photo = await decodeImageFromList(await cards.download(config.photoPath!));
    return (custom, photo);
  }

  Future<String> _export(EventModel event, Guest g, (ui.Image?, ui.Image?) images) async {
    final config = event.cardConfig;
    final size = InvitationCard.designSizeFor(config);
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
            customImage: images.$1,
            photo: images.$2,
          ),
        ),
      ),
      targetSize: size,
      pixelRatio: pixelRatio,
      delay: const Duration(milliseconds: 30),
    );
    return cards.uploadGuestCard(event.id!, g.id!, png, fingerprint: fingerprint(event, g));
  }
}
