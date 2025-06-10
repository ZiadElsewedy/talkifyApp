import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:talkifyapp/features/Notifcations/data/notification_service.dart';
import 'package:talkifyapp/features/Posts/domain/repos/Post_repo.dart';
import 'package:talkifyapp/features/Posts/domain/Entite/Posts.dart';

class FirebasePosts_repo implements PostRepo {
  final FirebaseFirestore firestore;
  final NotificationService _notificationService;

  FirebasePosts_repo({
    FirebaseFirestore? firestore,
    NotificationService? notificationService,
  }) : 
    this.firestore = firestore ?? FirebaseFirestore.instance,
    _notificationService = notificationService ?? NotificationService();

  @override
  Future<bool> toggleLikePost(String postId, String userId) async {
    try {
      DocumentReference postRef = firestore.collection('posts').doc(postId);

      return await firestore.runTransaction((transaction) async {
        DocumentSnapshot postSnapshot = await transaction.get(postRef);

        if (!postSnapshot.exists) {
          throw Exception('Post does not exist');
        }

        Map<String, dynamic>? postData = postSnapshot.data() as Map<String, dynamic>?;
        List<String> likes = List<String>.from(postData?['likes'] ?? []);
        bool isLiked = likes.contains(userId);
        bool didLike = false; // Track if we liked or unliked

        if (isLiked) {
          // Unlike the post
          likes.remove(userId);
          didLike = false;
          
          // Try to remove the like notification
          try {
            String postOwnerId = postData?['UserId'] ?? '';
            if (postOwnerId.isNotEmpty) {
              await _notificationService.removeLikeNotification(
                likerId: userId,
                postOwnerId: postOwnerId,
                postId: postId
              );
            }
          } catch (e) {
            print('Error removing like notification: $e');
            // Continue with unlike operation even if notification removal fails
          }
        } else {
          // Like the post
          likes.add(userId);
          didLike = true;
        }

        // Update the post document with the new likes array
        transaction.update(postRef, {'likes': likes});
        
        // If we just liked the post (not unliked), create a notification
        if (didLike) {
          final postOwnerId = postData?['UserId'];
          // Only send notification if it's not the user's own post
          if (postOwnerId != null && postOwnerId != userId) {
            // Get the user's name and profile picture
            final userDoc = await firestore.collection('users').doc(userId).get();
            if (userDoc.exists) {
              final userData = userDoc.data() as Map<String, dynamic>;
              final userName = userData['name'] as String? ?? 'User';
              final profilePicture = userData['profilePicture'] as String? ?? '';
              
              String? postImageUrl;
              if (postData?.containsKey('imageUrl') == true && postData?['imageUrl'] is List && (postData?['imageUrl'] as List).isNotEmpty) {
                postImageUrl = (postData?['imageUrl'] as List)[0];
              }
              
              await _notificationService.createLikePostNotification(
                postOwnerId: postOwnerId,
                likerUserId: userId,
                likerUserName: userName,
                likerProfilePic: profilePicture,
                postId: postId,
              );
            }
          }
        }
        
        return didLike; // Return true if now liked, false if now unliked
      });
    } catch (e) {
      print('Error toggling like on post: $e');
      rethrow;
    }
  }
  
  @override
  Future<bool> toggleDislikePost(String postId, String userId) async {
    try {
      DocumentReference postRef = firestore.collection('posts').doc(postId);

      return await firestore.runTransaction((transaction) async {
        DocumentSnapshot postSnapshot = await transaction.get(postRef);

        if (!postSnapshot.exists) {
          throw Exception('Post does not exist');
        }

        Map<String, dynamic>? postData = postSnapshot.data() as Map<String, dynamic>?;
        List<String> dislikes = List<String>.from(postData?['dislikes'] ?? []);
        List<String> likes = List<String>.from(postData?['likes'] ?? []);
        bool isDisliked = dislikes.contains(userId);
        bool didDislike = false;

        if (isDisliked) {
          // Remove dislike
          dislikes.remove(userId);
          didDislike = false;
        } else {
          // Add dislike and remove like if exists (can't like and dislike at the same time)
          dislikes.add(userId);
          didDislike = true;
          
          // Remove from likes if present
          if (likes.contains(userId)) {
            likes.remove(userId);
            
            // Try to remove like notification if it exists
            try {
              String postOwnerId = postData?['UserId'] ?? '';
              if (postOwnerId.isNotEmpty) {
                await _notificationService.removeLikeNotification(
                  likerId: userId,
                  postOwnerId: postOwnerId,
                  postId: postId
                );
              }
            } catch (e) {
              print('Error removing like notification: $e');
              // Continue with dislike operation even if notification removal fails
            }
          }
        }

        // Update the post document with new dislikes and likes arrays
        transaction.update(postRef, {
          'dislikes': dislikes,
          'likes': likes
        });
        
        return didDislike; // Return true if now disliked, false if now un-disliked
      });
    } catch (e) {
      print('Error toggling dislike on post: $e');
      rethrow;
    }
  }
  
  // Implement other required methods from PostRepo interface
  @override
  Future<List<Post>> fetechAllPosts() {
    throw UnimplementedError('fetechAllPosts not implemented');
  }
  
  @override
  Future<void> CreatePost(Post post) {
    throw UnimplementedError('CreatePost not implemented');
  }
  
  @override
  Future<void> deletePost(String postId) {
    throw UnimplementedError('deletePost not implemented');
  }
  
  @override
  Future<List<Post>> fetechPostsByUserId(String UserId) {
    throw UnimplementedError('fetechPostsByUserId not implemented');
  }
  
  @override
  Future<List<Post>> fetchFollowingPosts(String userId) {
    throw UnimplementedError('fetchFollowingPosts not implemented');
  }
  
  @override
  Future<List<Post>> fetchPostsByCategory(String category, {int limit = 20}) {
    throw UnimplementedError('fetchPostsByCategory not implemented');
  }
  
  @override
  Future<void> addComment(String postId, String userId, String userName, String profilePicture, String content) {
    throw UnimplementedError('addComment not implemented');
  }
  
  @override
  Future<void> deleteComment(String postId, String commentId) {
    throw UnimplementedError('deleteComment not implemented');
  }
  
  @override
  Future<void> updatePostCaption(String postId, String newCaption) {
    throw UnimplementedError('updatePostCaption not implemented');
  }
  
  @override
  Future<void> toggleLikeComment(String postId, String commentId, String userId) {
    throw UnimplementedError('toggleLikeComment not implemented');
  }
  
  @override
  Future<void> addReplyToComment(String postId, String commentId, String userId, String userName, String profilePicture, String content) {
    throw UnimplementedError('addReplyToComment not implemented');
  }
  
  @override
  Future<void> deleteReply(String postId, String commentId, String replyId) {
    throw UnimplementedError('deleteReply not implemented');
  }
  
  @override
  Future<void> toggleLikeReply(String postId, String commentId, String replyId, String userId) {
    throw UnimplementedError('toggleLikeReply not implemented');
  }
  
  @override
  Future<void> toggleSavePost(String postId, String userId) {
    throw UnimplementedError('toggleSavePost not implemented');
  }
  
  @override
  Future<List<Post>> fetchSavedPosts(String userId) {
    throw UnimplementedError('fetchSavedPosts not implemented');
  }
  
  @override
  Future<Post?> getPostById(String postId) {
    throw UnimplementedError('getPostById not implemented');
  }
  
  @override
  Future<void> incrementShareCount(String postId) {
    throw UnimplementedError('incrementShareCount not implemented');
  }
} 