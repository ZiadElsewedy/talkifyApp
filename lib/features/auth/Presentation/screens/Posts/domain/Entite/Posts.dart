import 'package:cloud_firestore/cloud_firestore.dart';

class Post{
  final String id;
  final String UserId;
  final String UserName;
  final String UserProfilePic;
  final String Text;
  final String imageUrl;
  final DateTime timestamp;
  Post({
    required this.id,
    required this.UserId,
    required this.UserName,
    required this.UserProfilePic,
    required this.Text,
    required this.imageUrl,
    required this.timestamp,
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
    };
  }


  // convert json --> post
  factory Post.fromJson(Map<String, dynamic> json){
    return Post(
      id: json["id"], 
      UserId: json["UserId"],
      UserName: json["name"],
      UserProfilePic: json["UserProfilePic"] ?? '',
      Text: json["text"],
      imageUrl: json["imageurl"],
      timestamp: (json["timestamp"] as Timestamp).toDate(),
    );
  }
}