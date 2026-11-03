import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/events_repository.dart';
import '../../models/event.dart';
import '../../widgets/async_view.dart';
import '../../widgets/ui.dart';
import 'event_tile.dart';

enum _Filter { upcoming, past, all }

/// Orodha ya matukio yote ya mteja.
class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final _repo = const EventsRepository();
  late Future<(List<EventModel>, Map<String, EventStats>)> _future = _load();
  _Filter _filter = _Filter.upcoming;
  String _query = '';

  Future<(List<EventModel>, Map<String, EventStats>)> _load() async {
    final results = await Future.wait([_repo.list(), _repo.allStats()]);
    return (results[0] as List<EventModel>, results[1] as Map<String, EventStats>);
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _open(String path) async {
    await context.push(path);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'new-event',
        onPressed: () => _open('/events/new'),
        icon: const Icon(Icons.add),
        label: const Text('Tukio jipya'),
      ),
      body: AsyncView(
        future: _future,
        onRetry: _reload,
        builder: (context, data) {
          final (events, stats) = data;
          final now = DateTime.now();
          final q = _query.toLowerCase();
          final shown = events.where((e) {
            final matches = q.isEmpty || e.title.toLowerCase().contains(q) || (e.venue ?? '').toLowerCase().contains(q);
            final ok = switch (_filter) {
              _Filter.upcoming => !e.eventDate.isBefore(now),
              _Filter.past => e.eventDate.isBefore(now),
              _Filter.all => true,
            };
            return matches && ok;
          }).toList();
          final upcomingCount = events.where((e) => !e.eventDate.isBefore(now)).length;

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: HeroHeader(
                    bottomPadding: 22,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        const Text(
                          'Matukio yako',
                          style: TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${events.length} jumla · $upcomingCount yanakuja',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          onChanged: (v) => setState(() => _query = v),
                          style: const TextStyle(color: Colors.white),
                          cursorColor: MwalikoColors.gold,
                          decoration: InputDecoration(
                            hintText: 'Tafuta tukio au ukumbi',
                            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                            prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.7)),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.12),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: MwalikoColors.gold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        for (final (f, label) in const [
                          (_Filter.upcoming, 'Yanayokuja'),
                          (_Filter.past, 'Yaliyopita'),
                          (_Filter.all, 'Yote'),
                        ])
                          ChoiceChip(
                            label: Text(label),
                            selected: _filter == f,
                            showCheckmark: false,
                            onSelected: (_) => setState(() => _filter = f),
                          ),
                      ],
                    ),
                  ),
                ),
                if (shown.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.celebration_outlined,
                      title: events.isEmpty ? 'Bado huna tukio' : 'Hakuna tukio hapa',
                      message: events.isEmpty
                          ? 'Unda tukio lako la kwanza, chagua kadi na uanze kuwaalika wageni.'
                          : 'Badilisha kichujio au utafutaji.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    sliver: SliverList.separated(
                      itemCount: shown.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final e = shown[i];
                        return EventTile(
                          event: e,
                          stats: stats[e.id] ?? const EventStats(),
                          onTap: () => _open('/events/${e.id}'),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
