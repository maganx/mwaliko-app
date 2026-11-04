import 'dart:ui';

/// Mpangilio wa kadi ya tukio: ama template ya Mwaliko, ama design ya mteja mwenyewe.
/// Huhifadhiwa kama JSON kwenye `events.card_config`.
class CardConfig {
  const CardConfig({
    this.mode = CardMode.template,
    this.paletteId = 'dhahabu_usiku',
    this.ornamentId = 'gold_frame',
    this.fontPairId = 'classic',
    this.layoutId = 'centered',
    this.customImagePath,
    this.customAspect = 4 / 5,
    this.namePosition = const Offset(0.5, 0.78),
    this.nameSize = 0.07,
    this.nameColor = 0xFF1A1A1A,
    this.nameFont = 'GreatVibes',
    this.showQr = true,
    this.qrPosition = const Offset(0.85, 0.88),
    this.qrSize = 0.16,
  });

  final CardMode mode;

  // Template
  final String paletteId;
  final String ornamentId;
  final String fontPairId;
  final String layoutId;

  // Design ya mteja
  final String? customImagePath;
  final double customAspect; // upana / urefu
  final Offset namePosition; // katikati ya jina, kwa sehemu (0..1) ya upana/urefu
  final double nameSize; // ukubwa wa herufi kama sehemu ya upana
  final int nameColor;
  final String nameFont;
  final bool showQr;
  final Offset qrPosition; // katikati ya QR, kwa sehemu (0..1)
  final double qrSize; // upana wa QR kama sehemu ya upana wa kadi

  bool get isCustom => mode == CardMode.custom && customImagePath != null;

  /// Uwiano wa kadi (upana / urefu).
  double get aspectRatio => isCustom ? customAspect : 4 / 5;

  CardConfig copyWith({
    CardMode? mode,
    String? paletteId,
    String? ornamentId,
    String? fontPairId,
    String? layoutId,
    String? customImagePath,
    double? customAspect,
    Offset? namePosition,
    double? nameSize,
    int? nameColor,
    String? nameFont,
    bool? showQr,
    Offset? qrPosition,
    double? qrSize,
  }) => CardConfig(
    mode: mode ?? this.mode,
    paletteId: paletteId ?? this.paletteId,
    ornamentId: ornamentId ?? this.ornamentId,
    fontPairId: fontPairId ?? this.fontPairId,
    layoutId: layoutId ?? this.layoutId,
    customImagePath: customImagePath ?? this.customImagePath,
    customAspect: customAspect ?? this.customAspect,
    namePosition: namePosition ?? this.namePosition,
    nameSize: nameSize ?? this.nameSize,
    nameColor: nameColor ?? this.nameColor,
    nameFont: nameFont ?? this.nameFont,
    showQr: showQr ?? this.showQr,
    qrPosition: qrPosition ?? this.qrPosition,
    qrSize: qrSize ?? this.qrSize,
  );

  factory CardConfig.fromJson(Map<String, dynamic>? j) {
    if (j == null || j.isEmpty) return const CardConfig();
    double d(Object? v, double fb) => v is num ? v.toDouble() : fb;
    Offset o(Object? v, Offset fb) => v is List && v.length == 2 ? Offset(d(v[0], fb.dx), d(v[1], fb.dy)) : fb;
    const fb = CardConfig();
    return CardConfig(
      mode: j['mode'] == 'custom' ? CardMode.custom : CardMode.template,
      paletteId: j['palette'] as String? ?? fb.paletteId,
      ornamentId: j['ornament'] as String? ?? fb.ornamentId,
      fontPairId: j['fonts'] as String? ?? fb.fontPairId,
      layoutId: j['layout'] as String? ?? fb.layoutId,
      customImagePath: j['custom_image_path'] as String?,
      customAspect: d(j['custom_aspect'], fb.customAspect),
      namePosition: o(j['name_pos'], fb.namePosition),
      nameSize: d(j['name_size'], fb.nameSize),
      nameColor: (j['name_color'] as num?)?.toInt() ?? fb.nameColor,
      nameFont: j['name_font'] as String? ?? fb.nameFont,
      showQr: j['show_qr'] as bool? ?? fb.showQr,
      qrPosition: o(j['qr_pos'], fb.qrPosition),
      qrSize: d(j['qr_size'], fb.qrSize),
    );
  }

  Map<String, dynamic> toJson() => {
    'mode': mode.name,
    'palette': paletteId,
    'ornament': ornamentId,
    'fonts': fontPairId,
    'layout': layoutId,
    if (customImagePath != null) 'custom_image_path': customImagePath,
    'custom_aspect': customAspect,
    'name_pos': [namePosition.dx, namePosition.dy],
    'name_size': nameSize,
    'name_color': nameColor,
    'name_font': nameFont,
    'show_qr': showQr,
    'qr_pos': [qrPosition.dx, qrPosition.dy],
    'qr_size': qrSize,
  };
}

enum CardMode { template, custom }
