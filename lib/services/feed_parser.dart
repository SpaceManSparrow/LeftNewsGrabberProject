import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parseFragment; 
import '../models/article.dart';
import '../core/app_config.dart';

class FeedParser {
  static List<Article> parse(String rawXml, String sourceName) {
    final List<Article> results = [];
    final itemRegex = RegExp(r'<item>(.*?)</item>', dotAll: true);
    final atomRegex = RegExp(r'<entry>(.*?)</entry>', dotAll: true);

    Iterable<RegExpMatch> items = itemRegex.allMatches(rawXml);
    if (items.isEmpty) items = atomRegex.allMatches(rawXml);

    for (var match in items) {
      final content = match.group(1) ?? '';

      String title = cleanHtml(RegExp(r'<title[^>]*>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</title>', dotAll: true).firstMatch(content)?.group(1) ?? 'Untitled');

      if (AppConfig.globalSources.values.contains(sourceName)) {
        bool isRelevant = AppConfig.auKeywords.any((k) {
          final pattern = r'\b' + k.toLowerCase() + r'\b';
          return RegExp(pattern).hasMatch(title.toLowerCase());
        });
        if (!isRelevant) continue;
      }

      String link = RegExp(r'<link>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</link>', dotAll: true).firstMatch(content)?.group(1) ?? 
                    RegExp(r"""<link[^>]+href=["']([^"']+)["']""").firstMatch(content)?.group(1) ?? '';
      String pubDateStr = RegExp(r'<pubDate>(.*?)</pubDate>', dotAll: true).firstMatch(content)?.group(1) ?? 
                          RegExp(r'<published>(.*?)</published>', dotAll: true).firstMatch(content)?.group(1) ?? '';

      String summary = RegExp(r'<summary.*?>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</summary>', dotAll: true).firstMatch(content)?.group(1) ?? '';
      String description = RegExp(r'<description>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</description>', dotAll: true).firstMatch(content)?.group(1) ?? '';
      String bestDesc = summary.isNotEmpty ? summary : description;

      List<String> tags = [];
      bool isTheory = AppConfig.theoryKeywords.any((k) => "$title $bestDesc".toLowerCase().contains(k.toLowerCase()));
      if (isTheory) tags.add("THEORY/REVIEW");

      AppConfig.topics.forEach((name, keywords) {
        if (keywords.any((k) => "$title $bestDesc".toLowerCase().contains(k))) {
          if (!tags.contains(name)) tags.add(name);
        }
      });

      results.add(Article(
        title: title,
        link: link.trim(),
        source: sourceName,
        topics: tags,
        description: cleanHtml(bestDesc),
        thumbnail: wrapProxy(scrapeImage(content + bestDesc)),
        parsedDate: parseDate(pubDateStr),
      ));
    }
    return results;
  }

  static Future<String> scrapeUrlForImage(String url) async {
    if (url.isEmpty) return "";
    try {
      String finalUrl = kIsWeb ? 'https://corsproxy.io/?${Uri.encodeComponent(url)}' : url;
      final response = await http.get(Uri.parse(finalUrl)).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final ogMatch = RegExp(r"""<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)["']""").firstMatch(response.body);
        return ogMatch?.group(1) ?? "";
      }
    } catch (_) {}
    return "";
  }

  static DateTime parseDate(String s) {
    if (s.isEmpty) return DateTime.now();
    DateTime? r = DateTime.tryParse(s);
    if (r != null) return r;
    try {
      String c = s.split(' +').first.split(' -').first;
      return DateFormat("E, d MMM yyyy HH:mm:ss").parse(c);
    } catch (_) { return DateTime.now(); }
  }

  /// AGGRESSIVE RECURSIVE CLEANER
  static String cleanHtml(String input) {
    if (input.isEmpty) return "";

    // 1. Pre-emptive strike on specific broken patterns
    String result = input
        .replaceAll(RegExp(r'<!\[CDATA\[|\]\]>'), '')
        .replaceAll('amp;nbsp', ' ')
        .replaceAll('&nbsp;', ' ');

    // 2. Recursive Decoding
    // Some feeds encode things 2 or 3 times. We keep decoding until 
    // the string stops changing or no entities remain.
    String previous;
    int limit = 0;
    do {
      previous = result;
      result = parseFragment(result).text ?? "";
      limit++;
    } while (result != previous && limit < 3);

    // 3. Final Regular Expression sweep
    // This removes literal strings like "<p>" if they survived as text
    result = result
        .replaceAll(RegExp(r'<[^>]*>', dotAll: true), '') 
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return result;
  }

  static String scrapeImage(String h) => RegExp(r"""<img[^>]+src=["']([^"']+)["']""", caseSensitive: false).firstMatch(h)?.group(1) ?? '';

  static String wrapProxy(String u) {
    if (u.isEmpty || !kIsWeb || u.startsWith('https://images.weserv.nl')) return u;
    return "https://images.weserv.nl/?url=${Uri.encodeComponent(u)}&w=1200&fit=cover&output=webp";
  }
}