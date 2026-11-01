import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'tokens.dart';

ThemeData buildLightTheme() {
  final textTheme = buildTextTheme(
      AppColorsLight.onSurface, AppColorsLight.onSurfaceMuted);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: AppFonts.sans,
    textTheme: textTheme,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: AppColorsLight.accent,
      onPrimary: AppColorsLight.onAccent,
      primaryContainer: AppColorsLight.accentSurface,
      onPrimaryContainer: AppColorsLight.accentDark,
      secondary: AppColorsLight.onSurfaceMuted,
      onSecondary: AppColorsLight.onAccent,
      secondaryContainer: AppColorsLight.surfaceContainer,
      onSecondaryContainer: AppColorsLight.onSurface,
      tertiary: AppColorsLight.success,
      onTertiary: Colors.white,
      tertiaryContainer: AppColorsLight.successSurface,
      onTertiaryContainer: AppColorsLight.success,
      error: AppColorsLight.error,
      onError: Colors.white,
      errorContainer: AppColorsLight.errorSurface,
      onErrorContainer: AppColorsLight.error,
      surface: AppColorsLight.surface,
      onSurface: AppColorsLight.onSurface,
      surfaceContainerHighest: AppColorsLight.surfaceContainer,
      onSurfaceVariant: AppColorsLight.onSurfaceMuted,
      outline: AppColorsLight.outline,
      outlineVariant: AppColorsLight.outlineVariant,
      shadow: AppColorsLight.onSurface,
      scrim: AppColorsLight.onSurface,
      inverseSurface: AppColorsLight.onSurface,
      onInverseSurface: AppColorsLight.surface,
      inversePrimary: AppColorsLight.accentSurface,
    ),
    scaffoldBackgroundColor: AppColorsLight.surface,
    canvasColor: AppColorsLight.surface,
    cardColor: AppColorsLight.surfaceElevated,
    dividerColor: AppColorsLight.outline,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColorsLight.surface,
      foregroundColor: AppColorsLight.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleLarge,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
        statusBarColor: Colors.transparent,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColorsLight.surface,
      indicatorColor: AppColorsLight.accentSurface,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColorsLight.accent, size: 24);
        }
        return const IconThemeData(color: AppColorsLight.onSurfaceMuted, size: 24);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return textTheme.labelMedium?.copyWith(color: AppColorsLight.accent);
        }
        return textTheme.labelMedium?.copyWith(color: AppColorsLight.onSurfaceMuted);
      }),
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: const CardThemeData(
      color: AppColorsLight.surfaceElevated,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: Radii.cardAll,
        side: BorderSide(color: AppColorsLight.outlineVariant),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      border: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColorsLight.outline)),
      enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColorsLight.outline)),
      focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColorsLight.accent, width: 1.5)),
      errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColorsLight.error)),
      hintStyle:
          textTheme.bodyMedium?.copyWith(color: AppColorsLight.onSurfaceDisabled),
      labelStyle:
          textTheme.bodyMedium?.copyWith(color: AppColorsLight.onSurfaceMuted),
      floatingLabelStyle:
          textTheme.labelMedium?.copyWith(color: AppColorsLight.accent),
      contentPadding: const EdgeInsets.symmetric(vertical: Spacing.sm),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColorsLight.accent,
        foregroundColor: AppColorsLight.onAccent,
        minimumSize: const Size(double.infinity, TouchTargets.minimum),
        shape: const RoundedRectangleBorder(borderRadius: Radii.buttonAll),
        elevation: 0,
        textStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg, vertical: Spacing.md),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColorsLight.accent,
        minimumSize: const Size(double.infinity, TouchTargets.minimum),
        shape: const RoundedRectangleBorder(borderRadius: Radii.buttonAll),
        side: const BorderSide(color: AppColorsLight.outline),
        textStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg, vertical: Spacing.md),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColorsLight.accent,
        minimumSize: const Size(0, TouchTargets.minimum),
        textStyle: textTheme.labelLarge,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColorsLight.accent,
        foregroundColor: AppColorsLight.onAccent,
        minimumSize: const Size(double.infinity, TouchTargets.minimum),
        shape: const RoundedRectangleBorder(borderRadius: Radii.buttonAll),
        textStyle: textTheme.labelLarge,
      ),
    ),
    chipTheme: const ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: Radii.chipAll),
      side: BorderSide.none,
    ),
    dividerTheme: const DividerThemeData(
        color: AppColorsLight.outlineVariant, thickness: 1, space: 1),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColorsLight.accent,
      foregroundColor: AppColorsLight.onAccent,
      elevation: 4,
      shape: CircleBorder(),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColorsLight.onSurface,
      contentTextStyle:
          textTheme.bodyMedium?.copyWith(color: AppColorsLight.surface),
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(borderRadius: Radii.cardAll),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColorsLight.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: Radii.sheetTop),
      elevation: 0,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColorsLight.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: Radii.cardAll),
      titleTextStyle: textTheme.titleMedium,
      contentTextStyle: textTheme.bodyMedium,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? AppColorsLight.accent
              : AppColorsLight.onSurfaceDisabled),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? AppColorsLight.accentSurface
              : AppColorsLight.outlineVariant),
    ),
  );
}

