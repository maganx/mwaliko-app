import '../core/config.dart';
import '../models/card_config.dart';
import '../models/event.dart';
import 'demo_store.dart';
import 'supabase.dart';

class EventsRepository {
  const EventsRepository();

  static DemoStore get _demo => DemoStore.instance;

  Future<List<EventModel>> list() async {
    if (AppConfig.demo) {
      final rows = _demo.events.values.toList()
        ..sort((a, b) => (b['event_date'] as String).compareTo(a['event_date'] as String));
      return rows.map(EventModel.fromJson).toList();
    }
    final rows = await sb.from('events').select().order('event_date', ascending: false);
    return rows.map(EventModel.fromJson).toList();
  }

  Future<EventModel> get(String id) async {
    if (AppConfig.demo) return EventModel.fromJson(_demo.events[id]!);
    final row = await sb.from('events').select().eq('id', id).single();
    return EventModel.fromJson(row);
  }

  Future<EventModel> create(EventModel e) async {
    if (AppConfig.demo) return EventModel.fromJson(_demo.addEvent(e.toJson()));
    final row = await sb.from('events').insert(e.toJson()).select().single();
    return EventModel.fromJson(row);
  }

  Future<EventModel> update(String id, EventModel e) async {
    if (AppConfig.demo) {
      _demo.events[id] = {..._demo.events[id]!, ...e.toJson()};
      return EventModel.fromJson(_demo.events[id]!);
    }
    final row = await sb.from('events').update(e.toJson()).eq('id', id).select().single();
    return EventModel.fromJson(row);
  }

  Future<void> saveCardConfig(String id, CardConfig c) async {
    if (AppConfig.demo) {
      _demo.events[id]!['card_config'] = c.toJson();
      return;
    }
    await sb.from('events').update({'card_config': c.toJson()}).eq('id', id);
  }

  Future<void> delete(String id) async {
    if (AppConfig.demo) {
      _demo.events.remove(id);
      _demo.guests.removeWhere((_, g) => g['event_id'] == id);
      return;
    }
    await sb.from('events').delete().eq('id', id);
  }

  Future<EventStats> stats(String id) async {
    if (AppConfig.demo) return EventStats.fromJson(_demo.stats(id));
    final row = await sb.from('event_stats').select().eq('event_id', id).maybeSingle();
    return EventStats.fromJson(row);
  }

  Future<Map<String, EventStats>> allStats() async {
    if (AppConfig.demo) {
      return {for (final id in _demo.events.keys) id: EventStats.fromJson(_demo.stats(id))};
    }
    final rows = await sb.from('event_stats').select();
    return {for (final r in rows) r['event_id'] as String: EventStats.fromJson(r)};
  }
}
