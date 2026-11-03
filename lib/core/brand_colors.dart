import 'package:flutter/material.dart';

/// U'r Invente brand palette (Aqua glass + orange).
/// Source of truth: assets/brand/tokens.json and assets/brand/BRAND.md.
class BrandColors {
  BrandColors._();

  // Orange: solid #FF7200 for actions, primary buttons, selected tab.
  static const orange = Color(0xFFFF7200);
  static const orangeLight = Color(0xFFFF8F33);
  static const orangeDeep = Color(0xFFE06400);
  static const orangeText = Color(0xFFC2410C);

  // Aqua: screen background gradient and decorative circles.
  static const aquaLight = Color(0xFFA8F0E0);
  static const aqua = Color(0xFF5CD6CF);
  static const lagoon = Color(0xFF3BB8D0);
  static const aquaDeep = Color(0xFF1BA6B8);

  // Glass surfaces (use with BackdropFilter blur 16-22).
  static const glass = Color(0x73FFFFFF); // 45% white
  static const glassStrong = Color(0xBFFFFFFF); // 75% white
  static const glassBorder = Color(0xCCFFFFFF); // 80% white

  // Text.
  static const ink = Color(0xFF08343A);
  static const muted = Color(0xFF2F5B60);
  static const onOrange = Colors.white;

  // Guest status.
  static const success = Color(0xFF00695C);
  static const successBg = Color(0xFFD7F7F1);
  static const pendingBg = Color(0xFFFFE7D6);
  static const danger = Color(0xFFB91C1C);

  static const backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [aquaLight, aqua, lagoon],
    stops: [0, 0.55, 1],
  );

  /// Primary buttons are solid [orange]; this subtle glow sits behind them.
  static const buttonShadow = BoxShadow(
    color: Color(0x59FF7200),
    blurRadius: 22,
    offset: Offset(0, 10),
  );
}
