import 'package:talkifyapp/features/Notifcations/Domain/Entite/Notification.dart';

abstract class NotificationRepository {
  /// Fetch all notifications for a specific user
  Future<List<Notification>> getNotifications(String userId);
  
  /// Create a notification for a user
  Future<void> createNotification(Notification notification);
  
  /// Delete a notification by ID
  Future<void> deleteNotification(String notificationId);
  
  /// Remove notifications based on action parameters (when action is undone)
  Future<void> removeNotificationsByAction({
    required String triggerUserId,
    required String recipientId,
    required String targetId,
    required NotificationType type,
  });
  
  /// Remove a follow notification when a user unfollows another
  Future<void> removeFollowNotification(String followerId, String followedId);
  
  /// Remove a like notification when a user unlikes a post
  Future<void> removeLikeNotification(String likerId, String postOwnerId, String postId);
  
  /// Mark a notification as read
  Future<void> markNotificationAsRead(String notificationId);
  
  /// Mark all notifications as read for a user
  Future<void> markAllNotificationsAsRead(String userId);
  
  /// Get the count of unread notifications for a user
  Future<int> getUnreadNotificationCount(String userId);
  
  /// Stream of notifications for a user
  Stream<List<Notification>> getNotificationsStream(String userId);
  
  /// Update a notification with post information (thumbnail URL and isVideo flag)
  Future<void> updateNotificationPostInfo(String notificationId, String? postImageUrl, bool isVideoPost);
  
  /// Fix video thumbnails for existing notifications that are missing them
  Future<void> fixVideoThumbnailsForExistingNotifications(String userId);
} 