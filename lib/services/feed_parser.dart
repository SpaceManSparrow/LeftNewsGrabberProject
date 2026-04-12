import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
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
      
      // Targeted Link Extraction (Prevents grabbing body-text URLs)
      String link = RegExp(r'<link>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</link>', dotAll: true).firstMatch(content)?.group(1) ?? 
                    RegExp(r"""<link[^>]+href=["']([^"']+)["']""").firstMatch(content)?.group(1) ?? '';

      String pubDateStr = RegExp(r'<pubDate>(.*?)</pubDate>', dotAll: true).firstMatch(content)?.group(1) ?? 
                          RegExp(r'<published>(.*?)</published>', dotAll: true).firstMatch(content)?.group(1) ?? 
                          RegExp(r'<updated>(.*?)</updated>', dotAll: true).firstMatch(content)?.group(1) ?? '';
      
      String author = cleanHtml(RegExp(r'<dc:creator[^>]*>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</dc:creator>', dotAll: true).firstMatch(content)?.group(1) ?? 
                                RegExp(r'<author[^>]*>.*?<name[^>]*>(.*?)</name>', dotAll: true).firstMatch(content)?.group(1) ?? '');

      String summary = RegExp(r'<summary.*?>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</summary>', dotAll: true).firstMatch(content)?.group(1) ?? '';
      String description = RegExp(r'<description>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</description>', dotAll: true).firstMatch(content)?.group(1) ?? '';
      String fullContent = RegExp(r'<content.*?>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</content>', dotAll: true).firstMatch(content)?.group(1) ?? '';
      String bestDesc = summary.isNotEmpty ? summary : (description.isNotEmpty ? description : fullContent);

      String thumb = scrapeImage(fullContent);
      if (thumb.isEmpty) thumb = scrapeImage(description);
      if (thumb.isEmpty) thumb = scrapeImage(summary);
      if (thumb.isEmpty) thumb = RegExp(r'<media:content[^>]+url="(.*?)"').firstMatch(content)?.group(1) ?? '';
      if (thumb.isEmpty) thumb = RegExp(r'(https?://[^\s"<>]+?\.(?:jpg|jpeg|png|webp))', caseSensitive: false).firstMatch(content)?.group(1) ?? '';

      List<String> tags = [];
      AppConfig.topics.forEach((name, keywords) {
        if (keywords.any((k) => "$title $bestDesc".toLowerCase().contains(k))) {
          if (!tags.contains(name)) tags.add(name);
        }
      });

      results.add(Article(
        title: title, link: link.trim(), source: sourceName, topics: tags,
        description: cleanHtml(bestDesc), thumbnail: wrapProxy(thumb),
        parsedDate: parseDate(pubDateStr), author: author.isNotEmpty ? author : null,
      ));
    }
    return results;
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

  static String cleanHtml(String h) {
    if (h.isEmpty) return "";
    String r = h.replaceAll(RegExp(r'<!\[CDATA\[|\]\]>'), '')
                .replaceAll(RegExp(r'&amp;nbsp;|&nbsp;'), ' ')
                .replaceAll('&amp;', '&').replaceAll('&quot;', '"').replaceAll('&apos;', "'").replaceAll('&lt;', '<').replaceAll('&gt;', '>')
                .replaceAll('&hellip;', '...').replaceAll('&ndash;', '-').replaceAll('&mdash;', '-');
    r = r.replaceAllMapped(RegExp(r'&#x?([0-9a-fA-F]+);'), (m) {
      try { return String.fromCharCode(m.group(0)!.contains('x') ? int.parse(m.group(1)!, radix: 16) : int.parse(m.group(1)!)); } catch (_) { return m.group(0)!; }
    });
    return r.replaceAll(RegExp(r'<[^>]*>', dotAll: true), '').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String scrapeImage(String h) => RegExp(r"""<img[^>]+src=["']([^"']+)["']""", caseSensitive: false).firstMatch(h)?.group(1) ?? '';

  static String wrapProxy(String u) {
    if (u.isEmpty || !kIsWeb || u.startsWith('https://images.weserv.nl')) return u;
    String c = u.contains("i0.wp.com/") ? "https://${u.split("i0.wp.com/").last.split("?").first}" : u;
    return "https://images.weserv.nl/?url=${Uri.encodeComponent(Uri.decodeFull(c))}&w=1200&fit=cover&output=webp";
  }
}