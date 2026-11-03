import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient get sb => Supabase.instance.client;

String get currentUserId {
  final id = sb.auth.currentUser?.id;
  if (id == null) throw StateError('Hujaingia (login)');
  return id;
}
