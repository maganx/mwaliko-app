/// Aina za matukio na maandishi yake ya Kiswahili.
class EventType {
  const EventType(this.id, this.label, this.cardHeading);
  final String id;
  final String label;
  final String cardHeading;
}

const eventTypes = <EventType>[
  EventType('harusi', 'Harusi', 'Mwaliko wa Harusi'),
  EventType('sendoff', 'Send-Off', 'Mwaliko wa Send-Off'),
  EventType('kitchen_party', 'Kitchen Party', 'Mwaliko wa Kitchen Party'),
  EventType('birthday', 'Siku ya Kuzaliwa', 'Mwaliko wa Sherehe'),
  EventType('graduation', 'Mahafali', 'Mwaliko wa Mahafali'),
  EventType('corporate', 'Tukio la Kikazi', 'Mwaliko Rasmi'),
  EventType('other', 'Tukio Lingine', 'Mwaliko'),
];

EventType eventTypeById(String id) =>
    eventTypes.firstWhere((t) => t.id == id, orElse: () => eventTypes.last);
