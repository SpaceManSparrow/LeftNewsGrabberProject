import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/app_colors.dart';
import '../core/app_config.dart';

/// ===========================================================================
/// DASHBOARD DIALOGS
/// Static builders for Information and Configuration popups.
/// ===========================================================================
class DashboardDialogs {
  /// ===========================================================================
  /// DIALOG: SOURCES
  /// Lists all active RSS feeds currently being polled.
  /// ===========================================================================
  static void showSourcesDialog(
    BuildContext context,
    Color primaryColor,
    bool extendedMode,
  ) {
    final allSources = Map.from(AppConfig.coreSources)
    ..addAll(AppConfig.globalSources);
    if (extendedMode) allSources.addAll(AppConfig.extendedSources);
    final sortedNames = allSources.values.toList()..sort();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.appSurface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "ACTIVE SIGNALS",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(FontAwesomeIcons.xmark, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: sortedNames.length,
                  itemBuilder: (context, index) => Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white10)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          sortedNames[index],
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMain,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.greenAccent.withValues(alpha: 0.5),
                                blurRadius: 4,
                                spreadRadius: 1,
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.black,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  child: const Text(
                    "CLOSE",
                    style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ===========================================================================
  /// DIALOG: ABOUT
  /// Information regarding the project version and mission.
  /// ===========================================================================
  static void showAboutDialog(BuildContext context, Color primaryColor) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.appSurface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              FontAwesomeIcons.circleInfo,
                              size: 16,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              "PROJECT BRIEFING",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "THE RADICAL",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const Text(
                          "v0.1.6",
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(FontAwesomeIcons.xmark, size: 18),
                    )
                  ],
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.only(left: 20),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                  child: const Text(
                    "The Radical is an independent news aggregator designed to centralise reporting from Australian political and social perspectives.",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Designed for tracking material and economic realities without having to manually check dozens of sources every day.",
                  style: TextStyle(color: AppColors.textMuted, fontSize: 16),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.black,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                    child: const Text(
                      "CLOSE",
                      style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
