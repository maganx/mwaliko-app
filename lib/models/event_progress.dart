import 'event.dart';

/// Hatua nne za mwaliko. Zinafanywa kwa mpangilio: hatua haifunguki mpaka zilizotangulia zikamilike.
enum EventStep {
  card(1, 'Kadi', 'card'),
  guests(2, 'Waalikwa', 'guests'),
  send(3, 'Tuma', 'send'),
  checkin(4, 'Check-in', 'checkin');

  const EventStep(this.number, this.title, this.path);
  final int number;
  final String title;

  /// Njia chini ya /events/:id/
  final String path;
}

class EventProgress {
  const EventProgress(this.event, this.stats);

  final EventModel event;
  final EventStats stats;

  bool isDone(EventStep step) => switch (step) {
    EventStep.card => event.cardConfig.chosen,
    EventStep.guests => stats.guests > 0,
    EventStep.send => stats.invited > 0,
    EventStep.checkin => stats.checkedIn > 0,
  };

  /// Hatua ya kwanza ambayo bado haijakamilika kati ya zilizotangulia [step], au null kama zote zimekamilika.
  EventStep? blockerOf(EventStep step) {
    for (final s in EventStep.values) {
      if (s.index >= step.index) return null;
      if (!isDone(s)) return s;
    }
    return null;
  }

  bool isUnlocked(EventStep step) => blockerOf(step) == null;

  /// Hatua inayofuata kufanywa (ya kwanza ambayo haijakamilika).
  EventStep get current => EventStep.values.firstWhere((s) => !isDone(s), orElse: () => EventStep.checkin);

  /// Ujumbe kwa mteja akigusa hatua iliyofungwa.
  String lockedMessage(EventStep step) {
    final b = blockerOf(step);
    if (b == null) return '';
    return switch (b) {
      EventStep.card => 'Kwanza chagua na uhifadhi design ya kadi (hatua ya 1).',
      EventStep.guests => 'Kwanza ongeza waalikwa (hatua ya 2).',
      EventStep.send => 'Kwanza tuma mialiko (hatua ya 3).',
      EventStep.checkin => '',
    };
  }
}
