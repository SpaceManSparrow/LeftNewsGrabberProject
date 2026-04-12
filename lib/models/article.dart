import 'package:flutter/material.dart';

class Article {
  final String title, link, description, source, thumbnail;
  final String? author;
  final DateTime parsedDate;
  final List<String> topics;
  final Color? dominantColor;

  Article({
    required this.title,
    required this.link,
    required this.parsedDate,
    required this.description,
    required this.source,
    required this.thumbnail,
    required this.topics,
    this.author,
    this.dominantColor,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'link': link,
      'description': description,
      'source': source,
      'thumbnail': thumbnail,
      'author': author,
      'parsedDate': parsedDate.toIso8601String(),
      'topics': topics,
      'dominantColor': dominantColor?.toARGB32(),
    };
  }

  factory Article.fromMap(Map<String, dynamic> map) {
    return Article(
      title: map['title'] ?? '',
      link: map['link'] ?? '',
      description: map['description'] ?? '',
      source: map['source'] ?? '',
      thumbnail: map['thumbnail'] ?? '',
      author: map['author'],
      parsedDate: DateTime.parse(map['parsedDate']),
      topics: List<String>.from(map['topics'] ?? []),
      dominantColor: map['dominantColor'] != null ? Color(map['dominantColor']) : null,
    );
  }
}