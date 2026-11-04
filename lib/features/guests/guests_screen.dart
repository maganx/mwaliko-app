import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config.dart';
import '../../core/phone.dart';
import '../../core/theme.dart';
import '../../data/cards_repository.dart';
import '../../data/guests_repository.dart';
import '../../models/guest.dart';
import '../../widgets/async_view.dart';
import '../../widgets/ui.dart';
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
  RsvpStatus? _status;

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
      final bytes = await const CardsRepository().cardBytes(g.cardPath!);
      final rsvp = AppConfig.rsvpBaseUrl.isEmpty
          ? ''
          : '\nThibitisha kuhudhuria: ${AppConfig.rsvpBaseUrl}?t=${g.rsvpToken}';
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, mimeType: 'image/png', name: 'mwaliko-${g.name}.png')],
          text: 'Habari ${g.name}, karibu sana kwenye sherehe yetu.$rsvp',
        ),
      );
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Waalikwa')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-guest',
        onPressed: () => _addOrEdit(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Mwalikwa'),
      ),
      body: AsyncView(
        future: _future,
        onRetry: _reload,
        builder: (context, guests) {
          final q = _query;
          final filtered = guests.where((g) {
            final matches = q.isEmpty || g.name.toLowerCase().contains(q) || (g.phone ?? '').contains(q);
            return matches && (_status == null || g.rsvpStatus == _status);
          }).toList();
          final seats = guests.fold<int>(0, (s, g) => s + g.seats);
          final notCharged = guests.where((g) => g.chargedAt == null).length;
          int count(RsvpStatus s) => guests.where((g) => g.rsvpStatus == s).length;

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              children: [
                Row(
                  children: [
                    _ImportButton(icon: Icons.contacts_outlined, label: 'Contacts', onTap: _fromContacts),
                    const SizedBox(width: 10),
                    _ImportButton(icon: Icons.table_chart_outlined, label: 'Excel / CSV', onTap: _fromFile),
                    const SizedBox(width: 10),
                    _ImportButton(icon: Icons.person_add_outlined, label: 'Mmoja', onTap: () => _addOrEdit()),
                  ],
                ),
                const SizedBox(height: 16),
                if (guests.isEmpty)
                  const SoftCard(
                    child: EmptyState(
                      icon: Icons.people_alt_outlined,
                      title: 'Bado hakuna waalikwa',
                      message: 'Ongeza kutoka contacts za simu, faili la Excel (safu: Jina, Simu, Email, Idadi) au mmoja mmoja.',
                    ),
                  )
                else ...[
                  SoftCard(
                    child: Row(
                      children: [
                        _Mini(value: guests.length, label: 'Waalikwa'),
                        _Mini(value: seats, label: 'Viti'),
                        _Mini(value: count(RsvpStatus.attending), label: 'Watakuja', color: MwalikoColors.success),
                        _Mini(value: notCharged, label: 'Hawajatozwa', color: MwalikoColors.warning),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Tafuta jina au simu'),
                    onChanged: (v) => setState(() => _query = v.toLowerCase().trim()),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final s in <RsvpStatus?>[null, ...RsvpStatus.values])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              showCheckmark: false,
                              label: Text(s == null ? 'Wote ${guests.length}' : '${s.label} ${count(s)}'),
                              selected: _status == s,
                              onSelected: (_) => setState(() => _status = s),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Hakuna anayelingana na utafutaji.',
                        textAlign: TextAlign.center,
                        style: t.bodyMedium,
                      ),
                    )
                  else
                    SoftCard(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        children: [
                          for (final (i, g) in filtered.indexed) ...[
                            if (i > 0) const Divider(indent: 70, endIndent: 16),
                            _GuestRow(
                              guest: g,
                              onTap: () => _addOrEdit(g),
                              onShare: () => _share(g),
                              onDelete: () => _confirmDelete(g),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(Guest g) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Futa ${g.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hapana')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44), backgroundColor: MwalikoColors.danger),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Futa'),
          ),
        ],
      ),
    );
    if (ok == true) await _delete(g);
  }
}

class _ImportButton extends StatelessWidget {
  const _ImportButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      child: Column(
        children: [
          IconBadge(icon, size: 38),
          const SizedBox(height: 6),
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

class _Mini extends StatelessWidget {
  const _Mini({required this.value, required this.label, this.color = MwalikoColors.ink});
  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          '$value',
          style: TextStyle(fontFamily: MwalikoFonts.display, fontSize: 22, fontWeight: FontWeight.w700, color: color),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, maxLines: 1, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    ),
  );
}

class _GuestRow extends StatelessWidget {
  const _GuestRow({required this.guest, required this.onTap, required this.onShare, required this.onDelete});
  final Guest guest;
  final VoidCallback onTap;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final g = guest;
    final t = Theme.of(context).textTheme;
    final (label, color) = g.checkedInAt != null
        ? ('Ameingia', MwalikoColors.primary)
        : switch (g.rsvpStatus) {
            RsvpStatus.attending => (g.rsvpStatus.label, MwalikoColors.success),
            RsvpStatus.declined => (g.rsvpStatus.label, MwalikoColors.danger),
            RsvpStatus.maybe => (g.rsvpStatus.label, MwalikoColors.warning),
            RsvpStatus.pending => (g.rsvpStatus.label, MwalikoColors.muted),
          };
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.only(left: 14, right: 4),
      leading: InitialsAvatar(g.name),
      title: Text(g.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleSmall),
      subtitle: Text(
        [
          if (g.phone != null) formatPhone(g.phone),
          if (g.phone == null && g.email != null) g.email!,
          if (g.category != null) g.category!,
          if (g.seats > 1) 'watu ${g.seats}',
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: t.bodySmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusChip(label, color: color),
          PopupMenuButton<String>(
            tooltip: 'Zaidi',
            icon: const Icon(Icons.more_vert, color: MwalikoColors.muted),
            onSelected: (v) => switch (v) {
              'share' => onShare(),
              'edit' => onTap(),
              _ => onDelete(),
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'share',
                enabled: g.cardPath != null,
                child: const ListTile(leading: Icon(Icons.share_outlined), title: Text('Shiriki kadi')),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Hariri')),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(leading: Icon(Icons.delete_outline), title: Text('Futa')),
              ),
            ],
          ),
        ],
      ),
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
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? 'Mwalikwa mpya' : 'Hariri mwalikwa',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
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
                IconButton(
                  onPressed: _seats > 1 ? () => setState(() => _seats--) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$_seats', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                IconButton(
                  onPressed: _seats < 20 ? () => setState(() => _seats++) : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
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
