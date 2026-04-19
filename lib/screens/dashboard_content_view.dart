import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/app_colors.dart';
import '../models/article.dart';
import '../widgets/article_tile.dart';
import '../widgets/story_bar.dart';

class DashboardContentView extends StatelessWidget {
  final int tabIndex, visibleCount, totalSources, completedSources;
  final bool isLoading;
  final double width;
  final Color primaryColor;
  final List<Article> displayList, allArticles;
  final Set<String> viewedStoryLinks; // NEW
  final Function(String) onStoryViewed; // NEW
  final ScrollController scrollController;
  final String statusMessage;
  final Future<void> Function() onRefresh;

  const DashboardContentView({
    super.key, required this.tabIndex, required this.isLoading, required this.width, required this.primaryColor,
    required this.displayList, required this.allArticles, required this.viewedStoryLinks, required this.onStoryViewed,
    required this.visibleCount, required this.scrollController, required this.totalSources, required this.completedSources,
    required this.statusMessage, required this.onRefresh
  });

  @override
  Widget build(BuildContext context) {
    if (tabIndex == 1) return _videoPlaceholder();
    if (isLoading) return _loader();
    return RefreshIndicator(onRefresh: onRefresh, color: primaryColor, backgroundColor: AppColors.appSurface, child: displayList.isEmpty ? _emptyState() : _mainScrollArea());
  }

  Widget _mainScrollArea() {
    return ListView(
      controller: scrollController, physics: const AlwaysScrollableScrollPhysics(),
      children: [
        if (tabIndex == 0) StoryBar(
          allArticles: allArticles, 
          viewedStoryLinks: viewedStoryLinks, 
          onStoryViewed: onStoryViewed, 
          primaryColor: primaryColor
        ),
        Center(child: Container(constraints: const BoxConstraints(maxWidth: 1754), padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16), child: Column(children: [
          Center(child: Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: displayList.take(visibleCount).map((a) {
            if (width < 432) return FittedBox(key: ValueKey(a.link), fit: BoxFit.scaleDown, child: ArticleTile(article: a, primaryColor: primaryColor));
            return ArticleTile(key: ValueKey(a.link), article: a, primaryColor: primaryColor);
          }).toList())),
        ]))),
      ],
    );
  }

  Widget _videoPlaceholder() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(FontAwesomeIcons.videoSlash, size: 40, color: primaryColor.withValues(alpha: 0.3)), const SizedBox(height: 20), Text("VIDEO SIGNALS OFFLINE", style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, letterSpacing: 2)), const Text("Future feature currently in development.", style: TextStyle(color: AppColors.textMuted, fontSize: 10))]));
  Widget _loader() {
    double progress = totalSources > 0 ? completedSources / totalSources : 0;
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(value: (progress == 0) ? null : progress, color: primaryColor, strokeWidth: 6), const SizedBox(height: 30), Text("${(progress * 100).toInt()}%", style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 10), Text("RECEIVING SIGNALS...", style: TextStyle(color: primaryColor, fontSize: 10, letterSpacing: 4)), const SizedBox(height: 20), Text(statusMessage.toUpperCase(), style: const TextStyle(color: AppColors.textSubtle, fontSize: 9, letterSpacing: 1))]));
  }
  Widget _emptyState() => const Center(child: Text("NO SIGNALS FOUND"));
}