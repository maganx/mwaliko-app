import 'package:intl/intl.dart';

/// Saa kwa mtindo wa Kiswahili: 16:00 -> "Saa 10:00 jioni", 07:30 -> "Saa 1:30 asubuhi".
String swahiliTime(DateTime t) {
  final h = t.hour;
  var swHour = (h + 6) % 12;
  if (swHour == 0) swHour = 12;
  final period = switch (h) {
    >= 5 && < 12 => 'asubuhi',
    >= 12 && < 16 => 'mchana',
    >= 16 && < 19 => 'jioni',
    >= 19 => 'usiku',
    _ => 'usiku',
  };
  final m = t.minute.toString().padLeft(2, '0');
  return 'Saa $swHour:$m $period';
}

/// Tarehe kamili kwa Kiswahili: "Jumamosi, 12 Desemba 2026".
/// Inahitaji initializeDateFormatting('sw') kuitwa mwanzoni (main.dart).
String swahiliDate(DateTime t) => DateFormat('EEEE, d MMMM y', 'sw').format(t);

String swahiliShortDate(DateTime t) => DateFormat('d MMM y', 'sw').format(t);
