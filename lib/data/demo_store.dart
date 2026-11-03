import 'dart:math';
import 'dart:typed_data';

import '../models/billing.dart';

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

  // --- Akaunti na salio -------------------------------------------------------
  /// Mteja aliyeingia (null = hajaingia). Demo inamfanya admin ili skrini ya admin ionekane.
  Map<String, dynamic>? signedInUser;
  int credits = 24;
  final transactions = <Map<String, dynamic>>[];
  final payments = <Map<String, dynamic>>[];
  static const pricePerGuest = 3000;

  void signIn({required String email, String? fullName, String? businessName, String? phone}) {
    signedInUser = {
      'id': 'demo',
      'email': email.trim(),
      'full_name': fullName ?? 'Asha Mohamed',
      'business_name': businessName ?? 'Asha Events & Decor',
      'phone': phone ?? '255713100200',
      'role': 'admin',
    };
  }

  Map<String, dynamic> _payment(
    String userId,
    int credits,
    String method,
    String status, {
    String? phone,
    String? reference,
    Map<String, dynamic>? profile,
    DateTime? at,
  }) => {
    'id': newId(),
    'user_id': userId,
    'credits': credits,
    'amount': credits * pricePerGuest,
    'method': method,
    'phone': phone,
    'reference': reference,
    'status': status,
    'created_at': (at ?? DateTime.now()).toUtc().toIso8601String(),
    'profiles': ?profile,
  };

  Map<String, dynamic> purchase({required int credits, required String method, String? phone, String? reference}) {
    if (credits < 10) throw ArgumentError('Kima cha chini ni mialiko 10');
    final p = _payment('demo', credits, method, 'pending', phone: phone, reference: reference);
    payments.insert(0, p);
    confirmPayment(p['id'] as String); // demo: inathibitishwa moja kwa moja
    return p;
  }

  void confirmPayment(String id) {
    final p = payments.firstWhere((p) => p['id'] == id);
    if (p['status'] != 'pending') return;
    p['status'] = 'paid';
    if (p['user_id'] == 'demo') {
      credits += p['credits'] as int;
      transactions.insert(0, {
        'kind': 'purchase',
        'credits': p['credits'],
        'amount': p['amount'],
        'note': 'Umenunua mialiko ${p['credits']}',
        'created_at': now(),
      });
    }
  }

  /// Inakata salio kwa waalikwa ambao hawajawahi kutozwa. Inarudisha idadi iliyotozwa.
  int consume(String eventId, List<String> guestIds) {
    final uncharged = guestIds.where((id) => guests[id]?['charged_at'] == null).toList();
    if (uncharged.isEmpty) return 0;
    if (credits < uncharged.length) {
      throw InsufficientCreditsException(needed: uncharged.length, balance: credits);
    }
    credits -= uncharged.length;
    for (final id in uncharged) {
      guests[id]!['charged_at'] = now();
    }
    transactions.insert(0, {
      'kind': 'usage',
      'credits': -uncharged.length,
      'note': 'Mialiko ${uncharged.length} imetumwa',
      'created_at': now(),
    });
    return uncharged.length;
  }

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
    // historia ya salio ya mfano
    final bought = DateTime.now().subtract(const Duration(days: 3));
    payments.add(_payment('demo', 30, 'mpesa', 'paid', phone: '255713100200', reference: 'SKD81HQ2P1', at: bought));
    transactions.add({
      'kind': 'purchase',
      'credits': 30,
      'amount': 30 * pricePerGuest,
      'note': 'Umenunua mialiko 30',
      'created_at': bought.toUtc().toIso8601String(),
    });
    transactions.insert(0, {
      'kind': 'usage',
      'credits': -6,
      'note': 'Mialiko 6 imetumwa',
      'created_at': DateTime.now().subtract(const Duration(days: 2)).toUtc().toIso8601String(),
    });
    // ombi la malipo la mteja mwingine, linasubiri admin
    payments.add(
      _payment(
        'other',
        200,
        'mixx',
        'pending',
        phone: '255754300400',
        reference: 'MX7719203',
        profile: {'business_name': 'Neema Wedding Planners'},
      ),
    );

    // historia ya utumaji ya mfano
    for (final g in guests.values.where((g) => g['event_id'] == harusi['id']).take(6)) {
      g['charged_at'] = now();
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
