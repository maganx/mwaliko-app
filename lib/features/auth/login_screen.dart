import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme.dart';
import '../../data/supabase.dart';
import '../../widgets/async_view.dart';

/// Kuingia kwa email: mtumiaji anapokea namba ya siri (OTP) ya tarakimu 6.
/// (Login kwa namba ya simu inaweza kuongezwa baadaye kupitia SMS provider wa Supabase.)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _email.text.trim();
    if (!email.contains('@')) return showSnack(context, 'Weka email sahihi');
    setState(() => _busy = true);
    try {
      await sb.auth.signInWithOtp(email: email, shouldCreateUser: true);
      if (!mounted) return;
      setState(() => _codeSent = true);
      showSnack(context, 'Tumekutumia namba ya siri kwenye $email');
    } on AuthException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    setState(() => _busy = true);
    try {
      await sb.auth.verifyOTP(type: OtpType.email, email: _email.text.trim(), token: _code.text.trim());
      // router itampeleka kwenye matukio yake
    } on AuthException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.mail_outline_rounded, size: 56, color: MwalikoColors.maroon),
                  const SizedBox(height: 12),
                  const Text(
                    'Mwaliko',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'GreatVibes', fontSize: 56, color: MwalikoColors.maroon),
                  ),
                  const Text('Tuma kadi za mwaliko kwa SMS, WhatsApp na email', textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _email,
                    enabled: !_codeSent,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Email yako'),
                  ),
                  if (_codeSent) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _code,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      decoration: const InputDecoration(labelText: 'Namba ya siri (tarakimu 6)'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _busy ? null : (_codeSent ? _verify : _sendCode),
                    child: _busy
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_codeSent ? 'Ingia' : 'Nitumie namba ya siri'),
                  ),
                  if (_codeSent)
                    TextButton(
                      onPressed: _busy ? null : () => setState(() => _codeSent = false),
                      child: const Text('Badilisha email'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
