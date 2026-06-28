// lib/theme/app_theme.dart
// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/sensor_data.dart';
import '../main.dart';

// ── Dynamic color accessor ────────────────────────────────────────────────────
// All widgets read from AppColors, which now returns dark or light values
// depending on themeNotifier.isDark. No widget changes needed for theming.

class AppColors {
  static bool get _dark => themeNotifier.isDark;

  // ── Backgrounds ─────────────────────────────────────────────────────────────
  static Color get background =>
      _dark ? const Color(0xFF0D0D0D) : const Color(0xFFF4F4F5);
  static Color get surface =>
      _dark ? const Color(0xFF161616) : const Color(0xFFFFFFFF);
  static Color get surfaceCard =>
      _dark ? const Color(0xFF1C1C1C) : const Color(0xFFFFFFFF);
  static Color get surfaceHighlight =>
      _dark ? const Color(0xFF242424) : const Color(0xFFEEEEEF);
  static Color get sidebarBg =>
      _dark ? const Color(0xFF111111) : const Color(0xFFF8F8F8);

  // ── Zinc scale ───────────────────────────────────────────────────────────────
  static Color get zinc900 =>
      _dark ? const Color(0xFF141414) : const Color(0xFFE4E4E7);
  static Color get zinc800 =>
      _dark ? const Color(0xFF1E1E1E) : const Color(0xFFD4D4D8);
  static Color get zinc700 =>
      _dark ? const Color(0xFF2A2A2A) : const Color(0xFFBBBBBF);
  static Color get zinc600 =>
      _dark ? const Color(0xFF3A3A3A) : const Color(0xFF9F9FA6);
  static Color get zinc500 =>
      _dark ? const Color(0xFF5A5A5A) : const Color(0xFF71717A);
  static Color get zinc400 =>
      _dark ? const Color(0xFF888888) : const Color(0xFF52525B);
  static Color get zinc300 =>
      _dark ? const Color(0xFFAAAAAA) : const Color(0xFF3F3F46);
  static Color get divider =>
      _dark ? const Color(0xFF222222) : const Color(0xFFE4E4E7);

  // ── Brand / semantic ─────────────────────────────────────────────────────────
  static Color get primary =>
      _dark ? const Color(0xFF4EDEA3) : const Color(0xFF10B981);
  static Color get primaryDark => const Color(0xFF10B981);
  static Color get secondary =>
      _dark ? const Color(0xFFFFB95F) : const Color(0xFFD97706);
  static Color get danger =>
      _dark ? const Color(0xFFFF453A) : const Color(0xFFDC2626);
  static Color get dangerContainer =>
      _dark ? const Color(0xFF5C0006) : const Color(0xFFFFE4E6);
  static Color get warning =>
      _dark ? const Color(0xFFFFB95F) : const Color(0xFFD97706);
  static Color get safe =>
      _dark ? const Color(0xFF4EDEA3) : const Color(0xFF10B981);

  // ── Text ─────────────────────────────────────────────────────────────────────
  static Color get onSurface =>
      _dark ? const Color(0xFFE8E8E8) : const Color(0xFF111111);
  static Color get onSurfaceMuted =>
      _dark ? const Color(0xFF9A9A9A) : const Color(0xFF52525B);
  static Color get outlineVariant =>
      _dark ? const Color(0xFF2C2C2C) : const Color(0xFFD4D4D8);
}

Color statusColor(SafetyStatus s) {
  switch (s) {
    case SafetyStatus.danger:
      return AppColors.danger;
    case SafetyStatus.warning:
      return AppColors.warning;
    case SafetyStatus.safe:
      return AppColors.safe;
    case SafetyStatus.unknown:
      return AppColors.zinc500;
  }
}

// ── Text styles ──────────────────────────────────────────────────────────────
TextStyle tLabel(BuildContext context) => GoogleFonts.spaceGrotesk(
  fontSize: 10,
  fontWeight: FontWeight.w600,
  letterSpacing: 1.3,
  color: AppColors.zinc400,
);
TextStyle tLabelGreen(BuildContext context) => GoogleFonts.spaceGrotesk(
  fontSize: 10,
  fontWeight: FontWeight.w600,
  letterSpacing: 1.3,
  color: AppColors.primary,
);
TextStyle tBody(BuildContext context) => GoogleFonts.spaceGrotesk(
  fontSize: 14,
  fontWeight: FontWeight.w400,
  color: AppColors.onSurfaceMuted,
);
TextStyle tHeadSm(BuildContext context) => GoogleFonts.spaceGrotesk(
  fontSize: 16,
  fontWeight: FontWeight.w700,
  color: AppColors.onSurface,
);
TextStyle tHeadMd(BuildContext context) => GoogleFonts.spaceGrotesk(
  fontSize: 22,
  fontWeight: FontWeight.w700,
  color: AppColors.onSurface,
);
TextStyle tHeadLg(BuildContext context) => GoogleFonts.spaceGrotesk(
  fontSize: 28,
  fontWeight: FontWeight.w800,
  color: AppColors.onSurface,
);
TextStyle tMono(BuildContext context) => TextStyle(
  fontFamily: 'monospace',
  fontSize: 13,
  fontWeight: FontWeight.w600,
  color: AppColors.primary,
);
TextStyle tDataLg(BuildContext context) => GoogleFonts.spaceGrotesk(
  fontSize: 32,
  fontWeight: FontWeight.w800,
  letterSpacing: -1,
  color: AppColors.onSurface,
);
