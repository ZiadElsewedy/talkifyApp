import '../../domain/Entites/community_message.dart';

class CommunityMessageModel extends CommunityMessage {
  CommunityMessageModel({
    required String id,
    required String communityId,
    required String senderId,
    required String senderName,
    required String senderAvatar,
    required String text,
    required DateTime timestamp,
    bool isPinned = false,
  }) : super(
          id: id,
          communityId: communityId,
          senderId: senderId,
          senderName: senderName,
          senderAvatar: senderAvatar,
          text: text,
          timestamp: timestamp,
          isPinned: isPinned,
        );

  factory CommunityMessageModel.fromJson(Map<String, dynamic> json) {
    return CommunityMessageModel(
      id: json['id'] ?? '',
      communityId: json['communityId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      senderAvatar: json['senderAvatar'] ?? '',
      text: json['text'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      isPinned: json['isPinned'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'communityId': communityId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'isPinned': isPinned,
    };
  }
} 