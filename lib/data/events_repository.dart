import '../models/card_config.dart';
import '../models/event.dart';
import 'supabase.dart';

class EventsRepository {
  const EventsRepository();

  Future<List<EventModel>> list() async {
    final rows = await sb.from('events').select().order('event_date', ascending: false);
    return rows.map(EventModel.fromJson).toList();
  }

  Future<EventModel> get(String id) async {
    final row = await sb.from('events').select().eq('id', id).single();
    return EventModel.fromJson(row);
  }

  Future<EventModel> create(EventModel e) async {
    final row = await sb.from('events').insert(e.toJson()).select().single();
    return EventModel.fromJson(row);
  }

  Future<EventModel> update(String id, EventModel e) async {
    final row = await sb.from('events').update(e.toJson()).eq('id', id).select().single();
    return EventModel.fromJson(row);
  }

  Future<void> saveCardConfig(String id, CardConfig c) =>
      sb.from('events').update({'card_config': c.toJson()}).eq('id', id);

  Future<void> delete(String id) => sb.from('events').delete().eq('id', id);

  Future<EventStats> stats(String id) async {
    final row = await sb.from('event_stats').select().eq('event_id', id).maybeSingle();
    return EventStats.fromJson(row);
  }

  Future<Map<String, EventStats>> allStats() async {
    final rows = await sb.from('event_stats').select();
    return {for (final r in rows) r['event_id'] as String: EventStats.fromJson(r)};
  }
}
