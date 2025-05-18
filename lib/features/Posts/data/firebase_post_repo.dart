import 'package:cloud_firestore/cloud_firestore.dart';
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
  Future<void> toggleLikePost(String postId, String userId) async {
    try {
      // Get the post document from firestore
      final postDoc = await postsCollection.doc(postId).get();
      if (postDoc.exists) {
        final post = Post.fromJson(postDoc.data() as Map<String, dynamic>);

        // check if the user has already like this post
        final HasLiked = post.likes.contains(userId);

        // update the like list 
        if (HasLiked){
          // remove the like
          post.likes.remove(userId); // unlike the post
        }else{
          // add the like
          post.likes.add(userId); // like the post
        }

        // update the post document with the new like list
        await postsCollection.doc(postId).update({
          'likes': post.likes,
        });
      } else {
        throw Exception("Post not found");
      }
    }
catch (e){
  throw Exception("Error toggling like: $e");
}
  }

}