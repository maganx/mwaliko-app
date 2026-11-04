import '../models/event.dart';
import 'swahili_time.dart';

// Maandishi ambayo mwalikwa anapokea. Yanatumika kwenye preview ya skrini ya kutuma,
// na LAZIMA yalingane na supabase/functions/send-invitations/index.ts (sms, email) na
// template ya WhatsApp "mwaliko_kadi" (README).

/// "Jumamosi, 12 Desemba 2026, saa 10:00 jioni"
String invitationDate(DateTime t) => '${swahiliDate(t)}, ${swahiliTime(t).toLowerCase()}';

String _hosts(EventModel e) => (e.hostNames?.trim().isNotEmpty ?? false) ? '${e.hostNames!.trim()} ' : '';

String smsText(EventModel e, String guestName, String rsvpUrl) {
  final venue = (e.venue?.isNotEmpty ?? false) ? ', ${e.venue}' : '';
  final link = rsvpUrl.isNotEmpty ? '. Kadi yako na kuthibitisha: $rsvpUrl' : '.';
  return 'Habari $guestName, ${_hosts(e)}wanakualika kwenye ${e.title}, ${invitationDate(e.eventDate)}$venue$link';
}

/// Body ya template ya WhatsApp: {{1}} jina, {{2}} tukio, {{3}} tarehe, {{4}} link.
String whatsAppText(EventModel e, String guestName, String rsvpUrl) =>
    'Habari $guestName, unakaribishwa kwenye ${e.title} tarehe ${invitationDate(e.eventDate)}.\n'
    'Kadi yako ya mwaliko iko hapo juu. Thibitisha kuhudhuria hapa: ${rsvpUrl.isEmpty ? '-' : rsvpUrl}';

String emailSubject(EventModel e) => 'Mwaliko: ${e.title}';

String emailIntro(EventModel e) => '${_hosts(e)}wanayo furaha kukualika kwenye';

/// Idadi ya SMS (vipande) kwa maandishi haya: 160 kwa SMS moja, 153 kwa kila kipande zikiwa zaidi.
int smsParts(String text) => text.length <= 160 ? 1 : (text.length / 153).ceil();
