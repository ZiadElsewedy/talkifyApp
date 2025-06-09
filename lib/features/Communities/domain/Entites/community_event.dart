import 'package:flutter/material.dart';

class CommunityEvent {
  final String id;
  final String communityId;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String createdBy;
  final DateTime createdAt;
  final String location;
  final bool isOnline;
  final String meetingLink;
  final List<String> attendees;

  CommunityEvent({
    required this.id,
    required this.communityId,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.createdBy,
    required this.createdAt,
    required this.location,
    required this.isOnline,
    required this.meetingLink,
    required this.attendees,
  });
} 