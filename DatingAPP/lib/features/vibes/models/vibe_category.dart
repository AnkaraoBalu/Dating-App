import 'package:flutter/material.dart';

class VibeCategory {
  const VibeCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.color,
    required this.interests,
  });

  final String id;
  final String title;
  final String description;
  final String emoji;
  final Color color;
  final List<String> interests;
}
