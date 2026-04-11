import 'package:flutter/material.dart';

/// ===========================================================================
/// ARTICLE DATA MODEL
/// Simple data container for article information.
/// ===========================================================================
class Article {
  final String title, link, description, source, thumbnail;
  final DateTime parsedDate;
  final List<String> topics;
  final Color? dominantColor; // ADDED: Field for vibrant slide background

  Article({
    required this.title,
    required this.link,
    required this.parsedDate,
    required this.description,
    required this.source,
    required this.thumbnail,
    required this.topics,
    this.dominantColor, // ADDED: Optional parameter
  });
}