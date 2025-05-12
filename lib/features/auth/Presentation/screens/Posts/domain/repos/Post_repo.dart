import 'package:talkifyapp/features/auth/Presentation/screens/Posts/Posts.dart';

abstract class PostRepo {
  Future <List<Post>> fetechAllPosts();
  Future <void> CreatePost(Post post);
  Future <void> deletePost(String postId);
  // fetching posts foe a specific user 
  Future <List<Post>> fetechPostsByUserId(String UserId);

}