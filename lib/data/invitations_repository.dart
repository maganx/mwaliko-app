import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart';
import '../models/billing.dart';
import 'demo_store.dart';
import 'supabase.dart';

enum Channel {
  sms('sms', 'SMS'),
  whatsapp('whatsapp', 'WhatsApp'),
  email('email', 'Email');

  const Channel(this.id, this.label);
  final String id;
  final String label;
}

class SendSummary {
  const SendSummary({this.sent = 0, this.failed = 0, this.skipped = 0, this.charged = 0, this.errors = const []});
  final int sent, failed, skipped;

  /// Waalikwa waliotozwa salio kwenye utumaji huu.
  final int charged;
  final List<String> errors;

  SendSummary operator +(SendSummary o) => SendSummary(
    sent: sent + o.sent,
    failed: failed + o.failed,
    skipped: skipped + o.skipped,
    charged: charged + o.charged,
    errors: [...errors, ...o.errors],
  );
}

class Delivery {
  const Delivery({
    required this.guestId,
    required this.channel,
    required this.status,
    this.error,
    required this.createdAt,
  });

  final String guestId;
  final String channel;
  final String status;
  final String? error;
  final DateTime createdAt;

  factory Delivery.fromJson(Map<String, dynamic> j) => Delivery(
    guestId: j['guest_id'] as String,
    channel: j['channel'] as String,
    status: j['status'] as String,
    error: j['error'] as String?,
    createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
  );
}

class InvitationsRepository {
  const InvitationsRepository();

  /// Waalikwa wanatumwa kwa vikundi vidogo ili function ya server isizidi muda.
  static const batchSize = 25;

  Future<SendSummary> send({
    required String eventId,
    required List<String> guestIds,
    required Set<Channel> channels,
    void Function(int done, int total)? onProgress,
  }) async {
    if (AppConfig.demo) return _demoSend(eventId, guestIds, channels, onProgress);
    var total = const SendSummary();
    for (var i = 0; i < guestIds.length; i += batchSize) {
      final batch = guestIds.skip(i).take(batchSize).toList();
      final FunctionResponse res;
      try {
        res = await sb.functions.invoke(
          'send-invitations',
          body: {'event_id': eventId, 'guest_ids': batch, 'channels': channels.map((c) => c.id).toList()},
        );
      } on FunctionException catch (e) {
        final d = e.details;
        if (e.status == 402 && d is Map) {
          throw InsufficientCreditsException(
            needed: (d['needed'] as num?)?.toInt() ?? 0,
            balance: (d['balance'] as num?)?.toInt() ?? 0,
          );
        }
        rethrow;
      }
      final data = res.data as Map<String, dynamic>;
      final errors = <String>[
        for (final r in (data['results'] as List? ?? const []))
          if (r is Map && r['ok'] == false) '${r['channel']}: ${r['error']}',
      ];
      total += SendSummary(
        sent: (data['sent'] as num?)?.toInt() ?? 0,
        failed: (data['failed'] as num?)?.toInt() ?? 0,
        skipped: (data['skipped'] as num?)?.toInt() ?? 0,
        charged: (data['charged'] as num?)?.toInt() ?? 0,
        errors: errors,
      );
      onProgress?.call(i + batch.length, guestIds.length);
    }
    return total;
  }

  /// Demo: hakuna ujumbe unaotumwa kweli; tunaandika tu "Imetumwa" kwenye historia.
  Future<SendSummary> _demoSend(
    String eventId,
    List<String> guestIds,
    Set<Channel> channels,
    void Function(int done, int total)? onProgress,
  ) async {
    final demo = DemoStore.instance;
    bool reachable(String id) {
      final g = demo.guests[id]!;
      return channels.any((c) => c == Channel.email ? g['email'] != null : g['phone'] != null);
    }

    // inarusha InsufficientCreditsException; anayetozwa ni anayefikiwa tu
    final charged = demo.consume(eventId, guestIds.where(reachable).toList());
    var sent = 0, skipped = 0;
    for (final (i, id) in guestIds.indexed) {
      final g = demo.guests[id]!;
      for (final c in channels) {
        final reachable = c == Channel.email ? g['email'] != null : g['phone'] != null;
        if (!reachable) {
          skipped++;
          continue;
        }
        sent++;
        demo.deliveries.insert(0, {
          'event_id': eventId,
          'guest_id': id,
          'channel': c.id,
          'status': 'sent',
          'error': null,
          'created_at': demo.now(),
        });
      }
      await Future<void>.delayed(const Duration(milliseconds: 120));
      onProgress?.call(i + 1, guestIds.length);
    }
    return SendSummary(sent: sent, skipped: skipped, charged: charged);
  }

  Future<List<Delivery>> deliveries(String eventId) async {
    if (AppConfig.demo) {
      return DemoStore.instance.deliveries.where((d) => d['event_id'] == eventId).map(Delivery.fromJson).toList();
    }
    final rows = await sb
        .from('deliveries')
        .select()
        .eq('event_id', eventId)
        .order('created_at', ascending: false)
        .limit(1000);
    return rows.map(Delivery.fromJson).toList();
  }
}