ThemeData buildDarkTheme() {
  final textTheme = buildTextTheme(
      AppColorsDark.onSurface, AppColorsDark.onSurfaceMuted);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: AppFonts.sans,
    textTheme: textTheme,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: AppColorsDark.accent,
      onPrimary: AppColorsDark.onAccent,
      primaryContainer: AppColorsDark.accentSurface,
      onPrimaryContainer: AppColorsDark.accent,
      secondary: AppColorsDark.onSurfaceMuted,
      onSecondary: AppColorsDark.onAccent,
      secondaryContainer: AppColorsDark.surfaceContainer,
      onSecondaryContainer: AppColorsDark.onSurface,
      tertiary: AppColorsDark.success,
      onTertiary: Colors.black,
      tertiaryContainer: AppColorsDark.successSurface,
      onTertiaryContainer: AppColorsDark.success,
      error: AppColorsDark.error,
      onError: Colors.black,
      errorContainer: AppColorsDark.errorSurface,
      onErrorContainer: AppColorsDark.error,
      surface: AppColorsDark.surface,
      onSurface: AppColorsDark.onSurface,
      surfaceContainerHighest: AppColorsDark.surfaceContainer,
      onSurfaceVariant: AppColorsDark.onSurfaceMuted,
      outline: AppColorsDark.outline,
      outlineVariant: AppColorsDark.outlineVariant,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: AppColorsDark.onSurface,
      onInverseSurface: AppColorsDark.surface,
      inversePrimary: AppColorsDark.accentSurface,
    ),
    scaffoldBackgroundColor: AppColorsDark.surface,
    canvasColor: AppColorsDark.surface,
    cardColor: AppColorsDark.surfaceElevated,
    dividerColor: AppColorsDark.outline,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColorsDark.surface,
      foregroundColor: AppColorsDark.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleLarge,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        statusBarColor: Colors.transparent,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColorsDark.surface,
      indicatorColor: AppColorsDark.accentSurface,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColorsDark.accent, size: 24);
        }
        return const IconThemeData(color: AppColorsDark.onSurfaceMuted, size: 24);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return textTheme.labelMedium?.copyWith(color: AppColorsDark.accent);
        }
        return textTheme.labelMedium?.copyWith(color: AppColorsDark.onSurfaceMuted);
      }),
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: const CardThemeData(
      color: AppColorsDark.surfaceElevated,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: Radii.cardAll,
        side: BorderSide(color: AppColorsDark.outlineVariant),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      border: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColorsDark.outline)),
      enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColorsDark.outline)),
      focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColorsDark.accent, width: 1.5)),
      hintStyle:
          textTheme.bodyMedium?.copyWith(color: AppColorsDark.onSurfaceDisabled),
      labelStyle:
          textTheme.bodyMedium?.copyWith(color: AppColorsDark.onSurfaceMuted),
      floatingLabelStyle:
          textTheme.labelMedium?.copyWith(color: AppColorsDark.accent),
      contentPadding: const EdgeInsets.symmetric(vertical: Spacing.sm),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColorsDark.accent,
        foregroundColor: AppColorsDark.onAccent,
        minimumSize: const Size(double.infinity, TouchTargets.minimum),
        shape: const RoundedRectangleBorder(borderRadius: Radii.buttonAll),
        elevation: 0,
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColorsDark.accent,
        minimumSize: const Size(double.infinity, TouchTargets.minimum),
        shape: const RoundedRectangleBorder(borderRadius: Radii.buttonAll),
        side: const BorderSide(color: AppColorsDark.outline),
        textStyle: textTheme.labelLarge,
      ),
    ),
    chipTheme: const ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: Radii.chipAll),
      side: BorderSide.none,
    ),
    dividerTheme: const DividerThemeData(
        color: AppColorsDark.outlineVariant, thickness: 1, space: 1),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColorsDark.accent,
      foregroundColor: AppColorsDark.onAccent,
      elevation: 4,
      shape: CircleBorder(),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColorsDark.onSurface,
      contentTextStyle:
          textTheme.bodyMedium?.copyWith(color: AppColorsDark.surface),
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(borderRadius: Radii.cardAll),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColorsDark.surfaceElevated,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: Radii.sheetTop),
      elevation: 0,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColorsDark.surfaceElevated,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: Radii.cardAll),
      titleTextStyle: textTheme.titleMedium,
      contentTextStyle: textTheme.bodyMedium,
    ),
  );
}
