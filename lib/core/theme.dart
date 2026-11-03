import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'brand_colors.dart';

/// Rangi za U'r Invente (Aqua glass + orange). Thamani zinatoka [BrandColors]
/// (assets/brand/tokens.json); majina hapa ni ya kazi ili skrini zisijue rangi halisi.
class MwalikoColors {
  static const primary = BrandColors.orange; // vitendo, tab iliyochaguliwa
  static const primaryDeep = BrandColors.orangeDeep; // kitufe kikibonyezwa
  static const primaryBright = BrandColors.orangeLight;
  static const accent = BrandColors.aquaDeep; // vivutio vya pili, duara za mapambo
  static const onAccent = BrandColors.ink;
  static const accentSoft = BrandColors.glassStrong;
  static const heroAccent = BrandColors.orangeText; // lebo juu ya asili ya aqua
  static const accentInk = BrandColors.orangeText; // maandishi madogo ya orange
  static const pendingBg = BrandColors.pendingBg;
  static const successBg = BrandColors.successBg;
  static const glass = BrandColors.glass;
  static const glassStrong = BrandColors.glassStrong;
  static const glassBorder = BrandColors.glassBorder;
  static const background = BrandColors.aqua;
  static const surface = BrandColors.glassStrong;
  static const ink = BrandColors.ink;
  static const muted = BrandColors.muted;
  static const line = Color(0x2608343A); // ink 15%: mistari na mipaka juu ya glass
  static const success = BrandColors.success;
  static const warning = BrandColors.orangeText;
  static const danger = BrandColors.danger;

  /// Paneli nzito ya aqua (kadi ya tukio lijalo, jumla ya malipo): maandishi meupe.
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1BA6B8), Color(0xFF128A9C), Color(0xFF0B5D6B)],
  );

  static const backgroundGradient = BrandColors.backgroundGradient;
}

/// Fonts za brand: Plus Jakarta Sans (vichwa, namba kubwa) na Inter (maandishi mengine).
class MwalikoFonts {
  static const display = 'PlusJakartaSans';
  static const body = 'Inter';
}

class MwalikoShadows {
  static final soft = [
    BoxShadow(color: BrandColors.ink.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 10)),
  ];
  static final lifted = [
    BoxShadow(color: BrandColors.ink.withValues(alpha: 0.16), blurRadius: 30, offset: const Offset(0, 14)),
  ];
  static const button = [BrandColors.buttonShadow];
}

/// Asili ya kila skrini: gradient ya aqua na duara za aqua-deep nyuma ya glass.
class BrandBackground extends StatelessWidget {
  const BrandBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: MwalikoColors.backgroundGradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: CustomPaint(painter: _CirclesPainter())),
          child,
        ],
      ),
    );
  }
}

class _CirclesPainter extends CustomPainter {
  const _CirclesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final deep = Paint()..color = BrandColors.aquaDeep.withValues(alpha: 0.55);
    final soft = Paint()..color = Colors.white.withValues(alpha: 0.35);
    canvas.drawCircle(Offset(-size.width * 0.12, size.height * 0.36), size.width * 0.34, deep);
    canvas.drawCircle(Offset(size.width * 1.08, size.height * 0.78), size.width * 0.38, deep);
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.06), size.width * 0.16, soft);
  }

  @override
  bool shouldRepaint(_CirclesPainter oldDelegate) => false;
}

