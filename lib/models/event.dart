import 'card_config.dart';

class EventModel {
  const EventModel({
    this.id,
    required this.title,
    this.eventType = 'harusi',
    this.hostNames,
    required this.eventDate,
    this.venue,
    this.venueMapUrl,
    this.dressCode,
    this.contactPhone,
    this.message,
    this.cardConfig = const CardConfig(),
  });

  final String? id;
  final String title;
  final String eventType;
  final String? hostNames;
  final DateTime eventDate;
  final String? venue;
  final String? venueMapUrl;
  final String? dressCode;
  final String? contactPhone;
  final String? message;
  final CardConfig cardConfig;

  factory EventModel.fromJson(Map<String, dynamic> j) => EventModel(
    id: j['id'] as String?,
    title: j['title'] as String,
    eventType: j['event_type'] as String? ?? 'other',
    hostNames: j['host_names'] as String?,
    eventDate: DateTime.parse(j['event_date'] as String).toLocal(),
    venue: j['venue'] as String?,
    venueMapUrl: j['venue_map_url'] as String?,
    dressCode: j['dress_code'] as String?,
    contactPhone: j['contact_phone'] as String?,
    message: j['message'] as String?,
    cardConfig: CardConfig.fromJson(j['card_config'] as Map<String, dynamic>?),
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'event_type': eventType,
    'host_names': hostNames,
    'event_date': eventDate.toUtc().toIso8601String(),
    'venue': venue,
    'venue_map_url': venueMapUrl,
    'dress_code': dressCode,
    'contact_phone': contactPhone,
    'message': message,
    'card_config': cardConfig.toJson(),
  };

  EventModel copyWith({CardConfig? cardConfig}) => EventModel(
    id: id,
    title: title,
    eventType: eventType,
    hostNames: hostNames,
    eventDate: eventDate,
    venue: venue,
    venueMapUrl: venueMapUrl,
    dressCode: dressCode,
    contactPhone: contactPhone,
    message: message,
    cardConfig: cardConfig ?? this.cardConfig,
  );
}

class EventStats {
  const EventStats({
    this.guests = 0,
    this.seats = 0,
    this.attending = 0,
    this.declined = 0,
    this.maybe = 0,
    this.pending = 0,
    this.checkedIn = 0,
  });

  final int guests, seats, attending, declined, maybe, pending, checkedIn;

  factory EventStats.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const EventStats();
    int n(String k) => (j[k] as num?)?.toInt() ?? 0;
    return EventStats(
      guests: n('guests'),
      seats: n('seats'),
      attending: n('attending'),
      declined: n('declined'),
      maybe: n('maybe'),
      pending: n('pending'),
      checkedIn: n('checked_in'),
    );
  }
}
