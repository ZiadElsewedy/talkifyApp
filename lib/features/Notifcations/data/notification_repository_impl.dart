import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:talkifyapp/features/Notifcations/Domain/Entite/Notification.dart';
import 'package:talkifyapp/features/Notifcations/Domain/repo/notification_repository.dart';
import 'package:talkifyapp/features/Posts/data/video_thumbnail_service.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  @override
  Future<List<Notification>> getNotifications(String userId) async {
    try {
      final notificationsSnapshot = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();
          
      return notificationsSnapshot.docs.map((doc) {
        final data = doc.data();
        return Notification.fromJson({
          ...data,
          'id': doc.id,
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to get notifications: $e');
    }
  }

  @override
  Future<void> createNotification(Notification notification) async {
    try {
      await _firestore.collection('notifications').add(notification.toJson());
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }
  
  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  @override
  Future<void> removeNotificationsByAction({
    required String triggerUserId,
    required String recipientId,
    required String targetId,
    required NotificationType type,
  }) async {
    try {
      print('Removing notifications for action: user=$triggerUserId, recipient=$recipientId, target=$targetId, type=${type.toString()}');
      
      // Find notifications that match the criteria
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: recipientId)
          .where('triggerUserId', isEqualTo: triggerUserId)
          .where('targetId', isEqualTo: targetId)
          .where('type', isEqualTo: type.toString().split('.').last)
          .get();
      
      // If no matching notifications, return early
      if (querySnapshot.docs.isEmpty) {
        print('No matching notifications found');
        return;
      }
      
      print('Found ${querySnapshot.docs.length} notifications to remove');
      
      // Delete all matching notifications
      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      print('Successfully removed ${querySnapshot.docs.length} notifications');
    } catch (e) {
      print('Error removing notifications by action: $e');
      throw Exception('Failed to remove notifications: $e');
    }
  }

  @override
  Future<void> removeFollowNotification(String followerId, String followedId) async {
    await removeNotificationsByAction(
      triggerUserId: followerId, 
      recipientId: followedId, 
      targetId: followerId,  // For follow notifications, targetId is the follower's ID
      type: NotificationType.follow,
    );
  }

  @override
  Future<void> removeLikeNotification(String likerId, String postOwnerId, String postId) async {
    await removeNotificationsByAction(
      triggerUserId: likerId, 
      recipientId: postOwnerId, 
      targetId: postId,
      type: NotificationType.like,
    );
  }

  @override
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  @override
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      // Get all unread notifications for this user
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      
      // If there are no unread notifications, return early
      if (querySnapshot.docs.isEmpty) {
        return;
      }
      
      // Use batch write to update all notifications efficiently
      final batch = _firestore.batch();
      
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      // Commit the batch
      await batch.commit();
      
      print('Marked all ${querySnapshot.docs.length} notifications as read for user $userId');
    } catch (e) {
      print('Error marking all notifications as read: $e');
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  @override
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();
          
      return querySnapshot.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get unread notification count: $e');
    }
  }

  @override
  Stream<List<Notification>> getNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return Notification.fromJson({
              ...data,
              'id': doc.id,
            });
          }).toList();
        });
  }

  @override
  Future<void> updateNotificationPostInfo(String notificationId, String? postImageUrl, bool isVideoPost) async {
    try {
      print('Updating notification $notificationId with imageUrl: $postImageUrl, isVideoPost: $isVideoPost');
      
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({
            'postImageUrl': postImageUrl,
            'isVideoPost': isVideoPost,
          });
          
      print('Successfully updated notification with video info');
    } catch (e) {
      print('Error updating notification post info: $e');
      throw Exception('Failed to update notification post info: $e');
    }
  }

  @override
  Future<void> fixVideoThumbnailsForExistingNotifications(String userId) async {
    try {
      print('Starting fix for video thumbnails in notifications for user: $userId');
      
      // Get all notifications for this user
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .get();
          
      if (querySnapshot.docs.isEmpty) {
        print('No notifications found for user $userId');
        return;
      }
      
      print('Found ${querySnapshot.docs.length} notifications to check');
      
      int fixCount = 0;
      // Go through each notification
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final notificationId = doc.id;
        
        // Check if this is a notification about a post (has a targetId that's not a user ID)
        if (data['type'] == 'like' || data['type'] == 'comment') {
          final postId = data['targetId'] as String;
          final isVideoPost = data['isVideoPost'] as bool? ?? false;
          final postImageUrl = data['postImageUrl'] as String?;
          
          // If this is a video post but has no thumbnail, or has an empty thumbnail, fix it
          if (isVideoPost && (postImageUrl == null || postImageUrl.isEmpty)) {
            print('Fixing thumbnail for video notification: $notificationId');
            
            // Get the post document to find the video URL
            final postDoc = await _firestore.collection('posts').doc(postId).get();
            
            if (postDoc.exists) {
              final postData = postDoc.data()!;
              
              // Get the video URL
              String videoUrl = '';
              if (postData['imageUrl'] != null) {
                if (postData['imageUrl'] is List && (postData['imageUrl'] as List).isNotEmpty) {
                  videoUrl = (postData['imageUrl'] as List)[0]?.toString() ?? '';
                } else if (postData['imageUrl'] is String) {
                  videoUrl = postData['imageUrl'] as String;
                }
              } else if (postData['imageurl'] != null && postData['imageurl'] is String) {
                videoUrl = postData['imageurl'] as String;
              }
              
              if (videoUrl.isNotEmpty) {
                // Generate a thumbnail for the video
                final thumbnailUrl = await VideoThumbnailService.generateThumbnailForPost(postId, videoUrl);
                
                if (thumbnailUrl != null) {
                  // Update the notification with the thumbnail URL
                  await _firestore
                      .collection('notifications')
                      .doc(notificationId)
                      .update({
                        'postImageUrl': thumbnailUrl,
                        'isVideoPost': true,
                      });
                      
                  fixCount++;
                  print('Fixed thumbnail for notification $notificationId with thumbnail: $thumbnailUrl');
                }
              }
            }
          }
        }
      }
      
      print('Finished fixing video thumbnails. Fixed $fixCount notifications.');
    } catch (e) {
      print('Error fixing video thumbnails: $e');
      throw Exception('Failed to fix video thumbnails: $e');
    }
  }
} 