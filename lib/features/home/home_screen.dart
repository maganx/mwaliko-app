import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/event_types.dart';
import '../../core/swahili_time.dart';
import '../../core/theme.dart';
import '../../data/auth_repository.dart';
import '../../data/billing_repository.dart';
import '../../data/events_repository.dart';
import '../../models/billing.dart';
import '../../models/event.dart';
import '../../widgets/async_view.dart';
import '../../widgets/ui.dart';
import '../events/event_tile.dart';

class _HomeData {
  const _HomeData(this.profile, this.credits, this.pricing, this.events, this.stats);
  final Profile profile;
  final int credits;
  final Pricing pricing;
  final List<EventModel> events;
  final Map<String, EventStats> stats;
}

/// Dashibodi: salio, tukio lijalo na njia za haraka.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<_HomeData> _future = _load();

  Future<_HomeData> _load() async {
    const events = EventsRepository();
    const billing = BillingRepository();
    final r = await Future.wait([
      AuthRepository.instance.profile(),
      billing.balance(),
      billing.pricing(),
      events.list(),
      events.allStats(),
    ]);
    return _HomeData(
      r[0] as Profile,
      r[1] as int,
      r[2] as Pricing,
      r[3] as List<EventModel>,
      r[4] as Map<String, EventStats>,
    );
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _go(String path) async {
    await context.push(path);
    _reload();
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Habari za asubuhi';
    if (h < 16) return 'Habari za mchana';
    return 'Habari za jioni';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AsyncView(
        future: _future,
        onRetry: _reload,
        builder: (context, d) {
          final now = DateTime.now();
          final upcoming = d.events.where((e) => e.eventDate.isAfter(now)).toList()
            ..sort((a, b) => a.eventDate.compareTo(b.eventDate));
          final next = upcoming.firstOrNull;
          final totals = d.stats.values.fold<(int, int)>((0, 0), (t, s) => (t.$1 + s.guests, t.$2 + s.attending));

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    HeroHeader(
                      bottomPadding: 86,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _greeting,
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      d.profile.displayName.split(' ').first,
                                      style: const TextStyle(
                                        fontFamily: 'PlayfairDisplay',
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (d.profile.businessName != null)
                                      Text(
                                        d.profile.businessName!,
                                        style: const TextStyle(color: MwalikoColors.gold, fontWeight: FontWeight.w600),
                                      ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.go('/account'),
                                child: Container(
                                  width: 46,
                                  height: 46,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.12),
                                    border: Border.all(color: MwalikoColors.gold.withValues(alpha: 0.6)),
                                  ),
                                  child: Text(
                                    d.profile.initials,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              _HeroStat(value: '${d.events.length}', label: 'Matukio'),
                              _HeroStat(value: '${totals.$1}', label: 'Waalikwa'),
                              _HeroStat(value: '${totals.$2}', label: 'Watakuja'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: -46,
                      child: BalanceCard(
                        credits: d.credits,
                        pricePerGuest: d.pricing.pricePerGuest,
                        onTopUp: () => context.go('/wallet'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 66),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          _QuickAction(
                            icon: Icons.add_circle_outline,
                            label: 'Tukio jipya',
                            onTap: () => _go('/events/new'),
                          ),
                          const SizedBox(width: 10),
                          _QuickAction(
                            icon: Icons.palette_outlined,
                            label: 'Kadi',
                            onTap: next == null ? () => _go('/events/new') : () => _go('/events/${next.id}/card'),
                          ),
                          const SizedBox(width: 10),
                          _QuickAction(
                            icon: Icons.send_outlined,
                            label: 'Tuma',
                            onTap: next == null ? () => _go('/events/new') : () => _go('/events/${next.id}/send'),
                          ),
                          const SizedBox(width: 10),
                          _QuickAction(
                            icon: Icons.qr_code_scanner,
                            label: 'Check-in',
                            onTap: next == null ? () => _go('/events/new') : () => _go('/events/${next.id}/checkin'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (next != null) ...[
                        const SectionHeader('Tukio lijalo'),
                        _NextEventCard(
                          event: next,
                          stats: d.stats[next.id] ?? const EventStats(),
                          onTap: () => _go('/events/${next.id}'),
                        ),
                        const SizedBox(height: 24),
                      ],
                      SectionHeader(
                        'Matukio yako',
                        action: d.events.isEmpty ? null : 'Yote',
                        onAction: () => context.go('/events'),
                      ),
                      if (d.events.isEmpty)
                        SoftCard(
                          child: EmptyState(
                            icon: Icons.celebration_outlined,
                            title: 'Anza na tukio lako la kwanza',
                            message: 'Unda tukio, chagua kadi nzuri, ongeza waalikwa na uwatumie kwa dakika chache.',
                            action: FilledButton.icon(
                              onPressed: () => _go('/events/new'),
                              icon: const Icon(Icons.add),
                              label: const Text('Tukio jipya'),
                            ),
                          ),
                        )
                      else
                        for (final e in d.events.take(4)) ...[
                          EventTile(
                            event: e,
                            stats: d.stats[e.id] ?? const EventStats(),
                            onTap: () => _go('/events/${e.id}'),
                          ),
                          const SizedBox(height: 12),
                        ],
                      const SizedBox(height: 24),
                    ],
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

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
      ],
    ),
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      child: Column(
        children: [
          IconBadge(icon, size: 40),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}

class _NextEventCard extends StatelessWidget {
  const _NextEventCard({required this.event, required this.stats, required this.onTap});
  final EventModel event;
  final EventStats stats;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final days = event.eventDate.difference(DateTime.now()).inDays;
    return SoftCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(
              height: 150,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(decoration: BoxDecoration(gradient: MwalikoColors.heroGradient)),
                  Positioned(
                    right: 18,
                    top: 14,
                    bottom: -40,
                    child: Transform.rotate(angle: 0.06, child: EventCardThumb(event: event)),
                  ),
                  Positioned(
                    left: 18,
                    top: 18,
                    right: 150,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: MwalikoColors.gold, borderRadius: BorderRadius.circular(20)),
                          child: Text(
                            days <= 0 ? 'Leo!' : 'Siku $days zimebaki',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: MwalikoColors.plumDeep,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          eventTypeById(event.eventType).label,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 15, color: MwalikoColors.muted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${swahiliDate(event.eventDate)} · ${swahiliTime(event.eventDate)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                if (event.venue != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 15, color: MwalikoColors.muted),
                      const SizedBox(width: 6),
                      Expanded(child: Text(event.venue!, style: Theme.of(context).textTheme.bodySmall)),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                RsvpBar(stats: stats),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
