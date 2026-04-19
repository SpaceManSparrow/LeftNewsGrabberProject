import 'package:flutter/material.dart';
import '../models/article.dart';
import '../core/app_colors.dart';
import 'story_viewer.dart';

/// ===========================================================================
/// STORY BAR
/// Displays a horizontal list of organizations with recent activity.
/// ===========================================================================
class StoryBar extends StatelessWidget {
  final List<Article> allArticles;
  final Color primaryColor;

  const StoryBar({
    super.key,
    required this.allArticles,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Group articles by source for those posted in the last 24 hours
    final now = DateTime.now();
    final Map<String, List<Article>> storyMap = {};

    for (var article in allArticles) {
      if (now.difference(article.parsedDate).inHours < 24) {
        storyMap.putIfAbsent(article.source, () => []).add(article);
      }
    }

    if (storyMap.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1754),
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
            itemCount: storyMap.length,
            itemBuilder: (context, index) {
              String source = storyMap.keys.elementAt(index);
              List<Article> stories = storyMap[source]!;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StoryViewer(
                        articles: stories,
                        primaryColor: primaryColor,
                        sourceName: source,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: primaryColor, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.tileBackground,
                          child: Text(
                            source.substring(0, source.length > 2 ? 2 : 1).toUpperCase(),
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        source,
                        style: const TextStyle(
                          fontSize: 9, 
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMuted
                        ),
                      ),
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