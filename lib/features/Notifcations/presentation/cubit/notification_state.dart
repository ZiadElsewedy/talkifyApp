import 'package:talkifyapp/features/Notifcations/Domain/Entite/Notification.dart' as app_notification;

enum NotificationStatus { initial, loading, loaded, error }

class NotificationState {
  final List<app_notification.Notification> notifications;
  final NotificationStatus status;
  final String errorMessage;
  final int unreadCount;
  final app_notification.Notification? newNotification;
  
  const NotificationState({
    this.notifications = const [],
    this.status = NotificationStatus.initial,
    this.errorMessage = '',
    this.unreadCount = 0,
    this.newNotification,
  });
  
  // Factory constructor for initial state
  factory NotificationState.initial() => const NotificationState();
  
  NotificationState copyWith({
    List<app_notification.Notification>? notifications,
    NotificationStatus? status,
    String? errorMessage,
    int? unreadCount,
    app_notification.Notification? newNotification,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      newNotification: newNotification,
    );
  }
  
  // Helper method to count unread notifications
  static int countUnread(List<app_notification.Notification> notifications) {
    return notifications.where((notification) => !notification.isRead).length;
  }
} 