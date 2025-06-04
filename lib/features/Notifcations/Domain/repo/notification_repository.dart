import 'package:talkifyapp/features/Notifcations/Domain/Entite/Notification.dart';

abstract class NotificationRepository {
  Future<void> createNotification(Notification notification);
  Future<List<Notification>> getUserNotifications(String userId);
  Future<void> markNotificationAsRead(String notificationId);
  Future<void> markAllNotificationsAsRead(String userId);
  Future<void> deleteNotification(String notificationId);
  Future<int> getUnreadNotificationCount(String userId);
  Stream<List<Notification>> streamUserNotifications(String userId);
} 