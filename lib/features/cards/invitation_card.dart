import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/event_types.dart';
import '../../core/swahili_time.dart';
import '../../data/cards_repository.dart';
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
    this.photo,
    this.photoProvider,
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

  /// Picha ya mteja kwa template za picha ([CardConfig.hasPhoto]), iliyokwisha decode-iwa (PNG).
  final ui.Image? photo;

  /// Au kama ImageProvider. Zote zikiwa null, picha inasomwa kutoka storage.
  final ImageProvider? photoProvider;

  static const templateSize = Size(540, 675);

  static Size designSizeFor(CardConfig c) => c.isCustom ? Size(540, 540 / c.customAspect) : templateSize;

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
    final nameStyle = cardFont(config.nameFont, size.width * config.nameSize, color: Color(config.nameColor));
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
            child: Text(guestName ?? 'Jina la Mwalikwa', textAlign: TextAlign.center, maxLines: 2, style: nameStyle),
          ),
        ),
        if (config.showQr) _anchored(size, config.qrPosition, _qr(qrSide, const Color(0xFF111111))),
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
    if (config.hasPhoto) return _photoTemplate(size, palette, fonts);
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
          child: CustomPaint(
            painter: OrnamentPainter(ornamentId: config.ornamentId, palette: palette),
          ),
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
      Text(
        swahiliDate(event.eventDate),
        textAlign: TextAlign.center,
        style: cardFont(f.body, 17, color: c, weight: FontWeight.w700),
      ),
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
      Text(
        'Mpendwa',
        style: cardFont(f.body, 13, color: (labelColor ?? p.text).withValues(alpha: 0.8), letterSpacing: 2),
      ),
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
          style: cardFont(
            f.title,
            f.titleUpper ? 30 : 36,
            color: p.text,
            weight: FontWeight.w700,
            height: 1.1,
            letterSpacing: f.titleUpper ? 2 : 0,
          ),
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
                    style: cardFont(
                      f.body,
                      13,
                      color: onBanner.withValues(alpha: 0.9),
                      letterSpacing: 4,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _title(f),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    style: cardFont(
                      f.title,
                      f.titleUpper ? 30 : 36,
                      color: onBanner,
                      weight: FontWeight.w700,
                      height: 1.1,
                    ),
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

  // -------------------------------------------------------------------------
  // Template zenye picha ya mteja
  // -------------------------------------------------------------------------
  Widget _photoImage({Alignment alignment = const Alignment(0, -0.3)}) {
    if (photo != null) return RawImage(image: photo, fit: BoxFit.cover, alignment: alignment);
    return Image(
      image: photoProvider ?? const CardsRepository().imageFor(config.photoPath!),
      fit: BoxFit.cover,
      alignment: alignment,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => const ColoredBox(
        color: Color(0x33000000),
        child: Center(child: Icon(Icons.person, size: 72, color: Colors.white70)),
      ),
    );
  }

  Widget _background(CardPalette p) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: p.background),
    ),
  );

  Widget _photoTemplate(Size size, CardPalette p, FontPair f) {
    final ornament = CustomPaint(
      painter: OrnamentPainter(ornamentId: config.ornamentId, palette: p),
    );
    final shadow = [BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 18, offset: const Offset(0, 8))];

    switch (config.layoutId) {
      case 'photo_full':
        final light = _brightOf(p);
        return Stack(
          children: [
            Positioned.fill(child: _photoImage(alignment: const Alignment(0, -0.6))),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0, 0.28, 0.5, 0.72, 1],
                    colors: [
                      Color(0x40000000),
                      Color(0x00000000),
                      Color(0x59000000),
                      Color(0xD9000000),
                      Color(0xF2000000),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              left: 18,
              top: 18,
              right: 18,
              bottom: 18,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: light.withValues(alpha: 0.75), width: 1.4),
                ),
              ),
            ),
            Positioned(
              left: 40,
              right: 40,
              bottom: 40,
              height: size.height * 0.52,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _fit(size.width - 80, _photoContent(p, f, text: Colors.white, accent: light)),
              ),
            ),
          ],
        );

      case 'photo_top':
        final photoHeight = size.height * 0.43;
        return Stack(
          children: [
            Positioned.fill(child: _background(p)),
            Positioned.fill(child: ornament),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: photoHeight,
              child: ClipPath(clipper: _CurveBottomClipper(), child: _photoImage()),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: photoHeight,
              child: CustomPaint(painter: _CurveLinePainter(p.primary)),
            ),
            Positioned(
              left: 48,
              right: 48,
              top: photoHeight + 14,
              bottom: 34,
              child: Center(child: _fit(size.width - 96, _photoContent(p, f))),
            ),
          ],
        );

      default:
        final Widget frame = switch (config.layoutId) {
          'photo_arch' => SizedBox(
            width: 212,
            height: 242,
            child: CustomPaint(
              foregroundPainter: _ArchBorderPainter(p.primary),
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: ClipPath(clipper: _ArchClipper(), child: _photoImage()),
              ),
            ),
          ),
          'photo_polaroid' => Transform.rotate(
            angle: -0.05,
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(3), boxShadow: shadow),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 196, height: 196, child: _photoImage()),
                  SizedBox(
                    height: 34,
                    child: Center(
                      child: Text('Karibu', style: cardFont(f.script, 24, color: p.primary.withValues(alpha: 0.9))),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // photo_circle
          _ => Container(
            width: 176,
            height: 176,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: p.primary, width: 3),
              boxShadow: shadow,
              color: p.background.first,
            ),
            child: ClipOval(child: _photoImage()),
          ),
        };
        final insets = _insetsFor(config.ornamentId, 'centered');
        return Stack(
          children: [
            Positioned.fill(child: _background(p)),
            Positioned.fill(child: ornament),
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  insets.left.clamp(48, 64),
                  insets.top.clamp(56, 92),
                  insets.right.clamp(48, 64),
                  insets.bottom.clamp(44, 80),
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        frame,
                        const SizedBox(height: 16),
                        SizedBox(width: size.width - 112, child: _photoContent(p, f)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }

  /// Rangi angavu ya palette (kwa maandishi juu ya picha yenye kivuli).
  static Color _brightOf(CardPalette p) {
    if (p.primary.computeLuminance() > 0.35) return p.primary;
    if (p.accent.computeLuminance() > 0.35) return p.accent;
    return const Color(0xFFF1D98A);
  }

  /// Maelezo mafupi ya kadi yenye picha (nafasi ni ndogo kuliko template za kawaida).
  Widget _photoContent(CardPalette p, FontPair f, {Color? text, Color? accent}) {
    final t = text ?? p.text;
    final a = accent ?? p.primary;
    final hosts = event.hostNames;
    final extras = [
      if (_has(event.dressCode)) 'Mavazi: ${event.dressCode}',
      if (_has(event.contactPhone)) 'Simu: ${event.contactPhone}',
    ];
    final align = config.showQr ? CrossAxisAlignment.start : CrossAxisAlignment.center;
    final textAlign = config.showQr ? TextAlign.left : TextAlign.center;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _heading.toUpperCase(),
          textAlign: TextAlign.center,
          style: cardFont(f.body, 12, color: a, letterSpacing: 3.5, weight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text('Mpendwa', style: cardFont(f.body, 12, color: t.withValues(alpha: 0.8), letterSpacing: 2)),
        Text(
          guestName ?? 'Jina la Mwalikwa',
          textAlign: TextAlign.center,
          maxLines: 2,
          style: cardFont(f.script, 36, color: a, height: 1.12),
        ),
        const SizedBox(height: 6),
        Text(
          _has(hosts) ? '$hosts wanayo furaha kukualika kwenye' : 'Unakaribishwa kwenye',
          textAlign: TextAlign.center,
          style: cardFont(f.body, 13.5, color: t, height: 1.3),
        ),
        const SizedBox(height: 4),
        Text(
          _title(f),
          textAlign: TextAlign.center,
          maxLines: 2,
          style: cardFont(
            f.title,
            f.titleUpper ? 26 : 30,
            color: t,
            weight: FontWeight.w700,
            height: 1.1,
            letterSpacing: f.titleUpper ? 1.5 : 0,
          ),
        ),
        const SizedBox(height: 10),
        _Divider(color: a),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: align,
                children: [
                  Text(
                    swahiliDate(event.eventDate),
                    textAlign: textAlign,
                    style: cardFont(f.body, 15, color: t, weight: FontWeight.w700),
                  ),
                  Text(
                    swahiliTime(event.eventDate),
                    textAlign: textAlign,
                    style: cardFont(f.body, 14, color: t),
                  ),
                  if (_has(event.venue))
                    Text(
                      event.venue!,
                      textAlign: textAlign,
                      maxLines: 2,
                      style: cardFont(f.body, 14, color: t),
                    ),
                ],
              ),
            ),
            if (config.showQr) ...[
              const SizedBox(width: 16),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _qr(62, const Color(0xFF111111)),
                  const SizedBox(height: 3),
                  Text(
                    seats != null && seats! > 1 ? 'Watu $seats' : 'Onyesha mlangoni',
                    style: cardFont(f.body, 9.5, color: t.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ],
          ],
        ),
        if (extras.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            extras.join('  ·  '),
            textAlign: TextAlign.center,
            style: cardFont(f.body, 11.5, color: t.withValues(alpha: 0.85)),
          ),
        ],
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
}) => TextStyle(
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

/// Picha ya juu yenye upinde chini.
class _CurveBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => _curvePath(size)..close();

  @override
  bool shouldReclip(_CurveBottomClipper oldClipper) => false;
}

