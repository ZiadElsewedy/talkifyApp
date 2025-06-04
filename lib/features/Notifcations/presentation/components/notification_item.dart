import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:talkifyapp/features/Notifcations/Domain/Entite/Notification.dart' as app_notification;
import 'package:talkifyapp/features/Notifcations/presentation/cubit/notification_cubit.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/ProfilePage.dart';
import 'package:talkifyapp/features/Profile/presentation/Cubits/ProfileCubit.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/components/FollowButtom.dart';

class NotificationItem extends StatefulWidget {
  final app_notification.Notification notification;
  final VoidCallback onTap;
  final Function(app_notification.Notification)? onDeleted;
  
  const NotificationItem({
    Key? key,
    required this.notification,
    required this.onTap,
    this.onDeleted,
  }) : super(key: key);

  @override
  State<NotificationItem> createState() => _NotificationItemState();
}

class _NotificationItemState extends State<NotificationItem> {
  bool _isFollowing = false;
  bool _isLoading = false;
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  
  @override
  void initState() {
    super.initState();
    // Check follow status if this is a follow notification
    if (widget.notification.type == app_notification.NotificationType.follow) {
      _checkFollowStatus();
    }
  }
  
  Future<void> _checkFollowStatus() async {
    if (_currentUserId.isEmpty) return;
    
    final profileCubit = context.read<ProfileCubit>();
    setState(() => _isLoading = true);
    
    try {
      final isFollowing = await profileCubit.isFollowing(
        _currentUserId, 
        widget.notification.triggerUserId
      );
      
      if (mounted) {
        setState(() {
          _isFollowing = isFollowing;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking follow status: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _handleFollowToggle(bool shouldFollow) async {
    if (_currentUserId.isEmpty) return;
    
    final profileCubit = context.read<ProfileCubit>();
    
    try {
      await profileCubit.toggleFollow(_currentUserId, widget.notification.triggerUserId);
      // We don't need to update state here as the FollowButton handles its own state
    } catch (e) {
      print('Error toggling follow: $e');
      // Show error toast
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update follow status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Store a reference to the cubit
    final notificationCubit = context.read<NotificationCubit>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    return Dismissible(
      key: Key(widget.notification.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        try {
          // Clear any existing SnackBars to prevent overlap and context issues
          scaffoldMessenger.clearSnackBars();
          
          // Delete the notification using stored cubit reference
          final deletedNotification = await notificationCubit.deleteNotification(widget.notification.id);
              
          // If deletion was successful
          if (deletedNotification != null) {
            // Show a snackbar with undo option
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: const Text('Notification will be deleted in 3 seconds'),
                action: SnackBarAction(
                  label: 'UNDO',
                  onPressed: () {
                    // Use stored cubit reference for the undo action
                    notificationCubit.restoreNotification(deletedNotification);
                  },
                ),
                duration: const Duration(seconds: 3), // Match the deletion delay
                behavior: SnackBarBehavior.floating,
              ),
            );
            
            // Notify parent if needed
            if (widget.onDeleted != null) {
              widget.onDeleted!(widget.notification);
            }
          }
          
          // Return true to confirm dismiss
          return deletedNotification != null;
        } catch (e) {
          debugPrint('Error during notification dismissal: $e');
          return false;
        }
      },
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        color: Colors.red,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete,
              color: Colors.white,
              size: 26,
            ),
            SizedBox(height: 4),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      child: InkWell(
        onTap: () {
          // Mark as read when tapped
          if (!widget.notification.isRead) {
            notificationCubit.markNotificationAsRead(widget.notification.id);
          }
          widget.onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: widget.notification.isRead ? Colors.transparent : Colors.grey.shade100,
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
              // Profile picture (clickable to navigate to profile)
              GestureDetector(
                onTap: () => _navigateToUserProfile(context, widget.notification.triggerUserId),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: widget.notification.triggerUserProfilePic.isNotEmpty
                      ? CachedNetworkImageProvider(widget.notification.triggerUserProfilePic)
                      : null,
                  child: widget.notification.triggerUserProfilePic.isEmpty
                      ? const Icon(Icons.person, size: 20, color: Colors.grey)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              
              // Notification content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: RichText(
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              style: TextStyle(fontSize: 14, color: Colors.black87),
                              children: [
                                // Username (no longer directly in TextSpan)
                                WidgetSpan(
                                  child: GestureDetector(
                                    onTap: () => _navigateToUserProfile(context, widget.notification.triggerUserId),
                                    child: Text(
                                      widget.notification.triggerUserName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                                TextSpan(
                                  text: ' ${_getActionText(widget.notification.type)}',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeago.format(widget.notification.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Follow back button for follow notifications
              if (widget.notification.type == app_notification.NotificationType.follow && 
                 _currentUserId != widget.notification.triggerUserId)
                FollowButton(
                  currentUserId: _currentUserId,
                  otherUserId: widget.notification.triggerUserId,
                  isFollowing: _isFollowing,
                  onFollow: _handleFollowToggle,
                ),
              
              // Post thumbnail (if available)
              if (widget.notification.postImageUrl != null && widget.notification.postImageUrl!.isNotEmpty)
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
                      imageUrl: widget.notification.postImageUrl!,
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
              if (widget.notification.type != app_notification.NotificationType.follow ||
                  _currentUserId == widget.notification.triggerUserId)
                _getNotificationIcon(widget.notification.type),
              
              // Unread indicator
              if (!widget.notification.isRead)
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
      ),
    );
  }
  
  // Helper method to navigate to a user's profile
  void _navigateToUserProfile(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(userId: userId),
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