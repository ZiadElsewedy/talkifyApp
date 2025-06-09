import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:talkifyapp/features/Notifcations/Domain/Entite/Notification.dart';
import 'package:talkifyapp/features/Notifcations/data/notification_repository_impl.dart';
import 'package:talkifyapp/features/Posts/domain/Entite/Posts.dart';
import 'package:talkifyapp/features/Posts/domain/Entite/Comments.dart';

class NotificationService {
  final NotificationRepositoryImpl _notificationRepository;
  final FirebaseFirestore _firestore;
  final Uuid _uuid = const Uuid();
  
  NotificationService({
    NotificationRepositoryImpl? notificationRepository,
    FirebaseFirestore? firestore,
  }) : 
    _notificationRepository = notificationRepository ?? NotificationRepositoryImpl(),
    _firestore = firestore ?? FirebaseFirestore.instance;

  // Check if a similar notification already exists
  Future<bool> _checkForExistingNotification({
    required String recipientId,
    required String triggerUserId, 
    required String targetId,
    required NotificationType type,
    Duration timeWindow = const Duration(hours: 24), // Consider notifications within this window
  }) async {
    try {
      final cutoffTime = DateTime.now().subtract(timeWindow);
      final cutoffTimestamp = Timestamp.fromDate(cutoffTime);
      
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: recipientId)
          .where('triggerUserId', isEqualTo: triggerUserId)
          .where('targetId', isEqualTo: targetId)
          .where('type', isEqualTo: type.toString().split('.').last)
          .where('timestamp', isGreaterThan: cutoffTimestamp)
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking for existing notification: $e');
      return false; // If there's an error, create the notification anyway
    }
  }

  // Remove a follow notification when a user unfollows someone
  Future<void> removeFollowNotification({
    required String followerId, 
    required String followedId,
  }) async {
    try {
      await _notificationRepository.removeFollowNotification(
        followerId, 
        followedId
      );
      print('Follow notification removed successfully');
    } catch (e) {
      print('Error removing follow notification in service: $e');
    }
  }
  
  // Remove a like notification when a user unlikes a post
  Future<void> removeLikeNotification({
    required String likerId,
    required String postOwnerId,
    required String postId,
  }) async {
    try {
      await _notificationRepository.removeLikeNotification(
        likerId, 
        postOwnerId, 
        postId
      );
      print('Like notification removed successfully');
    } catch (e) {
      print('Error removing like notification in service: $e');
    }
  }
  
  // Remove a like comment notification when a user unlikes a comment
  Future<void> removeLikeCommentNotification({
    required String likerId,
    required String commentOwnerId,
    required String postId,
  }) async {
    try {
      await _notificationRepository.removeNotificationsByAction(
        triggerUserId: likerId,
        recipientId: commentOwnerId,
        targetId: postId, 
        type: NotificationType.like,
      );
      print('Comment like notification removed successfully');
    } catch (e) {
      print('Error removing comment like notification: $e');
    }
  }

  // Fetch latest user profile picture directly from users collection
  Future<String> _getLatestUserProfilePic(String userId) async {
    const defaultProfilePic = 'https://ui-avatars.com/api/?name=User&background=cccccc&color=ffffff&size=128'; // You can change this to your own default image URL
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        // Try both field names to ensure we get the profile picture
        final pic = userData?['profilePicture'] as String? ?? userData?['profilePictureUrl'] as String? ?? '';
        if (pic == null || pic.isEmpty) {
          print('No profile picture found for user $userId, using default.');
          return defaultProfilePic;
        }
        return pic;
      }
    } catch (e) {
      print('Error fetching user profile picture: $e');
    }
    return defaultProfilePic;
  }

  // Get post image URL for notifications
  Future<Map<String, dynamic>> _getPostImageInfo(String postId) async {
    String? imageUrl;
    bool isVideo = false;
    
    try {
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (postDoc.exists) {
        final data = postDoc.data();
        print('Post data for image retrieval: $data');
        
        // Check if this is a video post
        isVideo = data?['isVideo'] as bool? ?? false;
        print('Post is video: $isVideo');
        
        // Get the appropriate image URL
        if (data?.containsKey('imageurl') == true) {
          imageUrl = data!['imageurl'] as String?;
          print('Found imageurl field: $imageUrl');
        } else if (data?.containsKey('imageUrl') == true) {
          if (data?['imageUrl'] is List && (data?['imageUrl'] as List).isNotEmpty) {
            imageUrl = (data?['imageUrl'] as List)[0]?.toString();
          } else if (data?['imageUrl'] is String && (data?['imageUrl'] as String).isNotEmpty) {
            imageUrl = data?['imageUrl'] as String;
          }
        }
        
        // Ensure video posts always have a thumbnail
        if (isVideo && (imageUrl == null || imageUrl.isEmpty)) {
          // For video posts without thumbnails, try to use a default video thumbnail
          print('Video post without thumbnail detected');
          imageUrl = await _generateVideoThumbnail(postId);
        }
        
        // Verify URL format
        if (imageUrl != null && imageUrl.isNotEmpty) {
          try {
            if (!imageUrl.startsWith('http')) {
              imageUrl = 'https://$imageUrl';
              print('Updated image URL with https: $imageUrl');
            }
          } catch (e) {
            print('Error parsing image URL: $e');
          }
        }
        
        print('Final image URL: $imageUrl, isVideo: $isVideo');
      }
    } catch (e) {
      print('Error fetching post image info: $e');
    }
    
    return {
      'imageUrl': imageUrl,
      'isVideo': isVideo,
    };
  }
  
  // Generate a video thumbnail if missing
  Future<String?> _generateVideoThumbnail(String postId) async {
    try {
      print('Generating video thumbnail for post: $postId');
      
      // First check if the post exists and is actually a video
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (!postDoc.exists) {
        print('Post does not exist: $postId');
        return null;
      }
      
      final postData = postDoc.data()!;
      final bool isVideo = postData['isVideo'] as bool? ?? false;
      
      if (!isVideo) {
        print('Post is not a video: $postId');
        return null;
      }
      
      // Get the video URL from the post
      final String videoUrl = postData['imageurl'] as String? ?? '';
      if (videoUrl.isEmpty) {
        print('Video URL is empty for post: $postId');
        return 'https://firebasestorage.googleapis.com/v0/b/talkify-12.appspot.com/o/default_video_thumbnail.png?alt=media';
      }
      
      print('Using video URL as thumbnail: $videoUrl');
      return videoUrl;
    } catch (e) {
      print('Error generating video thumbnail: $e');
      return 'https://firebasestorage.googleapis.com/v0/b/talkify-12.appspot.com/o/default_video_thumbnail.png?alt=media';
    }
  }

  // Check if a post is a video post and get its data
  Future<Map<String, dynamic>> _getCompletePostData(String postId) async {
    bool isVideo = false;
    String? imageUrl;
    
    try {
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (postDoc.exists) {
        final data = postDoc.data()!;
        
        // Extract video info
        isVideo = data['isVideo'] as bool? ?? false;
        imageUrl = data['imageurl'] as String? ?? '';
        
        print('NOTIFICATION DEBUG - Post $postId data:');
        print('  - Is video: $isVideo');
        print('  - Image URL: $imageUrl');
      }
    } catch (e) {
      print('Error getting post data: $e');
    }
    
    return {
      'isVideo': isVideo,
      'imageUrl': imageUrl,
    };
  }

  // Create a like post notification
  Future<void> createLikePostNotification({
    required String postOwnerId,
    required String postId, 
    required String likerUserId,
    required String likerUserName,
    required String likerProfilePic,
  }) async {
    try {
      // Don't create notification if user likes their own post
      if (postOwnerId == likerUserId) return;
      
      print('Creating like notification: Post owner: $postOwnerId, Liker: $likerUserId, Post: $postId');
      
      // Use a longer time window to prevent notification spam when users toggle like status
      final timeWindow = const Duration(days: 1); // Increase from 6 hours to 24 hours
      
      // First try to remove any existing notifications that might have been missed
      // This is an extra safety measure to avoid duplicates
      try {
        await _notificationRepository.removeNotificationsByAction(
          triggerUserId: likerUserId,
          recipientId: postOwnerId,
          targetId: postId,
          type: NotificationType.like,
        );
        print('Removed any potential existing like notifications as a precaution');
      } catch (e) {
        print('Error clearing existing notifications (non-critical): $e');
      }
      
      // Check if a similar notification already exists
      final exists = await _checkForExistingNotification(
        recipientId: postOwnerId,
        triggerUserId: likerUserId,
        targetId: postId,
        type: NotificationType.like,
        timeWindow: timeWindow,
      );
      
      if (exists) {
        print('Similar like notification already exists for post $postId from $likerUserId to $postOwnerId, skipping');
        return;
      }
      
      // Always get the latest profile picture directly from users collection
      final profilePic = await _getLatestUserProfilePic(likerUserId);
      
      // Get complete post data including video status
      final postData = await _getCompletePostData(postId);
      final bool isVideoPost = postData['isVideo'] as bool;
      String? postImageUrl = postData['imageUrl'] as String?;
      
      // For video posts, ensure we have a thumbnail
      if (isVideoPost && (postImageUrl == null || postImageUrl.isEmpty)) {
        postImageUrl = await _generateVideoThumbnail(postId);
        print('Generated video thumbnail: $postImageUrl');
      }
      
      print('Final notification data - Post: $postId, Image URL: $postImageUrl, Is Video: $isVideoPost');
      
      // Create the notification object
      final notification = Notification(
        id: _uuid.v4(),
        recipientId: postOwnerId, // Who receives the notification
        triggerUserId: likerUserId, // Who triggered the notification
        triggerUserName: likerUserName,
        triggerUserProfilePic: profilePic,
        targetId: postId,
        type: NotificationType.like,
        content: '$likerUserName liked your post',
        timestamp: DateTime.now(),
        postImageUrl: postImageUrl,
        isVideoPost: isVideoPost,
      );
      
      print('Creating notification with data: ${notification.toJson()}');
      await _notificationRepository.createNotification(notification);
      print('Notification created successfully with ID: ${notification.id} and image URL: ${notification.postImageUrl}');
    } catch (e) {
      print('Error creating like notification: $e');
    }
  }
  
  // Create a comment notification
  Future<void> createCommentNotification({
    required String postOwnerId,
    required String postId,
    required String commenterUserId,
    required String commenterUserName,
    required String commenterProfilePic,
    required String commentContent,
  }) async {
    try {
      // Don't create notification if user comments on their own post
      if (postOwnerId == commenterUserId) return;
      
      // Check if a similar notification already exists (for comments we use shorter time window)
      final exists = await _checkForExistingNotification(
        recipientId: postOwnerId,
        triggerUserId: commenterUserId,
        targetId: postId,
        type: NotificationType.comment,
        timeWindow: const Duration(minutes: 30), // Only consider notifications from last 30 minutes
      );
      
      if (exists) {
        print('Similar comment notification already exists, skipping');
        return;
      }
      
      // Always get the latest profile picture directly from users collection
      final profilePic = await _getLatestUserProfilePic(commenterUserId);
      
      // Get post image URL and video status
      final postInfo = await _getPostImageInfo(postId);
      final postImageUrl = postInfo['imageUrl'] as String?;
      final isVideoPost = postInfo['isVideo'] as bool;
      
      final notification = Notification(
        id: _uuid.v4(),
        recipientId: postOwnerId,
        triggerUserId: commenterUserId,
        triggerUserName: commenterUserName,
        triggerUserProfilePic: profilePic,
        targetId: postId,
        type: NotificationType.comment,
        content: '$commenterUserName commented on your post: "${_truncateContent(commentContent)}"',
        timestamp: DateTime.now(),
        postImageUrl: postImageUrl,
        isVideoPost: isVideoPost,
      );
      
      await _notificationRepository.createNotification(notification);
    } catch (e) {
      print('Error creating comment notification: $e');
    }
  }
  
  // Create a reply notification
  Future<void> createReplyNotification({
    required String commentOwnerId,
    required String commentId,
    required String postId,
    required String replierUserId,
    required String replierUserName,
    required String replierProfilePic,
    required String replyContent,
  }) async {
    try {
      // Don't create notification if user replies to their own comment
      if (commentOwnerId == replierUserId) return;
      
      // Check if a similar notification already exists
      final exists = await _checkForExistingNotification(
        recipientId: commentOwnerId,
        triggerUserId: replierUserId,
        targetId: postId,
        type: NotificationType.reply,
        timeWindow: const Duration(minutes: 30), // Only consider notifications from last 30 minutes
      );
      
      if (exists) {
        print('Similar reply notification already exists, skipping');
        return;
      }
      
      // Always get the latest profile picture directly from users collection
      final profilePic = await _getLatestUserProfilePic(replierUserId);
      
      // Get post image URL and video status
      final postInfo = await _getPostImageInfo(postId);
      final postImageUrl = postInfo['imageUrl'] as String?;
      final isVideoPost = postInfo['isVideo'] as bool;
      
      final notification = Notification(
        id: _uuid.v4(),
        recipientId: commentOwnerId,
        triggerUserId: replierUserId,
        triggerUserName: replierUserName,
        triggerUserProfilePic: profilePic,
        targetId: postId, // We use postId as target to navigate to the post containing the comment
        type: NotificationType.reply,
        content: '$replierUserName replied to your comment: "${_truncateContent(replyContent)}"',
        timestamp: DateTime.now(),
        postImageUrl: postImageUrl,
        isVideoPost: isVideoPost,
      );
      
      await _notificationRepository.createNotification(notification);
    } catch (e) {
      print('Error creating reply notification: $e');
    }
  }
  
  // Create a like comment notification
  Future<void> createLikeCommentNotification({
    required String commentOwnerId,
    required String commentId,
    required String postId,
    required String likerUserId,
    required String likerUserName,
    required String likerProfilePic,
  }) async {
    try {
      // Don't create notification if user likes their own comment
      if (commentOwnerId == likerUserId) return;
      
      // Check if a similar notification already exists
      final exists = await _checkForExistingNotification(
        recipientId: commentOwnerId,
        triggerUserId: likerUserId,
        targetId: commentId,
        type: NotificationType.like,
        timeWindow: const Duration(hours: 6), // Only consider notifications from last 6 hours
      );
      
      if (exists) {
        print('Similar comment like notification already exists, skipping');
        return;
      }
      
      // Always get the latest profile picture directly from users collection
      final profilePic = await _getLatestUserProfilePic(likerUserId);
      
      // Get post image URL and video status
      final postInfo = await _getPostImageInfo(postId);
      final postImageUrl = postInfo['imageUrl'] as String?;
      final isVideoPost = postInfo['isVideo'] as bool;
      
      final notification = Notification(
        id: _uuid.v4(),
        recipientId: commentOwnerId,
        triggerUserId: likerUserId,
        triggerUserName: likerUserName,
        triggerUserProfilePic: profilePic,
        targetId: postId, // We use postId as target to navigate to the post containing the comment
        type: NotificationType.like,
        content: '$likerUserName liked your comment',
        timestamp: DateTime.now(),
        postImageUrl: postImageUrl,
        isVideoPost: isVideoPost,
      );
      
      await _notificationRepository.createNotification(notification);
    } catch (e) {
      print('Error creating comment like notification: $e');
    }
  }
  
  // Create a follow notification
  Future<void> createFollowNotification({
    required String followedUserId,
    required String followerUserId,
    required String followerUserName,
    required String followerProfilePic,
  }) async {
    try {
      // Don't create notification if user follows themselves (shouldn't happen but just in case)
      if (followedUserId == followerUserId) return;
      
      print('Creating follow notification: Followed user: $followedUserId, Follower: $followerUserId');
      
      // Check if a similar notification already exists
      final exists = await _checkForExistingNotification(
        recipientId: followedUserId,
        triggerUserId: followerUserId,
        targetId: followerUserId, // For follow notifications, targetId is the follower's ID
        type: NotificationType.follow,
        timeWindow: const Duration(days: 7), // Only consider follow notifications from last 7 days
      );
      
      if (exists) {
        print('Similar follow notification already exists, skipping');
        return;
      }
      
      // Always get the latest profile picture directly from users collection
      final profilePic = await _getLatestUserProfilePic(followerUserId);
      
      final notification = Notification(
        id: _uuid.v4(),
        recipientId: followedUserId,
        triggerUserId: followerUserId,
        triggerUserName: followerUserName,
        triggerUserProfilePic: profilePic,
        targetId: followerUserId, // Target ID is the follower's ID to navigate to their profile
        type: NotificationType.follow,
        content: '$followerUserName started following you',
        timestamp: DateTime.now(),
        postImageUrl: null, // No post image for follow notifications
      );
      
      print('Creating notification with data: ${notification.toJson()}');
      await _notificationRepository.createNotification(notification);
      print('Follow notification created successfully');
    } catch (e) {
      print('Error creating follow notification: $e');
    }
  }
  
  // Helper method to truncate long content for notification display
  String _truncateContent(String content) {
    if (content.length <= 30) return content;
    return '${content.substring(0, 30)}...';
  }
} 