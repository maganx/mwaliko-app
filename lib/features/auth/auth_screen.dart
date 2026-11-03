import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config.dart';
import '../../core/phone.dart';
import '../../core/theme.dart';
import '../../data/auth_repository.dart';
import '../../models/card_config.dart';
import '../../models/event.dart';
import '../../widgets/async_view.dart';
import '../cards/invitation_card.dart';

/// Kuingia na kujisajili kwa wateja wa Mwaliko.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = AuthRepository.instance;
  final _form = GlobalKey<FormState>();
  bool _signUp = false;
  bool _busy = false;
  bool _hidePassword = true;

  final _name = TextEditingController();
  final _business = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController(text: AppConfig.demo ? 'asha@mfano.co.tz' : null);
  final _password = TextEditingController(text: AppConfig.demo ? 'mwaliko2026' : null);

  @override
  void dispose() {
    for (final c in [_name, _business, _phone, _email, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      if (_signUp) {
        final signedIn = await _auth.signUp(
          fullName: _name.text.trim(),
          businessName: _business.text.trim().isEmpty ? null : _business.text.trim(),
          phone: normalizePhone(_phone.text),
          email: _email.text.trim(),
          password: _password.text,
        );
        if (!signedIn && mounted) {
          showSnack(context, 'Akaunti imefunguliwa. Fungua email yako kuthibitisha, kisha uingie.');
          setState(() => _signUp = false);
        }
      } else {
        await _auth.signIn(email: _email.text.trim(), password: _password.text);
      }
    } on AuthException catch (e) {
      if (mounted) showSnack(context, _authMessage(e));
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _authMessage(AuthException e) {
    final m = e.message.toLowerCase();
    if (m.contains('invalid login')) return 'Email au nenosiri si sahihi.';
    if (m.contains('already registered')) return 'Email hii tayari ina akaunti. Ingia badala yake.';
    if (m.contains('email not confirmed')) return 'Thibitisha email yako kwanza (angalia inbox).';
    return e.message;
  }

  Future<void> _forgot() async {
    if (!_email.text.contains('@')) {
      showSnack(context, 'Andika email yako kwanza, kisha bonyeza "Umesahau nenosiri?"');
      return;
    }
    await _auth.resetPassword(_email.text);
    if (mounted) showSnack(context, 'Tumekutumia link ya kubadilisha nenosiri kwenye ${_email.text.trim()}');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: MwalikoColors.plumDeep,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: MwalikoColors.heroGradient),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Hero(compact: _signUp)),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Container(
                decoration: const BoxDecoration(
                  color: MwalikoColors.cream,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
                child: SafeArea(
                  top: false,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Form(
                        key: _form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(_signUp ? 'Fungua akaunti' : 'Karibu tena', style: textTheme.headlineMedium),
                            const SizedBox(height: 4),
                            Text(
                              _signUp
                                  ? 'Anza kutuma kadi nzuri za mwaliko kwa wateja wako.'
                                  : 'Ingia kusimamia matukio na mialiko yako.',
                              style: textTheme.bodyMedium?.copyWith(color: MwalikoColors.muted),
                            ),
                            const SizedBox(height: 22),
                            if (_signUp) ...[
                              TextFormField(
                                controller: _name,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  labelText: 'Jina lako kamili',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (v) => (v == null || v.trim().length < 3) ? 'Weka jina lako' : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _business,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  labelText: 'Jina la biashara (si lazima)',
                                  prefixIcon: Icon(Icons.storefront_outlined),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _phone,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Namba ya simu',
                                  hintText: '0712 345 678',
                                  prefixIcon: Icon(Icons.phone_outlined),
                                ),
                                validator: (v) => normalizePhone(v ?? '') == null ? 'Weka namba sahihi ya simu' : null,
                              ),
                              const SizedBox(height: 12),
                            ],
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.mail_outline),
                              ),
                              validator: (v) =>
                                  (v == null || !v.contains('@') || !v.contains('.')) ? 'Weka email sahihi' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _password,
                              obscureText: _hidePassword,
                              autofillHints: [_signUp ? AutofillHints.newPassword : AutofillHints.password],
                              decoration: InputDecoration(
                                labelText: 'Nenosiri',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  tooltip: _hidePassword ? 'Onyesha' : 'Ficha',
                                  icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                  onPressed: () => setState(() => _hidePassword = !_hidePassword),
                                ),
                              ),
                              validator: (v) =>
                                  (v == null || v.length < 8) ? 'Nenosiri liwe na herufi 8 au zaidi' : null,
                            ),
                            if (!_signUp)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(onPressed: _forgot, child: const Text('Umesahau nenosiri?')),
                              )
                            else
                              const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _busy ? null : _submit,
                              child: _busy
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                                    )
                                  : Text(_signUp ? 'Fungua akaunti' : 'Ingia'),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  _signUp ? 'Una akaunti tayari?' : 'Mgeni kwenye Mwaliko?',
                                  style: textTheme.bodyMedium?.copyWith(color: MwalikoColors.muted),
                                ),
                                TextButton(
                                  onPressed: _busy ? null : () => setState(() => _signUp = !_signUp),
                                  child: Text(_signUp ? 'Ingia' : 'Jisajili bure'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Juu ya skrini ya kuingia: kadi tatu za mfano zilizopangwa kama feni.
class _Hero extends StatelessWidget {
  const _Hero({required this.compact});
  final bool compact;

  static final _sample = EventModel(
    title: 'Harusi ya Amani & Neema',
    eventType: 'harusi',
    hostNames: 'Familia ya Mussa Juma',
    eventDate: DateTime(2026, 12, 12, 16),
    venue: 'Mlimani City Hall',
  );

  static const _configs = [
    CardConfig(paletteId: 'waridi', ornamentId: 'florals', fontPairId: 'classic', layoutId: 'framed'),
    CardConfig(paletteId: 'dhahabu_usiku', ornamentId: 'gold_frame', fontPairId: 'royal', layoutId: 'centered'),
    CardConfig(paletteId: 'kitenge', ornamentId: 'kitenge', fontPairId: 'friendly', layoutId: 'banner'),
  ];

  static const _names = ['Bi. Rehema', 'Bw. Juma', 'Dkt. Neema'];

  Widget _card(int i, double height) => Container(
    height: height,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 22, offset: const Offset(0, 12))],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: InvitationCard(event: _sample, config: _configs[i], guestName: _names[i]),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final cardHeight = compact ? 150.0 : 206.0;
    final shift = cardHeight * 0.5;
    return SafeArea(
      bottom: false,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            children: [
              SizedBox(
                height: cardHeight + 24,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // pembeni kwanza, katikati juu yake
                    for (final i in const [0, 2, 1])
                      Transform.translate(
                        offset: Offset((i - 1) * shift, i == 1 ? -6 : 8),
                        child: Transform.rotate(angle: (i - 1) * 0.14, child: _card(i, cardHeight)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Mwaliko',
                style: TextStyle(fontFamily: 'GreatVibes', fontSize: 54, color: MwalikoColors.gold, height: 1.1),
              ),
              Text(
                'Kadi za mwaliko za kidijitali kwa SMS, WhatsApp na email',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontSize: 13.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
