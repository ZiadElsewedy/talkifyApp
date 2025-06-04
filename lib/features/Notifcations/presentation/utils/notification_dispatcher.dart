import 'package:flutter/material.dart';
import 'package:talkifyapp/features/Notifcations/Domain/Entite/Notification.dart' as app_notification;
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
  
  /// Show an in-app notification from a notification entity
  static void showFromNotification({
    required BuildContext context,
    required app_notification.Notification notification,
  }) {
    switch (notification.type) {
      case app_notification.NotificationType.like:
        showLikeNotification(
          context: context,
          userName: notification.triggerUserName,
          userId: notification.triggerUserId,
          postId: notification.targetId,
          userAvatar: notification.triggerUserProfilePic,
        );
        break;
        
      case app_notification.NotificationType.comment:
        showCommentNotification(
          context: context,
          userName: notification.triggerUserName,
          userId: notification.triggerUserId,
          postId: notification.targetId,
          comment: notification.content.replaceAll('${notification.triggerUserName} commented on your post: ', ''),
          userAvatar: notification.triggerUserProfilePic,
        );
        break;
        
      case app_notification.NotificationType.follow:
        showFollowNotification(
          context: context,
          userName: notification.triggerUserName,
          userId: notification.triggerUserId,
          userAvatar: notification.triggerUserProfilePic,
        );
        break;
        
      // For other types, we could add more cases in the future
      default:
        // No specialized handling for other notification types yet
        break;
    }
  }
} 