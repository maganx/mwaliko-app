import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

import '../../core/config.dart';
import '../../core/phone.dart';
import '../../core/theme.dart';
import '../../data/cards_repository.dart';
import '../../data/guests_repository.dart';
import '../../models/guest.dart';
import '../../widgets/async_view.dart';
import 'contacts_picker_screen.dart';
import 'guest_import.dart';

class GuestsScreen extends StatefulWidget {
  const GuestsScreen({super.key, required this.eventId});
  final String eventId;

  @override
  State<GuestsScreen> createState() => _GuestsScreenState();
}

class _GuestsScreenState extends State<GuestsScreen> {
  final _repo = const GuestsRepository();
  late Future<List<Guest>> _future = _repo.list(widget.eventId);
  String _query = '';

  void _reload() => setState(() => _future = _repo.list(widget.eventId));

  Future<void> _addMany(List<GuestDraft> drafts, {int skipped = 0}) async {
    if (drafts.isEmpty) {
      showSnack(context, 'Hakuna waalikwa wapya waliopatikana');
      return;
    }
    try {
      final n = await _repo.addMany(widget.eventId, drafts);
      if (!mounted) return;
      showSnack(context, 'Umeongeza waalikwa $n${skipped > 0 ? ' ($skipped wameachwa: hawana simu/email)' : ''}');
      _reload();
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
    }
  }

  Future<void> _fromContacts() async {
    final picked = await Navigator.push<List<GuestDraft>>(
      context,
      MaterialPageRoute(builder: (_) => const ContactsPickerScreen()),
    );
    if (picked != null) await _addMany(picked);
  }

