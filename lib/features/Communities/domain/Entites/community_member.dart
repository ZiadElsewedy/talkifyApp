import 'package:flutter/material.dart';

enum MemberRole {
  member,
  moderator,
  admin,
}

class CommunityMember {
  final String id;
  final String communityId;
  final String userId;
  final String userName;
  final String userAvatar;
  final MemberRole role;
  final DateTime joinedAt;

  CommunityMember({
    required this.id,
    required this.communityId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.role,
    required this.joinedAt,
  });
} 