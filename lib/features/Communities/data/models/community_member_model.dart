import '../../domain/Entites/community_member.dart';

class CommunityMemberModel extends CommunityMember {
  CommunityMemberModel({
    required String id,
    required String communityId,
    required String userId,
    required String userName,
    required String userAvatar,
    required MemberRole role,
    required DateTime joinedAt,
  }) : super(
          id: id,
          communityId: communityId,
          userId: userId,
          userName: userName,
          userAvatar: userAvatar,
          role: role,
          joinedAt: joinedAt,
        );

  factory CommunityMemberModel.fromJson(Map<String, dynamic> json) {
    return CommunityMemberModel(
      id: json['id'] ?? '',
      communityId: json['communityId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userAvatar: json['userAvatar'] ?? '',
      role: _mapStringToRole(json['role'] ?? 'member'),
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'communityId': communityId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'role': role.toString().split('.').last,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }

  static MemberRole _mapStringToRole(String roleStr) {
    switch (roleStr) {
      case 'admin':
        return MemberRole.admin;
      case 'moderator':
        return MemberRole.moderator;
      case 'member':
      default:
        return MemberRole.member;
    }
  }
} 