import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/event_types.dart';
import '../../core/swahili_time.dart';
import '../../core/theme.dart';
import '../../data/events_repository.dart';
import '../../models/card_config.dart';
import '../../models/event.dart';
import '../../widgets/async_view.dart';
import '../../widgets/ui.dart';

/// Kuunda au kuhariri tukio.
class EventFormScreen extends StatefulWidget {
  const EventFormScreen({super.key, this.eventId});
  final String? eventId;

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _repo = const EventsRepository();
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _hosts = TextEditingController();
  final _venue = TextEditingController();
  final _map = TextEditingController();
  final _dress = TextEditingController();
  final _contact = TextEditingController();
  final _message = TextEditingController();
  String _type = 'harusi';
  DateTime _date = DateTime.now().add(const Duration(days: 30)).copyWith(hour: 16, minute: 0);
  CardConfig _card = const CardConfig();
  bool _loading = false;
  bool _saving = false;

  bool get _isEdit => widget.eventId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final e = await _repo.get(widget.eventId!);
      _title.text = e.title;
      _hosts.text = e.hostNames ?? '';
      _venue.text = e.venue ?? '';
      _map.text = e.venueMapUrl ?? '';
      _dress.text = e.dressCode ?? '';
      _contact.text = e.contactPhone ?? '';
      _message.text = e.message ?? '';
      _type = e.eventType;
      _date = e.eventDate;
      _card = e.cardConfig;
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    for (final c in [_title, _hosts, _venue, _map, _dress, _contact, _message]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_date));
    setState(() => _date = DateTime(d.year, d.month, d.day, t?.hour ?? _date.hour, t?.minute ?? _date.minute));
  }

  String? _nullIfEmpty(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final event = EventModel(
      title: _title.text.trim(),
      eventType: _type,
      hostNames: _nullIfEmpty(_hosts),
      eventDate: _date,
      venue: _nullIfEmpty(_venue),
      venueMapUrl: _nullIfEmpty(_map),
      dressCode: _nullIfEmpty(_dress),
      contactPhone: _nullIfEmpty(_contact),
      message: _nullIfEmpty(_message),
      cardConfig: _card,
    );
    try {
      if (_isEdit) {
        await _repo.update(widget.eventId!, event);
        if (mounted) context.pop();
      } else {
        final created = await _repo.create(event);
        if (!mounted) return;
        // pop kwanza ili skrini iliyofungua fomu (Nyumbani/Matukio) ijisasishe, kisha fungua tukio jipya.
        final router = GoRouter.of(context);
        router.pop();
        router.push('/events/${created.id}');
      }
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Hariri tukio' : 'Tukio jipya')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                children: [
                  const SectionHeader('Aina ya tukio'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final e in eventTypes)
                        ChoiceChip(
                          showCheckmark: false,
                          label: Text(e.label),
                          selected: _type == e.id,
                          onSelected: (_) => setState(() => _type = e.id),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader('Maelezo makuu'),
                  TextFormField(
                    controller: _title,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Jina la tukio',
                      hintText: 'mf. Harusi ya Amani & Neema',
                      prefixIcon: Icon(Icons.celebration_outlined),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Weka jina la tukio' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _hosts,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Wenyeji',
                      hintText: 'mf. Familia ya Bw. na Bi. Juma',
                      prefixIcon: Icon(Icons.family_restroom),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SoftCard(
                    onTap: _pickDate,
                    child: Row(
                      children: [
                        const IconBadge(Icons.calendar_month, size: 42),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(swahiliDate(_date), style: t.titleSmall),
                              Text(swahiliTime(_date), style: t.bodySmall),
                            ],
                          ),
                        ),
                        const Icon(Icons.edit_calendar, color: MwalikoColors.primary),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader('Mahali'),
                  TextFormField(
                    controller: _venue,
                    decoration: const InputDecoration(
                      labelText: 'Ukumbi / mahali',
                      hintText: 'mf. Mlimani City Hall',
                      prefixIcon: Icon(Icons.place_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _map,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Link ya Google Maps (si lazima)',
                      prefixIcon: Icon(Icons.map_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader('Ziada (si lazima)'),
                  TextFormField(
                    controller: _dress,
                    decoration: const InputDecoration(labelText: 'Mavazi', prefixIcon: Icon(Icons.checkroom)),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _contact,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Simu ya mawasiliano',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _message,
                    maxLines: 3,
                    maxLength: 240,
                    decoration: const InputDecoration(
                      labelText: 'Ujumbe wa ziada kwenye kadi',
                      prefixIcon: Icon(Icons.notes),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Inahifadhi…' : (_isEdit ? 'Hifadhi mabadiliko' : 'Unda tukio')),
                  ),
                ],
              ),
            ),
    );
  }
}
