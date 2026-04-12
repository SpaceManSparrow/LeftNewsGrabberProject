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
}