import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart';
import '../models/billing.dart';
import 'demo_store.dart';
import 'supabase.dart';

/// Akaunti za wateja wa Mwaliko (SaaS): kuingia, kujisajili, kutoka na wasifu.
class AuthRepository extends ChangeNotifier {
  AuthRepository._() {
    if (!AppConfig.demo) {
      _sub = sb.auth.onAuthStateChange.listen((_) => notifyListeners());
    }
  }

  static final instance = AuthRepository._();

  StreamSubscription<AuthState>? _sub;
  static DemoStore get _demo => DemoStore.instance;

  bool get isSignedIn => AppConfig.demo ? _demo.signedInUser != null : sb.auth.currentSession != null;

  Future<void> signIn({required String email, required String password}) async {
    if (AppConfig.demo) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      _demo.signIn(email: email);
      notifyListeners();
      return;
    }
    await sb.auth.signInWithPassword(email: email.trim(), password: password);
  }

  /// Inarudisha `true` kama mteja ameingia moja kwa moja, `false` kama anatakiwa kuthibitisha email kwanza.
  Future<bool> signUp({
    required String fullName,
    String? businessName,
    String? phone,
    required String email,
    required String password,
  }) async {
    if (AppConfig.demo) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      _demo.signIn(email: email, fullName: fullName, businessName: businessName, phone: phone);
      notifyListeners();
      return true;
    }
    final res = await sb.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': fullName, 'business_name': businessName, 'phone': phone},
    );
    return res.session != null;
  }

  Future<void> resetPassword(String email) async {
    if (AppConfig.demo) return;
    await sb.auth.resetPasswordForEmail(email.trim());
  }

  Future<void> signOut() async {
    if (AppConfig.demo) {
      _demo.signedInUser = null;
      notifyListeners();
      return;
    }
    await sb.auth.signOut();
  }

  Future<Profile> profile() async {
    if (AppConfig.demo) return Profile.fromJson(_demo.signedInUser!, email: _demo.signedInUser!['email'] as String?);
    final user = sb.auth.currentUser!;
    final row = await sb.from('profiles').select().eq('id', user.id).maybeSingle();
    return row == null ? Profile(id: user.id, email: user.email) : Profile.fromJson(row, email: user.email);
  }

  Future<void> updateProfile({String? fullName, String? businessName, String? phone}) async {
    final fields = {'full_name': fullName, 'business_name': businessName, 'phone': phone};
    if (AppConfig.demo) {
      _demo.signedInUser!.addAll(fields);
      notifyListeners();
      return;
    }
    await sb.from('profiles').update(fields).eq('id', currentUserId);
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
