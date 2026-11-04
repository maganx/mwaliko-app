import 'package:flutter/material.dart';

import '../../core/config.dart';
import '../../core/invitation_text.dart';
import '../../core/theme.dart';
import '../../data/cards_repository.dart';
import '../../data/invitations_repository.dart';
import '../../models/event.dart';
import '../../models/guest.dart';
import '../../widgets/ui.dart';
import '../cards/invitation_card.dart';

/// Preview: mwalikwa ataona nini kwenye SMS, WhatsApp na email (kwa mwalikwa halisi wa orodha).
class MessagePreview extends StatefulWidget {
  const MessagePreview({super.key, required this.event, required this.guests, required this.channels});

  final EventModel event;
  final List<Guest> guests;

  /// Njia zilizochaguliwa kwa kutuma; preview inaanza na ya kwanza.
  final Set<Channel> channels;

  @override
  State<MessagePreview> createState() => _MessagePreviewState();
}

class _MessagePreviewState extends State<MessagePreview> {
  Channel? _tab;
  int _guest = 0;

  @override
  Widget build(BuildContext context) {
    final tab = _tab ?? (widget.channels.isEmpty ? Channel.whatsapp : _ordered(widget.channels).first);
    final guests = widget.guests;
    final g = guests.isEmpty ? null : guests[_guest.clamp(0, guests.length - 1)];
    final name = g?.name ?? 'Jina la Mwalikwa';
    final rsvp = AppConfig.rsvpLink(g?.rsvpToken ?? 'mfano');

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Simu nyembamba: maandishi tu, ili "WhatsApp" isivunjike mistari miwili.
          LayoutBuilder(
            builder: (context, box) => SegmentedButton<Channel>(
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              segments: [
                for (final c in Channel.values)
                  ButtonSegment(
                    value: c,
                    label: Text(c.label, maxLines: 1, softWrap: false, overflow: TextOverflow.fade),
                    icon: box.maxWidth < 400
                        ? null
                        : Icon(switch (c) {
                            Channel.sms => Icons.sms_outlined,
                            Channel.whatsapp => Icons.chat_outlined,
                            Channel.email => Icons.mail_outline,
                          }, size: 18),
                  ),
              ],
              selected: {tab},
              onSelectionChanged: (s) => setState(() => _tab = s.first),
            ),
          ),
          const SizedBox(height: 12),
          if (guests.length > 1)
            Row(
              children: [
                const Icon(Icons.person_outline, size: 18, color: MwalikoColors.muted),
                const SizedBox(width: 6),
                const Text('Mwalikwa:', style: TextStyle(color: MwalikoColors.muted, fontSize: 13)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    isDense: true,
                    underline: const SizedBox.shrink(),
                    value: _guest.clamp(0, guests.length - 1),
                    items: [
                      for (var i = 0; i < guests.length; i++)
                        DropdownMenuItem(
                          value: i,
                          child: Text(guests[i].name, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (i) => setState(() => _guest = i ?? 0),
                  ),
                ),
              ],
            ),
          if (!widget.channels.contains(tab))
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(
                '${tab.label} haijachaguliwa juu, kwa hiyo ujumbe huu hautatumwa.',
                style: const TextStyle(fontSize: 12.5, color: MwalikoColors.warning, fontWeight: FontWeight.w600),
              ),
            ),
          const SizedBox(height: 8),
          switch (tab) {
            Channel.sms => _SmsPreview(text: smsText(widget.event, name, rsvp), missing: g != null && g.phone == null),
            Channel.whatsapp => _WhatsAppPreview(
              card: _card(g),
              text: whatsAppText(widget.event, name, rsvp),
              missing: g != null && g.phone == null,
            ),
            Channel.email => _EmailPreview(
              event: widget.event,
              guestName: name,
              to: g?.email,
              card: _card(g),
              missing: g != null && g.email == null,
            ),
          },
        ],
      ),
    );
  }

  Widget _card(Guest? g) {
    final config = widget.event.cardConfig;
    return AspectRatio(
      aspectRatio: config.aspectRatio,
      child: InvitationCard(
        event: widget.event,
        config: config,
        guestName: g?.name,
        seats: g?.seats,
        qrData: g?.qrData,
        customImageProvider: config.isCustom ? const CardsRepository().imageFor(config.customImagePath!) : null,
      ),
    );
  }

  static List<Channel> _ordered(Set<Channel> s) => [
    for (final c in Channel.values)
      if (s.contains(c)) c,
  ];
}

