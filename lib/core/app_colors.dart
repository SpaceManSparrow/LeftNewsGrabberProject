import 'package:flutter/material.dart';

/// ===========================================================================
/// DESIGN SYSTEM
/// Defines the visual identity of the app (colors and theme constants).
/// ===========================================================================
class AppColors {
  // Background and Surface colors for a high-contrast dark mode
  static const Color appBackground = Color(0xFF0e0e0e);
  static const Color appSurface = Color(0xFF131313);
  static const Color tileBackground = Color(0xFF151515);
  static const Color borderSubtle = Colors.white10;
  static const Color highlightOverlay = Color(0x0DFFFFFF);

  // Typography colors
  static const Color textMain = Colors.white;
  static const Color textMuted = Colors.white54;
  static const Color textSubtle = Colors.white38;

  // Available accent colors for the user to choose from in Settings
  static const List<Color> themeChoices = [
    Color(0xFFf59e0b), // Amber
    Color(0xFFf43f5e), // Rose
    Color(0xFF8b5cf6), // Violet
    Color(0xFF6366f1), // Indigo
    Color(0xFF3b82f6), // Blue
    Color(0xFF10b981), // Emerald
  ];
}
