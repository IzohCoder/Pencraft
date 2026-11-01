import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Spacing — 8pt grid
// ---------------------------------------------------------------------------
abstract final class Spacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}

// ---------------------------------------------------------------------------
// Border radii
// ---------------------------------------------------------------------------
abstract final class Radii {
  /// Documents, paper-like surfaces — minimal rounding
  static const double document = 4;
  /// Standard cards
  static const double card = 8;
  /// Buttons
  static const double button = 8;
  /// Bottom sheets
  static const double sheet = 16;
  /// Chips, tags — fully rounded
  static const double chip = 100;
  /// Input fields (for BoxDecoration use only; TextField uses UnderlineInputBorder)
  static const double input = 4;

  static const BorderRadius documentAll = BorderRadius.all(Radius.circular(document));
  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(card));
  /// Alias for cardAll — used in some widget files.
  static const BorderRadius cardBR = BorderRadius.all(Radius.circular(card));
  static const BorderRadius buttonAll = BorderRadius.all(Radius.circular(button));
  static const BorderRadius sheetTop = BorderRadius.only(
    topLeft: Radius.circular(sheet),
    topRight: Radius.circular(sheet),
  );
  static const BorderRadius chipAll = BorderRadius.all(Radius.circular(chip));
}

// ---------------------------------------------------------------------------
// Motion
// ---------------------------------------------------------------------------
abstract final class Motion {
  static const Duration micro = Duration(milliseconds: 150);
  static const Duration short = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration long = Duration(milliseconds: 400);
  static const Duration xlong = Duration(milliseconds: 600);
  static const Duration countUp = Duration(milliseconds: 800);

  static const Curve standard = Curves.easeInOutCubic;
  static const Curve decelerate = Curves.easeOutCubic;
  static const Curve accelerate = Curves.easeInCubic;
  static const Curve enter = Curves.easeOut;
  static const Curve exit = Curves.easeIn;
}

// ---------------------------------------------------------------------------
// Elevation / Shadow strategy
// ---------------------------------------------------------------------------
// We use borders rather than shadows on most surfaces.
// Shadows reserved for floating elements (FAB, bottom sheet, modal).
abstract final class AppShadows {
  /// Subtle paper depth — used on document cards
  static List<BoxShadow> document(Color inkColor) => [
        BoxShadow(
          color: inkColor.withValues(alpha: 0.04),
          blurRadius: 0,
          offset: Offset.zero,
        ),
        BoxShadow(
          color: inkColor.withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: inkColor.withValues(alpha: 0.03),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  /// Floating element shadow
  static List<BoxShadow> floating(Color inkColor) => [
        BoxShadow(
          color: inkColor.withValues(alpha: 0.12),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}

// ---------------------------------------------------------------------------
// Touch targets
// ---------------------------------------------------------------------------
abstract final class TouchTargets {
  /// Minimum touch target size per Material / WCAG guidelines
  static const double minimum = 48;
}
