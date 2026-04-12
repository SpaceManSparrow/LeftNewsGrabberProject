import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/app_colors.dart';
import '../core/app_config.dart';

/// ===========================================================================
/// DASHBOARD DRAWER
/// The sidebar containing application settings, theme selection, and filters.
/// ===========================================================================
class DashboardDrawer extends StatelessWidget {
  final Color primaryColor;
  final Function(Color) onThemeChanged;
  final bool prettyMode;
  final Function(bool) onPrettyModeChanged;
  final bool extendedMode;
  final Function(bool) onExtendedModeChanged;
  final String activeFilter;
  final Function(String) onFilterChanged;
  final VoidCallback onShowSources;
  final VoidCallback onShowAbout;

  const DashboardDrawer({
    super.key,
    required this.primaryColor,
    required this.onThemeChanged,
    required this.prettyMode,
    required this.onPrettyModeChanged,
    required this.extendedMode,
    required this.onExtendedModeChanged,
    required this.activeFilter,
    required this.onFilterChanged,
    required this.onShowSources,
    required this.onShowAbout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.appSurface,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 60),
          // Sidebar Header
          Row(
            children: [
              Icon(FontAwesomeIcons.gear, color: primaryColor),
              const SizedBox(width: 12),
              const Text(
                "CONTROL PANEL",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 30),
          // Coverage and Mode Toggles
          _coverageToggle(),
          _prettyModeToggle(),
          const SizedBox(height: 40),
          // Theme Selection
          const Text(
            "THEME PALETTE",
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textSubtle,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          _themePicker(),
          const SizedBox(height: 40),
          // Topic Filtering
          const Text(
            "TOPIC FILTERS",
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textSubtle,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          _topicList(),
          const SizedBox(height: 40),
          // Signal and Project Info Buttons
          _sourcesButton(),
          const SizedBox(height: 12),
          _aboutButton(),
        ],
      ),
    );
  }

  Widget _prettyModeToggle() {
    return SwitchListTile(
      title: const Text(
        "PRETTY MODE",
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      subtitle: const Text(
        "Only show articles that have photos.",
        style: TextStyle(fontSize: 10),
      ),
      value: prettyMode,
      activeThumbColor: primaryColor,
      onChanged: onPrettyModeChanged,
    );
  }

  Widget _coverageToggle() {
    return SwitchListTile(
      title: const Text(
        "EXTENDED COVERAGE",
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      subtitle: const Text(
        "Include broader independent sources.",
        style: TextStyle(fontSize: 10),
      ),
      value: extendedMode,
      activeThumbColor: primaryColor,
      onChanged: onExtendedModeChanged,
    );
  }

  Widget _themePicker() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: AppColors.themeChoices.map((c) {
        return GestureDetector(
          onTap: () => onThemeChanged(c),
          child: Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: c,
              border: Border.all(
                color: primaryColor == c ? Colors.white : Colors.transparent,
                width: 2,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _topicList() {
    final List<String> availableTopics = ["ALL", ...AppConfig.topics.keys];
    return Column(
      children: availableTopics.map((name) {
        bool isActive = activeFilter == name;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => onFilterChanged(name),
              style: TextButton.styleFrom(
                backgroundColor: isActive ? primaryColor : Colors.transparent,
                alignment: Alignment.centerLeft,
                side: BorderSide(
                  color: isActive ? primaryColor : AppColors.borderSubtle,
                ),
              ),
              child: Text(
                name,
                style: TextStyle(
                  color: isActive ? Colors.black : Colors.white60,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _sourcesButton() {
    return InkWell(
      onTap: onShowSources,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.3),
          ),
          color: AppColors.highlightOverlay,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  FontAwesomeIcons.satelliteDish,
                  size: 14,
                  color: primaryColor,
                ),
                const SizedBox(width: 12),
                const Text(
                  "SIGNAL SOURCES",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            Icon(
              FontAwesomeIcons.arrowRight,
              size: 10,
              color: primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _aboutButton() {
    return InkWell(
      onTap: onShowAbout,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: primaryColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  FontAwesomeIcons.circleInfo,
                  size: 14,
                  color: primaryColor,
                ),
                const SizedBox(width: 12),
                const Text(
                  "ABOUT PROJECT",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            Icon(
              FontAwesomeIcons.arrowRight,
              size: 10,
              color: primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
