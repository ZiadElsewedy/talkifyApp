import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:talkifyapp/features/Posts/domain/Entite/Comments.dart';

class Post{
  final String id;
  final String UserId;
  final String UserName;
  final String UserProfilePic;
  final String Text;
  final String imageUrl;
  final DateTime timestamp;
  final List<String> likes; // store user id who liked the post
  final List<Comments> comments;
  Post({
    required this.id,
    required this.UserId,
    required this.UserName,
    required this.UserProfilePic,
    required this.Text,
    required this.imageUrl,
    required this.timestamp,
    required this.likes,
    required this.comments,
  });

  // if u need change anything in this post
  Post copyWith({String? imageUrl}){
    return Post(
      id: id,
      UserId: UserId,
      UserName: UserName,
      UserProfilePic: UserProfilePic,
      Text: Text,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp,
      likes: likes,
      comments: comments,
    );
  }

  // convert post --> json
  Map<String, dynamic>toJson(){
    return {
      "id": id,
      "UserId": UserId,
      "name": UserName,
      "UserProfilePic": UserProfilePic,
      "text": Text,
      "imageurl": imageUrl,
      "timestamp": timestamp,
      "likes": likes,
      "comments": comments,
    };
  }


  // convert json --> post
  factory Post.fromJson(Map<String, dynamic> json){

    final List<Comments> comments = (json['comments'] as List).map((json) => Comments.fromJson(json)).toList();
    return Post(  
      id: json["id"], 
      UserId: json["UserId"],
      UserName: json["name"],
      UserProfilePic: json["UserProfilePic"] ?? '',
      Text: json["text"],
      imageUrl: json["imageurl"],
      timestamp: (json["timestamp"] as Timestamp).toDate(),
      likes: List<String>.from(json["likes"] ?? []),
      comments: comments,
    );
  }
}