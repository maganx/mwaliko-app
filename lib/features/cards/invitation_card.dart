import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/event_types.dart';
import '../../core/swahili_time.dart';
import '../../models/card_config.dart';
import '../../models/event.dart';
import 'card_styles.dart';
import 'ornaments.dart';

/// Kadi ya mwaliko. Inachorwa kwenye ukubwa wa kudumu ([designSize]) na
/// kupanuliwa/kupunguzwa kutoshea nafasi iliyopo, ili preview na PNG zifanane kabisa.
class InvitationCard extends StatelessWidget {
  const InvitationCard({
    super.key,
    required this.event,
    required this.config,
    this.guestName,
    this.seats,
    this.qrData,
    this.customImage,
    this.customImageProvider,
  });

  final EventModel event;
  final CardConfig config;

  /// Jina la mwalikwa. Likiwa null, kadi inaonyesha "Jina la Mwalikwa" (preview).
  final String? guestName;
  final int? seats;

  /// Data ya QR code (token ya mwalikwa). Ikiwa null, QR ya mfano inaonyeshwa.
  final String? qrData;

  /// Picha ya design ya mteja iliyokwisha decode-iwa (kwa kutengeneza PNG bila kusubiri).
  final ui.Image? customImage;

  /// Au picha kama ImageProvider (kwa preview kwenye skrini).
  final ImageProvider? customImageProvider;

  static const templateSize = Size(540, 675);

  static Size designSizeFor(CardConfig c) =>
      c.isCustom ? Size(540, 540 / c.customAspect) : templateSize;

  Size get designSize => designSizeFor(config);

