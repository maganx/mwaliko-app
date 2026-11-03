/// Mipangilio inayowekwa wakati wa kujenga app:
///   flutter run --dart-define-from-file=env.json
/// (angalia env.example.json)
class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Publishable key (au anon key ya zamani) kutoka Supabase > Project Settings > API.
  static const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// Link ya ukurasa wa RSVP (folda rsvp_web/), mf. https://mwaliko.co.tz/rsvp
  static const rsvpBaseUrl = String.fromEnvironment('RSVP_BASE_URL');

  /// Toleo la majaribio lenye data ya mfano, bila Supabase:
  ///   flutter run --dart-define=DEMO=true
  static const demo = bool.fromEnvironment('DEMO');

  static bool get isConfigured => supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;
}
