import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme.dart';
import '../../data/cards_repository.dart';
import '../../data/events_repository.dart';
import '../../data/guests_repository.dart';
import '../../models/card_config.dart';
import '../../models/event.dart';
import '../../widgets/async_view.dart';
import 'card_exporter.dart';
import 'card_styles.dart';
import 'invitation_card.dart';

/// Studio ya kadi: chagua template, tengeneza design mpya, au pakia design yako.
class CardStudioScreen extends StatefulWidget {
  const CardStudioScreen({super.key, required this.eventId});
  final String eventId;

  @override
  State<CardStudioScreen> createState() => _CardStudioScreenState();
}

class _CardStudioScreenState extends State<CardStudioScreen> with SingleTickerProviderStateMixin {
  final _events = const EventsRepository();
  final _cards = const CardsRepository();
  late final _tabs = TabController(length: 3, vsync: this);

  EventModel? _event;
  late CardConfig _config;
  Object? _loadError;
  bool _saving = false;

  /// Picha ya design ya mteja kwa preview (bila kupakua tena).
  ImageProvider? _customPreview;

  int _seed = DateTime.now().millisecondsSinceEpoch;
  late List<CardConfig> _generated;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final e = await _events.get(widget.eventId);
      setState(() {
        _event = e;
        _config = e.cardConfig;
        _generated = CardGenerator(_seed).generateMany(_config, 6, eventType: e.eventType);
        if (_config.isCustom) _customPreview = _cards.imageFor(_config.customImagePath!);
        if (_config.isCustom) _tabs.index = 2;
      });
    } catch (e) {
      setState(() => _loadError = e);
    }
  }

  void _regenerate() => setState(() {
    _seed = Random().nextInt(1 << 31);
    _generated = CardGenerator(_seed).generateMany(_config, 6, eventType: _event!.eventType);
  });

  Future<void> _uploadDesign() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 2160, imageQuality: 92);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final image = await decodeImageFromList(bytes);
    final aspect = image.width / image.height;
    image.dispose();
    if (!mounted) return;
    setState(() => _saving = true);
    try {
      final ext = picked.name.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
      final path = await _cards.uploadDesign(widget.eventId, bytes, ext);
      setState(() {
        _customPreview = MemoryImage(Uint8List.fromList(bytes));
        _config = _config.copyWith(mode: CardMode.custom, customImagePath: path, customAspect: aspect);
      });
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _save() async {
    setState(() => _saving = true);
    try {
      await _events.saveCardConfig(widget.eventId, _config);
      _event = _event!.copyWith(cardConfig: _config);
      return true;
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _generateGuestCards() async {
    if (!await _save()) return;
    final guests = await const GuestsRepository().list(widget.eventId);
    if (!mounted) return;
    if (guests.isEmpty) {
      showSnack(context, 'Ongeza waalikwa kwanza');
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ExportDialog(
        event: _event!,
        guestsCount: guests.length,
        run: (onProgress, isCancelled) {
          return CardExporter().exportAll(
            event: _event!,
            guests: guests,
            onProgress: onProgress,
            isCancelled: isCancelled,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(friendlyError(_loadError!))),
      );
    }
    final event = _event;
    if (event == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Studio ya kadi'),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Template'),
            Tab(text: 'Tengeneza mpya'),
            Tab(text: 'Design yangu'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _grid([for (final t in curatedTemplates) (t.name, t.apply(_config))]),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Design hizi zimetengenezwa kwa ajili ya tukio lako. Hupendi? Tengeneza nyingine.'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                      onPressed: _regenerate,
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Nyingine'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _grid([
                  for (final c in _generated) ('${paletteById(c.paletteId).name} · ${ornamentNames[c.ornamentId]}', c),
                ]),
              ),
            ],
          ),
          _customTab(event),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  onPressed: _saving
                      ? null
                      : () async {
                          if (await _save() && context.mounted) showSnack(context, 'Design imehifadhiwa');
                        },
                  child: const Text('Hifadhi'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _generateGuestCards,
                  icon: const Icon(Icons.collections_outlined),
                  label: const Text('Tengeneza kadi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _grid(List<(String, CardConfig)> items) => GridView.builder(
    padding: const EdgeInsets.all(12),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      childAspectRatio: 0.68,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
    ),
    itemCount: items.length,
    itemBuilder: (_, i) {
      final (name, c) = items[i];
      final selected =
          !_config.isCustom &&
          c.paletteId == _config.paletteId &&
          c.ornamentId == _config.ornamentId &&
          c.fontPairId == _config.fontPairId &&
          c.layoutId == _config.layoutId;
      return GestureDetector(
        onTap: () => setState(() => _config = c.copyWith(mode: CardMode.template)),
        child: Column(
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? MwalikoColors.primary : Colors.transparent, width: 3),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: InvitationCard(
                    event: _event!,
                    config: c.copyWith(mode: CardMode.template),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
          ],
        ),
      );
    },
  );

  Widget _customTab(EventModel event) {
    if (!_config.isCustom) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_photo_alternate_outlined, size: 64, color: MwalikoColors.primary),
              const SizedBox(height: 12),
              const Text(
                'Una kadi yako tayari? Pakia picha yake (PNG au JPG).\n'
                'Mwaliko itaweka jina la kila mwalikwa na QR code yake juu ya kadi yako.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _saving ? null : _uploadDesign,
                icon: const Icon(Icons.upload),
                label: Text(_saving ? 'Inapakia…' : 'Pakia design yangu'),
              ),
            ],
          ),
        ),
      );
    }
    return _CustomDesignEditor(
      event: event,
      config: _config,
      image: _customPreview,
      onChanged: (c) => setState(() => _config = c),
      onReplace: _uploadDesign,
    );
  }
}

