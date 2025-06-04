import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:talkifyapp/features/Notifcations/Domain/Entite/Notification.dart' as app_notification;
import 'package:talkifyapp/features/Notifcations/presentation/cubit/notification_cubit.dart';
import 'package:talkifyapp/features/Notifcations/presentation/cubit/notification_state.dart';
import 'package:talkifyapp/features/Notifcations/presentation/components/notification_item.dart';
import 'package:talkifyapp/features/Posts/presentation/cubits/post_cubit.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/ProfilePage.dart';

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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.white,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          BlocBuilder<NotificationCubit, NotificationState>(
            builder: (context, state) {
              // Only show the "Mark all as read" button if there are unread notifications
              if (state.unreadCount > 0) {
                return IconButton(
                  icon: const Icon(Icons.done_all, color: Colors.black),
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
                      backgroundColor: Colors.black,
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
          
          return RefreshIndicator(
            onRefresh: () => context.read<NotificationCubit>().loadNotifications(_currentUserId),
            child: ListView.builder(
              itemCount: state.notifications.length,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 20),
              itemBuilder: (context, index) {
                final notification = state.notifications[index];
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
    // Mark as read if not already read
    if (!notification.isRead) {
      context.read<NotificationCubit>().markNotificationAsRead(notification.id);
    }
    
    // Navigate to the appropriate screen based on notification type
    switch (notification.type) {
      case app_notification.NotificationType.like:
      case app_notification.NotificationType.comment:
      case app_notification.NotificationType.reply:
        // Navigate to the post
        _navigateToPostInProfile(notification.targetId);
        break;
      case app_notification.NotificationType.follow:
        // Navigate to the user profile
        _navigateToUserProfile(notification.triggerUserId);
        break;
      case app_notification.NotificationType.mention:
        // Navigate to the post where the user was mentioned
        _navigateToPostInProfile(notification.targetId);
        break;
    }
  }
  
  void _navigateToPostInProfile(String postId) {
    // Get the post data first to determine the owner
    final postCubit = context.read<PostCubit>();
    
    // Clear any existing SnackBars to prevent conflicts
    ScaffoldMessenger.of(context).clearSnackBars();
    
    postCubit.getPostById(postId).then((post) {
      if (post != null && mounted) {  // Check if widget is still mounted
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(
              userId: post.UserId,
            ),
          ),
        );
        
        // Show a snackbar to indicate which post was interacted with
        if (mounted) {  // Double check before showing SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Viewing post from ${post.UserName}'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else if (mounted) {  // Check if widget is still mounted
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post not found'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }).catchError((error) {
      if (mounted) {  // Check if widget is still mounted
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
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