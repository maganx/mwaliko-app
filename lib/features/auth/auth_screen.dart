import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config.dart';
import '../../core/links.dart';
import '../../core/phone.dart';
import '../../core/theme.dart';
import '../../data/auth_repository.dart';
import '../../models/card_config.dart';
import '../../models/event.dart';
import '../../widgets/async_view.dart';
import '../../widgets/ui.dart';
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

  Widget _formBody(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_signUp ? 'Fungua akaunti' : 'Karibu tena', style: textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            _signUp ? 'Anza kutuma kadi nzuri za mwaliko kwa wageni wako.' : 'Ingia kusimamia matukio na mialiko yako.',
            style: textTheme.bodyMedium?.copyWith(color: MwalikoColors.muted),
          ),
          const SizedBox(height: 22),
          if (_signUp) ...[
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Jina lako kamili', prefixIcon: Icon(Icons.person_outline)),
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
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
            validator: (v) => (v == null || !v.contains('@') || !v.contains('.')) ? 'Weka email sahihi' : null,
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
            validator: (v) => (v == null || v.length < 8) ? 'Nenosiri liwe na herufi 8 au zaidi' : null,
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
          if (_signUp) ...[
            const SizedBox(height: 10),
            Text(
              'Kwa kufungua akaunti unakubali masharti ya matumizi na sera ya faragha.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall,
            ),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                TextButton(onPressed: () => openLink(context, AppConfig.termsUrl), child: const Text('Masharti')),
                TextButton(
                  onPressed: () => openLink(context, AppConfig.privacyUrl),
                  child: const Text('Sera ya faragha'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                _signUp ? 'Una akaunti tayari?' : "Mgeni kwenye U'r Invente?",
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
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isWideLayout(context)) {
      // Web kwenye kompyuta: maelezo ya huduma upande wa kushoto, fomu upande wa kulia.
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Row(
                  children: [
                    const Expanded(child: _WideHero()),
                    const SizedBox(width: 56),
                    SizedBox(
                      width: 440,
                      child: Glass(
                        color: MwalikoColors.glassStrong,
                        radius: 28,
                        child: Padding(padding: const EdgeInsets.fromLTRB(30, 32, 30, 20), child: _formBody(context)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Hero(compact: _signUp)),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Align(
                alignment: Alignment.topCenter,
                child: Glass(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
                    child: SafeArea(
                      top: false,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: _formBody(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kadi tatu za mfano zilizopangwa kama feni.
class _CardFan extends StatelessWidget {
  const _CardFan({required this.cardHeight});
  final double cardHeight;

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

  Widget _card(int i) => Container(
    height: cardHeight,
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
    final shift = cardHeight * 0.5;
    return SizedBox(
      height: cardHeight + 24,
      width: cardHeight * 1.9,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // pembeni kwanza, katikati juu yake
          for (final i in const [0, 2, 1])
            Transform.translate(
              offset: Offset((i - 1) * shift, i == 1 ? -6 : 8),
              child: Transform.rotate(angle: (i - 1) * 0.14, child: _card(i)),
            ),
        ],
      ),
    );
  }
}

/// Juu ya skrini ya kuingia (simu): nembo, kadi za mfano na kauli mbiu.
class _Hero extends StatelessWidget {
  const _Hero({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          child: Column(
            children: [
              const BrandLogo(height: 58),
              const SizedBox(height: 10),
              _CardFan(cardHeight: compact ? 120.0 : 170.0),
              const SizedBox(height: 10),
              const Text(
                'Mialiko inayofika, wageni wanaofika.',
                textAlign: TextAlign.center,
                style: TextStyle(color: MwalikoColors.muted, fontSize: 13.5, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Upande wa kushoto wa ukurasa wa kuingia kwenye kompyuta: huduma inafanya nini.
class _WideHero extends StatelessWidget {
  const _WideHero();

  static const _features = [
    (
      Icons.palette_outlined,
      'Kadi ya kipekee kwa kila mgeni',
      'Chagua design au pakia yako, jina la mgeni linaingia lenyewe.',
    ),
    (Icons.send_outlined, 'SMS, WhatsApp na email', 'Tuma mialiko yote kwa mbofyo mmoja.'),
    (Icons.qr_code_scanner, 'RSVP na check-in', 'Wageni wanajibu mtandaoni, mlangoni unascan QR code.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const BrandLogo(height: 56),
        const SizedBox(height: 36),
        const Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'Mialiko inayofika,\n'),
              TextSpan(
                text: 'wageni wanaofika.',
                style: TextStyle(color: MwalikoColors.primary),
              ),
            ],
          ),
          style: TextStyle(
            fontFamily: MwalikoFonts.display,
            fontSize: 44,
            height: 1.12,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: MwalikoColors.ink,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Tengeneza kadi nzuri za mwaliko, zitume kwa wageni wako na ufuatilie nani anakuja, '
          'yote sehemu moja.',
          style: TextStyle(fontSize: 17, height: 1.5, color: MwalikoColors.muted),
        ),
        const SizedBox(height: 26),
        const Padding(padding: EdgeInsets.only(left: 8), child: _CardFan(cardHeight: 150)),
        const SizedBox(height: 30),
        for (final (icon, title, text) in _features)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                IconBadge(icon, size: 46),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5, color: MwalikoColors.ink),
                      ),
                      const SizedBox(height: 2),
                      Text(text, style: const TextStyle(fontSize: 13.5, color: MwalikoColors.muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
