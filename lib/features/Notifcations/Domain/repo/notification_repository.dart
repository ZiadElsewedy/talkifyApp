import 'package:talkifyapp/features/Notifcations/Domain/Entite/Notification.dart';

abstract class NotificationRepository {
  /// Fetch all notifications for a specific user
  Future<List<Notification>> getNotifications(String userId);
  
  /// Create a notification for a user
  Future<void> createNotification(Notification notification);
  
  /// Delete a notification by ID
  Future<void> deleteNotification(String notificationId);
  
  /// Mark a notification as read
  Future<void> markNotificationAsRead(String notificationId);
  
  /// Get the count of unread notifications for a user
  Future<int> getUnreadNotificationCount(String userId);
  
  /// Stream of notifications for a user
  Stream<List<Notification>> getNotificationsStream(String userId);
} 