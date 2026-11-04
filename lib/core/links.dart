import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/async_view.dart';

/// Inafungua link (sera ya faragha, masharti, n.k.) kwenye kivinjari.
Future<void> openLink(BuildContext context, String url) async {
  var ok = false;
  try {
    ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {}
  if (!ok && context.mounted) showSnack(context, 'Imeshindikana kufungua $url');
}
