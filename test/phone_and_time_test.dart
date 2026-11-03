import 'package:flutter_test/flutter_test.dart';
import 'package:mwaliko/core/phone.dart';
import 'package:mwaliko/core/swahili_time.dart';

void main() {
  group('normalizePhone', () {
    test('namba za Tanzania', () {
      expect(normalizePhone('0712 345 678'), '255712345678');
      expect(normalizePhone('712345678'), '255712345678');
      expect(normalizePhone('+255 712-345-678'), '255712345678');
      expect(normalizePhone('255712345678'), '255712345678');
      expect(normalizePhone('00255712345678'), '255712345678');
    });

    test('nchi nyingine kwa +', () {
      expect(normalizePhone('+254 712 345678'), '254712345678');
    });

    test('namba zisizo sahihi', () {
      expect(normalizePhone(''), isNull);
      expect(normalizePhone('12345'), isNull);
      expect(normalizePhone('abc'), isNull);
    });

    test('formatPhone', () {
      expect(formatPhone('255712345678'), '+255 712 345 678');
    });
  });

  group('swahiliTime', () {
    test('saa za Kiswahili', () {
      expect(swahiliTime(DateTime(2026, 1, 1, 7, 0)), 'Saa 1:00 asubuhi');
      expect(swahiliTime(DateTime(2026, 1, 1, 13, 30)), 'Saa 7:30 mchana');
      expect(swahiliTime(DateTime(2026, 1, 1, 16, 0)), 'Saa 10:00 jioni');
      expect(swahiliTime(DateTime(2026, 1, 1, 20, 0)), 'Saa 2:00 usiku');
      expect(swahiliTime(DateTime(2026, 1, 1, 0, 0)), 'Saa 6:00 usiku');
      expect(swahiliTime(DateTime(2026, 1, 1, 6, 0)), 'Saa 12:00 asubuhi');
    });
  });
}
