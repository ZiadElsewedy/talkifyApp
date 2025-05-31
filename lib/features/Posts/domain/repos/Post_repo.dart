import 'package:talkifyapp/features/Posts/domain/Entite/Posts.dart';

abstract class PostRepo {
  Future <List<Post>> fetechAllPosts();
  Future <void> CreatePost(Post post);
  Future <void> deletePost(String postId);
  // fetching posts foe a specific user 
  Future <List<Post>> fetechPostsByUserId(String UserId);
  // fetch posts from accounts the user is following
  Future <List<Post>> fetchFollowingPosts(String userId);
  // fetch posts by category (trending, latest, etc.)
  Future <List<Post>> fetchPostsByCategory(String category, {int limit = 20});
  Future <void> toggleLikePost(String postId, String userId);
  Future <void> addComment(String postId, String userId, String userName, String profilePicture, String content);
  Future <void> deleteComment(String postId, String commentId);
  Future<void> updatePostCaption(String postId, String newCaption);
  
  // New methods for comment likes and replies
  Future<void> toggleLikeComment(String postId, String commentId, String userId);
  Future<void> addReplyToComment(String postId, String commentId, String userId, String userName, String profilePicture, String content);
  Future<void> deleteReply(String postId, String commentId, String replyId);
  Future<void> toggleLikeReply(String postId, String commentId, String replyId, String userId);
  
  // Save post functionality
  Future<void> toggleSavePost(String postId, String userId);
  Future<List<Post>> fetchSavedPosts(String userId);
  
  // Get a specific post by ID
  Future<Post?> getPostById(String postId);
}