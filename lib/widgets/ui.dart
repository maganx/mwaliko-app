import 'dart:math';

import 'package:flutter/material.dart';

import '../core/money.dart';
import '../core/theme.dart';
import '../models/event.dart';

/// Kichwa chenye gradient ya zambarau na mapambo ya dhahabu.
class HeroHeader extends StatelessWidget {
  const HeroHeader({super.key, required this.child, this.bottomPadding = 28, this.radius = 32});

  final Widget child;
  final double bottomPadding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(radius)),
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: MwalikoColors.heroGradient),
        child: CustomPaint(
          painter: _HeroPatternPainter(),
          child: SafeArea(
            bottom: false,
            child: Padding(padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding), child: child),
          ),
        ),
      ),
    );
  }
}

class _HeroPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = MwalikoColors.accent.withValues(alpha: 0.18);
    final c = Offset(size.width + 20, -10);
    for (var r = 60.0; r < 260; r += 34) {
      canvas.drawCircle(c, r, ring);
    }
    final dots = Paint()..color = MwalikoColors.accent.withValues(alpha: 0.22);
    final rng = Random(5);
    for (var i = 0; i < 16; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width * 0.6, rng.nextDouble() * size.height),
        rng.nextDouble() * 1.6 + 0.6,
        dots,
      );
    }
  }

  @override
  bool shouldRepaint(_HeroPatternPainter oldDelegate) => false;
}

/// Kadi nyeupe yenye kivuli laini.
class SoftCard extends StatelessWidget {
  const SoftCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap, this.color});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? MwalikoColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: MwalikoShadows.soft,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 0, 10),
      child: Row(
        children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
          if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    );
  }
}

/// Ikoni ndani ya duara lenye rangi hafifu.
class IconBadge extends StatelessWidget {
  const IconBadge(this.icon, {super.key, this.color = MwalikoColors.primary, this.size = 44});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(size * 0.34)),
    child: Icon(icon, color: color, size: size * 0.5),
  );
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.label, {super.key, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 12, color: color), const SizedBox(width: 4)],
        Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    ),
  );
}

/// Mstari unaoonyesha majibu ya RSVP: watakuja / labda / hawaji / hawajajibu.
class RsvpBar extends StatelessWidget {
  const RsvpBar({super.key, required this.stats, this.showLegend = true, this.onDark = false});

  final EventStats stats;
  final bool showLegend;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final total = max(stats.guests, 1);
    final parts = [
      (stats.attending, MwalikoColors.success, 'Watakuja'),
      (stats.maybe, MwalikoColors.warning, 'Labda'),
      (stats.declined, MwalikoColors.danger, 'Hawaji'),
      (stats.pending, onDark ? Colors.white24 : MwalikoColors.line, 'Hawajajibu'),
    ];
    final labelColor = onDark ? Colors.white70 : MwalikoColors.muted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 8,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final p in parts)
                  if (p.$1 > 0)
                    Expanded(
                      flex: p.$1 * 1000 ~/ total,
                      child: ColoredBox(color: p.$2),
                    ),
                if (stats.guests == 0) Expanded(child: ColoredBox(color: parts.last.$2)),
              ],
            ),
          ),
        ),
        if (showLegend) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              for (final p in parts)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: p.$2, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text('${p.$3} ${p.$1}', style: TextStyle(fontSize: 12, color: labelColor)),
                  ],
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Kadi ya salio (mialiko iliyobaki) yenye mng'ao wa dhahabu.
class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key, required this.credits, required this.pricePerGuest, this.onTopUp});

  final int credits;
  final int pricePerGuest;
  final VoidCallback? onTopUp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: MwalikoColors.accentGradient,
        boxShadow: MwalikoShadows.lifted,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SALIO LAKO',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w700,
                    color: MwalikoColors.primaryDeep,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatNumber(credits),
                      style: const TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: MwalikoColors.primaryDeep,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 3),
                      child: Text(
                        'mialiko',
                        style: TextStyle(fontWeight: FontWeight.w600, color: MwalikoColors.primaryDeep),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Thamani ${formatTzs(credits * pricePerGuest)} · ${formatTzs(pricePerGuest)} kwa mwalikwa',
                  style: TextStyle(fontSize: 11.5, color: MwalikoColors.primaryDeep.withValues(alpha: 0.75)),
                ),
              ],
            ),
          ),
          if (onTopUp != null)
            FilledButton.icon(
              onPressed: onTopUp,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
                backgroundColor: MwalikoColors.primaryDeep,
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ongeza'),
            ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.message, this.action});

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(color: MwalikoColors.accentSoft, borderRadius: BorderRadius.circular(28)),
              child: Icon(icon, size: 40, color: MwalikoColors.primary),
            ),
            const SizedBox(height: 18),
            Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: MwalikoColors.muted),
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

/// Duara lenye herufi za mwanzo za jina (avatar).
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar(this.name, {super.key, this.size = 42});

  final String name;
  final double size;

  static const _tones = [
    Color(0xFF2A44D4),
    Color(0xFF2F5D3A),
    Color(0xFF0B4F6C),
    Color(0xFF8C6D3A),
    Color(0xFF5B3E8A),
    Color(0xFFB23A16),
  ];

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final initials = parts.isEmpty
        ? '?'
        : (parts.length == 1
                  ? parts.first.characters.first
                  : parts.first.characters.first + parts.last.characters.first)
              .toUpperCase();
    final tone = _tones[name.hashCode.abs() % _tones.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: tone.withValues(alpha: 0.12), shape: BoxShape.circle),
      child: Text(
        initials,
        style: TextStyle(fontWeight: FontWeight.w700, color: tone, fontSize: size * 0.36),
      ),
    );
  }
}