Path _curvePath(Size size) => Path()
  ..lineTo(size.width, 0)
  ..lineTo(size.width, size.height - 34)
  ..quadraticBezierTo(size.width / 2, size.height + 22, 0, size.height - 34);

class _CurveLinePainter extends CustomPainter {
  _CurveLinePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width, size.height - 34)
      ..quadraticBezierTo(size.width / 2, size.height + 22, 0, size.height - 34);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  @override
  bool shouldRepaint(_CurveLinePainter old) => old.color != color;
}

/// Dirisha la tao (juu nusu duara).
Path _archPath(Rect r) {
  final radius = r.width / 2;
  return Path()
    ..moveTo(r.left, r.bottom)
    ..lineTo(r.left, r.top + radius)
    ..arcToPoint(Offset(r.right, r.top + radius), radius: Radius.circular(radius))
    ..lineTo(r.right, r.bottom)
    ..close();
}

class _ArchClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => _archPath(Offset.zero & size);

  @override
  bool shouldReclip(_ArchClipper oldClipper) => false;
}

class _ArchBorderPainter extends CustomPainter {
  _ArchBorderPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke;
    canvas.drawPath(_archPath((Offset.zero & size).deflate(1.5)), stroke..strokeWidth = 3);
    canvas.drawPath(_archPath((Offset.zero & size).deflate(5.5)), stroke..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(_ArchBorderPainter old) => old.color != color;
}
