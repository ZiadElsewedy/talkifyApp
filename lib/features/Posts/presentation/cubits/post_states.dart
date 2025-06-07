/*
 Post States 
*/

import 'package:talkifyapp/features/Posts/domain/Entite/Posts.dart';

abstract class PostState {}

// initial 
class PostsInitial extends PostState {}


// loading....
class PostsLoading extends PostState {}


// Uploading state 
class PostsUploading extends PostState {}


// Uploading with progress state
class PostsUploadingProgress extends PostState {
  final double progress;
  final Post post; // The local post being uploaded
  final List<Post> previousPosts; // Keep track of previously loaded posts
  
  PostsUploadingProgress(this.progress, this.post, {this.previousPosts = const []});
}


// error 
class PostsError extends PostState {
  final String message;
  PostsError(this.message);
}

//loaded 
class PostsLoaded extends PostState {
  final List<Post> posts;
  PostsLoaded(this.posts);
}

