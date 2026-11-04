import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mwaliko/core/invitation_text.dart';
import 'package:mwaliko/models/card_config.dart';
import 'package:mwaliko/models/event.dart';
import 'package:mwaliko/models/event_progress.dart';

void main() {
  final base = EventModel(title: 'Harusi ya Amani', eventDate: DateTime(2026, 12, 12, 16), venue: 'Mlimani City');

  group('Hatua za mwaliko kwa mpangilio', () {
    test('tukio jipya: kadi tu ndiyo iko wazi', () {
      final p = EventProgress(base, const EventStats());
      expect(p.current, EventStep.card);
      expect(p.isUnlocked(EventStep.card), isTrue);
      expect(p.isUnlocked(EventStep.guests), isFalse);
      expect(p.isUnlocked(EventStep.send), isFalse);
      expect(p.blockerOf(EventStep.checkin), EventStep.card);
    });

    test('kadi imechaguliwa lakini hakuna waalikwa: kutuma kumefungwa', () {
      final e = base.copyWith(cardConfig: const CardConfig(chosen: true));
      final p = EventProgress(e, const EventStats());
      expect(p.current, EventStep.guests);
      expect(p.isUnlocked(EventStep.guests), isTrue);
      expect(p.blockerOf(EventStep.send), EventStep.guests);
      expect(p.lockedMessage(EventStep.send), contains('waalikwa'));
    });

    test('kutuma kunafungua check-in', () {
      final e = base.copyWith(cardConfig: const CardConfig(chosen: true));
      expect(EventProgress(e, const EventStats(guests: 3)).isUnlocked(EventStep.checkin), isFalse);
      final p = EventProgress(e, const EventStats(guests: 3, invited: 3));
      expect(p.isUnlocked(EventStep.checkin), isTrue);
      expect(p.current, EventStep.checkin);
    });

    test('"chosen" inahifadhiwa; matukio ya zamani yanahesabiwa yamechagua', () {
      expect(CardConfig.fromJson(const CardConfig(chosen: true).toJson()).chosen, isTrue);
      expect(CardConfig.fromJson(const CardConfig().toJson()).chosen, isFalse);
      expect(CardConfig.fromJson(null).chosen, isFalse);
      expect(CardConfig.fromJson({'mode': 'template', 'palette': 'waridi'}).chosen, isTrue);
    });
  });

  group('Maandishi ya mwaliko (sawa na send-invitations)', () {
    setUpAll(() => initializeDateFormatting('sw'));

    test('tarehe kwa Kiswahili', () {
      expect(invitationDate(DateTime(2026, 12, 12, 16)), 'Jumamosi, 12 Desemba 2026, saa 10:00 jioni');
      expect(invitationDate(DateTime(2027, 1, 23, 18, 30)), 'Jumamosi, 23 Januari 2027, saa 12:30 jioni');
    });

    test('SMS', () {
      final e = EventModel(
        title: 'Harusi ya Amani',
        hostNames: 'Familia ya Juma',
        eventDate: DateTime(2026, 12, 12, 16),
        venue: 'Mlimani City',
      );
      expect(
        smsText(e, 'Bi. Rehema', 'https://x.io/rsvp/?t=abc'),
        'Habari Bi. Rehema, Familia ya Juma wanakualika kwenye Harusi ya Amani, '
        'Jumamosi, 12 Desemba 2026, saa 10:00 jioni, Mlimani City. Kadi yako na kuthibitisha: https://x.io/rsvp/?t=abc',
      );
      expect(smsParts('a' * 160), 1);
      expect(smsParts('a' * 161), 2);
    });
  });
}