/// Kila ukurasa unachora asili yake mwenyewe wakati wa transition, ili ukurasa mpya ufunike wa zamani.
/// (MaterialApp.builder pia inaweka BrandBackground nyuma ya app nzima.)
class _BrandPageTransitions extends PageTransitionsBuilder {
  const _BrandPageTransitions(this.inner);
  final PageTransitionsBuilder inner;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => inner.buildTransitions(route, context, animation, secondaryAnimation, BrandBackground(child: child));
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: MwalikoColors.primary,
    primary: MwalikoColors.primary,
    onPrimary: Colors.white,
    secondary: MwalikoColors.accent,
    onSecondary: MwalikoColors.ink,
    surface: Colors.white,
    onSurface: MwalikoColors.ink,
    error: MwalikoColors.danger,
  );

  const body = MwalikoFonts.body;
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: body);
  final text = base.textTheme
      .apply(bodyColor: MwalikoColors.ink, displayColor: MwalikoColors.ink)
      .copyWith(
        headlineLarge: const TextStyle(
          fontFamily: MwalikoFonts.display,
          fontSize: 30,
          fontWeight: FontWeight.w800,
          height: 1.15,
        ),
        headlineMedium: const TextStyle(
          fontFamily: MwalikoFonts.display,
          fontSize: 26,
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
        headlineSmall: const TextStyle(
          fontFamily: MwalikoFonts.display,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          height: 1.25,
        ),
        titleLarge: const TextStyle(fontFamily: body, fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium: const TextStyle(fontFamily: body, fontSize: 15.5, fontWeight: FontWeight.w600),
        titleSmall: const TextStyle(fontFamily: body, fontSize: 13.5, fontWeight: FontWeight.w600),
        bodyLarge: const TextStyle(fontFamily: body, fontSize: 15, height: 1.45),
        bodyMedium: const TextStyle(fontFamily: body, fontSize: 13.5, height: 1.45, color: MwalikoColors.ink),
        bodySmall: const TextStyle(fontFamily: body, fontSize: 12, height: 1.4, color: MwalikoColors.muted),
        labelLarge: const TextStyle(fontFamily: body, fontSize: 14, fontWeight: FontWeight.w600),
        labelSmall: const TextStyle(fontFamily: body, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6),
      );

  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: c, width: w),
  );

  return base.copyWith(
    textTheme: text,
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: Colors.transparent,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _BrandPageTransitions(FadeForwardsPageTransitionsBuilder()),
        TargetPlatform.iOS: _BrandPageTransitions(CupertinoPageTransitionsBuilder()),
        TargetPlatform.macOS: _BrandPageTransitions(CupertinoPageTransitionsBuilder()),
        TargetPlatform.linux: _BrandPageTransitions(FadeForwardsPageTransitionsBuilder()),
        TargetPlatform.windows: _BrandPageTransitions(FadeForwardsPageTransitionsBuilder()),
        TargetPlatform.fuchsia: _BrandPageTransitions(FadeForwardsPageTransitionsBuilder()),
      },
    ),
    splashFactory: InkRipple.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: MwalikoColors.ink,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: MwalikoFonts.display,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: MwalikoColors.ink,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: MwalikoColors.glass,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(color: MwalikoColors.muted),
      floatingLabelStyle: const TextStyle(color: MwalikoColors.accentInk, fontWeight: FontWeight.w600),
      prefixIconColor: MwalikoColors.muted,
      border: border(MwalikoColors.glassBorder, 1.5),
      enabledBorder: border(MwalikoColors.glassBorder, 1.5),
      focusedBorder: border(MwalikoColors.primary, 1.6),
      errorBorder: border(MwalikoColors.danger),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style:
          FilledButton.styleFrom(
            minimumSize: const Size(64, 54),
            backgroundColor: MwalikoColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: MwalikoColors.glass,
            disabledForegroundColor: MwalikoColors.muted,
            // mng'ao wa orange nyuma ya kitufe kikuu
            elevation: 6,
            shadowColor: const Color(0x8CFF7200),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            textStyle: const TextStyle(fontFamily: body, fontWeight: FontWeight.w700, fontSize: 15.5),
          ).copyWith(
            backgroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.disabled)
                  ? MwalikoColors.glass
                  : s.contains(WidgetState.pressed)
                  ? MwalikoColors.primaryDeep
                  : MwalikoColors.primary,
            ),
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            elevation: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.disabled) ? 0 : 6),
          ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 50),
        foregroundColor: MwalikoColors.accentInk,
        backgroundColor: MwalikoColors.glass,
        side: const BorderSide(color: MwalikoColors.glassBorder, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontFamily: body, fontWeight: FontWeight.w600, fontSize: 14.5),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: MwalikoColors.accentInk,
        textStyle: const TextStyle(fontFamily: body, fontWeight: FontWeight.w600),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: MwalikoColors.primary,
      foregroundColor: Colors.white,
      elevation: 6,
      extendedTextStyle: TextStyle(fontFamily: body, fontWeight: FontWeight.w600),
    ),
    cardTheme: CardThemeData(
      color: MwalikoColors.glassStrong,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: MwalikoColors.glass,
      selectedColor: MwalikoColors.primary,
      secondarySelectedColor: MwalikoColors.primary,
      side: const BorderSide(color: MwalikoColors.glassBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      labelStyle: const TextStyle(fontFamily: body, fontSize: 13, color: MwalikoColors.ink),
      secondaryLabelStyle: const TextStyle(fontFamily: body, fontSize: 13, color: Colors.white),
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      indicatorColor: MwalikoColors.glassStrong,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 70,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontFamily: body,
          fontSize: 11.5,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
          color: s.contains(WidgetState.selected) ? MwalikoColors.accentInk : MwalikoColors.ink,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? MwalikoColors.primary : MwalikoColors.ink),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: MwalikoColors.primary,
      unselectedLabelColor: MwalikoColors.muted,
      indicatorColor: MwalikoColors.primary,
      dividerColor: MwalikoColors.line,
      labelStyle: TextStyle(fontFamily: body, fontWeight: FontWeight.w600, fontSize: 14),
      unselectedLabelStyle: TextStyle(fontFamily: body, fontWeight: FontWeight.w500, fontSize: 14),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xF5FFFFFF),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: const TextStyle(
        fontFamily: MwalikoFonts.display,
        fontSize: 21,
        fontWeight: FontWeight.w800,
        color: MwalikoColors.ink,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFFE8FBF7),
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: MwalikoColors.ink,
      contentTextStyle: const TextStyle(fontFamily: body, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: const DividerThemeData(color: MwalikoColors.line, space: 1),
    listTileTheme: const ListTileThemeData(iconColor: MwalikoColors.primary),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: MwalikoColors.primary),
    sliderTheme: const SliderThemeData(activeTrackColor: MwalikoColors.primary, thumbColor: MwalikoColors.primary),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? MwalikoColors.primary : null,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? MwalikoColors.primary : MwalikoColors.muted,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : null),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? MwalikoColors.primary : null,
      ),
    ),
  );
}
