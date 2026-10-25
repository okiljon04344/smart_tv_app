import 'package:flutter/material.dart';

/// Colour palette. Everything on screen is a neutral except [accent], which
/// marks the primary action, the current selection and playback progress.
abstract final class AppPalette {
  static const background = Color(0xFF111214);
  static const surface = Color(0xFF1A1C1F);
  static const surfaceHigh = Color(0xFF25282C);
  static const border = Color(0xFF2E3136);
  static const textPrimary = Color(0xFFF2F0EB);
  static const textSecondary = Color(0xFFA6A9AE);
  static const accent = Color(0xFFE9A23B);
  static const onAccent = Color(0xFF1B1408);
  static const danger = Color(0xFFE5534B);
}

/// Layout constants shared by the 10-foot screens.
abstract final class AppSpacing {
  static const double screenPadding = 32;
  static const double radius = 10;
  static const double focusRingWidth = 2;
}

/// Off-white ring drawn over a control while it has D-Pad focus. Used as a
/// `foregroundDecoration` so it never changes the control's layout size.
BoxDecoration? focusRing(
  ColorScheme colors,
  bool focused, {
  double radius = AppSpacing.radius,
}) {
  if (!focused) return null;
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: colors.onSurface,
      width: AppSpacing.focusRingWidth,
    ),
  );
}

/// Muted, opaque tint of a catalogue item's colour code, used for artwork
/// placeholders so they sit quietly on the near-black background.
Color posterTint(ColorScheme colors, int colorCode) {
  final hsl = HSLColor.fromColor(Color(colorCode | 0xFF000000));
  final muted = hsl
      .withSaturation(hsl.saturation * 0.45)
      .withLightness(hsl.lightness.clamp(0.0, 0.3))
      .toColor();
  return Color.lerp(colors.surfaceContainerHigh, muted, 0.7)!;
}

extension ThemeContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme.dark(
    primary: AppPalette.accent,
    onPrimary: AppPalette.onAccent,
    secondary: AppPalette.accent,
    onSecondary: AppPalette.onAccent,
    surface: AppPalette.background,
    onSurface: AppPalette.textPrimary,
    onSurfaceVariant: AppPalette.textSecondary,
    surfaceContainer: AppPalette.surface,
    surfaceContainerHigh: AppPalette.surfaceHigh,
    outline: AppPalette.border,
    outlineVariant: AppPalette.border,
    error: AppPalette.danger,
    onError: AppPalette.textPrimary,
  );

  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppSpacing.radius),
  );

  // Sizes are chosen for reading from a sofa: nothing on screen is below 13.
  const textTheme = TextTheme(
    headlineMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
    titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 17, height: 1.5),
    bodyMedium: TextStyle(fontSize: 15, height: 1.4),
    labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Roboto',
    colorScheme: scheme,
    scaffoldBackgroundColor: AppPalette.background,
    textTheme: textTheme.apply(
      bodyColor: AppPalette.textPrimary,
      displayColor: AppPalette.textPrimary,
    ),
    dividerColor: AppPalette.border,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppPalette.surface,
      foregroundColor: AppPalette.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppPalette.accent,
        foregroundColor: AppPalette.onAccent,
        elevation: 0,
        minimumSize: const Size(64, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: shape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppPalette.textPrimary,
        side: const BorderSide(color: AppPalette.border),
        minimumSize: const Size(64, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: shape,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppPalette.textSecondary,
        minimumSize: const Size(64, 48),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppPalette.surfaceHigh,
      labelStyle: const TextStyle(color: AppPalette.textSecondary),
      hintStyle: const TextStyle(color: AppPalette.textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        borderSide: const BorderSide(color: AppPalette.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        borderSide: const BorderSide(color: AppPalette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        borderSide: const BorderSide(color: AppPalette.accent, width: 2),
      ),
    ),
    sliderTheme: SliderThemeData(
      trackHeight: 4,
      activeTrackColor: AppPalette.accent,
      inactiveTrackColor: AppPalette.border,
      thumbColor: AppPalette.accent,
      overlayColor: AppPalette.accent.withValues(alpha: 0.16),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppPalette.onAccent
            : AppPalette.textSecondary,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppPalette.accent
            : AppPalette.surfaceHigh,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppPalette.accent
            : AppPalette.border,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppPalette.accent,
      linearTrackColor: AppPalette.border,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppPalette.surfaceHigh,
      contentTextStyle: const TextStyle(
        color: AppPalette.textPrimary,
        fontSize: 15,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        side: const BorderSide(color: AppPalette.border),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppPalette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        side: const BorderSide(color: AppPalette.border),
      ),
    ),
  );
}
