import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/event_types.dart';
import '../../core/swahili_time.dart';
import '../../core/theme.dart';
import '../../data/events_repository.dart';
import '../../data/supabase.dart';
import '../../models/event.dart';
import '../../widgets/async_view.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final _repo = const EventsRepository();
  late Future<(List<EventModel>, Map<String, EventStats>)> _future = _load();

  Future<(List<EventModel>, Map<String, EventStats>)> _load() async {
    final results = await Future.wait([_repo.list(), _repo.allStats()]);
    return (results[0] as List<EventModel>, results[1] as Map<String, EventStats>);
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matukio yangu'),
        actions: [
          IconButton(
            tooltip: 'Toka',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => sb.auth.signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/events/new');
          _reload();
        },
        icon: const Icon(Icons.add),
        label: const Text('Tukio jipya'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: AsyncView(
          future: _future,
          onRetry: _reload,
          builder: (context, data) {
            final (events, stats) = data;
            if (events.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Icon(Icons.celebration_outlined, size: 64, color: MwalikoColors.maroon),
                  SizedBox(height: 12),
                  Text(
                    'Bado huna tukio.\nBonyeza "Tukio jipya" kuanza.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: events.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final e = events[i];
                final s = stats[e.id] ?? const EventStats();
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: MwalikoColors.maroon.withValues(alpha: 0.1),
                      child: const Icon(Icons.event, color: MwalikoColors.maroon),
                    ),
                    title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${eventTypeById(e.eventType).label} · ${swahiliShortDate(e.eventDate)}\n'
                      '${s.guests} waalikwa · ${s.attending} watahudhuria',
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await context.push('/events/${e.id}');
                      _reload();
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
