import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart';
import 'demo_store.dart';
import 'supabase.dart';

/// Kadi zinahifadhiwa kwenye bucket "cards":
///   {owner_id}/{event_id}/design-{time}.{ext}   design ya mteja
///   {owner_id}/{event_id}/photo-{time}.{ext}    picha ya mteja ndani ya template
///   {owner_id}/{event_id}/guests/{guest_id}-{alama}.png kadi binafsi ya kila mwalikwa
///     (alama = CardExporter.fingerprint: design au maelezo yakibadilika, kadi mpya inapata jina jipya;
///     ya zamani inabaki ili email zilizokwisha tumwa zisipoteze picha)
class CardsRepository {
  const CardsRepository();

  static const bucket = 'cards';

  static DemoStore get _demo => DemoStore.instance;

  String get _owner => AppConfig.demo ? 'demo' : currentUserId;

  /// [kind]: `design` (kadi nzima ya mteja) au `photo` (picha inayowekwa ndani ya template).
  Future<String> uploadDesign(String eventId, Uint8List bytes, String extension, {String kind = 'design'}) async {
    final ext = extension.toLowerCase().replaceAll('.', '');
    final path = '$_owner/$eventId/$kind-${DateTime.now().millisecondsSinceEpoch}.$ext';
    if (AppConfig.demo) {
      _demo.files[path] = bytes;
      return path;
    }
    await sb.storage
        .from(bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(upsert: true, contentType: ext == 'png' ? 'image/png' : 'image/jpeg'),
        );
    return path;
  }

  Future<Uint8List> download(String path) async {
    if (AppConfig.demo) return _demo.files[path]!;
    return sb.storage.from(bucket).download(path);
  }

  Future<String> uploadGuestCard(String eventId, String guestId, Uint8List png, {String? fingerprint}) async {
    final path = '$_owner/$eventId/guests/$guestId${fingerprint == null ? '' : '-$fingerprint'}.png';
    if (AppConfig.demo) {
      _demo.files[path] = png;
      _demo.guests[guestId]!['card_path'] = path;
      return path;
    }
    await sb.storage
        .from(bucket)
        .uploadBinary(path, png, fileOptions: const FileOptions(upsert: true, contentType: 'image/png'));
    await sb.from('guests').update({'card_path': path}).eq('id', guestId);
    return path;
  }

  String publicUrl(String path) => sb.storage.from(bucket).getPublicUrl(path);

  /// Picha ya kadi/design kwa kuonyesha kwenye skrini.
  ImageProvider imageFor(String path) {
    if (AppConfig.demo) {
      return MemoryImage(_demo.files[path] ?? _transparentPng);
    }
    return NetworkImage(publicUrl(path));
  }

  /// PNG ya pixel 1 isiyoonekana (kama picha haipo kwenye demo).
  static final _transparentPng = Uint8List.fromList(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, //
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82,
  ]);

  /// PNG ya kadi ya mwalikwa (kwa kushiriki).
  Future<Uint8List> cardBytes(String path) async {
    if (AppConfig.demo) return _demo.files[path]!;
    final res = await http.get(Uri.parse(publicUrl(path)));
    return res.bodyBytes;
  }
}
