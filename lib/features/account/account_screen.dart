import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config.dart';
import '../../core/links.dart';
import '../../core/money.dart';
import '../../core/phone.dart';
import '../../core/theme.dart';
import '../../data/auth_repository.dart';
import '../../data/billing_repository.dart';
import '../../models/billing.dart';
import '../../widgets/async_view.dart';
import '../../widgets/ui.dart';

class _AccountData {
  const _AccountData(this.profile, this.pricing, this.pendingForAdmin);
  final Profile profile;
  final Pricing pricing;
  final int pendingForAdmin;
}

/// Akaunti ya mteja: wasifu, bei, admin na kutoka.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _billing = const BillingRepository();
  late Future<_AccountData> _future = _load();

  Future<_AccountData> _load() async {
    final profile = await AuthRepository.instance.profile();
    final pricing = await _billing.pricing();
    final pending = profile.isAdmin ? (await _billing.pendingPayments()).length : 0;
    return _AccountData(profile, pricing, pending);
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _edit(Profile p) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditProfileSheet(profile: p),
    );
    if (saved == true) _reload();
  }

  Future<void> _signOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Toka kwenye akaunti?'),
        content: const Text('Utahitaji kuingia tena kwa email na nenosiri lako.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hapana')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Toka'),
          ),
        ],
      ),
    );
    if (ok == true) await AuthRepository.instance.signOut();
  }

  Future<void> _deleteAccount() async {
    final messenger = ScaffoldMessenger.of(context);
    final deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (deleted == true) {
      messenger.showSnackBar(const SnackBar(content: Text('Akaunti yako na data yake vimefutwa.')));
    }
  }

  String get _support => [AppConfig.supportPhone, AppConfig.supportEmail].where((s) => s.isNotEmpty).join(' · ');

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: AsyncView(
        future: _future,
        onRetry: _reload,
        builder: (context, d) {
          final p = d.profile;
          final price = d.pricing;
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              HeroHeader(
                bottomPadding: 28,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 82,
                      height: 82,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: MwalikoColors.glass,
                        border: Border.all(color: MwalikoColors.primary, width: 2),
                      ),
                      child: Text(
                        p.initials,
                        style: const TextStyle(
                          fontFamily: MwalikoFonts.display,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: MwalikoColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      p.displayName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: MwalikoFonts.display,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: MwalikoColors.ink,
                      ),
                    ),
                    if (p.businessName != null)
                      Text(
                        p.businessName!,
                        style: const TextStyle(color: MwalikoColors.heroAccent, fontWeight: FontWeight.w600),
                      ),
                    if (p.email != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(p.email!, style: TextStyle(color: MwalikoColors.muted, fontSize: 13)),
                      ),
                    if (p.isAdmin) ...[
                      const SizedBox(height: 10),
                      const StatusChip('ADMIN', color: MwalikoColors.heroAccent, icon: Icons.verified_user_outlined),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (AppConfig.canBuyCredits) ...[
                      const SectionHeader('Bei'),
                      SoftCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  formatTzs(price.pricePerGuest),
                                  style: t.headlineMedium?.copyWith(color: MwalikoColors.primary),
                                ),
                                const SizedBox(width: 6),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    'kwa mwalikwa',
                                    style: t.bodyMedium?.copyWith(color: MwalikoColors.muted),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _PriceLine(
                              Icons.check_circle_outline,
                              'Tukio la watu 200 = ${formatTzs(price.priceFor(200))}',
                            ),
                            _PriceLine(
                              Icons.check_circle_outline,
                              'Kima cha chini: mialiko ${price.minPurchase} '
                              '(${formatTzs(price.priceFor(price.minPurchase))})',
                            ),
                            const _PriceLine(
                              Icons.check_circle_outline,
                              'SMS, WhatsApp na email bila gharama ya ziada',
                            ),
                            const _PriceLine(Icons.check_circle_outline, 'Kumtumia mwalikwa tena ni bure'),
                            const _PriceLine(Icons.check_circle_outline, 'Salio halina muda wa kuisha'),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () => context.go('/wallet'),
                              icon: const Icon(Icons.account_balance_wallet_outlined),
                              label: const Text('Nunua mialiko'),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (p.isAdmin) ...[
                      if (AppConfig.canBuyCredits) const SizedBox(height: 22),
                      const SectionHeader('Usimamizi'),
                      SoftCard(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: const IconBadge(Icons.fact_check_outlined, size: 40),
                          title: Text('Thibitisha malipo', style: t.titleSmall),
                          subtitle: Text(
                            d.pendingForAdmin == 0
                                ? 'Hakuna malipo yanayosubiri'
                                : 'Malipo ${d.pendingForAdmin} yanasubiri',
                            style: t.bodySmall,
                          ),
                          trailing: d.pendingForAdmin > 0
                              ? Badge(label: Text('${d.pendingForAdmin}'), backgroundColor: MwalikoColors.danger)
                              : const Icon(Icons.chevron_right),
                          onTap: () async {
                            await context.push('/admin/payments');
                            _reload();
                          },
                        ),
                      ),
                    ],
                    if (AppConfig.canBuyCredits || p.isAdmin) const SizedBox(height: 22),
                    const SectionHeader('Akaunti'),
                    SoftCard(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const IconBadge(Icons.person_outline, size: 40),
                            title: Text('Wasifu wako', style: t.titleSmall),
                            subtitle: Text(
                              [
                                p.businessName,
                                if (p.phone != null) formatPhone(p.phone),
                              ].whereType<String>().join(' · '),
                              style: t.bodySmall,
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _edit(p),
                          ),
                          const Divider(indent: 16, endIndent: 16),
                          if (_support.isNotEmpty) ...[
                            ListTile(
                              leading: const IconBadge(Icons.support_agent, size: 40),
                              title: Text('Msaada', style: t.titleSmall),
                              subtitle: Text(_support, style: t.bodySmall),
                            ),
                            const Divider(indent: 16, endIndent: 16),
                          ],
                          ListTile(
                            leading: const IconBadge(Icons.logout_rounded, color: MwalikoColors.danger, size: 40),
                            title: Text('Toka', style: t.titleSmall?.copyWith(color: MwalikoColors.danger)),
                            onTap: _signOut,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    const SectionHeader('Faragha'),
                    SoftCard(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const IconBadge(Icons.privacy_tip_outlined, size: 40),
                            title: Text('Sera ya faragha', style: t.titleSmall),
                            trailing: const Icon(Icons.open_in_new, size: 20),
                            onTap: () => openLink(context, AppConfig.privacyUrl),
                          ),
                          const Divider(indent: 16, endIndent: 16),
                          ListTile(
                            leading: const IconBadge(Icons.description_outlined, size: 40),
                            title: Text('Masharti ya matumizi', style: t.titleSmall),
                            trailing: const Icon(Icons.open_in_new, size: 20),
                            onTap: () => openLink(context, AppConfig.termsUrl),
                          ),
                          const Divider(indent: 16, endIndent: 16),
                          ListTile(
                            leading: const IconBadge(
                              Icons.delete_forever_outlined,
                              color: MwalikoColors.danger,
                              size: 40,
                            ),
                            title: Text('Futa akaunti', style: t.titleSmall?.copyWith(color: MwalikoColors.danger)),
                            subtitle: Text('Inafuta akaunti na data yako yote', style: t.bodySmall),
                            onTap: _deleteAccount,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      AppConfig.demo ? "U'r Invente by Tembo Cloud · toleo la demo" : "U'r Invente by Tembo Cloud",
                      textAlign: TextAlign.center,
                      style: t.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Uthibitisho wa kufuta akaunti: mteja anaandika FUTA, kisha akaunti inafutwa hapa hapa.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  bool get _ready => _confirm.text.trim().toUpperCase() == 'FUTA';

  @override
  void dispose() {
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthRepository.instance.deleteAccount();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = friendlyError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const IconBadge(Icons.delete_forever_outlined, color: MwalikoColors.danger, size: 52),
      title: const Text('Futa akaunti?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Akaunti yako itafutwa kabisa pamoja na matukio, waalikwa, kadi, salio lililobaki na historia ya malipo. '
            'Hili haliwezi kurudishwa.',
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _confirm,
            enabled: !_busy,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Andika FUTA kuthibitisha'),
            onChanged: (_) => setState(() {}),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: MwalikoColors.danger)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: const Text('Hapana')),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 44),
            backgroundColor: MwalikoColors.danger,
            foregroundColor: Colors.white,
          ),
          onPressed: _ready && !_busy ? _delete : null,
          child: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                )
              : const Text('Futa kabisa'),
        ),
      ],
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Icon(icon, size: 18, color: MwalikoColors.success),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    ),
  );
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.profile});
  final Profile profile;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final _name = TextEditingController(text: widget.profile.fullName);
  late final _business = TextEditingController(text: widget.profile.businessName);
  late final _phone = TextEditingController(text: widget.profile.phone);
  final _form = GlobalKey<FormState>();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _business.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await AuthRepository.instance.updateProfile(
        fullName: _name.text.trim(),
        businessName: _business.text.trim().isEmpty ? null : _business.text.trim(),
        phone: normalizePhone(_phone.text),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Wasifu wako', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Jina kamili', prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => (v ?? '').trim().length < 3 ? 'Weka jina lako' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _business,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Jina la biashara',
                prefixIcon: Icon(Icons.storefront_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Namba ya simu', prefixIcon: Icon(Icons.phone_outlined)),
              validator: (v) => (v ?? '').trim().isEmpty || normalizePhone(v!) != null ? null : 'Namba si sahihi',
            ),
            const SizedBox(height: 18),
            FilledButton(onPressed: _busy ? null : _save, child: const Text('Hifadhi')),
          ],
        ),
      ),
    );
  }
}
