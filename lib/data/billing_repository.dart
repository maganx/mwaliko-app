import '../core/config.dart';
import '../models/billing.dart';
import 'demo_store.dart';
import 'supabase.dart';

/// Salio la mialiko, manunuzi na malipo.
class BillingRepository {
  const BillingRepository();

  static DemoStore get _demo => DemoStore.instance;

  Future<Pricing> pricing() async {
    if (AppConfig.demo) return const Pricing(paymentInstructions: 'Demo: malipo yanathibitishwa moja kwa moja.');
    final row = await sb.from('pricing').select().eq('id', 1).maybeSingle();
    return row == null ? const Pricing() : Pricing.fromJson(row);
  }

  /// Salio la mialiko (1 = mwalikwa mmoja).
  Future<int> balance() async {
    if (AppConfig.demo) return _demo.credits;
    final row = await sb.from('wallets').select('credits').eq('user_id', currentUserId).maybeSingle();
    return (row?['credits'] as num?)?.toInt() ?? 0;
  }

  Future<List<CreditTransaction>> transactions() async {
    if (AppConfig.demo) return _demo.transactions.map(CreditTransaction.fromJson).toList();
    final rows = await sb.from('credit_transactions').select().order('created_at', ascending: false).limit(100);
    return rows.map(CreditTransaction.fromJson).toList();
  }

  Future<List<Payment>> myPayments() async {
    if (AppConfig.demo) {
      return _demo.payments.where((p) => p['user_id'] == 'demo').map(Payment.fromJson).toList();
    }
    final rows = await sb
        .from('payments')
        .select()
        .eq('user_id', currentUserId)
        .order('created_at', ascending: false)
        .limit(50);
    return rows.map(Payment.fromJson).toList();
  }

  /// Ombi la kununua mialiko. Bei inahesabiwa upande wa server.
  Future<Payment> requestPurchase({
    required int credits,
    required PaymentMethod method,
    String? phone,
    String? reference,
  }) async {
    if (AppConfig.demo) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      final p = _demo.purchase(credits: credits, method: method.id, phone: phone, reference: reference);
      return Payment.fromJson(p);
    }
    final row = await sb.rpc(
      'request_credit_purchase',
      params: {'p_credits': credits, 'p_method': method.id, 'p_phone': phone, 'p_reference': reference},
    );
    return Payment.fromJson(row as Map<String, dynamic>);
  }

  // --- Admin ---------------------------------------------------------------

  Future<List<Payment>> pendingPayments() async {
    if (AppConfig.demo) {
      return _demo.payments.where((p) => p['status'] == 'pending').map(Payment.fromJson).toList();
    }
    final rows = await sb
        .from('payments')
        .select('*, profiles(full_name, business_name)')
        .eq('status', 'pending')
        .order('created_at');
    return rows.map(Payment.fromJson).toList();
  }

  Future<void> confirmPayment(String id) async {
    if (AppConfig.demo) {
      _demo.confirmPayment(id);
      return;
    }
    await sb.rpc('confirm_payment', params: {'p_payment_id': id});
  }

  Future<void> rejectPayment(String id) async {
    if (AppConfig.demo) {
      _demo.payments.firstWhere((p) => p['id'] == id)['status'] = 'failed';
      return;
    }
    await sb.rpc('reject_payment', params: {'p_payment_id': id});
  }
}
