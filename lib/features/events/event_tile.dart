import 'package:flutter/material.dart';

import '../../core/event_types.dart';
import '../../core/swahili_time.dart';
import '../../core/theme.dart';
import '../../data/cards_repository.dart';
import '../../models/event.dart';
import '../../widgets/ui.dart';
import '../cards/invitation_card.dart';

/// Kadi ndogo ya mwaliko wa tukio (kwa orodha na dashibodi).
class EventCardThumb extends StatelessWidget {
  const EventCardThumb({super.key, required this.event, this.radius = 8});

  final EventModel event;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = event.cardConfig;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: InvitationCard(
          event: event,
          config: c,
          customImageProvider: c.isCustom ? const CardsRepository().imageFor(c.customImagePath!) : null,
        ),
      ),
    );
  }
}

/// Mstari wa tukio kwenye orodha: kadi ndogo, jina, tarehe na majibu ya RSVP.
class EventTile extends StatelessWidget {
  const EventTile({super.key, required this.event, required this.stats, this.onTap});

  final EventModel event;
  final EventStats stats;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final now = DateTime.now();
    final past = event.eventDate.isBefore(now);
    final days = event.eventDate.difference(now).inDays;
    final (chipLabel, chipColor) = past
        ? ('Limepita', MwalikoColors.muted)
        : days == 0
        ? ('Leo', MwalikoColors.success)
        : days <= 14
        ? ('Siku $days', MwalikoColors.warning)
        : ('Siku $days', MwalikoColors.plum);

    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 72, child: EventCardThumb(event: event, radius: 6)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        eventTypeById(event.eventType).label.toUpperCase(),
                        style: t.labelSmall?.copyWith(color: MwalikoColors.gold, letterSpacing: 1.2),
                      ),
                    ),
                    StatusChip(chipLabel, color: chipColor),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.titleMedium?.copyWith(height: 1.25),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 13, color: MwalikoColors.muted),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        swahiliShortDate(event.eventDate),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodySmall,
                      ),
                    ),
                    const Icon(Icons.people_outline, size: 14, color: MwalikoColors.muted),
                    const SizedBox(width: 4),
                    Text('${stats.guests}', style: t.bodySmall),
                  ],
                ),
                const SizedBox(height: 10),
                RsvpBar(stats: stats, showLegend: false),
                const SizedBox(height: 6),
                Text(
                  stats.guests == 0
                      ? 'Bado hujaongeza waalikwa'
                      : '${stats.attending} watakuja · ${stats.pending} hawajajibu',
                  style: t.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
