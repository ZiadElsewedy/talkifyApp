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
  Future<String?> _getPostImageUrl(String postId) async {
    try {
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (postDoc.exists) {
        final data = postDoc.data();
        return data?['imageUrl'] as String?;
      }
    } catch (e) {
      print('Error fetching post image: $e');
    }
    return null;
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
      
      print('Creating like notification: Post owner: $postOwnerId, Liker: $likerUserId');
      
      // Check if a similar notification already exists
      final exists = await _checkForExistingNotification(
        recipientId: postOwnerId,
        triggerUserId: likerUserId,
        targetId: postId,
        type: NotificationType.like,
        timeWindow: const Duration(hours: 6), // Only consider notifications from last 6 hours
      );
      
      if (exists) {
        print('Similar like notification already exists, skipping');
        return;
      }
      
      // Always get the latest profile picture directly from users collection
      final profilePic = await _getLatestUserProfilePic(likerUserId);
      
      // Get post image URL
      final postImageUrl = await _getPostImageUrl(postId);
      
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
      );
      
      print('Creating notification with data: ${notification.toJson()}');
      await _notificationRepository.createNotification(notification);
      print('Notification created successfully');
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
      
      // Get post image URL
      final postImageUrl = await _getPostImageUrl(postId);
      
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
      
      // Get post image URL
      final postImageUrl = await _getPostImageUrl(postId);
      
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
      
      // Get post image URL
      final postImageUrl = await _getPostImageUrl(postId);
      
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
      );
      
      await _notificationRepository.createNotification(notification);
    } catch (e) {
      print('Error creating comment like notification: $e');
    }
  }
  
  // Helper method to truncate long content for notification display
  String _truncateContent(String content) {
    if (content.length <= 30) return content;
    return '${content.substring(0, 30)}...';
  }
} 