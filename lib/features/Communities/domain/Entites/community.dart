import 'package:flutter/material.dart';

class Community {
  final String id;
  final String name;
  final String description;
  final String category;
  final String iconUrl;
  final int memberCount;
  final String createdBy;
  final bool isPrivate;
  final DateTime createdAt;

  Community({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.iconUrl,
    required this.memberCount,
    required this.createdBy,
    required this.isPrivate,
    required this.createdAt,
  });
} 