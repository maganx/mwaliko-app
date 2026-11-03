import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../core/phone.dart';
import '../../models/guest.dart';

/// Kuchagua waalikwa kutoka kwenye contacts za simu.
/// Inarudisha `List<GuestDraft>` kupitia Navigator.pop.
class ContactsPickerScreen extends StatefulWidget {
  const ContactsPickerScreen({super.key});

  @override
  State<ContactsPickerScreen> createState() => _ContactsPickerScreenState();
}

class _ContactsPickerScreenState extends State<ContactsPickerScreen> {
  List<GuestDraft>? _all;
  String? _error;
  final _selected = <int>{};
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final status = await FlutterContacts.permissions.request(PermissionType.read);
    if (status != PermissionStatus.granted && status != PermissionStatus.limited) {
      setState(() => _error = 'Ruhusu Mwaliko kusoma contacts kwenye Settings za simu.');
      return;
    }
    final contacts = await FlutterContacts.getAll(properties: {ContactProperty.phone, ContactProperty.email});
    final drafts = <GuestDraft>[];
    for (final c in contacts) {
      final name = c.displayName?.trim() ?? '';
      if (name.isEmpty) continue;
      final phone = c.phones.map((p) => normalizePhone(p.normalizedNumber ?? p.number)).whereType<String>().firstOrNull;
      final email = c.emails.map((e) => e.address).where((e) => e.contains('@')).firstOrNull;
      if (phone == null && email == null) continue;
      drafts.add(GuestDraft(name: name, phone: phone, email: email));
    }
    drafts.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    if (mounted) setState(() => _all = drafts);
  }

  @override
  Widget build(BuildContext context) {
    final all = _all;
    final visible = <int>[
      if (all != null)
        for (var i = 0; i < all.length; i++)
          if (_query.isEmpty ||
              all[i].name.toLowerCase().contains(_query) ||
              (all[i].phone ?? '').contains(_query))
            i,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_selected.isEmpty ? 'Chagua kutoka contacts' : 'Umechagua ${_selected.length}'),
        actions: [
          TextButton(
            onPressed: _selected.isEmpty ? null : () => Navigator.pop(context, [for (final i in _selected) all![i]]),
            child: const Text('Ongeza'),
          ),
        ],
      ),
      body: _error != null
          ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center)))
          : all == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Tafuta jina au namba'),
                        onChanged: (v) => setState(() => _query = v.toLowerCase().trim()),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: visible.length,
                        itemBuilder: (_, k) {
                          final i = visible[k];
                          final g = all[i];
                          return CheckboxListTile(
                            value: _selected.contains(i),
                            onChanged: (v) => setState(() => v == true ? _selected.add(i) : _selected.remove(i)),
                            title: Text(g.name),
                            subtitle: Text([formatPhone(g.phone), g.email].whereType<String>().where((s) => s.isNotEmpty).join(' · ')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
