import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase.dart';

/// Kadi zinahifadhiwa kwenye bucket "cards":
///   {owner_id}/{event_id}/design-{time}.{ext}   design ya mteja
///   {owner_id}/{event_id}/guests/{guest_id}.png kadi binafsi ya kila mwalikwa
class CardsRepository {
  const CardsRepository();

  static const bucket = 'cards';

  Future<String> uploadDesign(String eventId, Uint8List bytes, String extension) async {
    final ext = extension.toLowerCase().replaceAll('.', '');
    final path = '$currentUserId/$eventId/design-${DateTime.now().millisecondsSinceEpoch}.$ext';
    await sb.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(upsert: true, contentType: ext == 'png' ? 'image/png' : 'image/jpeg'),
        );
    return path;
  }

  Future<Uint8List> download(String path) => sb.storage.from(bucket).download(path);

  Future<String> uploadGuestCard(String eventId, String guestId, Uint8List png) async {
    final path = '$currentUserId/$eventId/guests/$guestId.png';
    await sb.storage.from(bucket).uploadBinary(
          path,
          png,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/png'),
        );
    await sb.from('guests').update({'card_path': path}).eq('id', guestId);
    return path;
  }

  String publicUrl(String path) => sb.storage.from(bucket).getPublicUrl(path);
}
