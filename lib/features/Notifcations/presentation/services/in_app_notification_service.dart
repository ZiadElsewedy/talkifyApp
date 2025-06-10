import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Posts/presentation/cubits/post_cubit.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/ProfilePage.dart';
import 'package:talkifyapp/features/Notifcations/presentation/utils/notification_navigation.dart';
import 'package:talkifyapp/features/Notifcations/Domain/Entite/Notification.dart' as app_notification;
import 'package:just_audio/just_audio.dart';

/// Service to display in-app notifications that slide in from the top of the screen
class InAppNotificationService {
  static OverlayEntry? _currentNotification;
  static bool _isVisible = false;
  static AudioPlayer? _audioPlayer;
  
  /// Shows an in-app notification with animation
  static void show({
    required BuildContext context,
    required String title,
    required String message,
    required NotificationType type,
    required String userId,
    String? postId,
    String? userAvatar,
    String? postThumbnail,
    bool isVideoPost = false,
    Duration duration = const Duration(seconds: 3),
    bool playSound = true,
  }) {
    // Don't show a new notification if one is already visible
    if (_isVisible) {
      _currentNotification?.remove();
      _isVisible = false;
    }
    
    // Play notification sound if not disabled
    if (playSound) {
      _playNotificationSound();
    }
    
    // Create the overlay entry for the notification
    final overlay = Overlay.of(context);
    final notification = OverlayEntry(
      builder: (context) => _InAppNotification(
        title: title,
        message: message,
        type: type,
        userId: userId,
        postId: postId,
        userAvatar: userAvatar,
        postThumbnail: postThumbnail,
        isVideoPost: isVideoPost,
        onDismiss: () {
          _currentNotification?.remove();
          _isVisible = false;
          _currentNotification = null;
        },
      ),
    );
    
    _currentNotification = notification;
    _isVisible = true;
    
    // Show the notification
    overlay.insert(notification);
    
    // Auto dismiss after duration
    Future.delayed(duration, () {
      if (_currentNotification == notification && _isVisible) {
        _currentNotification?.remove();
        _isVisible = false;
        _currentNotification = null;
      }
    });
  }
  
  /// Play notification sound
  static Future<void> _playNotificationSound() async {
    try {
      // Create a new player instance each time to avoid issues
      _audioPlayer?.dispose();
      _audioPlayer = AudioPlayer();
      
      // Using the existing notification sound file
      await _audioPlayer?.setAsset('lib/assets/notification.wav');
      await _audioPlayer?.play();
    } catch (e) {
      print('Error playing notification sound: $e');
    }
  }
  
  /// Hide the current notification if visible
  static void hide() {
    if (_isVisible && _currentNotification != null) {
      _currentNotification?.remove();
      _isVisible = false;
      _currentNotification = null;
    }
  }
}

/// Types of in-app notifications
enum NotificationType {
  like,
  comment,
  follow,
  message,

}

/// The actual notification widget that appears on screen
class _InAppNotification extends StatefulWidget {
  final String title;
  final String message;
  final NotificationType type;
  final String userId;
  final String? postId;
  final String? userAvatar;
  final String? postThumbnail;
  final bool isVideoPost;
  final VoidCallback onDismiss;
  
  const _InAppNotification({
    required this.title,
    required this.message,
    required this.type,
    required this.userId,
    required this.onDismiss,
    this.postId,
    this.userAvatar,
    this.postThumbnail,
    this.isVideoPost = false,
  });

  @override
  State<_InAppNotification> createState() => _InAppNotificationState();
}

class _InAppNotificationState extends State<_InAppNotification> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Set up the animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Define the animation (slide in from top)
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    // Start the animation
    _controller.forward();
    
    // Add a listener for when the user dismisses by swiping
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        widget.onDismiss();
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  // Get the color based on notification type
  Color _getColor() {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    switch (widget.type) {
      case NotificationType.like:
        return isDarkMode ? Colors.redAccent.shade400 : Colors.red.shade400;
      case NotificationType.comment:
        return isDarkMode ? Colors.blueAccent.shade400 : Colors.blue.shade400;
      case NotificationType.follow:
        return isDarkMode ? Colors.purpleAccent.shade400 : Colors.purple.shade400;
      case NotificationType.message:
        return isDarkMode ? Colors.greenAccent.shade400 : Colors.green.shade400;
    }
  }
  
  void _onTap() {
    // Convert our in-app notification type to the app's notification type
    final appNotificationType = _convertToAppNotificationType(widget.type);
    
    // Navigate using the notification navigation utility
    NotificationNavigation.navigateToDestination(
      context, 
      appNotificationType,
      widget.postId ?? widget.userId, // Target ID (post ID or user ID)
      widget.userId,                  // Trigger user ID
    );
    
    // Dismiss the notification
    widget.onDismiss();
  }
  
  // Convert in-app notification type to app notification type
  app_notification.NotificationType _convertToAppNotificationType(NotificationType type) {
    switch (type) {
      case NotificationType.like:
        return app_notification.NotificationType.like;
      case NotificationType.comment:
        return app_notification.NotificationType.comment;
      case NotificationType.follow:
        return app_notification.NotificationType.follow;
      case NotificationType.message:
        return app_notification.NotificationType.message;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate status bar height
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            child: GestureDetector(
              onTap: _onTap,
              onVerticalDragEnd: (_) => widget.onDismiss(),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 30),  // Narrow width with margins
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: Border.all(
                      color: isDarkMode 
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                      width: 0.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),  // More padding
                    child: Row(
                      children: [
                        // Profile picture
                        if (widget.userAvatar != null && widget.userAvatar!.isNotEmpty)
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                            backgroundImage: CachedNetworkImageProvider(widget.userAvatar!),
                          )
                        else
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                            child: Icon(
                              widget.type == NotificationType.like
                                  ? Icons.favorite
                                  : widget.type == NotificationType.comment
                                      ? Icons.comment
                                      : widget.type == NotificationType.message
                                          ? Icons.chat_bubble_outline
                                          : Icons.person,
                              color: isDarkMode ? Colors.white : Colors.black87,
                              size: 18,
                            ),
                          ),
                        
                        const SizedBox(width: 12),  // More spacing
                        
                        // Message
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                widget.message,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        
                        // Post thumbnail (if available)
                        if (widget.postThumbnail != null && widget.postThumbnail!.isNotEmpty)
                          Container(
                            width: 40,
                            height: 40,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: CachedNetworkImage(
                                    imageUrl: widget.postThumbnail!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey.shade200,
                                      child: const Center(
                                        child: SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) {
                                      if (widget.isVideoPost) {
                                        return Container(
                                          color: Colors.grey.shade800,
                                          child: const Icon(
                                            Icons.videocam,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        );
                                      }
                                      return Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(
                                          Icons.image_not_supported,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                if (widget.isVideoPost)
                                  Positioned(
                                    right: 2,
                                    bottom: 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(1),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow,
                                        color: Colors.white,
                                        size: 10,
                                      ),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Close button
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            size: 16,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: widget.onDismiss,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 