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
        return data?['imageurl'] as String?;
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
    // Don't create notification if user comments on their own post
    if (postOwnerId == commenterUserId) return;
    
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
    // Don't create notification if user replies to their own comment
    if (commentOwnerId == replierUserId) return;
    
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
    // Don't create notification if user likes their own comment
    if (commentOwnerId == likerUserId) return;
    
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
  }
  
  // Helper method to truncate long content for notification display
  String _truncateContent(String content) {
    if (content.length <= 30) return content;
    return '${content.substring(0, 30)}...';
  }
} 