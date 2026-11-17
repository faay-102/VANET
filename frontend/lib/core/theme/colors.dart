import 'package:flutter/material.dart';

class AppColors {
  // 🔹 Modern Crisp Light Mode Canvas & Surfaces
  static const Color background = Color(0xFFF8FAFC);       // Soft Clean Slate Canvas (Slate-50)
  static const Color surface = Color(0xFFFFFFFF);          // Crisp White Card Surface
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color secondarySurface = Color(0xFFF1F5F9); // Light Slate Accent Surface (Slate-100)

  // 🔹 High-Contrast Crisp Typography & Borders
  static const Color textPrimary = Color(0xFF0F172A);      // Deep Slate Charcoal (Slate-900)
  static const Color textSecondary = Color(0xFF64748B);    // Balanced Slate Grey (Slate-500)
  static const Color textTertiary = Color(0xFF94A3B8);     // Muted Slate Meta (Slate-400)
  static const Color border = Color(0xFFE2E8F0);           // Clean Hairline Border (Slate-200)
  static const Color borderStrong = Color(0xFFCBD5E1);     // Active Border (Slate-300)

  // 🔹 Primary Brand & Semantic Accents (Signature Onboarding Safety Orange)
  static const Color primary = Color(0xFFE45D3F);          // Signature Onboarding Warm Safety Orange
  static const Color primaryLight = Color(0xFFFFF1EE);     // Warm Soft Orange Ambient Tint
  static const Color primaryVariant = Color(0xFFC2410C);   // Deep Terracotta Orange
  static const Color secondary = Color(0xFF0F172A);
  static const Color secondaryVariant = Color(0xFF334155);

  // 🔹 Advanced High-Tech Domain Colors
  static const Color safe = Color(0xFF10B981);             // Electric Emerald (Verified Safe)
  static const Color safeLight = Color(0xFFD1FAE5);        // Light Emerald Ambient Tint
  static const Color accent = Color(0xFFE45D3F);           // Safety Orange
  static const Color accentLight = Color(0xFFFFF1EE);
  static const Color aiHighlight = Color(0xFF6366F1);       // XAI / SHAP Radiant Indigo
  static const Color aiHighlightLight = Color(0xFFEEF2FF);
  static const Color warning = Color(0xFFF59E0B);          // Warning Amber
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);            // Critical / Emergency Siren Red
  static const Color errorLight = Color(0xFFFEE2E2);

  // 🔹 Material Compatibility Tokens
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.white;
  static const Color onBackground = Color(0xFF0F172A);
  static const Color onSurface = Color(0xFF0F172A);
  static const Color onError = Colors.white;
}