  @override
  Widget build(BuildContext context) {
    final size = designSize;
    return AspectRatio(
      aspectRatio: size.width / size.height,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox.fromSize(
          size: size,
          child: MediaQuery(
            // ukubwa wa herufi wa simu usiharibu mpangilio wa kadi
            data: const MediaQueryData(textScaler: TextScaler.noScaling),
            child: config.isCustom ? _custom(size) : _template(size),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Design ya mteja: picha yake + jina la mwalikwa + QR mahali alipochagua
  // -------------------------------------------------------------------------
  Widget _custom(Size size) {
    final Widget bg;
    if (customImage != null) {
      bg = RawImage(image: customImage, fit: BoxFit.cover, width: size.width, height: size.height);
    } else if (customImageProvider != null) {
      bg = Image(image: customImageProvider!, fit: BoxFit.cover, width: size.width, height: size.height);
    } else {
      bg = Container(color: const Color(0xFFE0E0E0));
    }
    final nameStyle = cardFont(
      config.nameFont,
      size.width * config.nameSize,
      color: Color(config.nameColor),
    );
    final qrSide = size.width * config.qrSize;

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(child: bg),
        _anchored(
          size,
          config.namePosition,
          SizedBox(
            width: size.width * 0.9,
            child: Text(
              guestName ?? 'Jina la Mwalikwa',
              textAlign: TextAlign.center,
              maxLines: 2,
              style: nameStyle,
            ),
          ),
        ),
        if (config.showQr)
          _anchored(size, config.qrPosition, _qr(qrSide, const Color(0xFF111111))),
      ],
    );
  }

  /// Inaweka [child] ili katikati yake iwe kwenye [pos] (sehemu ya 0..1 ya kadi).
  Widget _anchored(Size size, Offset pos, Widget child) => Positioned(
        left: pos.dx * size.width,
        top: pos.dy * size.height,
        child: FractionalTranslation(translation: const Offset(-0.5, -0.5), child: child),
      );

  // -------------------------------------------------------------------------
  // Template za Mwaliko
  // -------------------------------------------------------------------------
  Widget _template(Size size) {
    final palette = paletteById(config.paletteId);
    final fonts = fontPairById(config.fontPairId);
    final layout = config.layoutId;
    final insets = _insetsFor(config.ornamentId, layout);

    final bannerHeight = size.height * 0.36;

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: palette.background,
              ),
            ),
          ),
        ),
        if (layout == 'banner')
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: bannerHeight,
            child: CustomPaint(painter: _BannerPainter(palette.primary)),
          ),
        Positioned.fill(
          child: CustomPaint(painter: OrnamentPainter(ornamentId: config.ornamentId, palette: palette)),
        ),
        if (layout == 'framed')
          Positioned.fill(
            left: 52,
            right: 52,
            top: 64,
            bottom: 64,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: (palette.panel ?? palette.background.first).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: palette.primary.withValues(alpha: 0.7), width: 1.2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 18, offset: const Offset(0, 6)),
                ],
              ),
            ),
          ),
        Positioned.fill(
          child: Padding(
            padding: insets,
            child: layout == 'banner'
                ? _bannerContent(size, palette, fonts, bannerHeight - insets.top)
                : Center(child: _fit(size.width - insets.horizontal, _centeredContent(palette, fonts))),
          ),
        ),
      ],
    );
  }

  EdgeInsets _insetsFor(String ornament, String layout) {
    if (layout == 'framed') return const EdgeInsets.fromLTRB(78, 84, 78, 84);
    return switch (ornament) {
      'florals' => const EdgeInsets.fromLTRB(70, 96, 70, 96),
      'kitenge' => const EdgeInsets.fromLTRB(56, 84, 56, 80),
      'arch' => const EdgeInsets.fromLTRB(68, 120, 68, 60),
      'stars' => const EdgeInsets.fromLTRB(60, 92, 60, 52),
      'waves' => const EdgeInsets.fromLTRB(60, 104, 60, 104),
      'confetti' => const EdgeInsets.fromLTRB(60, 150, 60, 110),
      'deco' => const EdgeInsets.fromLTRB(64, 96, 64, 76),
      _ => const EdgeInsets.fromLTRB(64, 72, 64, 72),
    };
  }

  /// Inapunguza maudhui yakiwa marefu kuliko kadi, badala ya kuyakata.
  Widget _fit(double width, Widget child) => FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(width: width, child: child),
      );

  String get _heading => eventTypeById(event.eventType).cardHeading;

  String _title(FontPair f) => f.titleUpper ? event.title.toUpperCase() : event.title;

  List<Widget> _details(CardPalette p, FontPair f, {Color? color}) {
    final c = color ?? p.text;
    final body = cardFont(f.body, 16, color: c);
    final small = cardFont(f.body, 12.5, color: c.withValues(alpha: 0.85));
    return [
      Text(swahiliDate(event.eventDate), textAlign: TextAlign.center, style: cardFont(f.body, 17, color: c, weight: FontWeight.w700)),
      const SizedBox(height: 2),
      Text(swahiliTime(event.eventDate), textAlign: TextAlign.center, style: body),
      if (_has(event.venue)) ...[
        const SizedBox(height: 6),
        Text(event.venue!, textAlign: TextAlign.center, style: body),
      ],
      if (_has(event.dressCode)) ...[
        const SizedBox(height: 10),
        Text('Mavazi: ${event.dressCode}', textAlign: TextAlign.center, style: small),
      ],
      if (_has(event.contactPhone)) ...[
        const SizedBox(height: 2),
        Text('Mawasiliano: ${event.contactPhone}', textAlign: TextAlign.center, style: small),
      ],
    ];
  }

  Widget _guestBlock(CardPalette p, FontPair f, {Color? labelColor}) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Mpendwa', style: cardFont(f.body, 13, color: (labelColor ?? p.text).withValues(alpha: 0.8), letterSpacing: 2)),
          Text(
            guestName ?? 'Jina la Mwalikwa',
            textAlign: TextAlign.center,
            maxLines: 2,
            style: cardFont(f.script, 40, color: p.primary, height: 1.15),
          ),
        ],
      );

  Widget _footer(CardPalette p, FontPair f) {
    if (!config.showQr) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 14),
        _qr(70, const Color(0xFF111111)),
        const SizedBox(height: 4),
        Text(
          seats != null && seats! > 1 ? 'Kadi hii ni ya watu $seats' : 'Onyesha kadi hii mlangoni',
          style: cardFont(f.body, 11, color: p.text.withValues(alpha: 0.75), letterSpacing: 0.5),
        ),
      ],
    );
  }

  Widget _centeredContent(CardPalette p, FontPair f) {
    final hosts = event.hostNames;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _heading.toUpperCase(),
          textAlign: TextAlign.center,
          style: cardFont(f.body, 13, color: p.primary, letterSpacing: 4, weight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        _guestBlock(p, f),
        const SizedBox(height: 12),
        if (_has(hosts))
          Text(
            '$hosts\nwanayo furaha kukualika kwenye',
            textAlign: TextAlign.center,
            style: cardFont(f.body, 14.5, color: p.text, height: 1.35),
          )
        else
          Text('Unakaribishwa kwenye', style: cardFont(f.body, 14.5, color: p.text)),
        const SizedBox(height: 8),
        Text(
          _title(f),
          textAlign: TextAlign.center,
          maxLines: 3,
          style: cardFont(f.title, f.titleUpper ? 30 : 36, color: p.text, weight: FontWeight.w700, height: 1.1, letterSpacing: f.titleUpper ? 2 : 0),
        ),
        const SizedBox(height: 12),
        _Divider(color: p.primary),
        const SizedBox(height: 12),
        ..._details(p, f),
        if (_has(event.message)) ...[
          const SizedBox(height: 10),
          Text(
            event.message!,
            textAlign: TextAlign.center,
            maxLines: 3,
            style: cardFont(f.body, 13, color: p.text.withValues(alpha: 0.9), italic: true),
          ),
        ],
        _footer(p, f),
      ],
    );
  }

  Widget _bannerContent(Size size, CardPalette p, FontPair f, double bannerInner) {
    final onBanner = p.background.first;
    final width = size.width - 112;
    return Column(
      children: [
        SizedBox(
          height: bannerInner - 8,
          child: Center(
            child: _fit(
              width,
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _heading.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: cardFont(f.body, 13, color: onBanner.withValues(alpha: 0.9), letterSpacing: 4, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _title(f),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    style: cardFont(f.title, f.titleUpper ? 30 : 36, color: onBanner, weight: FontWeight.w700, height: 1.1),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 26),
        Expanded(
          child: Center(
            child: _fit(
              width,
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _guestBlock(p, f),
                  const SizedBox(height: 8),
                  if (_has(event.hostNames))
                    Text(
                      '${event.hostNames} wanayo furaha kukualika',
                      textAlign: TextAlign.center,
                      style: cardFont(f.body, 14.5, color: p.text, height: 1.35),
                    ),
                  const SizedBox(height: 12),
                  _Divider(color: p.primary),
                  const SizedBox(height: 12),
                  ..._details(p, f),
                  _footer(p, f),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _qr(double side, Color fg) {
    final data = qrData ?? 'MWALIKO:mfano';
    return Container(
      padding: EdgeInsets.all(side * 0.06),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(side * 0.08)),
      child: QrImageView(
        data: data,
        size: side,
        padding: EdgeInsets.zero,
        backgroundColor: Colors.white,
        eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: fg),
        dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: fg),
      ),
    );
  }

  static bool _has(String? s) => s != null && s.trim().isNotEmpty;
}

/// TextStyle kwa font za kadi. Fonts nyingi ni "variable", kwa hiyo uzito
/// unawekwa pia kama FontVariation ili uonekane sawa kwenye iOS na Android.
TextStyle cardFont(
  String family,
  double size, {
  required Color color,
  FontWeight weight = FontWeight.w400,
  double? height,
  double letterSpacing = 0,
  bool italic = false,
}) =>
    TextStyle(
      fontFamily: family,
      fontSize: size,
      color: color,
      fontWeight: weight,
      fontVariations: [FontVariation.weight(weight.value.toDouble())],
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    );

class _Divider extends StatelessWidget {
  const _Divider({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 60, height: 1, color: color),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Transform.rotate(angle: 0.785, child: Container(width: 7, height: 7, color: color)),
          ),
          Container(width: 60, height: 1, color: color),
        ],
      );
}

class _BannerPainter extends CustomPainter {
  _BannerPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - 30)
      ..quadraticBezierTo(size.width / 2, size.height + 24, 0, size.height - 30)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_BannerPainter old) => old.color != color;
}
