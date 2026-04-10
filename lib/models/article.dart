import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';

/// ===========================================================================
/// ARTICLE DATA MODEL & PARSING ENGINE
/// Handles cleaning, image scraping, and data normalization for RSS/Atom.
/// ===========================================================================
class Article {
  final String title, link, description, source, thumbnail;
  final DateTime parsedDate;
  final List<String> topics;

  Article({
    required this.title,
    required this.link,
    required this.parsedDate,
    required this.description,
    required this.source,
    required this.thumbnail,
    required this.topics,
  });

  /// Normalizes various date formats found in RSS and Atom feeds.
  static DateTime parseDate(String dateString) {
    if (dateString.isEmpty) return DateTime.now();

    // Attempt standard ISO parsing first
    DateTime? result = DateTime.tryParse(dateString);
    if (result != null) return result;

    try {
      // Handles RSS standard: "E, d MMM yyyy HH:mm:ss"
      // Strips timezone offsets like +0000 or -0500 for parsing safety
      String cleaned = dateString.split(' +').first.split(' -').first;
      return DateFormat("E, d MMM yyyy HH:mm:ss").parse(cleaned);
    } catch (_) {
      try {
        // Fallback for simple database-style timestamps
        return DateFormat("yyyy-MM-dd HH:mm:ss").parse(dateString);
      } catch (_) {
        return DateTime.now(); // Default to today if all parsing fails
      }
    }
  }

  /// Handles image proxying for Web builds to avoid CORS issues.
  /// Uses 'weserv.nl' to resize and serve images as WebP.
  static String wrapProxy(String url) {
    if (url.isEmpty) return "";
    if (!kIsWeb) return url;
    if (url.startsWith('https://images.weserv.nl')) return url;

      String clean = url;
    // Clean up WordPress-style image wrappers
    if (clean.contains("i0.wp.com/")) {
      clean = "https://${clean.split("i0.wp.com/").last.split("?").first}";
    }

    clean = Uri.decodeFull(clean);
    return "https://images.weserv.nl/?url=${Uri.encodeComponent(clean)}&w=1200&fit=cover&output=webp";
  }

  /// Sanitizes text by removing HTML tags, CDATA, and decoding character entities.
  static String cleanHtml(String html) {
    if (html.isEmpty) return "";

    // 1. Remove CDATA wrappers and physical HTML tags
    String result = html
    .replaceAll(RegExp(r'<!\[CDATA\[|\]\]>'), '')
    .replaceAll(RegExp(r'<[^>]*>'), '');

    // 2. Decode standard named HTML entities
    result = result
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&')
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>');

    // 3. Decode Numeric (Decimal and Hexadecimal) entities like &#8217; or &#x201C;
    result = result.replaceAllMapped(RegExp(r'&#x?([0-9a-fA-F]+);'), (match) {
      final String value = match.group(1)!;
      try {
        final int code = match.group(0)!.contains('x')
        ? int.parse(value, radix: 16)
        : int.parse(value);
        return String.fromCharCode(code);
      } catch (_) {
        return match.group(0)!;
      }
    });

    // 4. Final sweep for tags that may have been hidden inside entities
    return result.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  /// Extracts the 'src' attribute from the first <img> tag found in text.
  static String scrapeImage(String html) {
    RegExp imgExp = RegExp(r'<img[^>]+src="([^">]+)"');
    var matches = imgExp.allMatches(html);
    return matches.isNotEmpty ? matches.first.group(1) ?? '' : '';
  }
}
