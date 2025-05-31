import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Storage/Domain/Storage_repo.dart';
import 'package:talkifyapp/features/Posts/domain/Entite/Posts.dart';

import 'package:talkifyapp/features/Posts/domain/repos/Post_repo.dart';
import 'package:talkifyapp/features/Posts/presentation/cubits/post_states.dart';

class PostCubit extends Cubit<PostState> {
final PostRepo postRepo;
final StorageRepo storageRepo;

PostCubit({
  required this.postRepo,
  required this.storageRepo,
}) : super(PostsInitial());

// create a new post 
Future<void> createPost(Post post, {String? imagePath, Uint8List? imageBytes}) async {
 String? imageUrl;


try{
// handle image upload for mobile platforms(using file path)
 if (imagePath != null) {
  emit(PostsUploading());
  imageUrl = await storageRepo.uploadPostImageMobile(imagePath, post.id);
 }
 
 
 // handle image upload for web platforms(using file bytes)
 else if (imageBytes != null) {
  emit(PostsUploading());
  imageUrl = await storageRepo.uploadPostImageWeb(imageBytes, post.id);
 }

// give image url to post 
final newPost = post.copyWith(imageUrl: imageUrl);


// create this post in the backend 
postRepo.CreatePost(newPost);

// re-fetch all posts
fetechAllPosts(); 

}catch(e){
    emit(PostsError("Failed to create post: $e"));
  }
  }

