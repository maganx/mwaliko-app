import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/event_types.dart';
import '../../core/swahili_time.dart';
import '../../data/events_repository.dart';
import '../../models/card_config.dart';
import '../../models/event.dart';
import '../../widgets/async_view.dart';

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
        if (mounted) context.pushReplacement('/events/${created.id}');
      }
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Hariri tukio' : 'Tukio jipya')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _type,
                    decoration: const InputDecoration(labelText: 'Aina ya tukio'),
                    items: [for (final t in eventTypes) DropdownMenuItem(value: t.id, child: Text(t.label))],
                    onChanged: (v) => setState(() => _type = v ?? _type),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _title,
                    decoration: const InputDecoration(
                      labelText: 'Jina la tukio',
                      hintText: 'mf. Harusi ya Amani & Neema',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Weka jina la tukio' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _hosts,
                    decoration: const InputDecoration(labelText: 'Wenyeji', hintText: 'mf. Familia ya Bw. na Bi. Juma'),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Colors.brown.shade100),
                    ),
                    tileColor: Colors.white,
                    leading: const Icon(Icons.calendar_month),
                    title: Text(swahiliDate(_date)),
                    subtitle: Text(swahiliTime(_date)),
                    trailing: const Icon(Icons.edit_calendar),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _venue,
                    decoration: const InputDecoration(labelText: 'Ukumbi / mahali', hintText: 'mf. Mlimani City Hall'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _map,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(labelText: 'Link ya Google Maps (si lazima)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _dress,
                    decoration: const InputDecoration(labelText: 'Mavazi (si lazima)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _contact,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Simu ya mawasiliano (si lazima)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _message,
                    maxLines: 3,
                    maxLength: 240,
                    decoration: const InputDecoration(labelText: 'Ujumbe wa ziada kwenye kadi (si lazima)'),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Inahifadhi…' : 'Hifadhi')),
                ],
              ),
            ),
    );
  }
}
