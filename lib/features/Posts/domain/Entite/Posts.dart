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
  final List<String> dislikes; // store user id who disliked the post
  final List<Comments> comments;
  final List<String> savedBy; // store user ids who saved the post
  final int shareCount; // track number of times post was shared
  final bool isVideo; // flag to indicate if the post is a video
  final String? localFilePath; // local file path for upload tracking (not stored in DB)
  
  Post({
    required this.id,
    required this.UserId,
    required this.UserName,
    required this.UserProfilePic,
    required this.Text,
    required this.imageUrl,
    required this.timestamp,
    required this.likes,
    required this.dislikes,
    required this.comments,
    required this.savedBy,
    this.shareCount = 0,
    this.isVideo = false,
    this.localFilePath,
  });

  // if u need change anything in this post
  Post copyWith({
    String? imageUrl,
    int? shareCount,
    bool? isVideo,
    String? localFilePath,
  }){
    return Post(
      id: id,
      UserId: UserId,
      UserName: UserName,
      UserProfilePic: UserProfilePic,
      Text: Text,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp,
      likes: likes,
      dislikes: dislikes,
      comments: comments,
      savedBy: savedBy,
      shareCount: shareCount ?? this.shareCount,
      isVideo: isVideo ?? this.isVideo,
      localFilePath: localFilePath ?? this.localFilePath,
    );
  }

  // convert post --> json
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "UserId": UserId,
      "name": UserName,
      "UserProfilePic": UserProfilePic,
      "text": Text,
      "imageurl": imageUrl,
      "timestamp": timestamp,
      "likes": likes,
      "dislikes": dislikes,
      "comments": comments.map((comment) => comment.toJson()).toList(),
      "savedBy": savedBy,
      "shareCount": shareCount,
      "isVideo": isVideo,
      // localFilePath is not stored in the database
    };
  }

  // convert json --> post
  factory Post.fromJson(Map<String, dynamic> json) {
    // Handle null comments by providing an empty list
    final List<Comments> comments = (json['comments'] as List<dynamic>?)?.map((commentJson) {
      return Comments.fromJson(commentJson as Map<String, dynamic>);
    }).toList() ?? [];

    return Post(  
      id: json["id"] as String, 
      UserId: json["UserId"] as String,
      UserName: json["name"] as String,
      UserProfilePic: json["UserProfilePic"] as String? ?? '',
      Text: json["text"] as String,
      imageUrl: json["imageurl"] as String? ?? '',
      timestamp: (json["timestamp"] as Timestamp).toDate(),
      likes: List<String>.from(json["likes"] ?? []),
      dislikes: List<String>.from(json["dislikes"] ?? []),
      comments: comments,
      savedBy: List<String>.from(json["savedBy"] ?? []),
      shareCount: json["shareCount"] as int? ?? 0,
      isVideo: json["isVideo"] as bool? ?? false,
      // localFilePath is not stored in the database
    );
  }
}