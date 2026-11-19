import 'package:material_ui/material_ui.dart';

/// Paleta minimalista y moderna para Hydra (Modo Claro y Modo Oscuro).
abstract final class AppColors {
  // Brand / Accent
  static const Color primary = Color(0xFF0EA5E9);
  static const Color primaryLight = Color(0xFF38BDF8);
  static const Color primaryDeep = Color(0xFF0284C7);
  static const Color primarySoftLight = Color(0xFFE0F2FE);
  static const Color primarySoftDark = Color(0xFF0C2D48);

  // Light Surfaces & Text
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceMuted = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // Dark Surfaces & Text
  static const Color darkBackground = Color(0xFF0B1120);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkSurfaceMuted = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF1F2937);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color streak = Color(0xFFF97316);
  static const Color freeze = Color(0xFF60A5FA);
  static const Color danger = Color(0xFFEF4444);
}
