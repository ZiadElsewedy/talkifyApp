import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Storage/Domain/Storage_repo.dart';

import 'package:talkifyapp/features/auth/Presentation/screens/Posts/domain/repos/Post_repo.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/Posts/presentation/cubits/post_states.dart';

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

// delete a post 
Future<void> deletePost(String postId) async{
  try{
    await postRepo.deletePost(postId);
  }
  catch(e){
    emit(PostsError("Failed to delete post: $e"));
  }
} 

}