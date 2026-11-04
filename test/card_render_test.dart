import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mwaliko/features/cards/card_styles.dart';
import 'package:mwaliko/features/cards/invitation_card.dart';
import 'package:mwaliko/models/card_config.dart';
import 'package:mwaliko/models/event.dart';

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
