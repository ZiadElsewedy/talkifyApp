import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:talkifyapp/features/Notifcations/Domain/Entite/Notification.dart' as app_notification;
import 'package:talkifyapp/features/Notifcations/presentation/cubit/notification_cubit.dart';

class NotificationItem extends StatelessWidget {
  final app_notification.Notification notification;
  final VoidCallback onTap;
  
  const NotificationItem({
    Key? key,
    required this.notification,
    required this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Mark as read when tapped
        if (!notification.isRead) {
          context.read<NotificationCubit>().markNotificationAsRead(notification.id);
        }
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.transparent : Colors.grey.shade100,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withOpacity(0.15),
              width: 1.0,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
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
                children: [
                  RichText(
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                      children: [
                        TextSpan(
                          text: notification.triggerUserName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: ' ${_getActionText(notification.type)}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeago.format(notification.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            
            // Post thumbnail (if available)
            if (notification.postImageUrl != null && notification.postImageUrl!.isNotEmpty)
              Container(
                width: 50,
                height: 50,
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: CachedNetworkImage(
                    imageUrl: notification.postImageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported, size: 20, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            
            // Notification type icon
            _getNotificationIcon(notification.type),
            
            // Unread indicator
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(left: 4),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _getNotificationIcon(app_notification.NotificationType type) {
    IconData iconData;
    Color iconColor;
    
    switch (type) {
      case app_notification.NotificationType.like:
        iconData = Icons.favorite;
        iconColor = Colors.red;
        break;
      case app_notification.NotificationType.comment:
        iconData = Icons.comment;
        iconColor = Colors.blue;
        break;
      case app_notification.NotificationType.reply:
        iconData = Icons.reply;
        iconColor = Colors.green;
        break;
      case app_notification.NotificationType.follow:
        iconData = Icons.person_add;
        iconColor = Colors.purple;
        break;
      case app_notification.NotificationType.mention:
        iconData = Icons.alternate_email;
        iconColor = Colors.orange;
        break;
    }
    
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: Icon(iconData, color: iconColor, size: 18),
    );
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
} 