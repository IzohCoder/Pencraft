import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Pencraft colour roles
// All colours are warm, paper-and-ink inspired. No fintech blue or purple.
// ---------------------------------------------------------------------------

abstract final class AppColorsLight {
  // Surfaces
  static const Color surface = Color(0xFFFAF7F2);
  static const Color surfaceElevated = Color(0xFFF3EFE6);
  static const Color surfaceContainer = Color(0xFFEDE8DE);

  // Text / Ink
  static const Color onSurface = Color(0xFF1A1410);
  static const Color onSurfaceMuted = Color(0xFF6B5E4E);
  static const Color onSurfaceDisabled = Color(0xFFB0A090);

  // Borders
  static const Color outline = Color(0xFFD4C9B8);
  static const Color outlineVariant = Color(0xFFE8E2D8);

  // Accent — sealing wax red
  static const Color accent = Color(0xFFC0392B);
  static const Color accentDark = Color(0xFF962D22);
  static const Color accentSurface = Color(0xFFF8EDEC);
  static const Color onAccent = Color(0xFFFFFFFF);

  // Semantic
  static const Color success = Color(0xFF1E7D45);
  static const Color successSurface = Color(0xFFE8F5EE);
  static const Color warning = Color(0xFFB35C00);
  static const Color warningSurface = Color(0xFFFFF3E0);
  static const Color error = Color(0xFFB00020);
  static const Color errorSurface = Color(0xFFFFF0F0);

  // Status chips
  static const Color statusDraft = Color(0xFF6B5E4E);
  static const Color statusDraftSurface = Color(0xFFF0ECE6);
  static const Color statusSent = Color(0xFF1565C0);
  static const Color statusSentSurface = Color(0xFFE3F0FF);
  static const Color statusPaid = Color(0xFF1E7D45);
  static const Color statusPaidSurface = Color(0xFFE8F5EE);
  static const Color statusOverdue = Color(0xFFB00020);
  static const Color statusOverdueSurface = Color(0xFFFFF0F0);
  static const Color statusPartial = Color(0xFFB35C00);
  static const Color statusPartialSurface = Color(0xFFFFF3E0);
}

abstract final class AppColorsDark {
  // Surfaces — desk lamp at night (warm amber-tinted)
  static const Color surface = Color(0xFF1C1914);
  static const Color surfaceElevated = Color(0xFF252018);
  static const Color surfaceContainer = Color(0xFF2E2820);

  // Text / Ink
  static const Color onSurface = Color(0xFFEDE5D5);
  static const Color onSurfaceMuted = Color(0xFF9E8E78);
  static const Color onSurfaceDisabled = Color(0xFF5A4E40);

  // Borders
  static const Color outline = Color(0xFF3D3528);
  static const Color outlineVariant = Color(0xFF2E2820);

  // Accent
  static const Color accent = Color(0xFFE05246);
  static const Color accentDark = Color(0xFFB03E34);
  static const Color accentSurface = Color(0xFF3D1E1C);
  static const Color onAccent = Color(0xFFFFFFFF);

  // Semantic
  static const Color success = Color(0xFF2ECC71);
  static const Color successSurface = Color(0xFF0D2E1A);
  static const Color warning = Color(0xFFE8922A);
  static const Color warningSurface = Color(0xFF2E1A00);
  static const Color error = Color(0xFFCF6679);
  static const Color errorSurface = Color(0xFF2E0010);

  // Status chips
  static const Color statusDraft = Color(0xFF9E8E78);
  static const Color statusDraftSurface = Color(0xFF2E2820);
  static const Color statusSent = Color(0xFF82B1FF);
  static const Color statusSentSurface = Color(0xFF0A1628);
  static const Color statusPaid = Color(0xFF2ECC71);
  static const Color statusPaidSurface = Color(0xFF0D2E1A);
  static const Color statusOverdue = Color(0xFFCF6679);
  static const Color statusOverdueSurface = Color(0xFF2E0010);
  static const Color statusPartial = Color(0xFFE8922A);
  static const Color statusPartialSurface = Color(0xFF2E1A00);
}
