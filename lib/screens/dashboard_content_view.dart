import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../core/app_colors.dart';
import '../models/article.dart';
import '../widgets/article_tile.dart';

/// ===========================================================================
/// DASHBOARD CONTENT VIEW
/// Manages the primary display areas: Feed, Video Placeholder, and Loaders.
/// ===========================================================================
class DashboardContentView extends StatelessWidget {
  final int tabIndex;
  final bool isLoading;
  final double width;
  final Color primaryColor;
  final List<Article> displayList;
  final int visibleCount;
  final ScrollController scrollController;
  final int totalSources;
  final int completedSources;
  final String statusMessage;
  final Future<void> Function() onRefresh;

  const DashboardContentView({
    super.key,
    required this.tabIndex,
    required this.isLoading,
    required this.width,
    required this.primaryColor,
    required this.displayList,
    required this.visibleCount,
    required this.scrollController,
    required this.totalSources,
    required this.completedSources,
    required this.statusMessage,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (tabIndex == 1) return _videoPlaceholder();
    if (isLoading) return _loader();

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: primaryColor,
      backgroundColor: AppColors.appSurface,
      child: displayList.isEmpty ? _emptyState() : _mainScrollArea(),
    );
  }

  /// ===========================================================================
  /// CONTENT: MAIN SCROLL AREA
  /// The grid/list layout for articles.
  /// ===========================================================================
  Widget _mainScrollArea() {
    const double articleGap = 30.0;
    return ListView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1754),
            padding: const EdgeInsets.symmetric(
              vertical: 32,
              horizontal: 16,
            ),
            child: Column(
              children: [
                _sectionHeader(),
                const SizedBox(height: 32),
                Center(
                  child: Wrap(
                    spacing: articleGap,
                    runSpacing: articleGap,
                    alignment: WrapAlignment.center,
                    children: displayList.take(visibleCount).map((a) {
                      if (width < 432) {
                        return FittedBox(
                          key: ValueKey(a.link),
                          fit: BoxFit.scaleDown,
                          child: ArticleTile(
                            article: a,
                            primaryColor: primaryColor,
                          ),
                        );
                      }
                      return ArticleTile(
                        key: ValueKey(a.link),
                        article: a,
                        primaryColor: primaryColor,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              "RECENT NEWS",
              style: GoogleFonts.spaceGrotesk(
                fontSize: width > 600 ? 60 : 32,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                color: AppColors.textMain,
              ),
            ),
          ),
          if (width > 600)
            Text(
              "REFRESHED: ${DateFormat('HH:mm').format(DateTime.now())}",
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }

  Widget _videoPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FontAwesomeIcons.videoSlash,
            size: 40,
            color: primaryColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 20),
          Text(
            "VIDEO SIGNALS OFFLINE",
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const Text(
            "Future feature currently in development.",
            style: TextStyle(color: AppColors.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _loader() {
    double progress = totalSources > 0 ? completedSources / totalSources : 0;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            value: (progress == 0) ? null : progress,
            color: primaryColor,
            strokeWidth: 6,
          ),
          const SizedBox(height: 30),
          Text(
            "${(progress * 100).toInt()}%",
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "RECEIVING SIGNALS...",
            style: TextStyle(
              color: primaryColor,
              fontSize: 10,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            statusMessage.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textSubtle,
              fontSize: 9,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() => const Center(child: Text("NO SIGNALS FOUND"));

  /// ===========================================================================
  /// OVERLAY: NEW SIGNAL PROMPT
  /// Floating button to indicate new background arrivals.
  /// ===========================================================================
  static Widget newSignalPrompt({
    required Color primaryColor,
    required int incomingCount,
    required VoidCallback onTap,
  }) {
    return Positioned(
      top: 130,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(99),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 20,
                  spreadRadius: 5,
                )
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  FontAwesomeIcons.bolt,
                  size: 14,
                  color: Colors.black,
                ),
                const SizedBox(width: 12),
                Text(
                  "NEW SIGNALS DETECTED ($incomingCount)",
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
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