class _Missing extends StatelessWidget {
  const _Missing(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        const Icon(Icons.info_outline, size: 16, color: MwalikoColors.warning),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 12.5, color: MwalikoColors.warning)),
        ),
      ],
    ),
  );
}

/// Maandishi yenye link zilizopakwa rangi (kama simu inavyoonyesha).
class _LinkText extends StatelessWidget {
  const _LinkText(this.text, {this.style, this.linkColor = const Color(0xFF1A73E8)});
  final String text;
  final TextStyle? style;
  final Color linkColor;

  @override
  Widget build(BuildContext context) {
    final re = RegExp(r'https?://\S+');
    final spans = <TextSpan>[];
    var last = 0;
    for (final m in re.allMatches(text)) {
      spans.add(TextSpan(text: text.substring(last, m.start)));
      spans.add(
        TextSpan(
          text: m.group(0),
          style: TextStyle(color: linkColor, decoration: TextDecoration.underline, decorationColor: linkColor),
        ),
      );
      last = m.end;
    }
    spans.add(TextSpan(text: text.substring(last)));
    return Text.rich(TextSpan(children: spans), style: style);
  }
}

class _SmsPreview extends StatelessWidget {
  const _SmsPreview({required this.text, required this.missing});
  final String text;
  final bool missing;

  @override
  Widget build(BuildContext context) {
    final parts = smsParts(text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (missing) const _Missing('Mwalikwa huyu hana namba ya simu, hatapata SMS.'),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(0xFFE3E6EA),
                    child: Icon(Icons.person, size: 18, color: Color(0xFF8A9199)),
                  ),
                  SizedBox(width: 8),
                  Text('Ujumbe mfupi (SMS)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE9E9EB),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                        bottomLeft: Radius.circular(4),
                      ),
                    ),
                    child: _LinkText(text, style: const TextStyle(fontSize: 14, height: 1.35, color: Colors.black)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Herufi ${text.length} · SMS $parts kwa kila mwalikwa',
          style: const TextStyle(fontSize: 12, color: MwalikoColors.muted),
        ),
      ],
    );
  }
}

class _WhatsAppPreview extends StatelessWidget {
  const _WhatsAppPreview({required this.card, required this.text, required this.missing});
  final Widget card;
  final String text;
  final bool missing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (missing) const _Missing('Mwalikwa huyu hana namba ya simu, hatapata WhatsApp.'),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFEFE7DD), borderRadius: BorderRadius.circular(18)),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 2, offset: Offset(0, 1))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(borderRadius: BorderRadius.circular(9), child: card),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
                      child: _LinkText(
                        text,
                        style: const TextStyle(fontSize: 14, height: 1.35, color: Color(0xFF111B21)),
                        linkColor: const Color(0xFF027EB5),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(8, 0, 8, 4),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text('10:00', style: TextStyle(fontSize: 11, color: Color(0xFF667781))),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmailPreview extends StatelessWidget {
  const _EmailPreview({
    required this.event,
    required this.guestName,
    required this.to,
    required this.card,
    required this.missing,
  });
  final EventModel event;
  final String guestName;
  final String? to;
  final Widget card;
  final bool missing;

  @override
  Widget build(BuildContext context) {
    const serif = TextStyle(fontFamily: 'Georgia', fontFamilyFallback: ['serif'], color: Color(0xFF222222));
    const meta = TextStyle(fontSize: 12.5, color: MwalikoColors.muted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (missing) const _Missing('Mwalikwa huyu hana email, hatapata email.'),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emailSubject(event),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: MwalikoColors.ink),
                    ),
                    const SizedBox(height: 4),
                    Text('Kwa: ${to ?? '—'}', style: meta),
                  ],
                ),
              ),
              const Divider(height: 1, color: MwalikoColors.line),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Column(
                      children: [
                        Text.rich(
                          TextSpan(
                            text: 'Habari ',
                            children: [
                              TextSpan(
                                text: guestName,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const TextSpan(text: ','),
                            ],
                          ),
                          style: serif.copyWith(fontSize: 15),
                        ),
                        const SizedBox(height: 8),
                        Text(emailIntro(event), textAlign: TextAlign.center, style: serif.copyWith(fontSize: 14)),
                        const SizedBox(height: 6),
                        Text(
                          event.title,
                          textAlign: TextAlign.center,
                          style: serif.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          [invitationDate(event.eventDate), if (event.venue != null) event.venue!].join('\n'),
                          textAlign: TextAlign.center,
                          style: serif.copyWith(fontSize: 13.5, height: 1.4),
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(borderRadius: BorderRadius.circular(12), child: card),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: MwalikoColors.primary,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Text(
                            'Thibitisha kuhudhuria',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
