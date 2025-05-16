import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/Posts/domain/Entite/Posts.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/Posts/domain/repos/Post_repo.dart';

class FirebasePostRepo implements PostRepo{
final FirebaseFirestore firestore = FirebaseFirestore.instance;

// store the posts in the firestore collection called 'posts'
final CollectionReference postsCollection = FirebaseFirestore.instance.collection('posts');

  @override
  Future <void> CreatePost(Post post) async{
    try{
      await postsCollection.doc().set(post.toJson());
    }catch(e){
      throw Exception("Error creating post: $e");
    }
  }

  @override
  Future <void> deletePost(String postId) async{
   
    await postsCollection.doc(postId).delete();
   
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
  Future <List<Post>> fetechPostsByUserId(String UserId) async{
    try{
      // fetch posts snapshot with this uid
      final postsSnapshot =
      await postsCollection.where('userId', isEqualTo: UserId).get();

      // convert firestore documents from json --> list of posts
      final userPosts = postsSnapshot.docs
      .map((doc) => Post.fromJson(doc.data() as Map<String, dynamic>))
      .toList();

      return userPosts;
    }catch(e){
      throw Exception("Error fetching posts by user: $e");
    }
  }
}