import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/event_types.dart';
import '../../core/swahili_time.dart';
import '../../core/theme.dart';
import '../../data/events_repository.dart';
import '../../models/event.dart';
import '../../models/event_progress.dart';
import '../../widgets/async_view.dart';
import '../../widgets/ui.dart';
import 'event_tile.dart';

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
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: MwalikoColors.danger, minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Futa'),
          ),
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
      body: AsyncView(
        future: _future,
        onRetry: _reload,
        builder: (context, data) {
          final (event, stats) = data;
          final progress = EventProgress(event, stats);
          final t = Theme.of(context).textTheme;
          final days = event.eventDate.difference(DateTime.now()).inDays;
          final past = event.eventDate.isBefore(DateTime.now());

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                HeroHeader(
                  bottomPadding: 26,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _HeroIcon(icon: Icons.arrow_back, tooltip: 'Rudi', onTap: () => context.pop()),
                          const Spacer(),
                          _HeroIcon(icon: Icons.edit_outlined, tooltip: 'Hariri', onTap: () => _open('edit')),
                          const SizedBox(width: 8),
                          _HeroIcon(icon: Icons.delete_outline, tooltip: 'Futa', onTap: () => _delete(event)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  eventTypeById(event.eventType).label.toUpperCase(),
                                  style: const TextStyle(
                                    color: MwalikoColors.heroAccent,
                                    fontSize: 11.5,
                                    letterSpacing: 1.6,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  event.title,
                                  style: const TextStyle(
                                    fontFamily: MwalikoFonts.display,
                                    fontSize: 25,
                                    height: 1.2,
                                    fontWeight: FontWeight.w700,
                                    color: MwalikoColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _HeroLine(Icons.calendar_today_outlined, swahiliDate(event.eventDate)),
                                _HeroLine(Icons.schedule, swahiliTime(event.eventDate)),
                                if (event.venue != null) _HeroLine(Icons.place_outlined, event.venue!),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: past ? MwalikoColors.glass : MwalikoColors.pendingBg,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    past ? 'Limepita' : (days == 0 ? 'Leo!' : 'Siku $days zimebaki'),
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: past ? MwalikoColors.muted : MwalikoColors.accentInk,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          GestureDetector(
                            onTap: () => _open('card'),
                            child: SizedBox(
                              width: 104,
                              child: Transform.rotate(angle: 0.05, child: EventCardThumb(event: event)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SoftCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                _Stat(value: stats.guests, label: 'Waalikwa', color: MwalikoColors.ink),
                                _Stat(value: stats.attending, label: 'Watakuja', color: MwalikoColors.success),
                                _Stat(value: stats.declined, label: 'Hawaji', color: MwalikoColors.danger),
                                _Stat(value: stats.checkedIn, label: 'Wameingia', color: MwalikoColors.primary),
                              ],
                            ),
                            const SizedBox(height: 16),
                            RsvpBar(stats: stats),
                            if (stats.seats > 0) ...[
                              const SizedBox(height: 10),
                              Text('Viti vilivyoalikwa: ${stats.seats}', style: t.bodySmall),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      const SectionHeader('Hatua za mwaliko'),
                      LayoutBuilder(
                        builder: (context, box) => GridView.count(
                          crossAxisCount: box.maxWidth >= 600 ? 4 : 2,
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.25,
                          children: [
                            for (final step in EventStep.values)
                              _ActionCard(
                                step: step,
                                icon: _stepIcons[step]!,
                                subtitle: _stepSubtitle(step, event, stats),
                                state: !progress.isUnlocked(step)
                                    ? _StepState.locked
                                    : progress.current == step
                                    ? _StepState.current
                                    : progress.isDone(step)
                                    ? _StepState.done
                                    : _StepState.open,
                                onTap: () => progress.isUnlocked(step)
                                    ? _open(step.path)
                                    : showSnack(context, progress.lockedMessage(step)),
                              ),
                          ],
                        ),
                      ),
                      if (_hasDetails(event)) ...[
                        const SizedBox(height: 22),
                        const SectionHeader('Maelezo'),
                        SoftCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (event.hostNames != null)
                                _DetailRow(Icons.family_restroom, 'Wenyeji', event.hostNames!),
                              if (event.dressCode != null) _DetailRow(Icons.checkroom, 'Mavazi', event.dressCode!),
                              if (event.contactPhone != null)
                                _DetailRow(Icons.phone_outlined, 'Mawasiliano', event.contactPhone!),
                              if (event.message != null) _DetailRow(Icons.notes, 'Ujumbe', event.message!),
                            ],
                          ),
                        ),
                      ],
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

  bool _hasDetails(EventModel e) =>
      e.hostNames != null || e.dressCode != null || e.contactPhone != null || e.message != null;
}

class _HeroIcon extends StatelessWidget {
  const _HeroIcon({required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: MwalikoColors.glassStrong,
    shape: const CircleBorder(),
    child: IconButton(
      tooltip: tooltip,
      icon: Icon(icon, color: MwalikoColors.ink, size: 20),
      onPressed: onTap,
    ),
  );
}

class _HeroLine extends StatelessWidget {
  const _HeroLine(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: MwalikoColors.heroAccent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(color: MwalikoColors.ink, fontSize: 13)),
        ),
      ],
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.color});
  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          '$value',
          style: TextStyle(fontFamily: MwalikoFonts.display, fontSize: 26, fontWeight: FontWeight.w700, color: color),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

const _stepIcons = {
  EventStep.card: Icons.palette_outlined,
  EventStep.guests: Icons.people_alt_outlined,
  EventStep.send: Icons.send_outlined,
  EventStep.checkin: Icons.qr_code_scanner,
};

String _stepSubtitle(EventStep step, EventModel event, EventStats stats) => switch (step) {
  EventStep.card =>
    !event.cardConfig.chosen
        ? 'Chagua design'
        : event.cardConfig.isCustom
        ? 'Design yako'
        : 'Design imechaguliwa',
  EventStep.guests => stats.guests == 0 ? 'Ongeza wageni' : '${stats.guests} wameongezwa',
  EventStep.send => stats.invited == 0 ? 'SMS, WhatsApp, email' : '${stats.invited} wametumiwa',
  EventStep.checkin => stats.checkedIn == 0 ? 'Skani QR mlangoni' : '${stats.checkedIn} wameingia',
};

enum _StepState { done, current, open, locked }

/// Kadi ya hatua: inayofuata ni ya orange, iliyokamilika ina alama ya tiki, iliyofungwa ina kufuli.
class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.step,
    required this.icon,
    required this.subtitle,
    required this.state,
    required this.onTap,
  });
  final EventStep step;
  final IconData icon;
  final String subtitle;
  final _StepState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final highlight = state == _StepState.current;
    final locked = state == _StepState.locked;
    final fg = highlight ? Colors.white : MwalikoColors.ink;
    final Widget marker = switch (state) {
      _StepState.done => const Icon(Icons.check_circle, color: MwalikoColors.success, size: 24),
      _StepState.locked => Icon(Icons.lock_outline, color: MwalikoColors.muted.withValues(alpha: 0.8), size: 22),
      _ => Text(
        '0${step.number}',
        style: TextStyle(
          fontFamily: MwalikoFonts.display,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: highlight ? Colors.white.withValues(alpha: 0.75) : MwalikoColors.accentInk.withValues(alpha: 0.45),
        ),
      ),
    };
    return Semantics(
      label: locked ? '${step.title}, imefungwa' : null,
      child: Opacity(
        opacity: locked ? 0.55 : 1,
        child: SoftCard(
          onTap: onTap,
          color: highlight ? MwalikoColors.primary : null,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconBadge(
                    icon,
                    color: highlight
                        ? Colors.white
                        : locked
                        ? MwalikoColors.muted
                        : MwalikoColors.primary,
                    size: 40,
                  ),
                  const Spacer(),
                  marker,
                ],
              ),
              const Spacer(),
              Text(
                '${step.number}. ${step.title}',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: fg),
              ),
              const SizedBox(height: 2),
              Text(
                locked ? 'Baada ya hatua ya ${step.number - 1}' : subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: highlight ? Colors.white70 : MwalikoColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconBadge(icon, size: 34),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    ),
  );
}
