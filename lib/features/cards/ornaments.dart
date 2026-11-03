import 'dart:math';

import 'package:flutter/material.dart';

import 'card_styles.dart';

/// Inachora mapambo ya kadi (fremu, maua, kitenge, nyota n.k.) juu ya rangi ya nyuma.
class OrnamentPainter extends CustomPainter {
  OrnamentPainter({required this.ornamentId, required this.palette});

  final String ornamentId;
  final CardPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    switch (ornamentId) {
      case 'florals':
        _florals(canvas, size);
      case 'kitenge':
        _kitenge(canvas, size);
      case 'arch':
        _arch(canvas, size);
      case 'stars':
        _stars(canvas, size);
      case 'waves':
        _waves(canvas, size);
      case 'confetti':
        _confetti(canvas, size);
      case 'deco':
        _deco(canvas, size);
      case 'gold_frame':
      default:
        _goldFrame(canvas, size);
    }
  }

  Paint _stroke(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..isAntiAlias = true;

  Paint _fill(Color c) => Paint()
    ..color = c
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  // -------------------------------------------------------------------------
  void _goldFrame(Canvas canvas, Size s) {
    final p = palette.primary;
    final outer = Rect.fromLTWH(18, 18, s.width - 36, s.height - 36);
    final inner = outer.deflate(9);
    canvas.drawRect(outer, _stroke(p, 2.2));
    canvas.drawRect(inner, _stroke(p.withValues(alpha: 0.7), 0.9));

    // Mapambo ya pembe nne
    for (final corner in [inner.topLeft, inner.topRight, inner.bottomLeft, inner.bottomRight]) {
      final sx = corner.dx < s.width / 2 ? 1.0 : -1.0;
      final sy = corner.dy < s.height / 2 ? 1.0 : -1.0;
      canvas.save();
      canvas.translate(corner.dx, corner.dy);
      canvas.scale(sx, sy);
      final path = Path()
        ..moveTo(0, 46)
        ..quadraticBezierTo(4, 4, 46, 0)
        ..moveTo(10, 46)
        ..quadraticBezierTo(14, 14, 46, 10);
      canvas.drawPath(path, _stroke(p, 1.4));
      canvas.drawCircle(const Offset(20, 20), 4, _fill(p));
      _diamond(canvas, const Offset(54, 4), 4, _fill(p));
      _diamond(canvas, const Offset(4, 54), 4, _fill(p));
      canvas.restore();
    }

    // Mapambo ya katikati juu na chini
    for (final y in [outer.top, outer.bottom]) {
      _diamond(canvas, Offset(s.width / 2, y), 9, _fill(palette.background.first));
      _diamond(canvas, Offset(s.width / 2, y), 7, _fill(p));
    }
  }

  // -------------------------------------------------------------------------
  void _florals(Canvas canvas, Size s) {
    final leaf = palette.primary.withValues(alpha: 0.35);
    final petal = palette.accent.withValues(alpha: 0.85);
    final center = palette.primary;

    void flower(Offset c, double r, double rot) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(rot);
      for (var i = 0; i < 6; i++) {
        canvas.save();
        canvas.rotate(i * pi / 3);
        canvas.drawOval(Rect.fromCenter(center: Offset(0, -r * 0.62), width: r * 0.78, height: r * 1.15), _fill(petal));
        canvas.drawOval(
          Rect.fromCenter(center: Offset(0, -r * 0.62), width: r * 0.78, height: r * 1.15),
          _stroke(palette.primary.withValues(alpha: 0.35), 0.8),
        );
        canvas.restore();
      }
      canvas.drawCircle(Offset.zero, r * 0.28, _fill(center));
      canvas.restore();
    }

    void leafAt(Offset c, double len, double rot) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(rot);
      final path = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(len * 0.5, -len * 0.32, len, 0)
        ..quadraticBezierTo(len * 0.5, len * 0.32, 0, 0);
      canvas.drawPath(path, _fill(leaf));
      canvas.drawLine(Offset.zero, Offset(len * 0.9, 0), _stroke(palette.primary.withValues(alpha: 0.4), 0.8));
      canvas.restore();
    }

    void cluster(Offset o, double dir) {
      leafAt(o + Offset(10 * dir, 70), 70, dir > 0 ? -0.3 : pi + 0.3);
      leafAt(o + Offset(70 * dir, 10), 70, dir > 0 ? 0.9 : pi - 0.9);
      leafAt(o + Offset(40 * dir, 40), 60, dir > 0 ? 0.3 : pi - 0.3);
      flower(o + Offset(38 * dir, 38), 30, 0.2);
      flower(o + Offset(100 * dir, 16), 18, 0.6);
      flower(o + Offset(14 * dir, 104), 18, 1.1);
      canvas.drawCircle(o + Offset(128 * dir, 40), 4, _fill(petal));
      canvas.drawCircle(o + Offset(46 * dir, 120), 4, _fill(petal));
    }

    // Juu kushoto na chini kulia
    cluster(const Offset(8, 8), 1);
    canvas.save();
    canvas.translate(s.width, s.height);
    canvas.rotate(pi);
    cluster(const Offset(8, 8), 1);
    canvas.restore();

    // Fremu nyembamba
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(24, 24, s.width - 48, s.height - 48), const Radius.circular(14));
    canvas.drawRRect(r, _stroke(palette.primary.withValues(alpha: 0.45), 1));
  }

  // -------------------------------------------------------------------------
  void _kitenge(Canvas canvas, Size s) {
    void band(double top, double h) {
      canvas.drawRect(Rect.fromLTWH(0, top, s.width, h), _fill(palette.primary));
      final tri = _fill(palette.accent);
      final light = _fill(palette.background.first);
      const step = 30.0;
      for (var x = 0.0; x < s.width + step; x += step) {
        // pembetatu juu na chini
        canvas.drawPath(
          Path()
            ..moveTo(x, top)
            ..lineTo(x + step / 2, top + h * 0.32)
            ..lineTo(x + step, top)
            ..close(),
          tri,
        );
        canvas.drawPath(
          Path()
            ..moveTo(x, top + h)
            ..lineTo(x + step / 2, top + h * 0.68)
            ..lineTo(x + step, top + h)
            ..close(),
          tri,
        );
        _diamond(canvas, Offset(x + step / 2, top + h / 2), 5.5, light);
        canvas.drawCircle(Offset(x, top + h / 2), 2.2, light);
      }
      canvas.drawLine(Offset(0, top + h + 4), Offset(s.width, top + h + 4), _stroke(palette.accent, 2));
      canvas.drawLine(Offset(0, top - 4), Offset(s.width, top - 4), _stroke(palette.accent, 2));
    }

    band(14, 46);
    band(s.height - 60, 46);
    // mistari ya pembeni
    for (final x in [16.0, s.width - 16]) {
      canvas.drawLine(Offset(x, 70), Offset(x, s.height - 70), _stroke(palette.primary.withValues(alpha: 0.5), 1.4));
    }
  }

  // -------------------------------------------------------------------------
  void _arch(Canvas canvas, Size s) {
    Path archPath(double inset) {
      final left = inset, right = s.width - inset, bottom = s.height - inset;
      final r = (right - left) / 2;
      final top = inset + r;
      return Path()
        ..moveTo(left, bottom)
        ..lineTo(left, top)
        ..arcToPoint(Offset(right, top), radius: Radius.circular(r))
        ..lineTo(right, bottom)
        ..close();
    }

    canvas.drawPath(archPath(30), _stroke(palette.primary, 2));
    canvas.drawPath(archPath(40), _stroke(palette.primary.withValues(alpha: 0.6), 0.9));
    _star(canvas, Offset(s.width / 2, 30), 10, _fill(palette.primary));
    // nguzo ndogo chini
    for (final x in [30.0, s.width - 30]) {
      canvas.drawRect(Rect.fromCenter(center: Offset(x, s.height - 30), width: 18, height: 8), _fill(palette.primary));
    }
    // vitone vya mapambo kando ya tao
    final rng = Random(11);
    for (var i = 0; i < 14; i++) {
      final a = pi + (i + 0.5) * pi / 14;
      final r = (s.width - 60) / 2 + 14;
      final c = Offset(s.width / 2 + cos(a) * r, 30 + (s.width - 60) / 2 + sin(a) * r);
      canvas.drawCircle(c, 1.5 + rng.nextDouble() * 1.5, _fill(palette.accent.withValues(alpha: 0.8)));
    }
  }

  // -------------------------------------------------------------------------
  void _stars(Canvas canvas, Size s) {
    final rng = Random(7);
    for (var i = 0; i < 70; i++) {
      final c = Offset(rng.nextDouble() * s.width, rng.nextDouble() * s.height);
      // nyota zaidi juu na chini, chache katikati ambako kuna maandishi
      final mid = (c.dy - s.height / 2).abs() < s.height * 0.28 && (c.dx - s.width / 2).abs() < s.width * 0.3;
      if (mid) continue;
      final big = rng.nextDouble() < 0.18;
      final color = (rng.nextBool() ? palette.primary : palette.accent).withValues(alpha: 0.4 + rng.nextDouble() * 0.6);
      if (big) {
        _star(canvas, c, 5 + rng.nextDouble() * 5, _fill(color));
      } else {
        canvas.drawCircle(c, 0.8 + rng.nextDouble() * 1.6, _fill(color));
      }
    }
    final rect = Rect.fromLTWH(22, 22, s.width - 44, s.height - 44);
    canvas.drawRect(rect, _stroke(palette.primary.withValues(alpha: 0.8), 1.2));
    // kofia ya mahafali juu
    final cx = s.width / 2;
    final cap = Path()
      ..moveTo(cx - 30, 52)
      ..lineTo(cx, 40)
      ..lineTo(cx + 30, 52)
      ..lineTo(cx, 64)
      ..close();
    canvas.drawPath(cap, _fill(palette.primary));
    canvas.drawRect(Rect.fromLTWH(cx - 16, 58, 32, 10), _fill(palette.primary));
    canvas.drawLine(Offset(cx + 22, 55), Offset(cx + 24, 74), _stroke(palette.accent, 1.5));
    canvas.drawCircle(Offset(cx + 24, 76), 2.5, _fill(palette.accent));
  }

  // -------------------------------------------------------------------------
  void _waves(Canvas canvas, Size s) {
    void wave(double baseY, double amp, double phase, Color c) {
      final path = Path()..moveTo(0, s.height);
      path.lineTo(0, baseY);
      for (var x = 0.0; x <= s.width; x += 6) {
        path.lineTo(x, baseY + sin(x / s.width * 2 * pi + phase) * amp);
      }
      path
        ..lineTo(s.width, s.height)
        ..close();
      canvas.drawPath(path, _fill(c));
    }

    wave(s.height - 92, 12, 0.4, palette.accent.withValues(alpha: 0.35));
    wave(s.height - 70, 14, 2.1, palette.primary.withValues(alpha: 0.35));
    wave(s.height - 46, 10, 4.0, palette.primary.withValues(alpha: 0.8));

    // mawimbi madogo juu kulia
    canvas.save();
    canvas.translate(s.width, 0);
    canvas.scale(-1, -1);
    canvas.translate(0, -90);
    final top = Path()..moveTo(0, 90);
    for (var x = 0.0; x <= s.width * 0.6; x += 6) {
      top.lineTo(x, 90 - (1 - x / (s.width * 0.6)) * 60 + sin(x / 40) * 6);
    }
    top
      ..lineTo(s.width * 0.6, 90)
      ..close();
    canvas.drawPath(top, _fill(palette.primary.withValues(alpha: 0.25)));
    canvas.restore();

    // jua dogo
    canvas.drawCircle(Offset(s.width - 70, 70), 24, _fill(palette.accent.withValues(alpha: 0.7)));
  }

  // -------------------------------------------------------------------------
  void _confetti(Canvas canvas, Size s) {
    final rng = Random(3);
    final colors = [palette.primary, palette.accent, palette.text.withValues(alpha: 0.6)];
    for (var i = 0; i < 90; i++) {
      final topZone = rng.nextBool();
      final y = topZone ? rng.nextDouble() * s.height * 0.2 : s.height * (0.84 + rng.nextDouble() * 0.16);
      final c = Offset(rng.nextDouble() * s.width, y);
      final paint = _fill(colors[rng.nextInt(colors.length)].withValues(alpha: 0.55 + rng.nextDouble() * 0.45));
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(rng.nextDouble() * pi);
      switch (rng.nextInt(3)) {
        case 0:
          canvas.drawRect(const Rect.fromLTWH(-5, -2, 10, 4), paint);
        case 1:
          canvas.drawCircle(Offset.zero, 3, paint);
        default:
          canvas.drawPath(
            Path()
              ..moveTo(-6, 0)
              ..quadraticBezierTo(-3, -5, 0, 0)
              ..quadraticBezierTo(3, 5, 6, 0),
            _stroke(paint.color, 2),
          );
      }
      canvas.restore();
    }
    // puto mbili
    for (final b in [(Offset(60, 120), palette.primary), (Offset(s.width - 62, 110), palette.accent)]) {
      canvas.drawOval(Rect.fromCenter(center: b.$1, width: 40, height: 50), _fill(b.$2.withValues(alpha: 0.9)));
      canvas.drawLine(b.$1 + const Offset(0, 25), b.$1 + const Offset(6, 80), _stroke(b.$2, 1));
    }
  }

  // -------------------------------------------------------------------------
  void _deco(Canvas canvas, Size s) {
    final p = palette.primary;
    final cx = s.width / 2;
    // miale ya feni juu (nusu duara inayoelekea chini)
    const fan = Offset(0, 22);
    for (var i = 0; i <= 12; i++) {
      final a = i * pi / 12;
      final dir = Offset(cos(a), sin(a));
      canvas.drawLine(
        Offset(cx, 0) + fan + dir * 18,
        Offset(cx, 0) + fan + dir * 58,
        _stroke(p.withValues(alpha: 0.7), 1),
      );
    }
    for (final r in [18.0, 38.0, 58.0]) {
      canvas.drawArc(Rect.fromCircle(center: Offset(cx, 22), radius: r), 0, pi, false, _stroke(p, r == 58 ? 1.6 : 0.9));
    }
    // fremu yenye pembe za ngazi
    final path = Path();
    const m = 22.0, st = 14.0;
    final w = s.width, h = s.height;
    path
      ..moveTo(m + st, m)
      ..lineTo(w - m - st, m)
      ..lineTo(w - m - st, m + st)
      ..lineTo(w - m, m + st)
      ..lineTo(w - m, h - m - st)
      ..lineTo(w - m - st, h - m - st)
      ..lineTo(w - m - st, h - m)
      ..lineTo(m + st, h - m)
      ..lineTo(m + st, h - m - st)
      ..lineTo(m, h - m - st)
      ..lineTo(m, m + st)
      ..lineTo(m + st, m + st)
      ..close();
    canvas.drawPath(path, _stroke(p, 1.6));
    canvas.drawRect(
      Rect.fromLTWH(m + 8, m + 8, w - 2 * m - 16, h - 2 * m - 16),
      _stroke(p.withValues(alpha: 0.5), 0.8),
    );
    // miale chini (kioo cha juu)
    canvas.save();
    canvas.translate(0, h);
    canvas.scale(1, -1);
    for (final r in [18.0, 38.0]) {
      canvas.drawArc(Rect.fromCircle(center: Offset(cx, 22), radius: r), 0, pi, false, _stroke(p, 0.9));
    }
    canvas.restore();
  }

  // -------------------------------------------------------------------------
  void _diamond(Canvas canvas, Offset c, double r, Paint paint) {
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy - r)
        ..lineTo(c.dx + r, c.dy)
        ..lineTo(c.dx, c.dy + r)
        ..lineTo(c.dx - r, c.dy)
        ..close(),
      paint,
    );
  }

  void _star(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final a = -pi / 2 + i * pi / 4;
      final rr = i.isEven ? r : r * 0.32;
      final pt = Offset(c.dx + cos(a) * rr, c.dy + sin(a) * rr);
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(OrnamentPainter old) => old.ornamentId != ornamentId || old.palette.id != palette.id;
}
