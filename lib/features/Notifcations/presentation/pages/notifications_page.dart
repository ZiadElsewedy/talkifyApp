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
import 'dart:async';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  late Timer _refreshTimer;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    
    // Initialize and load notifications
    _loadNotifications();
    
    // Set up auto-refresh timer for notifications
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) {
        _refreshNotifications();
      }
    });
  }

  void _loadNotifications() async {
    // Get current user ID
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = 'User not logged in';
        });
      }
      return;
    }
    
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _loadError = null;
        });
      }
      
      // Load notifications through the cubit
      await context.read<NotificationCubit>().loadNotifications(currentUser.uid);
      
      // Fix video thumbnails in notifications
      await context.read<NotificationCubit>().fixVideoThumbnails(currentUser.uid);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = e.toString();
        });
      }
    }
  }

  void _refreshNotifications() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || !mounted) return;
    
    // Reload notifications
    await context.read<NotificationCubit>().loadNotifications(currentUser.uid);
  }

  @override
  Widget build(BuildContext context) {
    // Check if there are any social notifications to show
    final theme = Theme.of(context);
    final notificationState = context.watch<NotificationCubit>().state;
    final socialNotifications = notificationState.notifications;
    final bool hasNotifications = socialNotifications.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: false,
        actions: _currentUserId.isNotEmpty ? [
          // Debug button to fix video thumbnails
          IconButton(
            icon: const Icon(Icons.video_library),
            tooltip: 'Fix video thumbnails',
            onPressed: () async {
              try {
                // Show loading dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Fixing video thumbnails...'),
                      ],
          ),
        ),
                );
                
                // Fix video thumbnails
                await context.read<NotificationCubit>().fixVideoThumbnails(_currentUserId);
                
                // Close loading dialog
                if (context.mounted) {
                  Navigator.of(context).pop();
                  
                  // Show success toast
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Video thumbnails fixed successfully'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                // Close loading dialog
                if (context.mounted) {
                  Navigator.of(context).pop();
                  
                  // Show error toast
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            tooltip: 'Mark all as read',
            onPressed: () async {
              try {
                await context.read<NotificationCubit>().markAllNotificationsAsRead(_currentUserId);
                
                // Show success toast
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('All notifications marked as read'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                }
              } catch (e) {
                // Show error toast
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ] : null,
      ),
      body: _isLoading 
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _loadError != null
              ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                      Text(
                        'Error loading notifications',
                        style: theme.textTheme.titleMedium,
                  ),
                      const SizedBox(height: 8),
                  Text(
                        _loadError!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                        onPressed: _loadNotifications,
                    child: const Text('Retry'),
                  ),
                ],
              ),
                )
              : !hasNotifications
                  ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                            size: 48,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                            style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                          const SizedBox(height: 8),
                          Text(
                            'When you get notifications, they will appear here',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                            textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _refreshNotifications,
                            child: const Text('Refresh'),
                      ),
                    ],
                  ),
                )
                  : ListView.separated(
                      padding: const EdgeInsets.only(top: 8.0),
                  itemCount: socialNotifications.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        thickness: 0.5,
                        color: theme.brightness == Brightness.dark 
                            ? Colors.grey.shade800 
                            : Colors.grey.shade300,
                        indent: 16,
                        endIndent: 16,
                      ),
                  itemBuilder: (context, index) {
                    final notification = socialNotifications[index];
                    return NotificationItem(
                      notification: notification,
                      onTap: () => _handleNotificationTap(notification),
                          onDeleted: (deletedNotification) {
                            // Handle notification deleted
                            // This is mostly for UI feedback if needed
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshNotifications,
        tooltip: 'Refresh notifications',
        child: const Icon(Icons.refresh),
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

  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }
} 