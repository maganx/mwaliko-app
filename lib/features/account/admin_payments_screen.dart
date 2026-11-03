import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/money.dart';
import '../../core/phone.dart';
import '../../core/theme.dart';
import '../../data/billing_repository.dart';
import '../../models/billing.dart';
import '../../widgets/async_view.dart';
import '../../widgets/ui.dart';

/// Admin: malipo yanayosubiri kuthibitishwa. Ukithibitisha, salio la mteja linaongezwa.
class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  final _repo = const BillingRepository();
  late Future<List<Payment>> _future = _repo.pendingPayments();
  final _busy = <String>{};

  void _reload() => setState(() => _future = _repo.pendingPayments());

  Future<void> _act(Payment p, {required bool confirm}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(confirm ? 'Thibitisha malipo?' : 'Kataa malipo?'),
        content: Text(
          confirm
              ? 'Hakikisha umepokea ${formatTzs(p.amount)} (${p.reference ?? 'bila namba ya muamala'}). '
                    'Mteja ataongezewa mialiko ${p.credits}.'
              : 'Ombi la ${p.customerName ?? 'mteja'} la ${formatTzs(p.amount)} litakataliwa.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hapana')),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 44),
              backgroundColor: confirm ? MwalikoColors.success : MwalikoColors.danger,
            ),
            onPressed: () => Navigator.pop(c, true),
            child: Text(confirm ? 'Thibitisha' : 'Kataa'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy.add(p.id));
    try {
      if (confirm) {
        await _repo.confirmPayment(p.id);
      } else {
        await _repo.rejectPayment(p.id);
      }
      if (mounted) showSnack(context, confirm ? 'Malipo yamethibitishwa' : 'Malipo yamekataliwa');
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
    } finally {
      _busy.remove(p.id);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final fmt = DateFormat('d MMM y, HH:mm', 'sw');
    return Scaffold(
      appBar: AppBar(title: const Text('Malipo yanayosubiri')),
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: AsyncView(
          future: _future,
          onRetry: _reload,
          builder: (context, payments) {
            if (payments.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 80),
                  EmptyState(
                    icon: Icons.task_alt,
                    title: 'Hakuna kinachosubiri',
                    message: 'Malipo mapya ya wateja yataonekana hapa.',
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: payments.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final p = payments[i];
                final busy = _busy.contains(p.id);
                return SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          InitialsAvatar(p.customerName ?? 'Mteja'),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.customerName ?? 'Mteja', style: t.titleMedium),
                                Text(fmt.format(p.createdAt), style: t.bodySmall),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatTzs(p.amount),
                                style: t.titleMedium?.copyWith(color: MwalikoColors.plum, fontWeight: FontWeight.w700),
                              ),
                              Text('mialiko ${formatNumber(p.credits)}', style: t.bodySmall),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          StatusChip(p.methodLabel, color: MwalikoColors.plum, icon: Icons.phone_android),
                          if (p.phone != null) StatusChip(formatPhone(p.phone), color: MwalikoColors.muted),
                          StatusChip(
                            p.reference ?? 'Hakuna namba ya muamala',
                            color: p.reference == null ? MwalikoColors.danger : MwalikoColors.success,
                            icon: Icons.tag,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: busy ? null : () => _act(p, confirm: false),
                              style: OutlinedButton.styleFrom(foregroundColor: MwalikoColors.danger),
                              child: const Text('Kataa'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: busy ? null : () => _act(p, confirm: true),
                              style: FilledButton.styleFrom(
                                backgroundColor: MwalikoColors.success,
                                minimumSize: const Size(0, 50),
                              ),
                              child: const Text('Thibitisha'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
