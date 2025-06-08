import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:talkifyapp/features/Notifcations/Domain/Entite/Notification.dart' as app_notification;
import 'package:talkifyapp/features/Notifcations/Domain/Entite/chat_notification.dart';
import 'package:talkifyapp/features/Notifcations/presentation/cubit/notification_cubit.dart';
import 'package:talkifyapp/features/Notifcations/presentation/cubit/notification_state.dart';
import 'package:talkifyapp/features/Notifcations/presentation/components/notification_item.dart';
import 'package:talkifyapp/features/Posts/presentation/cubits/post_cubit.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/ProfilePage.dart';
import 'package:talkifyapp/features/Profile/presentation/Cubits/ProfileCubit.dart';
import 'package:talkifyapp/features/Posts/PostComponents/SinglePostView.dart';
import 'package:talkifyapp/features/Notifcations/presentation/utils/notification_navigation.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    
    if (_currentUserId.isNotEmpty) {
      // Ensure notifications are loaded when page opens
      final notificationCubit = context.read<NotificationCubit>();
      notificationCubit.loadNotifications(_currentUserId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        backgroundColor: backgroundColor,
        title: Text(
          'Notifications',
          style: TextStyle(
            color: textColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          BlocBuilder<NotificationCubit, NotificationState>(
            builder: (context, state) {
              // Only show the "Mark all as read" button if there are unread notifications
              if (state.unreadCount > 0) {
                return IconButton(
                  icon: Icon(Icons.done_all, color: textColor),
                  onPressed: () {
                    final notificationCubit = context.read<NotificationCubit>();
                    notificationCubit.markAllNotificationsAsRead(_currentUserId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All notifications marked as read'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  tooltip: 'Mark all as read',
                );
              }
              return const SizedBox.shrink(); // Empty widget if no unread notifications
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          if (state.status == NotificationStatus.loading && state.notifications.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.black,
              ),
            );
          } else if (state.status == NotificationStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${state.errorMessage}',
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<NotificationCubit>().loadNotifications(_currentUserId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? Colors.grey[800] : Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (state.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 70,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'You will see notifications when someone interacts with your posts or comments',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            );
          }
          
          // Make sure we have the ProfileCubit available for the follow button in notifications
          final profileCubit = context.read<ProfileCubit>();
          
          // Get only social notifications (likes, comments, follows) and filter out message notifications
          final socialNotifications = state.notifications.where((notification) => 
            notification.type == app_notification.NotificationType.like || 
            notification.type == app_notification.NotificationType.comment || 
            notification.type == app_notification.NotificationType.follow
          ).toList();
          
          return RefreshIndicator(
            onRefresh: () => context.read<NotificationCubit>().loadNotifications(_currentUserId),
            child: socialNotifications.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 70,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No activity notifications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: socialNotifications.length,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 20),
                  itemBuilder: (context, index) {
                    final notification = socialNotifications[index];
                    
                    return NotificationItem(
                      notification: notification,
                      onTap: () => _handleNotificationTap(notification),
                      onDeleted: (_) {
                        // No additional action needed as deletion is handled in the NotificationItem
                      },
                    );
                  },
                ),
          );
        },
      ),
    );
  }

  void _handleNotificationTap(app_notification.Notification notification) {
    try {
      // Mark as read if not already read
      if (!notification.isRead) {
        context.read<NotificationCubit>().markNotificationAsRead(notification.id);
      }
      
      // Navigate to the appropriate screen based on notification type
      switch (notification.type) {
        case app_notification.NotificationType.like:
        case app_notification.NotificationType.comment:
        case app_notification.NotificationType.reply:
          // Check if targetId exists before navigating
          if (notification.targetId.isNotEmpty) {
            _navigateToPostInProfile(notification.targetId);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cannot view this post: missing reference'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          }
          break;
        case app_notification.NotificationType.follow:
          // Check if user ID exists before navigating
          if (notification.triggerUserId.isNotEmpty) {
            _navigateToUserProfile(notification.triggerUserId);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cannot view this user: missing reference'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          }
          break;
        case app_notification.NotificationType.mention:
          // Check if targetId exists before navigating
          if (notification.targetId.isNotEmpty) {
            _navigateToPostInProfile(notification.targetId);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cannot view this mention: missing reference'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          }
          break;
        case app_notification.NotificationType.message:
          // Use notification navigation for message notifications
          if (notification.targetId.isNotEmpty) {
            NotificationNavigation.navigateToDestination(
              context,
              notification.type,
              notification.targetId,
              notification.triggerUserId
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cannot open this chat: missing reference'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          }
          break;
      }
    } catch (e) {
      // Global error handler for any other exceptions
      print('Error handling notification tap: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing notification: $e'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
  
  void _navigateToPostInProfile(String postId) {
    // Check if postId is valid
    if (postId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Invalid post reference'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    
    // Clear any existing SnackBars to prevent conflicts
    ScaffoldMessenger.of(context).clearSnackBars();
    
    // Navigate directly to the SinglePostView instead of ProfilePage
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SinglePostView(postId: postId),
      ),
    );
  }
  
  void _navigateToUserProfile(String userId) {
    // Clear any existing SnackBars before navigation
    ScaffoldMessenger.of(context).clearSnackBars();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(userId: userId),
      ),
    );
  }
} 