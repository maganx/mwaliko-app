/// Bei za Mwaliko (zinatoka kwenye jedwali `pricing`, zinaweza kubadilishwa bila kubadilisha app).
class Pricing {
  const Pricing({
    this.currency = 'TZS',
    this.pricePerGuest = 3000,
    this.minPurchase = 10,
    this.packages = const [10, 50, 100, 200, 500],
    this.paymentInstructions = "Lipa kwa M-Pesa Lipa Namba 000000 (U'r Invente), kisha weka namba ya muamala.",
  });

  final String currency;
  final int pricePerGuest;
  final int minPurchase;
  final List<int> packages;
  final String paymentInstructions;

  int priceFor(int guests) => guests * pricePerGuest;

  factory Pricing.fromJson(Map<String, dynamic> j) => Pricing(
    currency: j['currency'] as String? ?? 'TZS',
    pricePerGuest: (j['price_per_guest'] as num?)?.toInt() ?? 3000,
    minPurchase: (j['min_purchase'] as num?)?.toInt() ?? 10,
    packages: ((j['packages'] as List?) ?? const [10, 50, 100, 200, 500]).map((e) => (e as num).toInt()).toList(),
    paymentInstructions: j['payment_instructions'] as String? ?? const Pricing().paymentInstructions,
  );
}

class CreditTransaction {
  const CreditTransaction({required this.kind, required this.credits, this.amount, this.note, required this.createdAt});

  final String kind; // purchase, usage, bonus, refund, adjustment
  final int credits;
  final int? amount;
  final String? note;
  final DateTime createdAt;

  factory CreditTransaction.fromJson(Map<String, dynamic> j) => CreditTransaction(
    kind: j['kind'] as String,
    credits: (j['credits'] as num).toInt(),
    amount: (j['amount'] as num?)?.toInt(),
    note: j['note'] as String?,
    createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
  );
}

enum PaymentMethod {
  mpesa('mpesa', 'M-Pesa'),
  mixx('mixx', 'Mixx by Yas'),
  airtel('airtel', 'Airtel Money'),
  halopesa('halopesa', 'HaloPesa'),
  bank('bank', 'Benki / Kadi');

  const PaymentMethod(this.id, this.label);
  final String id;
  final String label;
}

class Payment {
  const Payment({
    required this.id,
    required this.userId,
    required this.credits,
    required this.amount,
    required this.method,
    this.phone,
    this.reference,
    required this.status,
    required this.createdAt,
    this.customerName,
  });

  final String id;
  final String userId;
  final int credits;
  final int amount;
  final String method;
  final String? phone;
  final String? reference;
  final String status; // pending, paid, failed, cancelled
  final DateTime createdAt;
  final String? customerName;

  String get methodLabel => PaymentMethod.values.where((m) => m.id == method).firstOrNull?.label ?? method;

  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
    id: j['id'] as String,
    userId: j['user_id'] as String,
    credits: (j['credits'] as num).toInt(),
    amount: (j['amount'] as num).toInt(),
    method: j['method'] as String,
    phone: j['phone'] as String?,
    reference: j['reference'] as String?,
    status: j['status'] as String,
    createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
    customerName:
        (j['profiles'] as Map?)?['business_name'] as String? ?? (j['profiles'] as Map?)?['full_name'] as String?,
  );
}

class Profile {
  const Profile({required this.id, this.email, this.fullName, this.businessName, this.phone, this.role = 'customer'});

  final String id;
  final String? email;
  final String? fullName;
  final String? businessName;
  final String? phone;
  final String role;

  bool get isAdmin => role == 'admin';

  String get displayName => (fullName?.trim().isNotEmpty ?? false) ? fullName!.trim() : (email ?? 'Mteja');

  String get initials {
    final parts = displayName.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'M';
    return (parts.first[0] + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
  }

  factory Profile.fromJson(Map<String, dynamic> j, {String? email}) => Profile(
    id: j['id'] as String,
    email: email,
    fullName: j['full_name'] as String?,
    businessName: j['business_name'] as String?,
    phone: j['phone'] as String?,
    role: j['role'] as String? ?? 'customer',
  );
}

class InsufficientCreditsException implements Exception {
  const InsufficientCreditsException({required this.needed, required this.balance});
  final int needed;
  final int balance;

  @override
  String toString() => 'Salio halitoshi: unahitaji mialiko $needed, una $balance.';
}
