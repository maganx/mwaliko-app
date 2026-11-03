import 'package:flutter_test/flutter_test.dart';
import 'package:mwaliko/core/money.dart';
import 'package:mwaliko/data/demo_store.dart';
import 'package:mwaliko/models/billing.dart';

void main() {
  group('Bei', () {
    test('TSh 3,000 kwa mwalikwa: watu 200 = TSh 600,000', () {
      const p = Pricing();
      expect(p.pricePerGuest, 3000);
      expect(p.priceFor(200), 600000);
      expect(p.minPurchase, 10);
      expect(p.priceFor(p.minPurchase), 30000);
    });

    test('bei inasomwa kutoka database (inaweza kubadilishwa)', () {
      final p = Pricing.fromJson({
        'price_per_guest': 2500,
        'min_purchase': 20,
        'packages': [20, 300],
      });
      expect(p.priceFor(300), 750000);
      expect(p.minPurchase, 20);
      expect(p.packages, [20, 300]);
    });

    test('formatTzs', () {
      expect(formatTzs(600000), 'TSh 600,000');
      expect(formatTzs(3000), 'TSh 3,000');
    });
  });

  group('Salio (demo)', () {
    final demo = DemoStore.instance;

    test('kununua chini ya 10 kunakataliwa', () {
      expect(() => demo.purchase(credits: 9, method: 'mpesa'), throwsArgumentError);
    });

    test('kutozwa mara moja tu kwa kila mwalikwa', () {
      final eventId = demo.events.keys.first;
      final uncharged = demo.guests.values
          .where((g) => g['event_id'] == eventId && g['charged_at'] == null)
          .map((g) => g['id'] as String)
          .take(2)
          .toList();
      expect(uncharged, hasLength(2));
      final before = demo.credits;
      expect(demo.consume(eventId, uncharged), 2);
      expect(demo.credits, before - 2);
      expect(demo.consume(eventId, uncharged), 0, reason: 'kumtumia tena ni bure');
      expect(demo.credits, before - 2);
    });

    test('salio lisipotosha hakuna kinachokatwa', () {
      final eventId = demo.events.keys.first;
      final id = demo.guests.values.firstWhere((g) => g['event_id'] == eventId && g['charged_at'] == null)['id'];
      final saved = demo.credits;
      demo.credits = 0;
      expect(
        () => demo.consume(eventId, [id as String]),
        throwsA(isA<InsufficientCreditsException>().having((e) => e.needed, 'needed', 1)),
      );
      expect(demo.guests[id]!['charged_at'], isNull);
      demo.credits = saved;
    });
  });
}
