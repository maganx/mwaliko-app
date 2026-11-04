import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mwaliko/features/cards/card_exporter.dart';
import 'package:mwaliko/features/cards/card_styles.dart';
import 'package:mwaliko/features/cards/invitation_card.dart';
import 'package:mwaliko/models/card_config.dart';
import 'package:mwaliko/models/event.dart';
import 'package:mwaliko/models/guest.dart';

/// Inachora kila template kwa fonts halisi na kuhakikisha hakuna overflow.
/// Ukiweka SAVE_CARDS=1, PNG zinahifadhiwa kwenye build/card_samples/.
Future<void> _loadFonts() async {
  const families = {
    'PlayfairDisplay': ['PlayfairDisplay-Variable.ttf'],
    'GreatVibes': ['GreatVibes-Regular.ttf'],
    'Cinzel': ['Cinzel-Variable.ttf'],
    'CormorantGaramond': ['CormorantGaramond-Variable.ttf'],
    'Montserrat': ['Montserrat-Variable.ttf'],
    'DancingScript': ['DancingScript-Variable.ttf'],
    'Lato': ['Lato-Regular.ttf', 'Lato-Bold.ttf'],
    'Poppins': ['Poppins-Regular.ttf', 'Poppins-SemiBold.ttf'],
    'Marcellus': ['Marcellus-Regular.ttf'],
  };
  for (final e in families.entries) {
    final loader = FontLoader(e.key);
    for (final f in e.value) {
      final bytes = File('assets/fonts/$f').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }
}

final _event = EventModel(
  title: 'Harusi ya Amani & Neema',
  eventType: 'harusi',
  hostNames: 'Familia ya Bw. na Bi. Mussa Juma',
  eventDate: DateTime(2026, 12, 12, 16, 0),
  venue: 'Mlimani City Hall, Dar es Salaam',
  dressCode: 'Rangi ya dhahabu na nyeupe',
  contactPhone: '0712 345 678',
);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('sw');
    await _loadFonts();
  });

  final save = Platform.environment['SAVE_CARDS'] == '1';

  for (final t in curatedTemplates) {
    testWidgets('template ${t.id} (${t.name}) inachorwa bila overflow', (tester) async {
      final key = GlobalKey();
      final config = t.apply(const CardConfig());
      await tester.binding.setSurfaceSize(const Size(540, 675));
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Center(
              child: RepaintBoundary(
                key: key,
                child: SizedBox(
                  width: 540,
                  height: 675,
                  child: InvitationCard(
                    event: _event,
                    config: config,
                    guestName: 'Bi. Rehema Salim',
                    seats: 2,
                    qrData: 'MWALIKO:9f2c1a7b3d4e5f60a1b2c3d4',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      if (save) {
        await tester.runAsync(() async {
          final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1.5);
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          final dir = Directory('build/card_samples')..createSync(recursive: true);
          File('${dir.path}/${t.id}.png').writeAsBytesSync(png!.buffer.asUint8List());
        });
      }
      await tester.binding.setSurfaceSize(null);
    });
  }

  // Kila layout ya picha na kila pambo, kwa rangi na fonts tofauti.
  for (final (i, layout) in photoLayoutIds.indexed) {
    for (final (j, ornament) in ornamentIds.indexed) {
      final config = CardConfig(
        paletteId: palettes[(i * 3 + j) % palettes.length].id,
        fontPairId: fontPairs[(i + j) % fontPairs.length].id,
        ornamentId: ornament,
        layoutId: layout,
        photoPath: 'u/e/photo.jpg',
      );
      testWidgets('kadi ya picha $layout + $ornament inachorwa bila overflow', (tester) async {
        expect(config.hasPhoto, isTrue);
        final photo = await tester.runAsync(() async {
          final rec = ui.PictureRecorder();
          final canvas = Canvas(rec);
          canvas.drawRect(
            const Rect.fromLTWH(0, 0, 800, 600),
            Paint()
              ..shader = ui.Gradient.linear(Offset.zero, const Offset(800, 600), [
                const Color(0xFF6B8CAE),
                const Color(0xFFE8B98A),
              ]),
          );
          canvas.drawCircle(const Offset(320, 230), 90, Paint()..color = const Color(0xFF5A3825));
          canvas.drawCircle(const Offset(480, 250), 85, Paint()..color = const Color(0xFF7A4B30));
          return rec.endRecording().toImage(800, 600);
        });
        final key = GlobalKey();
        await tester.binding.setSurfaceSize(const Size(540, 675));
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: RepaintBoundary(
                  key: key,
                  child: SizedBox(
                    width: 540,
                    height: 675,
                    child: InvitationCard(
                      event: _event,
                      config: config,
                      guestName: 'Bi. Rehema Salim',
                      seats: 2,
                      qrData: 'MWALIKO:9f2c1a7b3d4e5f60a1b2c3d4',
                      photo: photo,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Bi. Rehema Salim'), findsOneWidget);
        if (save) {
          await tester.runAsync(() async {
            final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 1);
            final png = await image.toByteData(format: ui.ImageByteFormat.png);
            final dir = Directory('build/card_samples')..createSync(recursive: true);
            File('${dir.path}/$layout-$ornament.png').writeAsBytesSync(png!.buffer.asUint8List());
          });
        }
        await tester.binding.setSurfaceSize(null);
      });
    }
  }

  test('generator ya picha inatumia kila layout ya picha', () {
    final designs = CardGenerator(7)
        .generateWithPhoto(const CardConfig(photoPath: 'u/e/photo.jpg'), 8, eventType: 'harusi');
    expect(designs.length, 8);
    expect(designs.map(designKey).toSet().length, 8);
    expect(designs.map((c) => c.layoutId).toSet(), photoLayoutIds.toSet());
    expect(designs.every((c) => c.hasPhoto), isTrue);
  });

  test('kadi ya mwalikwa inatengenezwa upya design au picha ikibadilika', () {
    const g = Guest(eventId: 'e', name: 'Mzee Juma', seats: 2, rsvpToken: 'abc');
    final fp = CardExporter.fingerprint(_event, g);
    final withPhoto = _event.copyWith(
      cardConfig: const CardConfig(layoutId: 'photo_circle', photoPath: 'u/e/photo-1.jpg'),
    );
    expect(CardExporter.fingerprint(_event, g), fp, reason: 'alama haibadiliki bila sababu');
    expect(CardExporter.fingerprint(_event.copyWith(cardConfig: const CardConfig(chosen: true)), g), fp);
    expect(CardExporter.fingerprint(withPhoto, g), isNot(fp));
    expect(
      CardExporter.fingerprint(_event, const Guest(eventId: 'e', name: 'Mzee Juma Ali', seats: 2, rsvpToken: 'abc')),
      isNot(fp),
    );
    final current = Guest(
      eventId: 'e',
      name: 'Mzee Juma',
      seats: 2,
      rsvpToken: 'abc',
      cardPath: 'o/e/guests/g-$fp.png',
    );
    expect(CardExporter.isCurrent(_event, current), isTrue);
    expect(CardExporter.isCurrent(withPhoto, current), isFalse);
    expect(CardExporter.isCurrent(_event, g), isFalse, reason: 'hana kadi bado');
    expect(
      CardExporter.isCurrent(_event, const Guest(eventId: 'e', name: 'Mzee Juma', cardPath: 'o/e/guests/g.png')),
      isFalse,
      reason: 'kadi za mtindo wa zamani zinatengenezwa upya',
    );
  });

  test('picha ya mteja inahifadhika kwenye JSON; layout ya kawaida haionyeshi picha', () {
    const c = CardConfig(layoutId: 'photo_arch', photoPath: 'u/e/photo-1.jpg');
    final back = CardConfig.fromJson(c.toJson());
    expect(back.photoPath, 'u/e/photo-1.jpg');
    expect(back.hasPhoto, isTrue);
    expect(back.copyWith(layoutId: 'centered').hasPhoto, isFalse);
    expect(const CardConfig(layoutId: 'photo_arch').hasPhoto, isFalse);
  });

  testWidgets('design ya mteja (custom) inaweka jina na QR bila kosa', (tester) async {
    final image = await tester.runAsync(() async {
      final rec = ui.PictureRecorder();
      Canvas(rec).drawRect(const Rect.fromLTWH(0, 0, 600, 900), Paint()..color = const Color(0xFFF3E1C7));
      return rec.endRecording().toImage(600, 900);
    });
    const config = CardConfig(mode: CardMode.custom, customImagePath: 'u/e/design.png', customAspect: 600 / 900);
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 300,
            child: InvitationCard(
              event: _event,
              config: config,
              guestName: 'Mzee Juma',
              customImage: image,
              qrData: 'MWALIKO:abc',
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Mzee Juma'), findsOneWidget);
    expect(InvitationCard.designSizeFor(config), const Size(540, 810));
  });

  test('generator inatoa design tofauti', () {
    final designs = CardGenerator(42).generateMany(const CardConfig(), 12, eventType: 'harusi');
    final keys = designs.map((c) => '${c.paletteId}${c.ornamentId}${c.fontPairId}${c.layoutId}').toSet();
    expect(designs.length, 12);
    expect(keys.length, 12);
  });

  test('CardConfig inahifadhika na kusomeka (JSON)', () {
    const c = CardConfig(
      mode: CardMode.custom,
      customImagePath: 'u/e/design.png',
      customAspect: 0.7,
      namePosition: Offset(0.4, 0.6),
      nameColor: 0xFF123456,
    );
    final back = CardConfig.fromJson(c.toJson());
    expect(back.isCustom, isTrue);
    expect(back.customAspect, 0.7);
    expect(back.namePosition, const Offset(0.4, 0.6));
    expect(back.nameColor, 0xFF123456);
  });
}
