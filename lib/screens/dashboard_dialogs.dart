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
  /// Polished implementation for manually enabling/disabling sources.
  /// ===========================================================================
  static void showSourcesDialog({
    required BuildContext context,
    required Color primaryColor,
    required bool extendedMode,
    required bool allSourcesEnabled,
    required Set<String> enabledSources,
    required Function(bool, Set<String>) onSaved,
  }) {
    // Collect and sort all relevant names from config
    final List<String> allSourceNames = {
      ...AppConfig.coreSources.values,
      ...AppConfig.globalSources.values,
      if (extendedMode) ...AppConfig.extendedSources.values,
    }.toList(); 
    allSourceNames.sort();

    // Copy initial state to local variables for modal editing
    bool localAllEnabled = allSourcesEnabled;
    Set<String> localEnabledSet = {...enabledSources};

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            backgroundColor: AppColors.appSurface,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "SIGNAL SOURCES",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900, // Fixed: FontWeight.black is not a valid constant
                          letterSpacing: 2,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(FontAwesomeIcons.xmark, size: 18),
                      )
                    ],
                  ),
                  const Divider(color: AppColors.borderSubtle, height: 40),

                  // --- MASTER TOGGLE ---
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: primaryColor, // Fixed: activeColor is deprecated in SwitchListTile
                    title: const Text(
                      "ALL SOURCES",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    subtitle: const Text(
                      "Include all signals automatically.",
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    value: localAllEnabled,
                    onChanged: (val) {
                      setModalState(() => localAllEnabled = val);
                    },
                  ),

                  const SizedBox(height: 10),

                  // --- INDIVIDUAL SOURCE SELECTION ---
                  Expanded(
                    child: Opacity(
                      opacity: localAllEnabled ? 0.4 : 1.0,
                      child: AbsorbPointer(
                        absorbing: localAllEnabled,
                        child: ListView.builder(
                          itemCount: allSourceNames.length,
                          itemBuilder: (context, index) {
                            final name = allSourceNames[index];
                            final isChecked = localEnabledSet.contains(name);

                            return CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              activeColor: primaryColor,
                              checkColor: Colors.black,
                              dense: true,
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              value: localAllEnabled || isChecked,
                              onChanged: (val) {
                                setModalState(() {
                                  if (val == true) {
                                    localEnabledSet.add(name);
                                  } else {
                                    localEnabledSet.remove(name);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- SAVE ACTION ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        onSaved(localAllEnabled, localEnabledSet);
                        Navigator.pop(dialogContext);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.black,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                      child: const Text(
                        "SAVE & REFRESH",
                        style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
                          "v0.2.0",
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