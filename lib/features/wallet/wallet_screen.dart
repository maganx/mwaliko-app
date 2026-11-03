import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/config.dart';
import '../../core/money.dart';
import '../../core/phone.dart';
import '../../core/theme.dart';
import '../../data/billing_repository.dart';
import '../../models/billing.dart';
import '../../widgets/async_view.dart';
import '../../widgets/ui.dart';

class _WalletData {
  const _WalletData(this.credits, this.pricing, this.transactions, this.payments);
  final int credits;
  final Pricing pricing;
  final List<CreditTransaction> transactions;
  final List<Payment> payments;
}

/// Salio la mialiko: kununua kifurushi na historia ya malipo/matumizi.
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key, this.need});

  /// Idadi ya mialiko inayohitajika (inapotoka kwenye skrini ya kutuma).
  final int? need;

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _repo = const BillingRepository();
  late Future<_WalletData> _future = _load();

  int? _selected;
  final _custom = TextEditingController();
  final _phone = TextEditingController();
  final _reference = TextEditingController();
  PaymentMethod _method = PaymentMethod.mpesa;
  bool _busy = false;
  final _form = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.need != null) _custom.text = '${widget.need}';
  }

  @override
  void dispose() {
    _custom.dispose();
    _phone.dispose();
    _reference.dispose();
    super.dispose();
  }

  Future<_WalletData> _load() async {
    final r = await Future.wait([_repo.balance(), _repo.pricing(), _repo.transactions(), _repo.myPayments()]);
    return _WalletData(r[0] as int, r[1] as Pricing, r[2] as List<CreditTransaction>, r[3] as List<Payment>);
  }

  void _reload() => setState(() => _future = _load());

  int? get _quantity {
    final custom = int.tryParse(_custom.text.replaceAll(RegExp(r'[^0-9]'), ''));
    return custom ?? _selected;
  }

  Future<void> _pay(Pricing pricing) async {
    final qty = _quantity;
    if (qty == null || qty < pricing.minPurchase) {
      showSnack(context, 'Chagua kifurushi au weka idadi (kima cha chini ni mialiko ${pricing.minPurchase}).');
      return;
    }
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final p = await _repo.requestPurchase(
        credits: qty,
        method: _method,
        phone: normalizePhone(_phone.text),
        reference: _reference.text.trim().isEmpty ? null : _reference.text.trim(),
      );
      if (!mounted) return;
      final confirmed = AppConfig.demo;
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          icon: IconBadge(
            confirmed ? Icons.check_circle_outline : Icons.schedule,
            color: confirmed ? MwalikoColors.success : MwalikoColors.warning,
            size: 52,
          ),
          title: Text(confirmed ? 'Salio limeongezwa' : 'Ombi limepokelewa'),
          content: Text(
            confirmed
                ? 'Mialiko ${p.credits} (${formatTzs(p.amount)}) imeongezwa kwenye salio lako.'
                : 'Tumepokea ombi la mialiko ${p.credits} (${formatTzs(p.amount)}). '
                      'Salio litaongezwa mara malipo yatakapothibitishwa.',
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: () => Navigator.pop(c),
              child: const Text('Sawa'),
            ),
          ],
        ),
      );
      _custom.clear();
      _reference.clear();
      setState(() => _selected = null);
      _reload();
    } catch (e) {
      if (mounted) showSnack(context, _purchaseError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _purchaseError(Object e) {
    final m = RegExp(r'min_purchase:(\d+)').firstMatch('$e');
    if (m != null) return 'Kima cha chini ni mialiko ${m[1]}.';
    return friendlyError(e);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: AsyncView(
        future: _future,
        onRetry: _reload,
        builder: (context, d) {
          final p = d.pricing;
          final qty = _quantity;
          final valid = qty != null && qty >= p.minPurchase;
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    HeroHeader(
                      bottomPadding: 80,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (Navigator.of(context).canPop())
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: IconButton(
                                    onPressed: () => Navigator.of(context).maybePop(),
                                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                                  ),
                                ),
                              const Text(
                                'Salio',
                                style: TextStyle(
                                  fontFamily: 'PlayfairDisplay',
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Mwalikwa 1 = mwaliko 1 · ${formatTzs(p.pricePerGuest)} kwa mwalikwa',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: -46,
                      child: BalanceCard(credits: d.credits, pricePerGuest: p.pricePerGuest),
                    ),
                  ],
                ),
                const SizedBox(height: 64),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SectionHeader('Nunua mialiko'),
                        GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.92,
                          children: [
                            for (final n in p.packages)
                              _PackageCard(
                                credits: n,
                                price: p.priceFor(n),
                                selected: _custom.text.isEmpty && _selected == n,
                                popular: n == 200,
                                onTap: () => setState(() {
                                  _custom.clear();
                                  _selected = n;
                                }),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _custom,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Au weka idadi unayotaka',
                            hintText: 'mf. 350',
                            helperText: 'Kima cha chini ni mialiko ${p.minPurchase}',
                            prefixIcon: const Icon(Icons.edit_outlined),
                            suffixText: 'mialiko',
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text('Njia ya malipo', style: t.titleMedium),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final m in PaymentMethod.values)
                              ChoiceChip(
                                label: Text(m.label),
                                selected: _method == m,
                                showCheckmark: false,
                                avatar: Icon(
                                  m == PaymentMethod.bank ? Icons.account_balance_outlined : Icons.phone_android,
                                  size: 18,
                                  color: _method == m ? Colors.white : MwalikoColors.plum,
                                ),
                                onSelected: (_) => setState(() => _method = m),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SoftCard(
                          color: MwalikoColors.goldSoft,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline, color: MwalikoColors.plum),
                              const SizedBox(width: 10),
                              Expanded(child: Text(p.paymentInstructions, style: t.bodyMedium)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (_method != PaymentMethod.bank) ...[
                          TextFormField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Namba uliyolipia',
                              hintText: '0712 345 678',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            validator: (v) =>
                                (v ?? '').trim().isEmpty || normalizePhone(v!) != null ? null : 'Namba si sahihi',
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextFormField(
                          controller: _reference,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Namba ya muamala (transaction ID)',
                            hintText: 'mf. SKD81HQ2P1',
                            prefixIcon: Icon(Icons.tag),
                          ),
                          validator: (v) => AppConfig.demo || (v ?? '').trim().length >= 6
                              ? null
                              : 'Weka namba ya muamala uliyopokea kwenye SMS',
                        ),
                        const SizedBox(height: 18),
                        _TotalBar(
                          quantity: valid ? qty : null,
                          amount: valid ? p.priceFor(qty) : null,
                          busy: _busy,
                          onPay: () => _pay(p),
                        ),
                        if (d.payments.isNotEmpty) ...[
                          const SizedBox(height: 28),
                          const SectionHeader('Malipo yako'),
                          SoftCard(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(children: [for (final x in d.payments) _PaymentRow(x)]),
                          ),
                        ],
                        const SizedBox(height: 28),
                        const SectionHeader('Matumizi ya salio'),
                        if (d.transactions.isEmpty)
                          SoftCard(child: Text('Bado hakuna matumizi.', style: t.bodyMedium))
                        else
                          SoftCard(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(children: [for (final x in d.transactions) _TransactionRow(x)]),
                          ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.credits,
    required this.price,
    required this.selected,
    required this.onTap,
    this.popular = false,
  });
  final int credits;
  final int price;
  final bool selected;
  final bool popular;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : MwalikoColors.ink;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selected ? MwalikoColors.plum : MwalikoColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? MwalikoColors.plum : (popular ? MwalikoColors.gold : MwalikoColors.line),
          width: popular && !selected ? 1.8 : 1.2,
        ),
        boxShadow: selected ? MwalikoShadows.lifted : MwalikoShadows.soft,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Stack(
            children: [
              if (popular)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: const BoxDecoration(
                      color: MwalikoColors.gold,
                      borderRadius: BorderRadius.only(topRight: Radius.circular(16), bottomLeft: Radius.circular(10)),
                    ),
                    child: const Text(
                      'Tukio 1',
                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: MwalikoColors.plumDeep),
                    ),
                  ),
                ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatNumber(credits),
                        style: TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: selected ? MwalikoColors.gold : MwalikoColors.plum,
                        ),
                      ),
                      Text(
                        'waalikwa',
                        style: TextStyle(fontSize: 11, color: selected ? Colors.white70 : MwalikoColors.muted),
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        child: Text(
                          formatTzs(price),
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: fg),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalBar extends StatelessWidget {
  const _TotalBar({required this.quantity, required this.amount, required this.busy, required this.onPay});
  final int? quantity;
  final int? amount;
  final bool busy;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
      decoration: BoxDecoration(
        gradient: MwalikoColors.heroGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: MwalikoShadows.lifted,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quantity == null ? 'Chagua kifurushi' : 'Mialiko ${formatNumber(quantity!)}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12.5),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    amount == null ? 'TSh —' : formatTzs(amount!),
                    style: const TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: busy || quantity == null ? null : onPay,
            style: FilledButton.styleFrom(
              backgroundColor: MwalikoColors.gold,
              foregroundColor: MwalikoColors.plumDeep,
              disabledBackgroundColor: Colors.white24,
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: MwalikoColors.plumDeep),
                  )
                : const Text('Lipia'),
          ),
        ],
      ),
    );
  }
}

