import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config.dart';
import '../../core/money.dart';
import '../../core/theme.dart';
import '../../data/billing_repository.dart';
import '../../data/events_repository.dart';
import '../../data/guests_repository.dart';
import '../../data/invitations_repository.dart';
import '../../models/billing.dart';
import '../../models/event.dart';
import '../../models/guest.dart';
import '../../widgets/async_view.dart';
import '../../widgets/ui.dart';
import '../cards/card_exporter.dart';
import 'message_preview.dart';

enum _Audience {
  notSent('Bado hawajatumiwa', Icons.mark_email_unread_outlined),
  pending('Hawajajibu RSVP', Icons.hourglass_empty),
  all('Waalikwa wote', Icons.groups_outlined);

  const _Audience(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _SendData {
  const _SendData(this.event, this.guests, this.deliveries, this.credits, this.pricing);
  final EventModel event;
  final List<Guest> guests;
  final List<Delivery> deliveries;
  final int credits;
  final Pricing pricing;
}

class SendScreen extends StatefulWidget {
  const SendScreen({super.key, required this.eventId});
  final String eventId;

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final _guestsRepo = const GuestsRepository();
  final _inv = const InvitationsRepository();
  final _billing = const BillingRepository();
  late Future<_SendData> _future = _load();

  final _channels = <Channel>{Channel.whatsapp};
  _Audience _audience = _Audience.notSent;
  bool _sending = false;
  (int, int)? _progress;
  String _progressLabel = 'Inatuma';

  Future<_SendData> _load() async {
    final r = await Future.wait([
      const EventsRepository().get(widget.eventId),
      _guestsRepo.list(widget.eventId),
      _inv.deliveries(widget.eventId),
      _billing.balance(),
      _billing.pricing(),
    ]);
    return _SendData(r[0] as EventModel, r[1] as List<Guest>, r[2] as List<Delivery>, r[3] as int, r[4] as Pricing);
  }

  void _reload() => setState(() => _future = _load());

  bool _reachable(Guest g) => _channels.any((c) => c == Channel.email ? g.email != null : g.phone != null);

  List<Guest> _targets(List<Guest> guests, List<Delivery> deliveries) {
    final sentIds = {
      for (final d in deliveries)
        if (d.status != 'failed' && _channels.any((c) => c.id == d.channel)) d.guestId,
    };
    return switch (_audience) {
      _Audience.all => guests,
      _Audience.notSent => guests.where((g) => !sentIds.contains(g.id)).toList(),
      _Audience.pending => guests.where((g) => g.rsvpStatus == RsvpStatus.pending).toList(),
    };
  }

  Future<void> _needCredits(int needed, int balance, Pricing pricing) async {
    if (!AppConfig.canBuyCredits) {
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          icon: const IconBadge(Icons.account_balance_wallet_outlined, color: MwalikoColors.warning, size: 52),
          title: const Text('Salio halitoshi'),
          content: Text('Unahitaji mialiko $needed lakini una $balance. Chagua waalikwa wachache zaidi.'),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Sawa'))],
        ),
      );
      return;
    }
    final missing = needed - balance;
    final buy = missing < pricing.minPurchase ? pricing.minPurchase : missing;
    final go = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        icon: const IconBadge(Icons.account_balance_wallet_outlined, color: MwalikoColors.warning, size: 52),
        title: const Text('Salio halitoshi'),
        content: Text(
          'Unahitaji mialiko $needed lakini una $balance. '
          'Ongeza angalau mialiko $buy (${formatTzs(pricing.priceFor(buy))}) ili kuendelea.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Baadaye')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Ongeza salio'),
          ),
        ],
      ),
    );
    if (go == true && mounted) {
      await context.push('/topup?need=$buy');
      _reload();
    }
  }

  Future<void> _send(_SendData d, List<Guest> targets, int cost) async {
    if (cost > d.credits) return _needCredits(cost, d.credits, d.pricing);

    // Kadi binafsi ambazo bado hazijatengenezwa zinatengenezwa hapa kabla ya kutuma, ili mteja asisahau.
    final withoutCard = targets.where((g) => g.cardPath == null).toList();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Tuma mialiko?'),
        content: Text(
          'Waalikwa ${targets.length} kupitia ${_channels.map((c) => c.label).join(', ')}.\n'
          'Salio litakatwa mialiko $cost (${formatTzs(d.pricing.priceFor(cost))}).'
          '${withoutCard.isNotEmpty ? '\n\nKadi binafsi ${withoutCard.length} zitatengenezwa kwanza (jina na QR ya kila mwalikwa).' : ''}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hapana')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Tuma sasa'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() {
      _sending = true;
      _progressLabel = 'Inatengeneza kadi';
      _progress = (0, withoutCard.length);
    });
    try {
      if (withoutCard.isNotEmpty) {
        await CardExporter().exportAll(
          event: d.event,
          guests: withoutCard,
          onProgress: (done, total) => setState(() => _progress = (done, total)),
        );
      }
      setState(() {
        _progressLabel = 'Inatuma';
        _progress = (0, targets.length);
      });
      final summary = await _inv.send(
        eventId: widget.eventId,
        guestIds: [for (final g in targets) g.id!],
        channels: _channels,
        onProgress: (done, total) => setState(() => _progress = (done, total)),
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          icon: const IconBadge(Icons.check_circle_outline, color: MwalikoColors.success, size: 52),
          title: const Text('Mialiko imetumwa'),
          content: SingleChildScrollView(
            child: Text(
              'Zimetumwa: ${summary.sent}\n'
              'Zimeshindikana: ${summary.failed}\n'
              'Zimerukwa (hakuna simu/email): ${summary.skipped}\n'
              'Salio lililokatwa: mialiko ${summary.charged}'
              '${summary.errors.isEmpty ? '' : '\n\nMakosa:\n${summary.errors.take(5).join('\n')}'}',
            ),
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: () => Navigator.pop(c),
              child: const Text('Sawa'),
            ),
          ],
        ),
      );
    } on InsufficientCreditsException catch (e) {
      if (mounted) await _needCredits(e.needed, e.balance, d.pricing);
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
          _progress = null;
        });
        _reload();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Tuma mialiko')),
      body: AsyncView(
        future: _future,
        onRetry: _reload,
        builder: (context, d) {
          final targets = _targets(d.guests, d.deliveries);
          final cost = targets.where((g) => g.chargedAt == null && _reachable(g)).length;
          final free = targets.length - cost;
          final enough = cost <= d.credits;
          final byStatus = <String, int>{};
          for (final x in d.deliveries) {
            byStatus[x.status] = (byStatus[x.status] ?? 0) + 1;
          }
          final names = {for (final g in d.guests) g.id: g.name};

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              const SectionHeader('Njia za kutuma'),
              Row(
                children: [
                  for (final c in Channel.values) ...[
                    Expanded(
                      child: _ChannelCard(
                        channel: c,
                        selected: _channels.contains(c),
                        onTap: _sending
                            ? null
                            : () => setState(() => _channels.contains(c) ? _channels.remove(c) : _channels.add(c)),
                      ),
                    ),
                    if (c != Channel.values.last) const SizedBox(width: 10),
                  ],
                ],
              ),
              const SizedBox(height: 22),
              const SectionHeader('Watumiwe nani?'),
              SoftCard(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    for (final a in _Audience.values)
                      ListTile(
                        onTap: _sending ? null : () => setState(() => _audience = a),
                        leading: IconBadge(a.icon, size: 38),
                        title: Text(a.label, style: t.titleSmall),
                        subtitle: Text('Waalikwa ${_countFor(a, d)}', style: t.bodySmall),
                        trailing: Icon(
                          _audience == a ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: _audience == a ? MwalikoColors.primary : MwalikoColors.muted,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const SectionHeader('Mwalikwa ataona hivi'),
              MessagePreview(event: d.event, guests: targets.isNotEmpty ? targets : d.guests, channels: _channels),
              const SizedBox(height: 22),
              _CostCard(
                targets: targets.length,
                cost: cost,
                free: free,
                credits: d.credits,
                pricing: d.pricing,
                onTopUp: () async {
                  await context.push('/topup');
                  _reload();
                },
              ),
              const SizedBox(height: 16),
              if (_progress != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: _progress!.$2 == 0 ? null : _progress!.$1 / _progress!.$2,
                    backgroundColor: MwalikoColors.line,
                  ),
                ),
                const SizedBox(height: 8),
                Text('$_progressLabel… ${_progress!.$1} kati ya ${_progress!.$2}', textAlign: TextAlign.center),
                const SizedBox(height: 12),
              ],
              FilledButton.icon(
                onPressed: _sending || _channels.isEmpty || targets.isEmpty ? null : () => _send(d, targets, cost),
                icon: Icon(enough ? Icons.send_rounded : Icons.add_card),
                label: Text(
                  targets.isEmpty
                      ? 'Hakuna wa kutumiwa'
                      : enough
                      ? 'Tuma kwa waalikwa ${targets.length}'
                      : AppConfig.canBuyCredits
                      ? 'Ongeza salio ili kutuma'
                      : 'Salio halitoshi',
                ),
              ),
              const SizedBox(height: 28),
              const SectionHeader('Historia ya utumaji'),
              if (d.deliveries.isEmpty)
                SoftCard(child: Text('Bado hujatuma mwaliko wowote.', style: t.bodyMedium))
              else ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final e in byStatus.entries)
                      StatusChip('${_statusLabel(e.key)} ${e.value}', color: _statusColor(e.key)),
                  ],
                ),
                const SizedBox(height: 12),
                SoftCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      for (final x in d.deliveries.take(30))
                        ListTile(
                          dense: true,
                          leading: InitialsAvatar(names[x.guestId] ?? '?', size: 36),
                          title: Text(names[x.guestId] ?? '—', style: t.titleSmall),
                          subtitle: Text(
                            '${x.channel.toUpperCase()}${x.error != null ? ' · ${x.error}' : ''}',
                            style: t.bodySmall,
                          ),
                          trailing: StatusChip(_statusLabel(x.status), color: _statusColor(x.status)),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  int _countFor(_Audience a, _SendData d) {
    final saved = _audience;
    _audience = a;
    final n = _targets(d.guests, d.deliveries).length;
    _audience = saved;
    return n;
  }

  static String _statusLabel(String s) => switch (s) {
    'queued' => 'Foleni',
    'sent' => 'Imetumwa',
    'delivered' => 'Imefika',
    'read' => 'Imesomwa',
    'failed' => 'Imeshindikana',
    _ => s,
  };

  static Color _statusColor(String s) => switch (s) {
    'failed' => MwalikoColors.danger,
    'read' => MwalikoColors.success,
    'delivered' => MwalikoColors.success,
    'queued' => MwalikoColors.warning,
    _ => MwalikoColors.primary,
  };
}

