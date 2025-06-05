import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:talkifyapp/features/Notifcations/Domain/Entite/Notification.dart';

enum ChatNotificationType {
  message,          // Regular chat message
  groupInvite,      // Invitation to join a group chat
  groupUpdate,      // Group chat updates (name change, etc.)
  mentionInChat,    // User mentioned in a chat
  roomCreated       // New chat room created
}

class ChatNotification extends Notification {
  final String chatRoomId;
  final String? messageId;
  final ChatNotificationType chatType;
  final Map<String, dynamic>? chatMetadata;

  const ChatNotification({
    required String id,
    required String recipientId,
    required String triggerUserId,
    required String triggerUserName,
    required String triggerUserProfilePic,
    required String targetId,
    required String content,
    required DateTime timestamp,
    required this.chatRoomId,
    required this.chatType,
    this.messageId,
    this.chatMetadata,
    bool isRead = false,
    String? postImageUrl,
  }) : super(
    id: id,
    recipientId: recipientId,
    triggerUserId: triggerUserId,
    triggerUserName: triggerUserName,
    triggerUserProfilePic: triggerUserProfilePic,
    targetId: targetId,
    type: NotificationType.mention, // Using mention type for all chat notifications
    content: content,
    timestamp: timestamp,
    isRead: isRead,
    postImageUrl: postImageUrl,
  );

  @override
  ChatNotification copyWith({
    bool? isRead,
    String? triggerUserProfilePic,
    String? postImageUrl,
  }) {
    return ChatNotification(
      id: id,
      recipientId: recipientId,
      triggerUserId: triggerUserId,
      triggerUserName: triggerUserName,
      triggerUserProfilePic: triggerUserProfilePic ?? this.triggerUserProfilePic,
      targetId: targetId,
      content: content,
      timestamp: timestamp,
      chatRoomId: chatRoomId,
      chatType: chatType,
      messageId: messageId,
      chatMetadata: chatMetadata,
      isRead: isRead ?? this.isRead,
      postImageUrl: postImageUrl ?? this.postImageUrl,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'chatRoomId': chatRoomId,
      'messageId': messageId,
      'chatType': chatType.toString().split('.').last,
      'chatMetadata': chatMetadata,
    };
  }

  factory ChatNotification.fromJson(Map<String, dynamic> json) {
    final baseNotification = Notification.fromJson(json);
    
    return ChatNotification(
      id: baseNotification.id,
      recipientId: baseNotification.recipientId,
      triggerUserId: baseNotification.triggerUserId,
      triggerUserName: baseNotification.triggerUserName,
      triggerUserProfilePic: baseNotification.triggerUserProfilePic,
      targetId: baseNotification.targetId,
      content: baseNotification.content,
      timestamp: baseNotification.timestamp,
      isRead: baseNotification.isRead,
      postImageUrl: baseNotification.postImageUrl,
      chatRoomId: json['chatRoomId'] as String,
      messageId: json['messageId'] as String?,
      chatType: ChatNotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == json['chatType'],
        orElse: () => ChatNotificationType.message,
      ),
      chatMetadata: json['chatMetadata'] as Map<String, dynamic>?,
    );
  }
} 