   // fetch all posts 
  Future<void> fetechAllPosts() async{
    try{
      emit(PostsLoading());
      final posts = await postRepo.fetechAllPosts();
      print('Fetched ${posts.length} posts'); // Debug print
      emit(PostsLoaded(posts));
    }
    catch (e){
      print('Error fetching posts: $e'); // Debug print
      emit(PostsError("Failed to fetch posts: $e"));
    }
}

// fetch posts from followed accounts
Future<void> fetchFollowingPosts(String userId) async {
  try {
    emit(PostsLoading());
    final posts = await postRepo.fetchFollowingPosts(userId);
    print('Fetched ${posts.length} following posts'); // Debug print
    emit(PostsLoaded(posts));
  } catch (e) {
    print('Error fetching following posts: $e'); // Debug print
    emit(PostsError("Failed to fetch following posts: $e"));
  }
}

// fetch posts by category
Future<void> fetchPostsByCategory(String category) async {
  try {
    emit(PostsLoading());
    final posts = await postRepo.fetchPostsByCategory(category);
    print('Fetched ${posts.length} ${category} posts'); // Debug print
    emit(PostsLoaded(posts));
  } catch (e) {
    print('Error fetching ${category} posts: $e'); // Debug print
    emit(PostsError("Failed to fetch ${category} posts: $e"));
  }
}

// delete a post 
Future<void> deletePost(String postId) async{
  try{
    await postRepo.deletePost(postId);
  }
  catch(e){
    emit(PostsError("Failed to delete post: $e"));
  }
} 

// toggle like in a post 
Future<void> toggleLikePost(String postId, String userId) async{
  try{
    await postRepo.toggleLikePost(postId, userId);
  }
  catch(e){
    emit(PostsError("Failed to toggle like: $e"));
  }
}

// add a comment to a post without refreshing the entire page
Future<void> addCommentLocal(String postId, String userId, String userName, String profilePicture, String content) async {
  try {
    await postRepo.addComment(postId, userId, userName, profilePicture, content);
    // Don't emit a loading state or fetch all posts - let the UI handle the update
  } catch(e) {
    // Just throw the error to be handled by the UI
    throw Exception("Failed to add comment: $e");
  }
}

// add a comment to a post
Future<void> addComment(String postId, String userId, String userName, String profilePicture, String content) async {
  try {
    await postRepo.addComment(postId, userId, userName, profilePicture, content);
    // Refresh posts after adding comment
    await fetechAllPosts();
  } catch(e) {
    emit(PostsError("Failed to add comment: $e"));
  }
}

// delete a comment from a post without refreshing
Future<void> deleteCommentLocal(String postId, String commentId) async {  
  try {
    await postRepo.deleteComment(postId, commentId);
    // Don't emit loading state or refresh posts
  } catch(e) {
    // Just throw the error to be handled by the UI
    throw Exception("Failed to delete comment: $e");
  }
}  

// delete a comment from a post
Future<void> deleteComment(String postId, String commentId) async {  
  try {
    emit(PostsLoading());
    await postRepo.deleteComment(postId, commentId);
    // Refresh posts after deleting comment
    await fetechAllPosts();
  } catch(e) {
    emit(PostsError("Failed to delete comment: $e"));
  }
}  

// update post caption
Future<void> updatePostCaption(String postId, String newCaption) async {
  try {
    await postRepo.updatePostCaption(postId, newCaption);
    await fetechAllPosts();
  } catch (e) {
    emit(PostsError('Failed to update caption: $e'));
  }
}

// COMMENT LIKES AND REPLIES

// Toggle like on a comment
Future<void> toggleLikeComment(String postId, String commentId, String userId) async {
  try {
    await postRepo.toggleLikeComment(postId, commentId, userId);
    await fetechAllPosts();
  } catch (e) {
    emit(PostsError('Failed to like comment: $e'));
  }
}

// Add a reply to a comment
Future<void> addReplyToComment(String postId, String commentId, String userId, String userName, String profilePicture, String content) async {
  try {
    await postRepo.addReplyToComment(postId, commentId, userId, userName, profilePicture, content);
    await fetechAllPosts();
  } catch (e) {
    emit(PostsError('Failed to add reply: $e'));
  }
}

// Delete a reply
Future<void> deleteReply(String postId, String commentId, String replyId) async {
  try {
    await postRepo.deleteReply(postId, commentId, replyId);
    await fetechAllPosts();
  } catch (e) {
    emit(PostsError('Failed to delete reply: $e'));
  }
}

// Toggle like on a reply
Future<void> toggleLikeReply(String postId, String commentId, String replyId, String userId) async {
  try {
    await postRepo.toggleLikeReply(postId, commentId, replyId, userId);
    await fetechAllPosts();
  } catch (e) {
    emit(PostsError('Failed to like reply: $e'));
  }
}

// Local versions that don't refresh the entire post list

// Toggle like on a comment without refreshing
Future<void> toggleLikeCommentLocal(String postId, String commentId, String userId) async {
  try {
    await postRepo.toggleLikeComment(postId, commentId, userId);
    // Don't emit a loading state or fetch all posts
  } catch (e) {
    // Just throw the error to be handled by the UI
    throw Exception('Failed to like comment: $e');
  }
}

// Add a reply to a comment without refreshing
Future<void> addReplyToCommentLocal(String postId, String commentId, String userId, String userName, String profilePicture, String content) async {
  try {
    await postRepo.addReplyToComment(postId, commentId, userId, userName, profilePicture, content);
    // Don't emit a loading state or fetch all posts
  } catch (e) {
    // Just throw the error to be handled by the UI
    throw Exception('Failed to add reply: $e');
  }
}

// Delete a reply without refreshing
Future<void> deleteReplyLocal(String postId, String commentId, String replyId) async {
  try {
    await postRepo.deleteReply(postId, commentId, replyId);
    // Don't emit a loading state or fetch all posts
  } catch (e) {
    // Just throw the error to be handled by the UI
    throw Exception('Failed to delete reply: $e');
  }
}

// Toggle like on a reply without refreshing
Future<void> toggleLikeReplyLocal(String postId, String commentId, String replyId, String userId) async {
  try {
    print('PostCubit: Attempting to toggle like for reply: $replyId');
    if (postId.isEmpty || commentId.isEmpty || replyId.isEmpty || userId.isEmpty) {
      throw Exception("Invalid parameters: missing required IDs");
    }
    
    await postRepo.toggleLikeReply(postId, commentId, replyId, userId);
    print('PostCubit: Successfully toggled like for reply: $replyId');
  } catch (e) {
    print('PostCubit: Error toggling like for reply: $e');
    // Rethrow with a clearer message for the UI
    throw Exception('Failed to like reply: $e');
  }
}

// Save/unsave post
Future<void> toggleSavePost(String postId, String userId) async {
  try {
    await postRepo.toggleSavePost(postId, userId);
    // Refresh posts to update UI
    await fetechAllPosts();
  } catch (e) {
    emit(PostsError('Failed to save/unsave post: $e'));
  }
}

// Toggle save post without refreshing the entire list
Future<void> toggleSavePostLocal(String postId, String userId) async {
  try {
    await postRepo.toggleSavePost(postId, userId);
    // Don't refresh posts - UI will handle the update
  } catch (e) {
    // Just throw the error to be handled by the UI
    throw Exception('Failed to save/unsave post: $e');
  }
}

// Fetch saved posts
Future<void> fetchSavedPosts(String userId) async {
  try {
    emit(PostsLoading());
    final posts = await postRepo.fetchSavedPosts(userId);
    emit(PostsLoaded(posts));
  } catch (e) {
    emit(PostsError('Failed to fetch saved posts: $e'));
  }
}

// Get a specific post by ID
Future<Post?> getPostById(String postId) async {
  try {
    final post = await postRepo.getPostById(postId);
    return post;
  } catch (e) {
    print('Error fetching post by ID: $e');
    throw Exception('Failed to fetch post: $e');
  }
}

// Increment share count for a post
Future<void> incrementShareCount(String postId) async {
  try {
    await postRepo.incrementShareCount(postId);
    // No need to refresh the entire post list for a share count update
  } catch (e) {
    print('Error incrementing share count: $e');
    // Don't emit error state to avoid disrupting the UI flow
  }
}
}