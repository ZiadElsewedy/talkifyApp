import 'package:talkifyapp/features/Posts/domain/Entite/Posts.dart';

abstract class PostRepo {
  Future <List<Post>> fetechAllPosts();
  Future <void> CreatePost(Post post);
  Future <void> deletePost(String postId);
  // fetching posts foe a specific user 
  Future <List<Post>> fetechPostsByUserId(String UserId);
  Future <void> toggleLikePost(String postId, String userId);
  Future <void> addComment(String postId, String userId, String userName, String profilePicture, String content);
  Future <void> deleteComment(String postId, String commentId);
  Future<void> updatePostCaption(String postId, String newCaption);
}