class _ChannelCard extends StatelessWidget {
  const _ChannelCard({required this.channel, required this.selected, this.onTap});
  final Channel channel;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, hint) = switch (channel) {
      Channel.sms => (Icons.sms_outlined, 'Link ya kadi'),
      Channel.whatsapp => (Icons.chat_outlined, 'Picha ya kadi'),
      Channel.email => (Icons.mail_outline, 'Kadi + RSVP'),
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selected ? MwalikoColors.primary : MwalikoColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: selected ? MwalikoColors.primary : MwalikoColors.line, width: 1.4),
        boxShadow: selected ? MwalikoShadows.soft : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Column(
              children: [
                Icon(icon, color: selected ? Colors.white : MwalikoColors.primary),
                const SizedBox(height: 6),
                Text(
                  channel.label,
                  style: TextStyle(fontWeight: FontWeight.w700, color: selected ? Colors.white : MwalikoColors.ink),
                ),
                Text(
                  hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: selected ? Colors.white70 : MwalikoColors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Muhtasari wa gharama: wangapi watatozwa, salio lililopo na litakalobaki.
class _CostCard extends StatelessWidget {
  const _CostCard({
    required this.targets,
    required this.cost,
    required this.free,
    required this.credits,
    required this.pricing,
    required this.onTopUp,
  });
  final int targets, cost, free, credits;
  final Pricing pricing;
  final VoidCallback onTopUp;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final enough = cost <= credits;
    Widget row(String label, String value, {bool bold = false, Color? color}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: t.bodyMedium?.copyWith(color: MwalikoColors.muted)),
          ),
          Text(
            value,
            style: t.bodyMedium?.copyWith(fontWeight: bold ? FontWeight.w700 : FontWeight.w600, color: color),
          ),
        ],
      ),
    );
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const IconBadge(Icons.receipt_long_outlined, size: 38),
              const SizedBox(width: 12),
              Expanded(child: Text('Gharama ya utumaji', style: t.titleMedium)),
              if (AppConfig.canBuyCredits)
                Text(
                  '${formatTzs(pricing.pricePerGuest)}/mtu',
                  style: t.bodySmall?.copyWith(color: MwalikoColors.primary, fontWeight: FontWeight.w600),
                ),
            ],
          ),
          const SizedBox(height: 12),
          row('Waalikwa waliochaguliwa', '$targets'),
          if (free > 0) row('Walishatozwa au hawafikiki (bure)', '$free'),
          row('Watakaotozwa', '$cost'),
          const Divider(height: 20),
          if (AppConfig.canBuyCredits) row('Jumla', formatTzs(pricing.priceFor(cost)), bold: true),
          row('Salio lako', 'mialiko $credits'),
          row(
            enough ? 'Salio litakalobaki' : 'Unakosa',
            enough ? 'mialiko ${credits - cost}' : 'mialiko ${cost - credits}',
            color: enough ? MwalikoColors.success : MwalikoColors.danger,
            bold: true,
          ),
          if (!enough && AppConfig.canBuyCredits) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(onPressed: onTopUp, icon: const Icon(Icons.add), label: const Text('Ongeza salio')),
          ],
          const SizedBox(height: 6),
          Text(
            'Unatozwa mara moja tu kwa kila mwalikwa, hata ukimtumia kwa njia zote tatu au ukimtumia tena.',
            style: t.bodySmall,
          ),
        ],
      ),
    );
  }
}
