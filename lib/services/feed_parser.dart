import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import '../models/article.dart';
import '../core/app_config.dart';

/// ===========================================================================
/// FEED PARSER SERVICE
/// The single source of truth for decoding XML, cleaning HTML, and scraping.
/// ===========================================================================
class FeedParser {
  /// Main entry point for converting raw XML into a list of Article objects.
  static List<Article> parse(String rawXml, String sourceName) {
    final List<Article> results = [];

    // Support both RSS (<item>) and Atom (<entry>)
    final itemRegex = RegExp(r'<item>(.*?)</item>', dotAll: true);
    final atomRegex = RegExp(r'<entry>(.*?)</entry>', dotAll: true);

    Iterable<RegExpMatch> items = itemRegex.allMatches(rawXml);
    if (items.isEmpty) items = atomRegex.allMatches(rawXml);

    for (var match in items) {
      final content = match.group(1) ?? '';

      // 1. Extract Title (Supports tags with attributes like <title type="text">)
      String title = cleanHtml(
        RegExp(r'<title[^>]*>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</title>', dotAll: true)
        .firstMatch(content)
        ?.group(1) ?? 'Untitled');

      // 2. Extract Link
      String link = RegExp(r'href="([^"]+)"').firstMatch(content)?.group(1) ??
      RegExp(r'<link>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</link>', dotAll: true)
      .firstMatch(content)
      ?.group(1) ?? '';

      // 3. Extract Date
      String pubDateStr = RegExp(r'<pubDate>(.*?)</pubDate>', dotAll: true).firstMatch(content)?.group(1) ??
      RegExp(r'<published>(.*?)</published>', dotAll: true).firstMatch(content)?.group(1) ??
      RegExp(r'<updated>(.*?)</updated>', dotAll: true).firstMatch(content)?.group(1) ?? '';

      // 4. Extract Description / Content
      String summary = RegExp(r'<summary.*?>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</summary>', dotAll: true).firstMatch(content)?.group(1) ?? '';
      String description = RegExp(r'<description>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</description>', dotAll: true).firstMatch(content)?.group(1) ?? '';
      String fullContent = RegExp(r'<content.*?>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</content>', dotAll: true).firstMatch(content)?.group(1) ?? '';

      // Choose best available text for the snippet
      String bestDesc = summary.isNotEmpty ? summary : (description.isNotEmpty ? description : fullContent);

      // 5. Extract Thumbnail (Multi-step process)
      String thumb = scrapeImage(fullContent);
      if (thumb.isEmpty) thumb = scrapeImage(description);
      if (thumb.isEmpty) thumb = scrapeImage(summary);
      
      // Step D: Check for media enclosure tags
      if (thumb.isEmpty) {
        thumb = RegExp(r'<media:content[^>]+url="(.*?)"').firstMatch(content)?.group(1) ?? '';
      }

      // Step E: Final Last Resort - Deep scan entire block for any direct image URL
      if (thumb.isEmpty) {
        final deepScan = RegExp(r'(https?://[^\s"<>]+?\.(?:jpg|jpeg|png|webp))', caseSensitive: false);
        thumb = deepScan.firstMatch(content)?.group(1) ?? '';
      }

      // 6. Topic Categorization Logic
      String searchable = "$title $bestDesc $fullContent".toLowerCase();
      List<String> tags = [];
      AppConfig.topics.forEach((name, keywords) {
        if (keywords.any((k) => searchable.contains(k))) {
          if (!tags.contains(name)) tags.add(name);
        }
      });

      results.add(Article(
        title: title,
        link: link,
        source: sourceName,
        topics: tags,
        description: cleanHtml(bestDesc),
        thumbnail: wrapProxy(thumb),
        parsedDate: parseDate(pubDateStr),
      ));
    }
    return results;
  }

  static DateTime parseDate(String dateString) {
    if (dateString.isEmpty) return DateTime.now();
    DateTime? result = DateTime.tryParse(dateString);
    if (result != null) return result;
    try {
      String cleaned = dateString.split(' +').first.split(' -').first;
      return DateFormat("E, d MMM yyyy HH:mm:ss").parse(cleaned);
    } catch (_) {
      try {
        return DateFormat("yyyy-MM-dd HH:mm:ss").parse(dateString);
      } catch (_) {
        return DateTime.now();
      }
    }
  }

  static String cleanHtml(String html) {
    if (html.isEmpty) return "";
    
    // 1. Remove CDATA wrappers
    String result = html.replaceAll(RegExp(r'<!\[CDATA\[|\]\]>'), '');

    // 2. Decode all entities FIRST (converting &lt;p&gt; into <p>)
    result = result
    .replaceAll(RegExp(r'&amp;nbsp;|&nbsp;'), ' ')
    .replaceAll('&amp;', '&')
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&hellip;', '...')
    .replaceAll('&ndash;', '-')
    .replaceAll('&mdash;', '-');

    // Decode Numeric entities
    result = result.replaceAllMapped(RegExp(r'&#x?([0-9a-fA-F]+);'), (match) {
      final String value = match.group(1)!;
      try {
        final int code = match.group(0)!.contains('x') ? int.parse(value, radix: 16) : int.parse(value);
        return String.fromCharCode(code);
      } catch (_) {
        return match.group(0)!;
      }
    });

    // 3. Strip all HTML tags (literal and previously escaped)
    result = result.replaceAll(RegExp(r'<[^>]*>', dotAll: true), '');

    // 4. Final trim and cleanup of excess whitespace
    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String scrapeImage(String html) {
    // Triple-quoted raw string to prevent syntax errors with mixed single/double quotes
    final RegExp imgExp = RegExp(r"""<img[^>]+src=["']([^"']+)["']""", caseSensitive: false);
    final match = imgExp.firstMatch(html);
    return match?.group(1) ?? '';
  }

  static String wrapProxy(String url) {
    if (url.isEmpty) return "";
    if (!kIsWeb) return url;
    if (url.startsWith('https://images.weserv.nl')) return url;
      String clean = url;
    if (clean.contains("i0.wp.com/")) {
      clean = "https://${clean.split("i0.wp.com/").last.split("?").first}";
    }
    clean = Uri.decodeFull(clean);
    return "https://images.weserv.nl/?url=${Uri.encodeComponent(clean)}&w=1200&fit=cover&output=webp";
  }
}