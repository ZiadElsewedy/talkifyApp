import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:talkifyapp/features/Notifcations/Domain/Entite/Notification.dart' as app_notification;
import 'package:talkifyapp/features/Notifcations/Domain/repo/notification_repository.dart';
import 'package:talkifyapp/features/Notifcations/presentation/cubit/notification_state.dart';
import 'package:talkifyapp/features/Notifcations/presentation/utils/notification_dispatcher.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository notificationRepository;
  StreamSubscription<List<app_notification.Notification>>? _notificationSubscription;
  
  // Map to store pending delete operations with timeouts
  final Map<String, Timer> _pendingDeletes = {};
  
  // Store the latest notification IDs to prevent duplicate in-app notifications
  final Set<String> _processedNotificationIds = {};
  
  // Store BuildContext to show in-app notifications
  BuildContext? _context;
  
  NotificationCubit({
    required this.notificationRepository,
  }) : super(NotificationState.initial());
  
  // Initialize the notification cubit with context for in-app notifications
  void initialize(String userId, {BuildContext? context}) {
    print('NotificationCubit: Initializing for user $userId');
    _context = context;
    loadNotifications(userId);
    startNotificationStream(userId);
  }
  
  // Set context for showing in-app notifications
  void setContext(BuildContext context) {
    _context = context;
  }
  
  @override
  Future<void> close() async {
    print('NotificationCubit: Closing');
    // Cancel all pending delete operations
    for (final timer in _pendingDeletes.values) {
      timer.cancel();
    }
    _pendingDeletes.clear();
    
    await _notificationSubscription?.cancel();
    return super.close();
  }
  
  Future<void> loadNotifications(String userId) async {
    try {
      emit(state.copyWith(status: NotificationStatus.loading));
      
      final notifications = await notificationRepository.getNotifications(userId);
      final unreadCount = notifications.where((n) => !n.isRead).length;
      
      // Store current notification IDs to avoid duplicate in-app notifications
      for (final notification in notifications) {
        _processedNotificationIds.add(notification.id);
      }
      
      emit(state.copyWith(
        status: NotificationStatus.loaded,
        notifications: notifications,
        unreadCount: unreadCount,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: NotificationStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
  
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await notificationRepository.markNotificationAsRead(notificationId);
      
      // Update the notification locally
      final updatedNotifications = state.notifications.map((notification) {
        if (notification.id == notificationId) {
          return notification.copyWith(isRead: true);
        }
        return notification;
      }).toList();
      
      // Update unread count
      final unreadCount = updatedNotifications.where((n) => !n.isRead).length;
      
      emit(state.copyWith(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: e.toString(),
      ));
    }
  }
  
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      print('Marking all notifications as read for user $userId');
      
      // First update locally for responsive UI
      final updatedNotifications = state.notifications.map((notification) {
        return notification.copyWith(isRead: true);
      }).toList();
      
      emit(state.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
      ));
      
      // Then update in the repository
      await notificationRepository.markAllNotificationsAsRead(userId);
      print('All notifications marked as read');
    } catch (e) {
      print('Error marking all notifications as read: $e');
      emit(state.copyWith(
        errorMessage: 'Failed to mark all notifications as read: ${e.toString()}',
      ));
      
      // Reload notifications to ensure correct state
      loadNotifications(userId);
    }
  }
  
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final count = await notificationRepository.getUnreadNotificationCount(userId);
      emit(state.copyWith(unreadCount: count));
      return count;
    } catch (e) {
      return state.unreadCount;
    }
  }
  
  // Delete a notification with ability to restore
  Future<app_notification.Notification?> deleteNotification(String notificationId) async {
    try {
      // First find and store the notification for potential restore
      final deletedNotification = state.notifications.firstWhere(
        (notification) => notification.id == notificationId,
        orElse: () => throw Exception('Notification not found'),
      );
      
      if (deletedNotification == null) {
        return null;
      }
      
      // Cancel any existing pending delete for this notification
      if (_pendingDeletes.containsKey(notificationId)) {
        _pendingDeletes[notificationId]?.cancel();
        _pendingDeletes.remove(notificationId);
      }
      
      // Update local state immediately for responsive UI
      final updatedNotifications = state.notifications
          .where((notification) => notification.id != notificationId)
          .toList();
      
      final newUnreadCount = deletedNotification.isRead 
          ? state.unreadCount 
          : state.unreadCount - 1;
      
      emit(state.copyWith(
        notifications: updatedNotifications,
        unreadCount: newUnreadCount,
      ));
      
      // Schedule the actual deletion after 3 seconds
      _pendingDeletes[notificationId] = Timer(const Duration(seconds: 3), () async {
        try {
          // Delete from repository
          await notificationRepository.deleteNotification(notificationId);
          // Remove from pending deletes
          _pendingDeletes.remove(notificationId);
          print('Notification $notificationId deleted after delay');
        } catch (e) {
          print('Error in delayed deletion: $e');
        }
      });
      
      // Return the deleted notification for undo functionality
      return deletedNotification;
    } catch (e) {
      print('Error deleting notification: $e');
      emit(state.copyWith(
        errorMessage: 'Failed to delete notification: ${e.toString()}',
      ));
      return null;
    }
  }
  
  // Restore a deleted notification
  Future<void> restoreNotification(app_notification.Notification notification) async {
    try {
      // Check if notification already exists in current list (avoid duplicates)
      final exists = state.notifications.any((n) => n.id == notification.id);
      if (exists) {
        // Notification already restored, skip
        return;
      }
      
      // Cancel any pending delete operation for this notification
      if (_pendingDeletes.containsKey(notification.id)) {
        _pendingDeletes[notification.id]?.cancel();
        _pendingDeletes.remove(notification.id);
        print('Cancelled pending delete for notification ${notification.id}');
      } else {
        // If no pending delete, we need to re-add the notification to the repository
        await notificationRepository.createNotification(notification);
      }
      
      // Update local state
      final updatedNotifications = [...state.notifications, notification];
      
      // Sort by timestamp (newest first)
      updatedNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      // Update unread count if the notification was unread
      final newUnreadCount = notification.isRead 
          ? state.unreadCount 
          : state.unreadCount + 1;
      
      emit(state.copyWith(
        notifications: updatedNotifications,
        unreadCount: newUnreadCount,
      ));
    } catch (e) {
      print('Error restoring notification: $e');
      emit(state.copyWith(
        errorMessage: 'Failed to restore notification: ${e.toString()}',
      ));
    }
  }
  
  void startNotificationStream(String userId) {
    try {
      // Cancel any existing subscription first
      _notificationSubscription?.cancel();
      
      // Start listening to notifications stream
      _notificationSubscription = notificationRepository.getNotificationsStream(userId).listen(
        (notifications) {
          // Find new notifications by comparing with processed IDs
          final newNotifications = notifications.where(
            (notification) => !_processedNotificationIds.contains(notification.id)
          ).toList();

          // Show in-app notifications for new notifications
          if (newNotifications.isNotEmpty && _context != null) {
            // Get most recent notification to show
            final latestNotification = newNotifications.first;
            
            // Only show notifications for supported types
            if (_shouldShowInAppNotification(latestNotification)) {
              // Add a small delay to ensure context is ready
              Future.delayed(const Duration(milliseconds: 300), () {
                if (_context != null) {
                  NotificationDispatcher.showFromNotification(
                    context: _context!,
                    notification: latestNotification,
                  );
                }
              });
            }
            
            // Mark all new notification IDs as processed
            for (final notification in newNotifications) {
              _processedNotificationIds.add(notification.id);
            }
          }
          
          // Update unread count and notifications list
          final unreadCount = notifications.where((n) => !n.isRead).length;
          
          emit(state.copyWith(
            status: NotificationStatus.loaded,
            notifications: notifications,
            unreadCount: unreadCount,
          ));
        },
        onError: (error) {
          emit(state.copyWith(
            status: NotificationStatus.error,
            errorMessage: error.toString(),
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: NotificationStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
  
  // Check if we should show an in-app notification for this notification
  bool _shouldShowInAppNotification(app_notification.Notification notification) {
    // We only support these notification types for in-app notifications
    return notification.type == app_notification.NotificationType.like ||
           notification.type == app_notification.NotificationType.comment ||
           notification.type == app_notification.NotificationType.follow;
  }
} 