final _dateFmt = DateFormat('d MMM y, HH:mm', 'sw');

class _PaymentRow extends StatelessWidget {
  const _PaymentRow(this.p);
  final Payment p;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final (label, color) = switch (p.status) {
      'paid' => ('Imelipwa', MwalikoColors.success),
      'pending' => ('Inasubiri', MwalikoColors.warning),
      'failed' => ('Imekataliwa', MwalikoColors.danger),
      _ => ('Imesitishwa', MwalikoColors.muted),
    };
    return ListTile(
      leading: const IconBadge(Icons.payments_outlined, size: 38),
      title: Text('Mialiko ${formatNumber(p.credits)} · ${formatTzs(p.amount)}', style: t.titleSmall),
      subtitle: Text(
        '${p.methodLabel}${p.reference != null ? ' · ${p.reference}' : ''}\n${_dateFmt.format(p.createdAt)}',
        style: t.bodySmall,
      ),
      isThreeLine: true,
      trailing: StatusChip(label, color: color),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow(this.x);
  final CreditTransaction x;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final positive = x.credits > 0;
    final icon = switch (x.kind) {
      'purchase' => Icons.add_card,
      'usage' => Icons.send_outlined,
      'bonus' => Icons.card_giftcard,
      'refund' => Icons.undo,
      _ => Icons.tune,
    };
    return ListTile(
      leading: IconBadge(icon, size: 38, color: positive ? MwalikoColors.success : MwalikoColors.plum),
      title: Text(x.note ?? x.kind, style: t.titleSmall),
      subtitle: Text(_dateFmt.format(x.createdAt), style: t.bodySmall),
      trailing: Text(
        '${positive ? '+' : ''}${x.credits}',
        style: TextStyle(fontWeight: FontWeight.w700, color: positive ? MwalikoColors.success : MwalikoColors.ink),
      ),
    );
  }
}
