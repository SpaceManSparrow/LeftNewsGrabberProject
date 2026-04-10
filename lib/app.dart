import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/app_colors.dart';
import 'screens/news_dashboard.dart';

/// ===========================================================================
/// ROOT WIDGET
/// Manages the application-level state (Theme color and SharedPrefs).
/// ===========================================================================
class TheRadicalApp extends StatefulWidget {
  const TheRadicalApp({super.key});
  @override
  State<TheRadicalApp> createState() => _TheRadicalAppState();
}

class _TheRadicalAppState extends State<TheRadicalApp> {
  // Default primary color (Amber) until user preferences load
  Color primaryColor = AppColors.themeChoices[0];

  /// Loads the saved theme color from device storage on startup
  Future<void> _initApp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? colorValue = prefs.getInt('theme_color');
      if (colorValue != null) {
        primaryColor = Color(colorValue);
      }
    } catch (e) {
      debugPrint("Initialization Error: $e");
    }
  }

  /// Updates the app's primary color and persists it to storage
  void updateTheme(Color newColor) async {
    setState(() => primaryColor = newColor);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_color', newColor.toARGB32());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initApp(),
      builder: (context, snapshot) {
        // Show a blank dark screen while waiting for storage to initialize
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(color: AppColors.appBackground);
        }

        return MaterialApp(
          title: 'The Radical',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppColors.appBackground,
            primaryColor: primaryColor,
            colorScheme: ColorScheme.dark(primary: primaryColor),
            // Custom font used for standard body text
            textTheme: GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme),
          ),
          home: NewsDashboard(
            primaryColor: primaryColor,
            onThemeChanged: updateTheme,
          ),
        );
      },
    );
  }
}
