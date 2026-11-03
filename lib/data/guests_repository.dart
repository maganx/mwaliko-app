import '../models/guest.dart';
import 'supabase.dart';

class GuestsRepository {
  const GuestsRepository();

  Future<List<Guest>> list(String eventId) async {
    final rows = await sb.from('guests').select().eq('event_id', eventId).order('name');
    return rows.map(Guest.fromJson).toList();
  }

  Future<Guest> add(Guest g) async {
    final row = await sb.from('guests').insert(g.toInsertJson()).select().single();
    return Guest.fromJson(row);
  }

  Future<int> addMany(String eventId, List<GuestDraft> drafts) async {
    if (drafts.isEmpty) return 0;
    const chunk = 200;
    for (var i = 0; i < drafts.length; i += chunk) {
      final part = drafts.skip(i).take(chunk).map((d) => d.toGuest(eventId).toInsertJson()).toList();
      await sb.from('guests').insert(part);
    }
    return drafts.length;
  }

  Future<void> update(String id, Map<String, dynamic> fields) =>
      sb.from('guests').update(fields).eq('id', id);

  Future<void> delete(String id) => sb.from('guests').delete().eq('id', id);

  Future<Guest?> findByToken(String eventId, String token) async {
    final row = await sb
        .from('guests')
        .select()
        .eq('event_id', eventId)
        .eq('rsvp_token', token)
        .maybeSingle();
    return row == null ? null : Guest.fromJson(row);
  }

  Future<void> checkIn(String id) =>
      update(id, {'checked_in_at': DateTime.now().toUtc().toIso8601String()});
}