  Future<void> _fromFile() async {
    final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['xlsx', 'csv']);
    if (file == null) return;
    try {
      final bytes = await file.xFile.readAsBytes();
      final result = parseGuestFile(bytes, file.name);
      await _addMany(result.guests, skipped: result.skippedRows);
    } catch (e) {
      if (mounted) showSnack(context, 'Faili halikusomeka: ${friendlyError(e)}');
    }
  }

  Future<void> _addOrEdit([Guest? existing]) async {
    final draft = await showModalBottomSheet<GuestDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _GuestForm(existing: existing),
    );
    if (draft == null) return;
    try {
      if (existing == null) {
        await _repo.add(draft.toGuest(widget.eventId));
      } else {
        await _repo.update(existing.id!, {
          'name': draft.name,
          'phone': draft.phone,
          'email': draft.email,
          'seats': draft.seats,
          'category': draft.category,
        });
      }
      _reload();
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
    }
  }

  Future<void> _delete(Guest g) async {
    await _repo.delete(g.id!);
    _reload();
  }

  /// Kushiriki kadi binafsi kupitia app yoyote (WhatsApp ya kawaida, Telegram n.k.) bila gharama ya API.
  Future<void> _share(Guest g) async {
    if (g.cardPath == null) {
      showSnack(context, 'Tengeneza kadi kwanza kwenye Studio ya kadi');
      return;
    }
    try {
      final url = const CardsRepository().publicUrl(g.cardPath!);
      final res = await http.get(Uri.parse(url));
      final rsvp = AppConfig.rsvpBaseUrl.isEmpty ? '' : '\nThibitisha kuhudhuria: ${AppConfig.rsvpBaseUrl}?t=${g.rsvpToken}';
      await SharePlus.instance.share(ShareParams(
        files: [XFile.fromData(res.bodyBytes, mimeType: 'image/png', name: 'mwaliko-${g.name}.png')],
        text: 'Habari ${g.name}, karibu sana kwenye sherehe yetu.$rsvp',
      ));
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Waalikwa'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Ongeza waalikwa',
            onSelected: (v) => switch (v) {
              'one' => _addOrEdit(),
              'contacts' => _fromContacts(),
              _ => _fromFile(),
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'one', child: ListTile(leading: Icon(Icons.person_add), title: Text('Mmoja mmoja'))),
              PopupMenuItem(value: 'contacts', child: ListTile(leading: Icon(Icons.contacts), title: Text('Kutoka contacts'))),
              PopupMenuItem(value: 'file', child: ListTile(leading: Icon(Icons.table_chart), title: Text('Kutoka Excel / CSV'))),
            ],
          ),
        ],
      ),
      body: AsyncView(
        future: _future,
        onRetry: _reload,
        builder: (context, guests) {
          if (guests.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Bado hakuna waalikwa.\nBonyeza kitufe cha juu kulia kuongeza kutoka contacts, Excel au mmoja mmoja.\n\n'
                  'Excel iwe na safu: Jina, Simu, Email, Idadi',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final filtered = guests
              .where((g) => _query.isEmpty || g.name.toLowerCase().contains(_query) || (g.phone ?? '').contains(_query))
              .toList();
          final seats = guests.fold<int>(0, (s, g) => s + g.seats);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Tafuta (${guests.length} waalikwa, viti $seats)',
                  ),
                  onChanged: (v) => setState(() => _query = v.toLowerCase().trim()),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final g = filtered[i];
                      return Dismissible(
                        key: ValueKey(g.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red.shade400,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (_) async =>
                            await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: Text('Futa ${g.name}?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hapana')),
                                  FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Futa')),
                                ],
                              ),
                            ) ??
                            false,
                        onDismissed: (_) => _delete(g),
                        child: ListTile(
                          onTap: () => _addOrEdit(g),
                          leading: CircleAvatar(
                            backgroundColor: MwalikoColors.maroon.withValues(alpha: 0.1),
                            child: Text(g.name.characters.first.toUpperCase(), style: const TextStyle(color: MwalikoColors.maroon)),
                          ),
                          title: Text(g.name),
                          subtitle: Text([
                            if (g.phone != null) formatPhone(g.phone),
                            if (g.email != null) g.email!,
                            if (g.seats > 1) 'watu ${g.seats}',
                          ].join(' · ')),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _RsvpChip(status: g.rsvpStatus, checkedIn: g.checkedInAt != null),
                              IconButton(
                                tooltip: 'Shiriki kadi',
                                icon: Icon(Icons.share, color: g.cardPath == null ? Colors.grey : MwalikoColors.maroon),
                                onPressed: () => _share(g),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RsvpChip extends StatelessWidget {
  const _RsvpChip({required this.status, required this.checkedIn});
  final RsvpStatus status;
  final bool checkedIn;

  @override
  Widget build(BuildContext context) {
    final (label, color) = checkedIn
        ? ('Ameingia', MwalikoColors.maroon)
        : switch (status) {
            RsvpStatus.attending => (status.label, Colors.green.shade700),
            RsvpStatus.declined => (status.label, Colors.red.shade700),
            RsvpStatus.maybe => (status.label, Colors.orange.shade800),
            RsvpStatus.pending => (status.label, Colors.grey.shade600),
          };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _GuestForm extends StatefulWidget {
  const _GuestForm({this.existing});
  final Guest? existing;

  @override
  State<_GuestForm> createState() => _GuestFormState();
}

class _GuestFormState extends State<_GuestForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _phone = TextEditingController(text: formatPhone(widget.existing?.phone));
  late final _email = TextEditingController(text: widget.existing?.email);
  late final _category = TextEditingController(text: widget.existing?.category);
  late int _seats = widget.existing?.seats ?? 1;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _category.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(
      context,
      GuestDraft(
        name: _name.text.trim(),
        phone: normalizePhone(_phone.text),
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        seats: _seats,
        category: _category.text.trim().isEmpty ? null : _category.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.existing == null ? 'Mwalikwa mpya' : 'Hariri mwalikwa', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Jina kamili'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Weka jina' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Simu', hintText: '0712 345 678'),
              validator: (v) {
                final hasPhone = v != null && v.trim().isNotEmpty;
                if (hasPhone && normalizePhone(v) == null) return 'Namba si sahihi';
                if (!hasPhone && _email.text.trim().isEmpty) return 'Weka simu au email';
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email (si lazima)'),
              validator: (v) => v != null && v.trim().isNotEmpty && !v.contains('@') ? 'Email si sahihi' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _category,
              decoration: const InputDecoration(labelText: 'Kundi (si lazima)', hintText: 'mf. VIP, Familia, Marafiki'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Expanded(child: Text('Idadi ya watu kwenye kadi')),
                IconButton(onPressed: _seats > 1 ? () => setState(() => _seats--) : null, icon: const Icon(Icons.remove_circle_outline)),
                Text('$_seats', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                IconButton(onPressed: _seats < 20 ? () => setState(() => _seats++) : null, icon: const Icon(Icons.add_circle_outline)),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: _submit, child: const Text('Hifadhi')),
          ],
        ),
      ),
    );
  }
}
