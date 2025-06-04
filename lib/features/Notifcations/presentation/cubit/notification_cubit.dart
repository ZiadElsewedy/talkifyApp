import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:talkifyapp/features/Notifcations/Domain/repo/notification_repository.dart';
import 'package:talkifyapp/features/Notifcations/presentation/cubit/notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository notificationRepository;
  StreamSubscription? _notificationSubscription;
  
  NotificationCubit({
    required this.notificationRepository,
  }) : super(const NotificationState());
  
  Future<void> loadNotifications(String userId) async {
    try {
      emit(state.copyWith(status: NotificationStatus.loading));
      
      final notifications = await notificationRepository.getUserNotifications(userId);
      final unreadCount = NotificationState.countUnread(notifications);
      
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
      
      // Update local state
      final updatedNotifications = state.notifications.map((notification) {
        if (notification.id == notificationId) {
          return notification.copyWith(isRead: true);
        }
        return notification;
      }).toList();
      
      final unreadCount = NotificationState.countUnread(updatedNotifications);
      
      emit(state.copyWith(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to mark notification as read: ${e.toString()}',
      ));
    }
  }
  
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      await notificationRepository.markAllNotificationsAsRead(userId);
      
      // Update local state
      final updatedNotifications = state.notifications.map((notification) {
        return notification.copyWith(isRead: true);
      }).toList();
      
      emit(state.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to mark all notifications as read: ${e.toString()}',
      ));
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
  
  void startNotificationStream(String userId) {
    try {
      // Cancel any existing subscription first
      _notificationSubscription?.cancel();
      
      // Start listening to notifications stream
      _notificationSubscription = notificationRepository.streamUserNotifications(userId).listen(
        (notifications) {
          final unreadCount = NotificationState.countUnread(notifications);
          
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
  
  @override
  Future<void> close() {
    _notificationSubscription?.cancel();
    return super.close();
  }
} 