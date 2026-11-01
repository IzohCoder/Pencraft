import 'package:flutter/material.dart';

abstract final class AppFonts {
  static const String serif = 'DMSerifDisplay';
  static const String sans = 'Inter';
}

TextTheme buildTextTheme(Color onSurface, Color onSurfaceMuted) {
  return TextTheme(
    displayLarge: TextStyle(
      fontFamily: AppFonts.serif,
      fontSize: 36,
      fontWeight: FontWeight.w400,
      color: onSurface,
      letterSpacing: -0.5,
      height: 1.1,
    ),
    displayMedium: TextStyle(
      fontFamily: AppFonts.serif,
      fontSize: 28,
      fontWeight: FontWeight.w400,
      color: onSurface,
      height: 1.2,
    ),
    titleLarge: TextStyle(
      fontFamily: AppFonts.sans,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: onSurface,
      letterSpacing: -0.2,
      height: 1.3,
    ),
    titleMedium: TextStyle(
      fontFamily: AppFonts.sans,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: onSurface,
      height: 1.4,
    ),
    titleSmall: TextStyle(
      fontFamily: AppFonts.sans,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: onSurface,
      height: 1.4,
    ),
    bodyLarge: TextStyle(
      fontFamily: AppFonts.sans,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: onSurface,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontFamily: AppFonts.sans,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: onSurface,
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontFamily: AppFonts.sans,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: onSurfaceMuted,
      height: 1.4,
    ),
    labelSmall: TextStyle(
      fontFamily: AppFonts.sans,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: onSurfaceMuted,
      letterSpacing: 0.4,
      height: 1.3,
    ),
    labelMedium: TextStyle(
      fontFamily: AppFonts.sans,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: onSurface,
      letterSpacing: 0.2,
      height: 1.3,
    ),
    labelLarge: TextStyle(
      fontFamily: AppFonts.sans,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: onSurface,
      height: 1.3,
    ),
  );
}

extension TabularTextStyle on TextStyle {
  TextStyle get tabular =>
      copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}
