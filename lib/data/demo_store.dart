import 'dart:math';
import 'dart:typed_data';

/// Data ya mfano kwa "demo mode" (flutter run --dart-define=DEMO=true).
/// Kila kitu kinakaa kwenye kumbukumbu ya app tu; hakuna kinachotumwa kwa Supabase
/// wala kwa watoa huduma wa SMS/WhatsApp/email.
class DemoStore {
  DemoStore._() {
    _seed();
  }

  static final instance = DemoStore._();

  final events = <String, Map<String, dynamic>>{};
  final guests = <String, Map<String, dynamic>>{};
  final deliveries = <Map<String, dynamic>>[];
  final files = <String, Uint8List>{};

  final _rng = Random(2026);

  String newId() => List.generate(16, (_) => _rng.nextInt(16).toRadixString(16)).join();
  String newToken() => List.generate(24, (_) => _rng.nextInt(16).toRadixString(16)).join();
  String now() => DateTime.now().toUtc().toIso8601String();

  Map<String, dynamic> addEvent(Map<String, dynamic> data) {
    final id = newId();
    final row = {...data, 'id': id, 'created_at': now()};
    events[id] = row;
    return row;
  }

  Map<String, dynamic> addGuest(Map<String, dynamic> data) {
    final id = newId();
    final row = <String, dynamic>{
      'seats': 1,
      'rsvp_status': 'pending',
      ...data,
      'id': id,
      'rsvp_token': newToken(),
      'created_at': now(),
    };
    guests[id] = row;
    return row;
  }

  Map<String, dynamic> stats(String eventId) {
    final g = guests.values.where((x) => x['event_id'] == eventId).toList();
    int count(String s) => g.where((x) => x['rsvp_status'] == s).length;
    return {
      'event_id': eventId,
      'guests': g.length,
      'seats': g.fold<int>(0, (s, x) => s + (x['seats'] as int)),
      'attending': count('attending'),
      'declined': count('declined'),
      'maybe': count('maybe'),
      'pending': count('pending'),
      'checked_in': g.where((x) => x['checked_in_at'] != null).length,
    };
  }

  void _seed() {
    final harusi = addEvent({
      'title': 'Harusi ya Amani & Neema',
      'event_type': 'harusi',
      'host_names': 'Familia ya Bw. na Bi. Mussa Juma',
      'event_date': DateTime(2026, 12, 12, 16, 0).toUtc().toIso8601String(),
      'venue': 'Mlimani City Hall, Dar es Salaam',
      'venue_map_url': 'https://maps.google.com/?q=Mlimani+City',
      'dress_code': 'Rangi ya dhahabu na nyeupe',
      'contact_phone': '0712 345 678',
      'message': 'Karibu tusherehekee pamoja siku yetu ya furaha.',
      'card_config': {
        'mode': 'template',
        'palette': 'dhahabu_usiku',
        'ornament': 'gold_frame',
        'fonts': 'royal',
        'layout': 'centered',
      },
    });
    final sendoff = addEvent({
      'title': 'Send-Off ya Rehema',
      'event_type': 'sendoff',
      'host_names': 'Familia ya Mzee Salim',
      'event_date': DateTime(2027, 1, 23, 18, 30).toUtc().toIso8601String(),
      'venue': 'Golden Tulip, Masaki',
      'card_config': {
        'mode': 'template',
        'palette': 'waridi',
        'ornament': 'florals',
        'fonts': 'classic',
        'layout': 'framed',
      },
    });

    const people = [
      ('Bi. Rehema Salim', '255712345678', 'rehema@example.com', 2, 'attending', 'Familia'),
      ('Bw. Juma Mussa', '255754000111', null, 2, 'attending', 'Familia'),
      ('Dkt. Neema Mushi', '255767888999', 'neema@example.com', 1, 'maybe', 'VIP'),
      ('Baraka Kimaro', '255713222333', null, 1, 'pending', 'Marafiki'),
      ('Amina Hassan', '255655111222', 'amina@example.com', 3, 'attending', 'Familia'),
      ('Eng. Peter Mwakyusa', '255688444555', null, 1, 'declined', 'Kazini'),
      ('Zawadi Lyimo', '255715666777', null, 2, 'pending', 'Marafiki'),
      ('Mchungaji Elia Mollel', '255784123123', null, 2, 'attending', 'VIP'),
      ('Fatma Omary', '255621987654', 'fatma@example.com', 1, 'pending', 'Marafiki'),
      ('Hamisi Ally', '255744321321', null, 1, 'attending', 'Kazini'),
    ];
    for (final p in people) {
      addGuest({
        'event_id': harusi['id'],
        'name': p.$1,
        'phone': p.$2,
        'email': p.$3,
        'seats': p.$4,
        'rsvp_status': p.$5,
        'rsvp_seats': p.$5 == 'attending' ? p.$4 : null,
        'category': p.$6,
      });
    }
    for (final p in people.take(4)) {
      addGuest({'event_id': sendoff['id'], 'name': p.$1, 'phone': p.$2, 'seats': 1, 'category': p.$6});
    }
    // historia ya utumaji ya mfano
    for (final g in guests.values.where((g) => g['event_id'] == harusi['id']).take(6)) {
      deliveries.add({
        'event_id': harusi['id'],
        'guest_id': g['id'],
        'channel': 'whatsapp',
        'status': g['rsvp_status'] == 'pending' ? 'delivered' : 'read',
        'error': null,
        'created_at': DateTime.now().subtract(const Duration(days: 2)).toUtc().toIso8601String(),
      });
    }
  }
}
