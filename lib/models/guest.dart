class Guest {
  const Guest({
    this.id,
    required this.eventId,
    required this.name,
    this.phone,
    this.email,
    this.seats = 1,
    this.category,
    this.rsvpStatus = RsvpStatus.pending,
    this.rsvpSeats,
    this.rsvpToken,
    this.cardPath,
    this.checkedInAt,
    this.chargedAt,
  });

  final String? id;
  final String eventId;
  final String name;
  final String? phone;
  final String? email;
  final int seats;
  final String? category;
  final RsvpStatus rsvpStatus;
  final int? rsvpSeats;
  final String? rsvpToken;
  final String? cardPath;
  final DateTime? checkedInAt;

  /// Ametozwa (salio limekatwa) lini. Kumtumia tena hakumtozi.
  final DateTime? chargedAt;

  /// Data iliyo ndani ya QR code ya kadi (inaskaniwa mlangoni).
  String get qrData => 'MWALIKO:${rsvpToken ?? ''}';

  factory Guest.fromJson(Map<String, dynamic> j) => Guest(
    id: j['id'] as String?,
    eventId: j['event_id'] as String,
    name: j['name'] as String,
    phone: j['phone'] as String?,
    email: j['email'] as String?,
    seats: (j['seats'] as num?)?.toInt() ?? 1,
    category: j['category'] as String?,
    rsvpStatus: RsvpStatus.fromId(j['rsvp_status'] as String?),
    rsvpSeats: (j['rsvp_seats'] as num?)?.toInt(),
    rsvpToken: j['rsvp_token'] as String?,
    cardPath: j['card_path'] as String?,
    checkedInAt: j['checked_in_at'] == null ? null : DateTime.parse(j['checked_in_at'] as String).toLocal(),
    chargedAt: j['charged_at'] == null ? null : DateTime.parse(j['charged_at'] as String).toLocal(),
  );

  /// Sehemu zinazoweza kuandikwa na app (token/rsvp zinawekwa na database).
  Map<String, dynamic> toInsertJson() => {
    'event_id': eventId,
    'name': name,
    'phone': phone,
    'email': email,
    'seats': seats,
    'category': category,
  };
}

enum RsvpStatus {
  pending('pending', 'Hajajibu'),
  attending('attending', 'Atahudhuria'),
  declined('declined', 'Hatahudhuria'),
  maybe('maybe', 'Labda');

  const RsvpStatus(this.id, this.label);
  final String id;
  final String label;

  static RsvpStatus fromId(String? id) => values.firstWhere((s) => s.id == id, orElse: () => RsvpStatus.pending);
}

/// Mwalikwa kabla ya kuhifadhiwa (kutoka contacts au Excel).
class GuestDraft {
  const GuestDraft({required this.name, this.phone, this.email, this.seats = 1, this.category});
  final String name;
  final String? phone;
  final String? email;
  final int seats;
  final String? category;

  Guest toGuest(String eventId) =>
      Guest(eventId: eventId, name: name, phone: phone, email: email, seats: seats, category: category);
}