/// Kuweka jina la mwalikwa na QR mahali unapotaka kwenye design ya mteja.
class _CustomDesignEditor extends StatefulWidget {
  const _CustomDesignEditor({
    required this.event,
    required this.config,
    required this.image,
    required this.onChanged,
    required this.onReplace,
  });

  final EventModel event;
  final CardConfig config;
  final ImageProvider? image;
  final ValueChanged<CardConfig> onChanged;
  final VoidCallback onReplace;

  @override
  State<_CustomDesignEditor> createState() => _CustomDesignEditorState();
}

class _CustomDesignEditorState extends State<_CustomDesignEditor> {
  bool _movingQr = false;

  static const _colors = [0xFF1A1A1A, 0xFFFFFFFF, 0xFFD4AF37, 0xFF7A1F3D, 0xFF0B4F6C, 0xFF2F5D3A];
  static const _fonts = ['GreatVibes', 'DancingScript', 'PlayfairDisplay', 'Cinzel', 'Montserrat', 'Poppins'];

  void _move(Offset local, Size size) {
    final p = Offset((local.dx / size.width).clamp(0.05, 0.95), (local.dy / size.height).clamp(0.03, 0.97));
    widget.onChanged(_movingQr ? widget.config.copyWith(qrPosition: p) : widget.config.copyWith(namePosition: p));
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.config;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 420),
            child: AspectRatio(
              aspectRatio: c.aspectRatio,
              child: LayoutBuilder(
                builder: (context, box) => GestureDetector(
                  onPanDown: (d) => _move(d.localPosition, box.biggest),
                  onPanUpdate: (d) => _move(d.localPosition, box.biggest),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: InvitationCard(
                      event: widget.event,
                      config: c,
                      guestName: 'Bi. Rehema Salim',
                      customImageProvider: widget.image,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Gusa au buruta kwenye kadi kuweka kitu ulichochagua.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 12),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, icon: Icon(Icons.text_fields), label: Text('Sogeza jina')),
            ButtonSegment(value: true, icon: Icon(Icons.qr_code), label: Text('Sogeza QR')),
          ],
          selected: {_movingQr},
          onSelectionChanged: (s) => setState(() => _movingQr = s.first),
        ),
        const SizedBox(height: 12),
        Text('Ukubwa wa jina', style: Theme.of(context).textTheme.labelLarge),
        Slider(
          value: c.nameSize,
          min: 0.03,
          max: 0.14,
          onChanged: (v) => widget.onChanged(c.copyWith(nameSize: v)),
        ),
        Text('Rangi ya jina', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Wrap(
          spacing: 10,
          children: [
            for (final col in _colors)
              GestureDetector(
                onTap: () => widget.onChanged(c.copyWith(nameColor: col)),
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: c.nameColor == col ? MwalikoColors.primary : Colors.grey.shade300,
                  child: CircleAvatar(radius: 14, backgroundColor: Color(col)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Mtindo wa herufi', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final f in _fonts)
              ChoiceChip(
                label: Text('Rehema', style: TextStyle(fontFamily: f, fontSize: 16)),
                selected: c.nameFont == f,
                onSelected: (_) => widget.onChanged(c.copyWith(nameFont: f)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Weka QR code (kwa check-in mlangoni)'),
          value: c.showQr,
          onChanged: (v) => widget.onChanged(c.copyWith(showQr: v)),
        ),
        if (c.showQr) ...[
          Text('Ukubwa wa QR', style: Theme.of(context).textTheme.labelLarge),
          Slider(
            value: c.qrSize,
            min: 0.1,
            max: 0.3,
            onChanged: (v) => widget.onChanged(c.copyWith(qrSize: v)),
          ),
        ],
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: widget.onReplace,
          icon: const Icon(Icons.swap_horiz),
          label: const Text('Badilisha picha'),
        ),
      ],
    );
  }
}

class _ExportDialog extends StatefulWidget {
  const _ExportDialog({required this.event, required this.guestsCount, required this.run});

  final EventModel event;
  final int guestsCount;
  final Future<int> Function(void Function(int, int) onProgress, bool Function() isCancelled) run;

  @override
  State<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<_ExportDialog> {
  int _done = 0;
  bool _cancelled = false;
  bool _finished = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget
        .run((d, _) {
          if (mounted) setState(() => _done = d);
        }, () => _cancelled)
        .then((_) {
          if (mounted) setState(() => _finished = true);
        })
        .catchError((Object e) {
          if (mounted) setState(() => _error = friendlyError(e));
        });
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.guestsCount;
    return AlertDialog(
      title: Text(_finished ? 'Kadi ziko tayari' : 'Inatengeneza kadi…'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(value: total == 0 ? null : _done / total),
          const SizedBox(height: 12),
          Text(_error ?? '$_done kati ya $total'),
        ],
      ),
      actions: [
        if (!_finished && _error == null)
          TextButton(onPressed: () => setState(() => _cancelled = true), child: const Text('Simamisha')),
        if (_finished || _error != null || _cancelled)
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Sawa')),
      ],
    );
  }
}
