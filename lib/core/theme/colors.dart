// lib/core/theme/colors.dart
import 'dart:ui';

class ColorsManager {
  /// ── Primary ───────────────────────────────────────────────
  /// Slate-blue — professional, calm, works on both light & dark
  static const Color primaryColor = Color(0xFF3B5BDB);       // indigo-600
  static const Color primaryLight = Color(0xFFEEF2FF);       // indigo-50
  static const Color primaryDark = Color(0xFF2F4AC0);        // indigo-700

  static const Color secondaryColor = Color(0xFF0F172A);     // slate-900

  /// ── Dark Mode Surfaces ────────────────────────────────────
  static const Color darkColor = Color(0xFF0F172A);          // slate-900
  static const Color secondaryDarkColor = Color(0xFF1E293B); // slate-800

  /// ── Neutral / Surface ─────────────────────────────────────
  static const Color defaultSurface = Color(0xFFF8FAFC);     // slate-50
  static const Color defaultSurfaceSecondary = Color(0xFFF1F5F9); // slate-100

  static const Color defaultText = Color(0xFF0F172A);        // slate-900
  static const Color defaultTextSecondary = Color(0xFF64748B); // slate-500
  static const Color defaultTextSecondaryDark = Color(0xFFCBD5E1); // slate-300
  static const Color miscellaneous = Color(0xFF94A3B8);      // slate-400

  /// ── Info ──────────────────────────────────────────────────
  static const Color infoSurface = Color(0xFFEFF6FF);        // blue-50
  static const Color infoText = Color(0xFF1D4ED8);           // blue-700
  static const Color infoFill = Color(0xFF3B82F6);           // blue-500
  static const Color infoOnFill = Color(0xFFFFFFFF);

  /// ── Success ───────────────────────────────────────────────
  static const Color successSurface = Color(0xFFF0FDF4);     // green-50
  static const Color successText = Color(0xFF15803D);        // green-700
  static const Color successFill = Color(0xFF22C55E);        // green-500
  static const Color successOnFill = Color(0xFFFFFFFF);

  /// ── Warning ───────────────────────────────────────────────
  static const Color warningSurface = Color(0xFFFFFBEB);     // amber-50
  static const Color warningText = Color(0xFFB45309);        // amber-700
  static const Color warningFill = Color(0xFFF59E0B);        // amber-500
  static const Color warningOnFill = Color(0xFFFFFFFF);

  /// ── Active ────────────────────────────────────────────────
  static const Color activeSurface = Color(0xFFEEF2FF);      // indigo-50
  static const Color activeFill = Color(0xFF3B5BDB);         // indigo-600

  /// ── Input ─────────────────────────────────────────────────
  static const Color inputSurface = Color(0xFFFFFFFF);
  static const Color inputBorder = Color(0xFFCBD5E1);        // slate-300

  /// ── Background ────────────────────────────────────────────
  static const Color backgroundSurface = Color(0xFFF8FAFC);  // slate-50
  static const Color backgroundCard = Color(0xFFFFFFFF);

  /// ── Error ─────────────────────────────────────────────────
  static const Color errorSurface = Color(0xFFFFF1F2);       // rose-50
  static const Color errorText = Color(0xFFBE123C);          // rose-700
  static const Color errorFill = Color(0xFFF43F5E);          // rose-500
  static const Color errorOnFill = Color(0xFFFFFFFF);
}