import 'package:flutter/material.dart';

class CommunityMessage {
  final String id;
  final String communityId;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String text;
  final DateTime timestamp;
  final bool isPinned;

  CommunityMessage({
    required this.id,
    required this.communityId,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.text,
    required this.timestamp,
    this.isPinned = false,
  });
} 