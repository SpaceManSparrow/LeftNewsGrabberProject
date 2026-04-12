import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/app_colors.dart';

/// ===========================================================================
/// DASHBOARD HEADER
/// Contains the beta banner, branding logo, and search bar.
/// ===========================================================================
class DashboardHeader extends StatelessWidget {
  final double width;
  final Color primaryColor;
  final TextEditingController searchController;
  final Function(String) onSearchChanged;
  final VoidCallback onLogoTap;
  final VoidCallback onOpenSettings;

  const DashboardHeader({
    super.key,
    required this.width,
    required this.primaryColor,
    required this.searchController,
    required this.onSearchChanged,
    required this.onLogoTap,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Beta Warning Banner
        Container(
          width: double.infinity,
          color: primaryColor,
          padding: const EdgeInsets.symmetric(
            vertical: 6,
          ),
          child: const Text(
            "THIS WEBSITE IS STILL IN BETA — DEVELOPMENT IN PROGRESS",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.appBackground,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
        // Navigation Bar
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.appBackground,
            border: Border(
              bottom: BorderSide(
                color: AppColors.borderSubtle,
              ),
            ),
          ),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 1800,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              child: Row(
                children: [
                  // Brand Logo
                  GestureDetector(
                    onTap: onLogoTap,
                    child: Text(
                      width > 500 ? "THE RADICAL" : "TR",
                      style: GoogleFonts.spaceGrotesk(
                        color: primaryColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Search Interface
                  Expanded(
                    child: _searchBar(),
                  ),
                  const SizedBox(width: 20),
                  // Settings Trigger
                  _settingsButton(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _searchBar() {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 600,
      ),
      child: TextField(
        controller: searchController,
        onChanged: onSearchChanged,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textMain,
        ),
        decoration: InputDecoration(
          hintText: "Search articles...",
          hintStyle: const TextStyle(
            color: AppColors.textMuted,
          ),
          prefixIcon: const Icon(
            FontAwesomeIcons.magnifyingGlass,
            size: 12,
            color: AppColors.textMuted,
          ),
          filled: true,
          fillColor: AppColors.highlightOverlay,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(99),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _settingsButton() {
    return ElevatedButton(
      onPressed: onOpenSettings,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.highlightOverlay,
        foregroundColor: AppColors.textMain,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(99),
          ),
          side: const BorderSide(
            color: AppColors.borderSubtle,
          ),
      ),
      child: Row(
        children: [
          if (width > 700) ...[
            const Text(
              "SETTINGS",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Icon(
            FontAwesomeIcons.sliders,
            size: 12,
            color: primaryColor,
          ),
        ],
      ),
    );
  }
}
