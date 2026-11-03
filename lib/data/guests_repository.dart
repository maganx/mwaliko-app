import '../core/config.dart';
import '../models/guest.dart';
import 'demo_store.dart';
import 'supabase.dart';

class GuestsRepository {
  const GuestsRepository();

  static DemoStore get _demo => DemoStore.instance;

  Future<List<Guest>> list(String eventId) async {
    if (AppConfig.demo) {
      final rows = _demo.guests.values.where((g) => g['event_id'] == eventId).toList()
        ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
      return rows.map(Guest.fromJson).toList();
    }
    final rows = await sb.from('guests').select().eq('event_id', eventId).order('name');
    return rows.map(Guest.fromJson).toList();
  }

  Future<Guest> add(Guest g) async {
    if (AppConfig.demo) return Guest.fromJson(_demo.addGuest(g.toInsertJson()));
    final row = await sb.from('guests').insert(g.toInsertJson()).select().single();
    return Guest.fromJson(row);
  }

  Future<int> addMany(String eventId, List<GuestDraft> drafts) async {
    if (drafts.isEmpty) return 0;
    if (AppConfig.demo) {
      for (final d in drafts) {
        _demo.addGuest(d.toGuest(eventId).toInsertJson());
      }
      return drafts.length;
    }
    const chunk = 200;
    for (var i = 0; i < drafts.length; i += chunk) {
      final part = drafts.skip(i).take(chunk).map((d) => d.toGuest(eventId).toInsertJson()).toList();
      await sb.from('guests').insert(part);
    }
    return drafts.length;
  }

  Future<void> update(String id, Map<String, dynamic> fields) async {
    if (AppConfig.demo) {
      _demo.guests[id]!.addAll(fields);
      return;
    }
    await sb.from('guests').update(fields).eq('id', id);
  }

  Future<void> delete(String id) async {
    if (AppConfig.demo) {
      _demo.guests.remove(id);
      return;
    }
    await sb.from('guests').delete().eq('id', id);
  }

  Future<Guest?> findByToken(String eventId, String token) async {
    if (AppConfig.demo) {
      final row = _demo.guests.values.where((g) => g['event_id'] == eventId && g['rsvp_token'] == token).firstOrNull;
      return row == null ? null : Guest.fromJson(row);
    }
    final row = await sb.from('guests').select().eq('event_id', eventId).eq('rsvp_token', token).maybeSingle();
    return row == null ? null : Guest.fromJson(row);
  }

  Future<void> checkIn(String id) => update(id, {'checked_in_at': DateTime.now().toUtc().toIso8601String()});
}
