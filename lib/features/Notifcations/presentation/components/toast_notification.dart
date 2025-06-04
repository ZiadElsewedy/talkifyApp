import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:talkifyapp/features/Notifcations/Domain/Entite/Notification.dart' as app_notification;
import 'package:talkifyapp/features/Profile/presentation/Pages/ProfilePage.dart';
import 'package:talkifyapp/features/Posts/presentation/HomePage.dart';

class ToastNotification extends StatelessWidget {
  final app_notification.Notification notification;
  final VoidCallback onDismiss;
  
  const ToastNotification({
    Key? key,
    required this.notification,
    required this.onDismiss,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () {
          onDismiss();
          _handleNavigation(context);
        },
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: ModalRoute.of(context)?.animation ?? AnimationController(vsync: Scaffold.of(context), duration: Duration.zero),
            curve: Curves.easeOut,
          )),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      // Profile picture
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: notification.triggerUserProfilePic.isNotEmpty
                            ? CachedNetworkImageProvider(notification.triggerUserProfilePic)
                            : null,
                        child: notification.triggerUserProfilePic.isEmpty
                            ? const Icon(Icons.person, size: 20, color: Colors.grey)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      
                      // Notification content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              notification.triggerUserName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _getActionText(notification.type),
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Notification icon or post image
                      if (notification.postImageUrl != null && notification.postImageUrl!.isNotEmpty)
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey.shade300),
                            image: DecorationImage(
                              image: CachedNetworkImageProvider(notification.postImageUrl!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getNotificationColor(notification.type).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getNotificationIcon(notification.type),
                            color: _getNotificationColor(notification.type),
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Close button
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    color: Colors.grey,
                    onPressed: onDismiss,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  IconData _getNotificationIcon(app_notification.NotificationType type) {
    switch (type) {
      case app_notification.NotificationType.like:
        return Icons.favorite;
      case app_notification.NotificationType.comment:
        return Icons.comment;
      case app_notification.NotificationType.reply:
        return Icons.reply;
      case app_notification.NotificationType.follow:
        return Icons.person_add;
      case app_notification.NotificationType.mention:
        return Icons.alternate_email;
    }
  }
  
  Color _getNotificationColor(app_notification.NotificationType type) {
    switch (type) {
      case app_notification.NotificationType.like:
        return Colors.red;
      case app_notification.NotificationType.comment:
        return Colors.blue;
      case app_notification.NotificationType.reply:
        return Colors.green;
      case app_notification.NotificationType.follow:
        return Colors.purple;
      case app_notification.NotificationType.mention:
        return Colors.orange;
    }
  }
  
  String _getActionText(app_notification.NotificationType type) {
    switch (type) {
      case app_notification.NotificationType.like:
        return 'liked your post';
      case app_notification.NotificationType.comment:
        return 'commented on your post';
      case app_notification.NotificationType.reply:
        return 'replied to your comment';
      case app_notification.NotificationType.follow:
        return 'started following you';
      case app_notification.NotificationType.mention:
        return 'mentioned you in a post';
    }
  }
  
  void _handleNavigation(BuildContext context) {
    switch (notification.type) {
      case app_notification.NotificationType.like:
      case app_notification.NotificationType.comment:
      case app_notification.NotificationType.reply:
      case app_notification.NotificationType.mention:
        // Navigate to the post
        _navigateToPost(context, notification.targetId);
        break;
      case app_notification.NotificationType.follow:
        // Navigate to the user profile
        _navigateToUserProfile(context, notification.triggerUserId);
        break;
    }
  }
  
  void _navigateToPost(BuildContext context, String postId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HomePage(initialTabIndex: 0, targetPostId: postId),
      ),
    );
  }
  
  void _navigateToUserProfile(BuildContext context, String userId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfilePage(userId: userId),
      ),
    );
  }
} 