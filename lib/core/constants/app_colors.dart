import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Core Brand Colors
  static const Color primary = Color(0xFF7C3AED);
  static const Color secondary = Color(0xFF06B6D4);
  static const Color accent = Color(0xFFF59E0B);
  
  // Gradient Colors
  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
  );
  
  static const Gradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
  );
  
  static const Gradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0F0F23),
      Color(0xFF1A1B2F),
      Color(0xFF252642),
    ],
  );

  // Neutral Colors
  static const Color background = Color(0xFF0F0F23);
  static const Color surface = Color(0xFF1A1B2F);
  static const Color surfaceVariant = Color(0xFF252642);
  static const Color onSurface = Color(0xFFE2E8F0);
  static const Color onSurfaceVariant = Color(0xFF94A3B8);

  // Semantic Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Glass Morphism Colors
  static const Color glassSurface = Color(0x201A1B2F);
  static const Color glassBorder = Color(0x30FFFFFF);

  // Glow Colors
  static const Color glowPrimary = Color(0x557C3AED);
  static const Color glowSecondary = Color(0x5506B6D4);
  static const Color glowAccent = Color(0x55F59E0B);

  // Social Colors
  static const Color instagram = Color(0xFFE4405F);
  static const Color tiktok = Color(0xFF69C9D0);
  static const Color twitter = Color(0xFF1DA1F2);
}

// Extension for easy color access
extension ColorExtensions on Color {
  Color withOpacity(double opacity) => withOpacity(opacity);
}