import 'package:flutter/material.dart';

/// Rangi za Mwaliko: bluu ya kifalme na samawati, mandhari meupe.
/// Majina ni ya kazi (primary, accent...) ili kubadilisha rangi kuwe hapa tu.
class MwalikoColors {
  static const primary = Color(0xFF2A44D4); // bluu ya kifalme
  static const primaryDeep = Color(0xFF0D1B5E); // bluu ya usiku
  static const primaryBright = Color(0xFF3D6BF0);
  static const accent = Color(0xFF6FCDF9); // samawati (juu ya rangi nzito)
  static const accentSoft = Color(0xFFE0F2FE);
  static const accentInk = Color(0xFF0369A1); // samawati kwa maandishi juu ya nyeupe
  static const background = Color(0xFFF4F7FD);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF121833);
  static const muted = Color(0xFF667085);
  static const line = Color(0xFFE3E8F4);
  static const success = Color(0xFF12805C);
  static const warning = Color(0xFFC27C0E);
  static const danger = Color(0xFFC62828);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBright, primary, primaryDeep],
  );

  /// Kadi ya salio
  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFBAE6FD), accent, Color(0xFF38BDF8)],
  );
}

class MwalikoShadows {
  static final soft = [
    BoxShadow(color: MwalikoColors.primaryDeep.withValues(alpha: 0.06), blurRadius: 24, offset: const Offset(0, 8)),
  ];
  static final lifted = [
    BoxShadow(color: MwalikoColors.primaryDeep.withValues(alpha: 0.18), blurRadius: 30, offset: const Offset(0, 14)),
  ];
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: MwalikoColors.primary,
    primary: MwalikoColors.primary,
    onPrimary: Colors.white,
    secondary: MwalikoColors.accent,
    onSecondary: MwalikoColors.primaryDeep,
    surface: MwalikoColors.background,
    onSurface: MwalikoColors.ink,
    error: MwalikoColors.danger,
  );

  const body = 'Poppins';
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: body);
  final text = base.textTheme
      .apply(bodyColor: MwalikoColors.ink, displayColor: MwalikoColors.ink)
      .copyWith(
        headlineLarge: const TextStyle(
          fontFamily: 'PlayfairDisplay',
          fontSize: 30,
          fontWeight: FontWeight.w700,
          height: 1.15,
        ),
        headlineMedium: const TextStyle(
          fontFamily: 'PlayfairDisplay',
          fontSize: 26,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        headlineSmall: const TextStyle(
          fontFamily: 'PlayfairDisplay',
          fontSize: 22,
          fontWeight: FontWeight.w700,
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
    scaffoldBackgroundColor: MwalikoColors.background,
    splashFactory: InkRipple.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: MwalikoColors.background,
      foregroundColor: MwalikoColors.ink,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'PlayfairDisplay',
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: MwalikoColors.ink,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: MwalikoColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(color: MwalikoColors.muted),
      floatingLabelStyle: const TextStyle(color: MwalikoColors.primary, fontWeight: FontWeight.w600),
      prefixIconColor: MwalikoColors.muted,
      border: border(MwalikoColors.line),
      enabledBorder: border(MwalikoColors.line),
      focusedBorder: border(MwalikoColors.primary, 1.6),
      errorBorder: border(MwalikoColors.danger),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 54),
        backgroundColor: MwalikoColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: MwalikoColors.line,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontFamily: body, fontWeight: FontWeight.w600, fontSize: 15.5),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 50),
        foregroundColor: MwalikoColors.primary,
        side: const BorderSide(color: MwalikoColors.line, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontFamily: body, fontWeight: FontWeight.w600, fontSize: 14.5),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: MwalikoColors.primary,
        textStyle: const TextStyle(fontFamily: body, fontWeight: FontWeight.w600),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: MwalikoColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      extendedTextStyle: TextStyle(fontFamily: body, fontWeight: FontWeight.w600),
    ),
    cardTheme: CardThemeData(
      color: MwalikoColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: MwalikoColors.surface,
      selectedColor: MwalikoColors.primary,
      secondarySelectedColor: MwalikoColors.primary,
      side: const BorderSide(color: MwalikoColors.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      labelStyle: const TextStyle(fontFamily: body, fontSize: 13, color: MwalikoColors.ink),
      secondaryLabelStyle: const TextStyle(fontFamily: body, fontSize: 13, color: Colors.white),
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: MwalikoColors.surface,
      indicatorColor: MwalikoColors.accentSoft,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 70,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontFamily: body,
          fontSize: 11.5,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
          color: s.contains(WidgetState.selected) ? MwalikoColors.primary : MwalikoColors.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? MwalikoColors.primary : MwalikoColors.muted),
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
      backgroundColor: MwalikoColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: const TextStyle(
        fontFamily: 'PlayfairDisplay',
        fontSize: 21,
        fontWeight: FontWeight.w700,
        color: MwalikoColors.ink,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: MwalikoColors.background,
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
