import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:talkifyapp/features/Posts/domain/Entite/Comments.dart';
import 'package:talkifyapp/features/Posts/domain/Entite/Posts.dart';
import 'package:talkifyapp/features/Posts/domain/repos/Post_repo.dart';

class FirebasePostRepo implements PostRepo{
final FirebaseFirestore firestore = FirebaseFirestore.instance;

// store the posts in the firestore collection called 'posts'
final CollectionReference postsCollection = FirebaseFirestore.instance.collection('posts');

  @override
  Future <void> CreatePost(Post post) async{
    try{
      // Create a new document reference
      final docRef = postsCollection.doc();
      // Create a new post with the document ID
      final postWithId = Post(
        id: docRef.id,
        UserId: post.UserId,
        UserName: post.UserName,
        UserProfilePic: post.UserProfilePic,
        Text: post.Text,
        imageUrl: post.imageUrl,
        timestamp: post.timestamp,
        likes: post.likes,
        comments: post.comments,
        savedBy: post.savedBy,
      );
      // Set the document with the post data
      await docRef.set(postWithId.toJson());
    }catch(e){
      print('Error creating post: $e');
      throw Exception("Error creating post: $e");
    }
  }

  @override
  Future <void> deletePost(String postId) async{
    try {
      print('Attempting to delete post with ID: $postId');
      // First check if the document exists
      final docRef = postsCollection.doc(postId);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        throw Exception("Post not found");
      }
      
      await docRef.delete();
      print('Successfully deleted post with ID: $postId');
    } catch (e) {
      print('Error deleting post: $e');
      throw Exception("Error deleting post: $e");
    }
  }

  @override
  Future <List<Post>> fetechAllPosts() async{
     try{
      // get all the posts with most recent post at the top
      final snapshot = await postsCollection.orderBy('timestamp', descending: true).get();
      
      print('Firestore documents count: ${snapshot.docs.length}'); // Debug print
      
      // convert each firestore document from json ---> list of posts
      final List<Post> allposts = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Add the document ID to the data
        data['id'] = doc.id;
        print('Post data: $data'); // Debug print
        return Post.fromJson(data);
      }).toList();

      return allposts;
     }catch(e){
      print('Error in fetchAllPosts: $e'); // Debug print
      throw Exception("Error fetching posts: $e");
     }
  }
  
  @override
  Future<List<Post>> fetechPostsByUserId(String UserId) async {
    try {
      // fetch posts snapshot with this uid
      final postsSnapshot = await postsCollection.where('UserId', isEqualTo: UserId).get();

      // convert firestore documents from json --> list of posts
      final userPosts = postsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Add the document ID to the data
        data['id'] = doc.id;
        return Post.fromJson(data);
      }).toList();

      return userPosts;
    } catch (e) {
      throw Exception("Error fetching posts by user: $e");
    }
  }

  @override
  Future<List<Post>> fetchFollowingPosts(String userId) async {
    try {
      // Step 1: Get the list of users that the current user is following
      final userDoc = await firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        throw Exception("User not found");
      }
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final List<String> following = List<String>.from(userData['following'] ?? []);
      
      // If user isn't following anyone, return empty list
      if (following.isEmpty) {
        return [];
      }
      
      // Step 2: Fetch all posts first
      final snapshot = await postsCollection.get();
      final allPosts = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Post.fromJson(data);
      }).toList();
      
      // Step 3: Filter posts by followed users and sort by timestamp
      final followingPosts = allPosts.where((post) => 
        following.contains(post.UserId)
      ).toList();
      
      // Sort by timestamp (most recent first)
      followingPosts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return followingPosts;
    } catch (e) {
      print('Error fetching following posts: $e');
      throw Exception("Error fetching following posts: $e");
    }
  }

  @override
  Future<List<Post>> fetchPostsByCategory(String category, {int limit = 20}) async {
    try {
      late QuerySnapshot snapshot;
      
      switch (category.toLowerCase()) {
        case 'trending':
          // For trending posts, fetch posts with most likes
          final allPostsDocs = await postsCollection.get();
          
          // Convert to list for sorting
          final allPosts = allPostsDocs.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            // Get likes count for sorting
            final likesCount = (data['likes'] as List?)?.length ?? 0;
            return {'doc': doc, 'likesCount': likesCount};
          }).toList();
          
          // Sort by likes count (descending)
          allPosts.sort((a, b) => (b['likesCount'] as int).compareTo(a['likesCount'] as int));
          
          // Take only the top posts based on limit
          final limitedPosts = allPosts.take(limit).map((item) {
            final doc = item['doc'] as QueryDocumentSnapshot;
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return Post.fromJson(data);
          }).toList();
          
          return limitedPosts;
          
        case 'latest':
          // For latest posts, order by timestamp
          snapshot = await postsCollection
              .orderBy('timestamp', descending: true)
              .limit(limit)
              .get();
          break;
          
        case 'popular':
          // For popular posts, sort by number of comments
          final allPostsDocs = await postsCollection.get();
          
          // Convert to list for sorting by comment count
          final allPosts = allPostsDocs.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            // Get comments count for sorting
            final commentsCount = (data['comments'] as List?)?.length ?? 0;
            return {'doc': doc, 'commentsCount': commentsCount};
          }).toList();
          
          // Sort by comment count (descending)
          allPosts.sort((a, b) => (b['commentsCount'] as int).compareTo(a['commentsCount'] as int));
          
          // Take only the top posts based on limit
          final limitedPosts = allPosts.take(limit).map((item) {
            final doc = item['doc'] as QueryDocumentSnapshot;
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return Post.fromJson(data);
          }).toList();
          
          return limitedPosts;
          
        default:
          // Default to latest posts
          snapshot = await postsCollection
              .orderBy('timestamp', descending: true)
              .limit(limit)
              .get();
      }
      
      // Convert snapshot to Post objects (for cases that use snapshot)
      final posts = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Post.fromJson(data);
      }).toList();
      
      return posts;
    } catch (e) {
      print('Error fetching posts by category: $e');
      throw Exception("Error fetching posts by category: $e");
    }
  }

  @override
  Future<void> toggleLikePost(String postId, String userId) async {
    try {
      // Validate parameters
      if (postId.isEmpty || userId.isEmpty) {
        throw Exception("Invalid parameters: postId or userId is empty");
      }
      
      // Get the post document from firestore
      final postDoc = await postsCollection.doc(postId).get();
      if (postDoc.exists) {
        final data = postDoc.data() as Map<String, dynamic>;
        
        // Ensure 'likes' field exists and is a List
        List<String> likes = [];
        if (data.containsKey('likes')) {
          // Convert all items to String to avoid type issues
          likes = (data['likes'] as List?)
              ?.map((item) => item?.toString() ?? "")
              .where((item) => item.isNotEmpty)
              .toList() ?? [];
        }
        
        // Check if user has already liked this post
        final hasLiked = likes.contains(userId);
        
        // Update the likes list
        if (hasLiked) {
          likes.remove(userId); // Unlike the post
        } else {
          likes.add(userId); // Like the post
        }
        
        // Update the post document with the new likes list
        await postsCollection.doc(postId).update({
          'likes': likes,
        });
      } else {
        throw Exception("Post not found");
      }
    } catch (e) {
      print('Error in toggleLikePost: $e');
      throw Exception("Error toggling like: $e");
    }
  }

  @override
  Future<void> addComment(String postId, String userId, String userName, String profilePicture, String content) async {
    try {
      // Get the post document from firestore
      final postDoc = await postsCollection.doc(postId).get();    

      if (!postDoc.exists) {
        throw Exception("Post not found");
      }

      final post = Post.fromJson(postDoc.data() as Map<String, dynamic>);   
      
      // Generate a new unique ID for the comment
      final commentId = FirebaseFirestore.instance.collection('comments').doc().id;
      
      // create a new comment
      final newComment = Comments(
        commentId: commentId,
        content: content,
        postId: postId,
        userId: userId,
        userName: userName,
        profilePicture: profilePicture,
        createdAt: DateTime.now(),
      );

      // add the comment to the post
      post.comments.add(newComment);

      // update the post document with the new comment
      await postsCollection.doc(postId).update({
        'comments': post.comments.map((comment) => comment.toJson()).toList(),
      });
    } catch (e) {
      print('Error adding comment: $e'); // Add logging
      throw Exception("Error adding comment: $e");
    }
  }

  @override
  Future<void> deleteComment(String postId, String commentId) async {
    try {
      // Get the post document from firestore
      final postDoc = await postsCollection.doc(postId).get();

      if (!postDoc.exists) {
        throw Exception("Post not found");
      }

      final post = Post.fromJson(postDoc.data() as Map<String, dynamic>);

      // Check if comment exists
      final commentExists = post.comments.any((comment) => comment.commentId == commentId);
      if (!commentExists) {
        throw Exception("Comment not found");
      }

      // delete the comment from the post
      post.comments.removeWhere((comment) => comment.commentId == commentId);

      // update the post document with the new comment list
      await postsCollection.doc(postId).update({
        'comments': post.comments.map((comment) => comment.toJson()).toList(),
      }); 
    } catch (e) {
      print('Error deleting comment: $e'); // Add logging
      throw Exception("Error deleting comment: $e");
    }
  }

  @override
  Future<void> updatePostCaption(String postId, String newCaption) async {
    try {
      await postsCollection.doc(postId).update({
        'text': newCaption,
      });
    } catch (e) {
      print('Error updating post caption: $e');
      throw Exception('Error updating post caption: $e');
    }
  }

  @override
  Future<void> toggleLikeComment(String postId, String commentId, String userId) async {
    try {
      // Get the post document
      final postDoc = await postsCollection.doc(postId).get();
      
      if (!postDoc.exists) {
        throw Exception("Post not found");
      }
      
      final post = Post.fromJson(postDoc.data() as Map<String, dynamic>);
      
      // Find the comment
      final commentIndex = post.comments.indexWhere((comment) => comment.commentId == commentId);
      
      if (commentIndex == -1) {
        throw Exception("Comment not found");
      }
      
      // Get the comment
      final comment = post.comments[commentIndex];
      
      // Create a new list of likes
      List<String> updatedLikes = List<String>.from(comment.likes);
      
      // Toggle the like
      if (updatedLikes.contains(userId)) {
        updatedLikes.remove(userId);
      } else {
        updatedLikes.add(userId);
      }
      
      // Create a new comment with updated likes
      final updatedComment = Comments(
        commentId: comment.commentId,
        content: comment.content,
        postId: comment.postId,
        userId: comment.userId,
        userName: comment.userName,
        profilePicture: comment.profilePicture,
        createdAt: comment.createdAt,
        likes: updatedLikes,
        replies: comment.replies,
      );
      
      // Update the comment in the post's comments list
      post.comments[commentIndex] = updatedComment;
      
      // Update the post document
      await postsCollection.doc(postId).update({
        'comments': post.comments.map((c) => c.toJson()).toList(),
      });
    } catch (e) {
      print('Error toggling comment like: $e');
      throw Exception("Error toggling comment like: $e");
    }
  }

  @override
  Future<void> addReplyToComment(String postId, String commentId, String userId, String userName, String profilePicture, String content) async {
    try {
      // Get the post document
      final postDoc = await postsCollection.doc(postId).get();
      
      if (!postDoc.exists) {
        throw Exception("Post not found");
      }
      
      final post = Post.fromJson(postDoc.data() as Map<String, dynamic>);
      
      // Find the comment
      final commentIndex = post.comments.indexWhere((comment) => comment.commentId == commentId);
      
      if (commentIndex == -1) {
        throw Exception("Comment not found");
      }
      
      // Get the comment
      final comment = post.comments[commentIndex];
      
      // Generate a new unique ID for the reply
      final replyId = FirebaseFirestore.instance.collection('replies').doc().id;
      
      // Create a new reply
      final newReply = Reply(
        replyId: replyId,
        content: content,
        userId: userId,
        userName: userName,
        profilePicture: profilePicture,
        createdAt: DateTime.now(),
        likes: [],
      );
      
      // Add the reply to the comment's replies list
      final updatedReplies = List<Reply>.from(comment.replies)..add(newReply);
      
      // Create a new comment with the updated replies
      final updatedComment = Comments(
        commentId: comment.commentId,
        content: comment.content,
        postId: comment.postId,
        userId: comment.userId,
        userName: comment.userName,
        profilePicture: comment.profilePicture,
        createdAt: comment.createdAt,
        likes: comment.likes,
        replies: updatedReplies,
      );
      
      // Update the comment in the post's comments list
      post.comments[commentIndex] = updatedComment;
      
      // Update the post document
      await postsCollection.doc(postId).update({
        'comments': post.comments.map((c) => c.toJson()).toList(),
      });
    } catch (e) {
      print('Error adding reply to comment: $e');
      throw Exception("Error adding reply to comment: $e");
    }
  }

  @override
  Future<void> deleteReply(String postId, String commentId, String replyId) async {
    try {
      // Get the post document
      final postDoc = await postsCollection.doc(postId).get();
      
      if (!postDoc.exists) {
        throw Exception("Post not found");
      }
      
      final post = Post.fromJson(postDoc.data() as Map<String, dynamic>);
      
      // Find the comment
      final commentIndex = post.comments.indexWhere((comment) => comment.commentId == commentId);
      
      if (commentIndex == -1) {
        throw Exception("Comment not found");
      }
      
      // Get the comment
      final comment = post.comments[commentIndex];
      
      // Check if reply exists
      final replyExists = comment.replies.any((reply) => reply.replyId == replyId);
      
      if (!replyExists) {
        throw Exception("Reply not found");
      }
      
      // Remove the reply from the comment's replies list
      final updatedReplies = List<Reply>.from(comment.replies)
        ..removeWhere((reply) => reply.replyId == replyId);
      
      // Create a new comment with the updated replies
      final updatedComment = Comments(
        commentId: comment.commentId,
        content: comment.content,
        postId: comment.postId,
        userId: comment.userId,
        userName: comment.userName,
        profilePicture: comment.profilePicture,
        createdAt: comment.createdAt,
        likes: comment.likes,
        replies: updatedReplies,
      );
      
      // Update the comment in the post's comments list
      post.comments[commentIndex] = updatedComment;
      
      // Update the post document
      await postsCollection.doc(postId).update({
        'comments': post.comments.map((c) => c.toJson()).toList(),
      });
    } catch (e) {
      print('Error deleting reply: $e');
      throw Exception("Error deleting reply: $e");
    }
  }

  @override
  Future<void> toggleLikeReply(String postId, String commentId, String replyId, String userId) async {
    try {
      // Validate parameters
      if (postId.isEmpty || commentId.isEmpty || replyId.isEmpty || userId.isEmpty) {
        throw Exception("Invalid parameters: one or more required IDs are empty");
      }
      
      print('Toggling like for reply: $replyId in comment: $commentId of post: $postId by user: $userId');
      
      // Get the post document
      final postDoc = await postsCollection.doc(postId).get();
      
      if (!postDoc.exists) {
        throw Exception("Post not found with ID: $postId");
      }
      
      final post = Post.fromJson(postDoc.data() as Map<String, dynamic>);
      
      // Find the comment
      final commentIndex = post.comments.indexWhere((comment) => comment.commentId == commentId);
      
      if (commentIndex == -1) {
        throw Exception("Comment not found with ID: $commentId in post: $postId");
      }
      
      // Get the comment
      final comment = post.comments[commentIndex];
      
      // Find the reply
      final replyIndex = comment.replies.indexWhere((reply) => reply.replyId == replyId);
      
      if (replyIndex == -1) {
        print('Reply not found. Available replies: ${comment.replies.map((r) => r.replyId).join(', ')}');
        throw Exception("Reply not found with ID: $replyId in comment: $commentId");
      }
      
      // Get the reply
      final reply = comment.replies[replyIndex];
      
      // Create a new list of likes
      List<String> updatedLikes = List<String>.from(reply.likes);
      
      // Toggle the like
      if (updatedLikes.contains(userId)) {
        updatedLikes.remove(userId);
        print('Removed like from reply: $replyId');
      } else {
        updatedLikes.add(userId);
        print('Added like to reply: $replyId');
      }
      
      // Create a new reply with updated likes
      final updatedReply = Reply(
        replyId: reply.replyId,
        content: reply.content,
        userId: reply.userId,
        userName: reply.userName,
        profilePicture: reply.profilePicture,
        createdAt: reply.createdAt,
        likes: updatedLikes,
      );
      
      // Update the reply in the comment's replies list
      final updatedReplies = List<Reply>.from(comment.replies);
      updatedReplies[replyIndex] = updatedReply;
      
      // Create a new comment with the updated replies
      final updatedComment = Comments(
        commentId: comment.commentId,
        content: comment.content,
        postId: comment.postId,
        userId: comment.userId,
        userName: comment.userName,
        profilePicture: comment.profilePicture,
        createdAt: comment.createdAt,
        likes: comment.likes,
        replies: updatedReplies,
      );
      
      // Update the comment in the post's comments list
      post.comments[commentIndex] = updatedComment;
      
      // Update the post document
      await postsCollection.doc(postId).update({
        'comments': post.comments.map((c) => c.toJson()).toList(),
      });
      
      print('Successfully toggled like for reply: $replyId');
    } catch (e) {
      print('Error toggling reply like: $e');
      throw Exception("Error toggling reply like: $e");
    }
  }

  @override
  Future<void> toggleSavePost(String postId, String userId) async {
    try {
      // Get the post document
      final postDoc = await postsCollection.doc(postId).get();
      
      if (!postDoc.exists) {
        throw Exception("Post not found with ID: $postId");
      }
      
      final data = postDoc.data() as Map<String, dynamic>;
      
      // Create a list of saved users if it doesn't exist
      List<String> savedBy = List<String>.from(data['savedBy'] ?? []);
      
      // Toggle the save status
      if (savedBy.contains(userId)) {
        // Unsave the post
        savedBy.remove(userId);
        print('Removed post $postId from saved by user $userId');
      } else {
        // Save the post
        savedBy.add(userId);
        print('Added post $postId to saved by user $userId');
      }
      
      // Update the post document with the new savedBy list
      await postsCollection.doc(postId).update({
        'savedBy': savedBy,
      });
      
      // Also update user's saved posts collection for faster retrieval
      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      
      if (savedBy.contains(userId)) {
        // Add to saved collection
        await userRef.collection('savedPosts').doc(postId).set({
          'savedAt': FieldValue.serverTimestamp(),
          'postId': postId
        });
      } else {
        // Remove from saved collection
        await userRef.collection('savedPosts').doc(postId).delete();
      }
      
    } catch (e) {
      print('Error toggling save post: $e');
      throw Exception("Error toggling save post: $e");
    }
  }
  
  @override
  Future<List<Post>> fetchSavedPosts(String userId) async {
    try {
      // Get the user's saved posts collection
      final savedPostsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('savedPosts')
          .orderBy('savedAt', descending: true)
          .get();
      
      if (savedPostsSnapshot.docs.isEmpty) {
        return [];
      }
      
      // Extract post IDs
      final savedPostIds = savedPostsSnapshot.docs.map((doc) => doc.id).toList();
      
      // Fetch all posts
      final allPosts = await fetechAllPosts();
      
      // Filter to only include saved posts
      final savedPosts = allPosts.where((post) => 
        savedPostIds.contains(post.id)
      ).toList();
      
      return savedPosts;
    } catch (e) {
      print('Error fetching saved posts: $e');
      throw Exception("Error fetching saved posts: $e");
    }
  }
}

