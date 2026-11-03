import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/event_types.dart';
import '../../core/swahili_time.dart';
import '../../core/theme.dart';
import '../../data/cards_repository.dart';
import '../../data/events_repository.dart';
import '../../models/event.dart';
import '../../widgets/async_view.dart';
import '../cards/invitation_card.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key, required this.eventId});
  final String eventId;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _repo = const EventsRepository();
  late Future<(EventModel, EventStats)> _future = _load();

  Future<(EventModel, EventStats)> _load() async {
    final r = await Future.wait([_repo.get(widget.eventId), _repo.stats(widget.eventId)]);
    return (r[0] as EventModel, r[1] as EventStats);
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _open(String sub) async {
    await context.push('/events/${widget.eventId}/$sub');
    _reload();
  }

  Future<void> _delete(EventModel e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Futa tukio?'),
        content: Text('"${e.title}" na waalikwa wake wote watafutwa. Huwezi kurudisha.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hapana')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Futa')),
        ],
      ),
    );
    if (ok != true) return;
    await _repo.delete(e.id!);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tukio'),
        actions: [
          IconButton(tooltip: 'Hariri', icon: const Icon(Icons.edit_outlined), onPressed: () => _open('edit')),
          FutureBuilder(
            future: _future,
            builder: (_, s) => IconButton(
              tooltip: 'Futa',
              icon: const Icon(Icons.delete_outline),
              onPressed: s.hasData ? () => _delete(s.data!.$1) : null,
            ),
          ),
        ],
      ),
      body: AsyncView(
        future: _future,
        onRetry: _reload,
        builder: (context, data) {
          final (event, stats) = data;
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontFamily: 'PlayfairDisplay', fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${eventTypeById(event.eventType).label} · ${swahiliDate(event.eventDate)} · ${swahiliTime(event.eventDate)}',
                ),
                if (event.venue != null) Text(event.venue!),
                const SizedBox(height: 16),
                _StatsRow(stats: stats),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: InvitationCard(
                          event: event,
                          config: event.cardConfig,
                          customImageProvider: event.cardConfig.isCustom
                              ? const CardsRepository().imageFor(event.cardConfig.customImagePath!)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.cardConfig.isCustom ? 'Design yako mwenyewe' : 'Template ya Mwaliko',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          const Text('Badilisha design, tengeneza mpya au pakia kadi yako.'),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () => _open('card'),
                            icon: const Icon(Icons.palette_outlined),
                            label: const Text('Studio ya kadi'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ActionTile(
                  icon: Icons.people_alt_outlined,
                  title: 'Waalikwa',
                  subtitle: 'Ongeza kutoka contacts, Excel au mmoja mmoja',
                  onTap: () => _open('guests'),
                ),
                _ActionTile(
                  icon: Icons.send_outlined,
                  title: 'Tuma mialiko',
                  subtitle: 'SMS, WhatsApp na email',
                  onTap: () => _open('send'),
                ),
                _ActionTile(
                  icon: Icons.qr_code_scanner,
                  title: 'Check-in mlangoni',
                  subtitle: 'Skani QR ya kadi ya mwalikwa',
                  onTap: () => _open('checkin'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});
  final EventStats stats;

  @override
  Widget build(BuildContext context) {
    Widget cell(String label, int value, Color color) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color),
            ),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
    return Row(
      children: [
        cell('Waalikwa', stats.guests, MwalikoColors.ink),
        cell('Watakuja', stats.attending, Colors.green.shade700),
        cell('Hawaji', stats.declined, Colors.red.shade700),
        cell('Wameingia', stats.checkedIn, MwalikoColors.maroon),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      leading: Icon(icon, color: MwalikoColors.maroon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}
