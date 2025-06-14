import 'package:flutter/material.dart';
import 'package:talkifyapp/features/Notifcations/Domain/Entite/Notification.dart' as app_notification;
import 'package:talkifyapp/features/Notifcations/Domain/Entite/chat_notification.dart';
import 'package:talkifyapp/features/Notifcations/presentation/services/in_app_notification_service.dart';

/// A utility class to dispatch in-app notifications for various events
class NotificationDispatcher {
  /// Show an in-app notification when a like event occurs
  static void showLikeNotification({
    required BuildContext context,
    required String userName,
    required String userId,
    required String postId,
    String? userAvatar,
  }) {
    InAppNotificationService.show(
      context: context,
      title: 'New Like',
      message: '$userName liked your post',
      type: NotificationType.like,
      userId: userId,
      postId: postId,
      userAvatar: userAvatar,
    );
  }

  /// Show an in-app notification when a comment event occurs
  static void showCommentNotification({
    required BuildContext context,
    required String userName,
    required String userId,
    required String postId,
    required String comment,
    String? userAvatar,
  }) {
    String truncatedComment = comment.length > 30 
        ? '${comment.substring(0, 30)}...' 
        : comment;
        
    InAppNotificationService.show(
      context: context,
      title: 'New Comment',
      message: '$userName commented: "$truncatedComment"',
      type: NotificationType.comment,
      userId: userId,
      postId: postId,
      userAvatar: userAvatar,
    );
  }

  /// Show an in-app notification when a follow event occurs
  static void showFollowNotification({
    required BuildContext context,
    required String userName,
    required String userId,
    String? userAvatar,
  }) {
    InAppNotificationService.show(
      context: context,
      title: 'New Follower',
      message: '$userName started following you',
      type: NotificationType.follow,
      userId: userId,
      userAvatar: userAvatar,
    );
  }
  
  /// Show an in-app notification for a chat message
  static void showChatNotification({
    required BuildContext context,
    required String userName,
    required String userId,
    required String chatRoomId,
    required String message,
    String? userAvatar,
    String? chatRoomName,
    bool isGroupChat = false,
  }) {
    String truncatedMessage = message.length > 30 
        ? '${message.substring(0, 30)}...' 
        : message;
    
    String title = 'New Message';
    String displayMessage = '$userName: $truncatedMessage';
    
    // Add chat room name for group chats
    if (isGroupChat && chatRoomName != null && chatRoomName.isNotEmpty) {
      title = 'New Message in $chatRoomName';
    }
        
    InAppNotificationService.show(
      context: context,
      title: title,
      message: displayMessage,
      type: NotificationType.message,
      userId: userId,
      postId: chatRoomId,
      userAvatar: userAvatar,
    );
  }
  
  /// Show an in-app notification for a mention in chat
  static void showChatMentionNotification({
    required BuildContext context,
    required String userName,
    required String userId,
    required String chatRoomId,
    required String message,
    String? userAvatar,
    String? chatRoomName,
  }) {
    String truncatedMessage = message.length > 30 
        ? '${message.substring(0, 30)}...' 
        : message;
    
    String title = 'Mention in Chat';
    String displayMessage = '$userName mentioned you: "$truncatedMessage"';
    
    // Add chat room name if available
    if (chatRoomName != null && chatRoomName.isNotEmpty) {
      title = 'Mention in $chatRoomName';
    }
        
    InAppNotificationService.show(
      context: context,
      title: title,
      message: displayMessage,
      type: NotificationType.message,
      userId: userId,
      postId: chatRoomId,
      userAvatar: userAvatar,
    );
  }
  
  /// Show an in-app notification from a notification entity
  static void showFromNotification({
    required BuildContext context,
    required app_notification.Notification notification,
  }) {
    // Check if it's a chat notification
    if (notification is ChatNotification) {
      final chatNotif = notification;
      final isGroupChat = chatNotif.chatMetadata?['isGroupChat'] as bool? ?? false;
      final chatRoomName = chatNotif.chatMetadata?['chatRoomName'] as String? ?? '';
      
      // Show appropriate notification based on chat notification type
      switch (chatNotif.chatType) {
        case ChatNotificationType.message:
          showChatNotification(
            context: context,
            userName: chatNotif.triggerUserName,
            userId: chatNotif.triggerUserId,
            chatRoomId: chatNotif.chatRoomId,
            message: chatNotif.content,
            userAvatar: chatNotif.triggerUserProfilePic,
            chatRoomName: chatRoomName,
            isGroupChat: isGroupChat,
          );
          break;
          
        case ChatNotificationType.mentionInChat:
          showChatMentionNotification(
            context: context,
            userName: chatNotif.triggerUserName,
            userId: chatNotif.triggerUserId,
            chatRoomId: chatNotif.chatRoomId,
            message: chatNotif.content,
            userAvatar: chatNotif.triggerUserProfilePic,
            chatRoomName: chatRoomName,
          );
          break;
          
        case ChatNotificationType.groupInvite:
          InAppNotificationService.show(
            context: context,
            title: 'Group Chat Invite',
            message: '${chatNotif.triggerUserName} invited you to ${chatRoomName}',
            type: NotificationType.message,
            userId: chatNotif.triggerUserId,
            postId: chatNotif.chatRoomId,
            userAvatar: chatNotif.triggerUserProfilePic,
          );
          break;
          
        case ChatNotificationType.groupUpdate:
          InAppNotificationService.show(
            context: context,
            title: 'Group Chat Updated',
            message: chatNotif.content,
            type: NotificationType.message,
            userId: chatNotif.triggerUserId,
            postId: chatNotif.chatRoomId,
            userAvatar: chatNotif.triggerUserProfilePic,
          );
          break;
          
        case ChatNotificationType.roomCreated:
          InAppNotificationService.show(
            context: context,
            title: 'New Chat',
            message: chatNotif.content,
            type: NotificationType.message,
            userId: chatNotif.triggerUserId,
            postId: chatNotif.chatRoomId,
            userAvatar: chatNotif.triggerUserProfilePic,
          );
          break;
      }
    } else {
      // Handle regular notifications
      InAppNotificationService.show(
        context: context,
        title: _getTitleForNotificationType(notification.type),
        message: notification.content,
        type: _convertToServiceNotificationType(notification.type),
        userId: notification.triggerUserId,
        postId: notification.targetId,
        userAvatar: notification.triggerUserProfilePic,
        postThumbnail: notification.postImageUrl,
        isVideoPost: notification.isVideoPost,
      );
    }
  }

  static String _getTitleForNotificationType(app_notification.NotificationType type) {
    switch (type) {
      case app_notification.NotificationType.like:
        return 'New Like';
      case app_notification.NotificationType.comment:
        return 'New Comment';
      case app_notification.NotificationType.follow:
        return 'New Follower';
      case app_notification.NotificationType.message:
        return 'New Message';
      case app_notification.NotificationType.mention:
        return 'Mention';
      default:
        return 'Notification';
    }
  }

  static NotificationType _convertToServiceNotificationType(app_notification.NotificationType type) {
    switch (type) {
      case app_notification.NotificationType.like:
        return NotificationType.like;
      case app_notification.NotificationType.comment:
        return NotificationType.comment;
      case app_notification.NotificationType.follow:
        return NotificationType.follow;
      case app_notification.NotificationType.message:
        return NotificationType.message;
      case app_notification.NotificationType.mention:
        return NotificationType.message;
      default:
        throw Exception('Unsupported notification type');
    }
  }
} 