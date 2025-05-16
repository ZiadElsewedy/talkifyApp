/*
 Post States 
*/

import 'package:talkifyapp/features/auth/Presentation/screens/Posts/domain/Entite/Posts.dart';

abstract class PostState {}

// initial 
class PostsInitial extends PostState {}


// loading....
class PostsLoading extends PostState {}


// Uploading state 
class PostsUploading extends PostState {}


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

