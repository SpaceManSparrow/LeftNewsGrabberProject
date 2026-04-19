import 'package:flutter/material.dart';
import '../models/article.dart';
import '../core/app_colors.dart';
import 'story_viewer.dart';

class StoryBar extends StatelessWidget {
  final List<Article> allArticles;
  final Set<String> viewedStoryLinks;
  final Function(String) onStoryViewed;
  final Color primaryColor;

  const StoryBar({
    super.key, 
    required this.allArticles, 
    required this.viewedStoryLinks, 
    required this.onStoryViewed, 
    required this.primaryColor
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final Map<String, List<Article>> storyMap = {};

    // 1. Group articles by source within 24h
    for (var article in allArticles) {
      if (now.difference(article.parsedDate).inHours < 24) {
        storyMap.putIfAbsent(article.source, () => []).add(article);
      }
    }
    if (storyMap.isEmpty) return const SizedBox.shrink();

    // 2. REORDERING LOGIC (Instagram Algorithm)
    final List<MapEntry<String, List<Article>>> unviewedEntries = [];
    final List<MapEntry<String, List<Article>>> viewedEntries = [];

    for (var entry in storyMap.entries) {
      bool isFullyViewed = entry.value.every((a) => viewedStoryLinks.contains(a.link));
      if (isFullyViewed) {
        viewedEntries.add(entry);
      } else {
        unviewedEntries.add(entry);
      }
    }

    // Sort both sub-lists by newest article
    unviewedEntries.sort((a, b) => b.value.first.parsedDate.compareTo(a.value.first.parsedDate));
    viewedEntries.sort((a, b) => b.value.first.parsedDate.compareTo(a.value.first.parsedDate));

    // Combine: Unviewed first, then fully viewed
    final finalEntries = [...unviewedEntries, ...viewedEntries];

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderSubtle))),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1754),
          height: 135,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            itemCount: finalEntries.length,
            itemBuilder: (context, index) {
              final entry = finalEntries[index];
              final source = entry.key;
              final stories = entry.value;
              final bool isFullyViewed = stories.every((a) => viewedStoryLinks.contains(a.link));

              return GestureDetector(
                onTap: () {
                  // Find index of first unviewed story, or start at 0 if all viewed
                  int startIndex = stories.indexWhere((a) => !viewedStoryLinks.contains(a.link));
                  if (startIndex == -1) startIndex = 0;

                  Navigator.push(context, MaterialPageRoute(builder: (context) => StoryViewer(
                    articles: stories, 
                    initialIndex: startIndex,
                    primaryColor: primaryColor, 
                    sourceName: source,
                    onStoryViewed: onStoryViewed,
                  )));
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle, 
                          border: Border.all(
                            color: isFullyViewed ? Colors.white24 : primaryColor, // Dull gray if viewed
                            width: 2
                          )
                        ),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.tileBackground,
                          child: Opacity(
                            opacity: isFullyViewed ? 0.5 : 1.0,
                            child: Text(
                              source.substring(0, source.length > 2 ? 2 : 1).toUpperCase(), 
                              style: TextStyle(
                                color: isFullyViewed ? Colors.white38 : primaryColor, 
                                fontWeight: FontWeight.w900, 
                                fontSize: 18
                              )
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(width: 80, child: Text(
                        source, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, 
                        style: TextStyle(
                          fontSize: 9, 
                          fontWeight: FontWeight.bold, 
                          color: isFullyViewed ? AppColors.textSubtle : AppColors.textMuted
                        )
                      )),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}