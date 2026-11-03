import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/guests_repository.dart';
import '../../data/invitations_repository.dart';
import '../../models/guest.dart';
import '../../widgets/async_view.dart';

enum _Audience {
  all('Wote'),
  notSent('Ambao bado hawajatumiwa'),
  pending('Ambao hawajajibu (RSVP)');

  const _Audience(this.label);
  final String label;
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
  late Future<(List<Guest>, List<Delivery>)> _future = _load();

  final _channels = <Channel>{Channel.whatsapp};
  _Audience _audience = _Audience.notSent;
  bool _sending = false;
  (int, int)? _progress;

  Future<(List<Guest>, List<Delivery>)> _load() async {
    final r = await Future.wait([_guestsRepo.list(widget.eventId), _inv.deliveries(widget.eventId)]);
    return (r[0] as List<Guest>, r[1] as List<Delivery>);
  }

  void _reload() => setState(() => _future = _load());

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

  Future<void> _send(List<Guest> targets) async {
    final withoutCard = targets.where((g) => g.cardPath == null).length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Tuma mialiko?'),
        content: Text(
          'Utatuma kwa waalikwa ${targets.length} kupitia ${_channels.map((c) => c.label).join(', ')}.'
          '${withoutCard > 0 ? '\n\nWaalikwa $withoutCard hawana kadi binafsi bado; tengeneza kwenye Studio ya kadi ili picha itumwe.' : ''}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hapana')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Tuma')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() {
      _sending = true;
      _progress = (0, targets.length);
    });
    try {
      final summary = await _inv.send(
        eventId: widget.eventId,
        guestIds: [for (final g in targets) g.id!],
        channels: _channels,
        onProgress: (d, t) => setState(() => _progress = (d, t)),
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Matokeo'),
          content: SingleChildScrollView(
            child: Text(
              'Zimetumwa: ${summary.sent}\nZimeshindikana: ${summary.failed}\nZimerukwa (hakuna simu/email): ${summary.skipped}'
              '${summary.errors.isEmpty ? '' : '\n\nMakosa:\n${summary.errors.take(5).join('\n')}'}',
            ),
          ),
          actions: [FilledButton(onPressed: () => Navigator.pop(c), child: const Text('Sawa'))],
        ),
      );
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
    return Scaffold(
      appBar: AppBar(title: const Text('Tuma mialiko')),
      body: AsyncView(
        future: _future,
        onRetry: _reload,
        builder: (context, data) {
          final (guests, deliveries) = data;
          final targets = _targets(guests, deliveries);
          final byStatus = <String, int>{};
          for (final d in deliveries) {
            byStatus[d.status] = (byStatus[d.status] ?? 0) + 1;
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Njia za kutuma', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              for (final c in Channel.values)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _channels.contains(c),
                  onChanged: _sending
                      ? null
                      : (v) => setState(() => v == true ? _channels.add(c) : _channels.remove(c)),
                  title: Text(c.label),
                  subtitle: Text(switch (c) {
                    Channel.sms => 'Ujumbe mfupi wenye link ya kadi na RSVP',
                    Channel.whatsapp => 'Picha ya kadi binafsi + link ya RSVP',
                    Channel.email => 'Email yenye kadi na kitufe cha RSVP',
                  }),
                  secondary: Icon(switch (c) {
                    Channel.sms => Icons.sms_outlined,
                    Channel.whatsapp => Icons.chat_outlined,
                    Channel.email => Icons.email_outlined,
                  }, color: MwalikoColors.maroon),
                ),
              const Divider(height: 32),
              Text('Watumiwe nani?', style: Theme.of(context).textTheme.titleMedium),
              RadioGroup<_Audience>(
                groupValue: _audience,
                onChanged: (v) {
                  if (!_sending && v != null) setState(() => _audience = v);
                },
                child: Column(
                  children: [
                    for (final a in _Audience.values)
                      RadioListTile<_Audience>(contentPadding: EdgeInsets.zero, value: a, title: Text(a.label)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_progress != null) ...[
                LinearProgressIndicator(value: _progress!.$2 == 0 ? null : _progress!.$1 / _progress!.$2),
                const SizedBox(height: 6),
                Text('Inatuma… ${_progress!.$1} kati ya ${_progress!.$2}', textAlign: TextAlign.center),
                const SizedBox(height: 12),
              ],
              FilledButton.icon(
                onPressed: _sending || _channels.isEmpty || targets.isEmpty ? null : () => _send(targets),
                icon: const Icon(Icons.send),
                label: Text('Tuma kwa waalikwa ${targets.length}'),
              ),
              const Divider(height: 40),
              Text('Historia ya utumaji', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (deliveries.isEmpty)
                const Text('Bado hujatuma mwaliko wowote.')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final e in byStatus.entries) Chip(label: Text('${_statusLabel(e.key)}: ${e.value}'))],
                ),
              const SizedBox(height: 8),
              for (final d in deliveries.take(30))
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    d.status == 'failed' ? Icons.error_outline : Icons.check_circle_outline,
                    color: d.status == 'failed' ? Colors.red : Colors.green,
                  ),
                  title: Text(guests.where((g) => g.id == d.guestId).firstOrNull?.name ?? '—'),
                  subtitle: Text(
                    '${d.channel.toUpperCase()} · ${_statusLabel(d.status)}${d.error != null ? '\n${d.error}' : ''}',
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static String _statusLabel(String s) => switch (s) {
    'queued' => 'Kwenye foleni',
    'sent' => 'Imetumwa',
    'delivered' => 'Imefika',
    'read' => 'Imesomwa',
    'failed' => 'Imeshindikana',
    _ => s,
  };
}
