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
  const SendSummary({this.sent = 0, this.failed = 0, this.skipped = 0, this.errors = const []});
  final int sent, failed, skipped;
  final List<String> errors;

  SendSummary operator +(SendSummary o) => SendSummary(
        sent: sent + o.sent,
        failed: failed + o.failed,
        skipped: skipped + o.skipped,
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
    var total = const SendSummary();
    for (var i = 0; i < guestIds.length; i += batchSize) {
      final batch = guestIds.skip(i).take(batchSize).toList();
      final res = await sb.functions.invoke('send-invitations', body: {
        'event_id': eventId,
        'guest_ids': batch,
        'channels': channels.map((c) => c.id).toList(),
      });
      final data = res.data as Map<String, dynamic>;
      final errors = <String>[
        for (final r in (data['results'] as List? ?? const []))
          if (r is Map && r['ok'] == false) '${r['channel']}: ${r['error']}',
      ];
      total += SendSummary(
        sent: (data['sent'] as num?)?.toInt() ?? 0,
        failed: (data['failed'] as num?)?.toInt() ?? 0,
        skipped: (data['skipped'] as num?)?.toInt() ?? 0,
        errors: errors,
      );
      onProgress?.call(i + batch.length, guestIds.length);
    }
    return total;
  }

  Future<List<Delivery>> deliveries(String eventId) async {
    final rows = await sb
        .from('deliveries')
        .select()
        .eq('event_id', eventId)
        .order('created_at', ascending: false)
        .limit(1000);
    return rows.map(Delivery.fromJson).toList();
  }
}
