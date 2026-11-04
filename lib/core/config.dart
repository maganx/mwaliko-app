import 'package:flutter/foundation.dart';

/// Mipangilio inayowekwa wakati wa kujenga app:
///   flutter run --dart-define-from-file=env.json
/// (angalia env.example.json)
class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Publishable key (au anon key ya zamani) kutoka Supabase > Project Settings > API.
  static const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// Link ya ukurasa wa RSVP (folda rsvp_web/), mf. https://mwaliko.co.tz/rsvp
  static const rsvpBaseUrl = String.fromEnvironment('RSVP_BASE_URL');

  /// Link ya RSVP ya mwalikwa (ukurasa wa kadi yake). Bila RSVP_BASE_URL: `{webBaseUrl}/rsvp/`.
  static String rsvpLink(String? token) =>
      '${rsvpBaseUrl.isNotEmpty ? rsvpBaseUrl : '$webBaseUrl/rsvp/'}?t=${token ?? ''}';

  /// Toleo la majaribio lenye data ya mfano, bila Supabase:
  ///   flutter run --dart-define=DEMO=true
  static const demo = bool.fromEnvironment('DEMO');

  /// Ukanda wa "DEMO" juu ya demo (zima kwa picha za stores: --dart-define=DEMO_BANNER=false).
  static const demoBanner = bool.fromEnvironment('DEMO_BANNER', defaultValue: true);

  static bool get isConfigured => supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;

  /// Anwani ya web app; sera ya faragha, masharti na kufuta akaunti zinakaa hapa.
  static const webBaseUrl = String.fromEnvironment(
    'WEB_BASE_URL',
    defaultValue: 'https://maganx.github.io/mwaliko-app',
  );
  static String get privacyUrl => '$webBaseUrl/privacy.html';
  static String get termsUrl => '$webBaseUrl/terms.html';

  /// Mawasiliano ya msaada yanayoonyeshwa kwenye Akaunti (mf. +255 7xx xxx xxx, msaada@domain).
  static const supportPhone = String.fromEnvironment('SUPPORT_PHONE', defaultValue: demo ? '+255 700 000 000' : '');
  static const supportEmail = String.fromEnvironment('SUPPORT_EMAIL');

  /// Kununua salio ndani ya app. Kwenye app ya iPhone imezimwa (App Store 3.1.3(f)): hakuna manunuzi ndani ya
  /// app wala kumwelekeza mteja anunue mahali pengine. Lazimisha kwa --dart-define=IN_APP_PURCHASES=true|false.
  static const _purchasesOverride = String.fromEnvironment('IN_APP_PURCHASES');
  static bool get canBuyCredits => _purchasesOverride.isNotEmpty
      ? _purchasesOverride == 'true'
      : kIsWeb || defaultTargetPlatform != TargetPlatform.iOS;
}
