import 'dart:async'; // Add this for StreamSubscription
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Storage/Domain/Storage_repo.dart';
import 'package:talkifyapp/features/Posts/domain/Entite/Posts.dart';
import 'package:talkifyapp/features/Posts/data/video_thumbnail_service.dart';

import 'package:talkifyapp/features/Posts/domain/repos/Post_repo.dart';
import 'package:talkifyapp/features/Posts/presentation/cubits/post_states.dart';

class PostCubit extends Cubit<PostState> {
  final PostRepo _postRepo;
  final StorageRepo _storageRepo;
  StreamSubscription? _uploadProgressSubscription;
  
  PostCubit({
    required PostRepo postRepo,
    required StorageRepo storageRepo,
  }) : _postRepo = postRepo, _storageRepo = storageRepo, super(PostsInitial());

  @override
  Future<void> close() {
    _uploadProgressSubscription?.cancel();
    _storageRepo.dispose();
    return super.close();
  }

  // create a new post 
  Future<void> createPost(Post post, {String? imagePath, Uint8List? imageBytes}) async {
    try {
      // Save current posts if they are loaded
      List<Post> previousPosts = [];
      if (state is PostsLoaded) {
        previousPosts = (state as PostsLoaded).posts;
      }
      
      // Initially emit uploading state
      emit(PostsUploading());
      
      // Create a local post that will be updated during upload
      final localPost = post.copyWith(
        localFilePath: imagePath // Add the local file path to the post
      );
      
      print('Creating post: isVideo=${post.isVideo}, imageUrl=${post.imageUrl}');
      
      // Upload image or video to storage
      String? mediaUrl;
      if (imagePath != null || imageBytes != null) {
        print('Uploading media: path=$imagePath, hasBytes=${imageBytes != null}');
        
        // Determine if it's a video from file extension or post flag
        final bool isVideo = post.isVideo || 
            (imagePath != null && (imagePath.endsWith('.mp4') || 
                                 imagePath.endsWith('.mov') || 
                                 imagePath.endsWith('.avi')));
        
        print('Media type: isVideo=$isVideo');
        
        // Subscribe to upload progress
        _uploadProgressSubscription?.cancel();
        _uploadProgressSubscription = _storageRepo.uploadProgressStream.listen((progress) {
          print('Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
          emit(PostsUploadingProgress(progress, localPost, previousPosts: previousPosts));
        });
        
        // Upload to appropriate storage location
        final String storagePath = isVideo ? 'PostVideos/${post.id}' : 'PostImages/${post.id}';
        print('Storage path: $storagePath');
        
        if (imagePath != null) {
          mediaUrl = await _storageRepo.uploadPostImageMobile(imagePath, post.id);
        } else if (imageBytes != null) {
          mediaUrl = await _storageRepo.uploadPostImageWeb(imageBytes, post.id);
        }
        
        // Cancel the subscription after upload completes
        _uploadProgressSubscription?.cancel();
        _uploadProgressSubscription = null;
        
        print('Media uploaded successfully, URL: $mediaUrl');
        
        // If this is a video, generate a thumbnail
        String? thumbnailUrl;
        if (isVideo && mediaUrl != null) {
          print('Generating thumbnail for video: $mediaUrl');
          try {
            thumbnailUrl = await VideoThumbnailService.generateThumbnail(mediaUrl);
            print('Generated thumbnail URL: $thumbnailUrl');
            
            // If thumbnail generation failed, use the video URL as the thumbnail
            if (thumbnailUrl == null) {
              print('Thumbnail generation failed, using video URL as thumbnail');
              thumbnailUrl = mediaUrl;
            }
          } catch (e) {
            print('Error generating thumbnail: $e');
            // Use video URL as thumbnail if generation fails
            thumbnailUrl = mediaUrl;
          }
        }
      }
      
      // Create updated post with media URL
      final updatedPost = post.copyWith(imageUrl: mediaUrl ?? post.imageUrl);
      
      // Save post to Firestore
      print('Saving post to Firestore: id=${updatedPost.id}, isVideo=${updatedPost.isVideo}');
      await _postRepo.CreatePost(updatedPost);
      print('Post created successfully');
      
      // Refresh posts
      await fetchAllPosts();
    } catch (e) {
      print('Error creating post: $e');
      emit(PostsError(e.toString()));
    }
  }

     // fetch all posts 
    Future<void> fetchAllPosts() async{
      try{
        emit(PostsLoading());
        final posts = await _postRepo.fetechAllPosts();
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
      final posts = await _postRepo.fetchFollowingPosts(userId);
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
      final posts = await _postRepo.fetchPostsByCategory(category);
      print('Fetched ${posts.length} ${category} posts'); // Debug print
      emit(PostsLoaded(posts));
    } catch (e) {
      print('Error fetching ${category} posts: $e'); // Debug print
      emit(PostsError("Failed to fetch ${category} posts: $e"));
    }
  }



  Future<void> deletePost(String postId) async{
    try{
      await _postRepo.deletePost(postId);
    }
    catch(e){
      emit(PostsError("Failed to delete post: $e"));
    }
  } 

  // toggle like in a post 
  Future<void> toggleLikePost(String postId, String userId) async {
    try {
      // Update the like status in the database
      await _postRepo.toggleLikePost(postId, userId);
      
      // No need to refresh all posts, the notification will be handled by the repository
    } catch (e) {
      print('Error toggling like: $e');
      throw Exception('Failed to toggle like: $e');
    }
  }

  // add a comment to a post without refreshing the entire page
  Future<void> addCommentLocal(String postId, String userId, String userName, String profilePicture, String content) async {
    try {
      await _postRepo.addComment(postId, userId, userName, profilePicture, content);
      // Don't emit a loading state or fetch all posts - let the UI handle the update
    } catch(e) {
      // Just throw the error to be handled by the UI
      throw Exception("Failed to add comment: $e");
    }
  }

  // add a comment to a post
  Future<void> addComment(String postId, String userId, String userName, String profilePicture, String content) async {
    try {
      await _postRepo.addComment(postId, userId, userName, profilePicture, content);
      // Refresh posts after adding comment
      await fetchAllPosts();
    } catch(e) {
      emit(PostsError("Failed to add comment: $e"));
    }
  }

  // delete a comment from a post without refreshing
  Future<void> deleteCommentLocal(String postId, String commentId) async {  
    try {
      await _postRepo.deleteComment(postId, commentId);
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
      await _postRepo.deleteComment(postId, commentId);
      // Refresh posts after deleting comment
      await fetchAllPosts();
    } catch(e) {
      emit(PostsError("Failed to delete comment: $e"));
    }
  }  

  // update post caption
  Future<void> updatePostCaption(String postId, String newCaption) async {
    try {
      await _postRepo.updatePostCaption(postId, newCaption);
      await fetchAllPosts();
    } catch (e) {
      emit(PostsError('Failed to update caption: $e'));
    }
  }

  // COMMENT LIKES AND REPLIES

  // Toggle like on a comment
  Future<void> toggleLikeComment(String postId, String commentId, String userId) async {
    try {
      await _postRepo.toggleLikeComment(postId, commentId, userId);
      await fetchAllPosts();
    } catch (e) {
      emit(PostsError('Failed to like comment: $e'));
    }
  }

  // Add a reply to a comment
  Future<void> addReplyToComment(String postId, String commentId, String userId, String userName, String profilePicture, String content) async {
    try {
      await _postRepo.addReplyToComment(postId, commentId, userId, userName, profilePicture, content);
      await fetchAllPosts();
    } catch (e) {
      emit(PostsError('Failed to add reply: $e'));
    }
  }

  // Delete a reply
  Future<void> deleteReply(String postId, String commentId, String replyId) async {
    try {
      await _postRepo.deleteReply(postId, commentId, replyId);
      await fetchAllPosts();
    } catch (e) {
      emit(PostsError('Failed to delete reply: $e'));
    }
  }

  // Toggle like on a reply
  Future<void> toggleLikeReply(String postId, String commentId, String replyId, String userId) async {
    try {
      await _postRepo.toggleLikeReply(postId, commentId, replyId, userId);
      await fetchAllPosts();
    } catch (e) {
      emit(PostsError('Failed to like reply: $e'));
    }
  }

  // Local versions that don't refresh the entire post list

  // Toggle like on a comment without refreshing
  Future<void> toggleLikeCommentLocal(String postId, String commentId, String userId) async {
    try {
      await _postRepo.toggleLikeComment(postId, commentId, userId);
      // Don't emit a loading state or fetch all posts
    } catch (e) {
      // Just throw the error to be handled by the UI
      throw Exception('Failed to like comment: $e');
    }
  }

  // Add a reply to a comment without refreshing
  Future<void> addReplyToCommentLocal(String postId, String commentId, String userId, String userName, String profilePicture, String content) async {
    try {
      await _postRepo.addReplyToComment(postId, commentId, userId, userName, profilePicture, content);
      // Don't emit a loading state or fetch all posts
    } catch (e) {
      // Just throw the error to be handled by the UI
      throw Exception('Failed to add reply: $e');
    }
  }

  // Delete a reply without refreshing
  Future<void> deleteReplyLocal(String postId, String commentId, String replyId) async {
    try {
      await _postRepo.deleteReply(postId, commentId, replyId);
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
      
      await _postRepo.toggleLikeReply(postId, commentId, replyId, userId);
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
      await _postRepo.toggleSavePost(postId, userId);
      // Refresh posts to update UI
      await fetchAllPosts();
    } catch (e) {
      emit(PostsError('Failed to save/unsave post: $e'));
    }
  }

  // Toggle save post without refreshing the entire list
  Future<void> toggleSavePostLocal(String postId, String userId) async {
    try {
      await _postRepo.toggleSavePost(postId, userId);
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
      final posts = await _postRepo.fetchSavedPosts(userId);
      emit(PostsLoaded(posts));
    } catch (e) {
      emit(PostsError('Failed to fetch saved posts: $e'));
    }
  }

  // Get a specific post by ID
  Future<Post?> getPostById(String postId) async {
    try {
      final post = await _postRepo.getPostById(postId);
      return post;
    } catch (e) {
      print('Error fetching post by ID: $e');
      throw Exception('Failed to fetch post: $e');
    }
  }

  // Increment share count for a post
  Future<void> incrementShareCount(String postId) async {
    try {
      await _postRepo.incrementShareCount(postId);
      // No need to refresh the entire post list for a share count update
    } catch (e) {
      print('Error incrementing share count: $e');
      // Don't emit error state to avoid disrupting the UI flow
    }
  }

  // Fetch posts by user ID
  Future<List<Post>> fetchUserPosts(String userId) async {
    try {
      emit(PostsLoading());
      final posts = await _postRepo.fetechPostsByUserId(userId);
      print('Fetched ${posts.length} posts for user $userId');
      emit(PostsLoaded(posts));
      return posts;
    } catch (e) {
      print('Error fetching user posts: $e');
      emit(PostsError(e.toString()));
      return [];
    }
  }

  // Generate thumbnails for existing video posts
  Future<void> generateThumbnailsForVideoPosts() async {
    try {
      print('Generating thumbnails for video posts');
      
      // Get all posts
      final posts = await _postRepo.fetechAllPosts();
      
      // Filter for video posts
      final videoPosts = posts.where((post) => post.isVideo).toList();
      print('Found ${videoPosts.length} video posts');
      
      // Generate thumbnails for each video post
      int successCount = 0;
      for (final post in videoPosts) {
        if (post.imageUrl.isNotEmpty) {
          try {
            print('Generating thumbnail for video post: ${post.id}');
            final thumbnailUrl = await VideoThumbnailService.generateThumbnailForPost(post.id, post.imageUrl);
            
            if (thumbnailUrl != null) {
              print('Generated thumbnail URL: $thumbnailUrl');
              successCount++;
            }
          } catch (e) {
            print('Error generating thumbnail for post ${post.id}: $e');
          }
        }
      }
      
      print('Successfully generated $successCount thumbnails for ${videoPosts.length} video posts');
    } catch (e) {
      print('Error generating thumbnails for video posts: $e');
    }
  }
}