import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/app_colors.dart';
import 'screens/news_dashboard.dart';

class TheRadicalApp extends StatefulWidget {
  const TheRadicalApp({super.key});
  @override
  State<TheRadicalApp> createState() => _TheRadicalAppState();
}

class _TheRadicalAppState extends State<TheRadicalApp> {
  Color primaryColor = AppColors.themeChoices[0];
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initApp();
  }

  Future<void> _initApp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? colorValue = prefs.getInt('theme_color');
      if (colorValue != null) {
        setState(() => primaryColor = Color(colorValue));
      }
    } catch (e) {
      debugPrint("Initialization Error: $e");
    }
  }

  void updateTheme(Color newColor) async {
    setState(() => primaryColor = newColor);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_color', newColor.toARGB32());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
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
