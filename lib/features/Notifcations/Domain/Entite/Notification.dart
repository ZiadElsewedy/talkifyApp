import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  like,
  comment,
  reply,
  follow,
  mention,
  message   // Added for regular chat messages
}

class Notification {
  final String id;
  final String recipientId; // User who will receive the notification
  final String triggerUserId; // User who triggered the notification
  final String triggerUserName;
  final String triggerUserProfilePic;
  final String targetId; // ID of post, comment or other content
  final NotificationType type;
  final String content; // Short description of notification
  final DateTime timestamp;
  final bool isRead;
  final String? postImageUrl; // URL of the post image thumbnail
  final bool isVideoPost; // Flag to indicate if the post is a video
  
  const Notification({
    required this.id,
    required this.recipientId,
    required this.triggerUserId,
    required this.triggerUserName,
    required this.triggerUserProfilePic,
    required this.targetId,
    required this.type,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.postImageUrl,
    this.isVideoPost = false,
  });

  Notification copyWith({
    bool? isRead,
    String? triggerUserProfilePic,
    String? postImageUrl,
    bool? isVideoPost,
  }) {
    return Notification(
      id: id,
      recipientId: recipientId,
      triggerUserId: triggerUserId,
      triggerUserName: triggerUserName,
      triggerUserProfilePic: triggerUserProfilePic ?? this.triggerUserProfilePic,
      targetId: targetId,
      type: type,
      content: content,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      postImageUrl: postImageUrl ?? this.postImageUrl,
      isVideoPost: isVideoPost ?? this.isVideoPost,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipientId': recipientId,
      'triggerUserId': triggerUserId,
      'triggerUserName': triggerUserName,
      'triggerUserProfilePic': triggerUserProfilePic,
      'targetId': targetId,
      'type': type.toString().split('.').last,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'postImageUrl': postImageUrl,
      'isVideoPost': isVideoPost,
    };
  }

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as String,
      recipientId: json['recipientId'] as String? ?? json['userId'] as String, // Support both field names
      triggerUserId: json['triggerUserId'] as String,
      triggerUserName: json['triggerUserName'] as String,
      triggerUserProfilePic: json['triggerUserProfilePic'] as String,
      targetId: json['targetId'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => NotificationType.like,
      ),
      content: json['content'] as String,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      isRead: json['isRead'] as bool? ?? false,
      postImageUrl: json['postImageUrl'] as String?,
      isVideoPost: json['isVideoPost'] as bool? ?? false,
    );
  }
} 