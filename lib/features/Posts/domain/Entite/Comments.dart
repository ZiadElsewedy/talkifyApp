import 'package:cloud_firestore/cloud_firestore.dart';

class Comments {
  final String commentId;
  final String content;
  final String postId;
  final String userId;
  final String userName;
  final String profilePicture;
  final DateTime createdAt;

  Comments({
    required this.commentId,
    required this.content,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.profilePicture,
    required this.createdAt,
  });

  //toJson
  Map<String, dynamic> toJson() => {
    'commentId': commentId,
    'content': content,
    'postId': postId,
    'userId': userId,
    'userName': userName,
    'profilePicture': profilePicture,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  //fromJson
  factory Comments.fromJson(Map<String, dynamic> json) => Comments(
    commentId: json['commentId'] as String,
    content: json['content'] as String,
    postId: json['postId'] as String,
    userId: json['userId'] as String,
    userName: json['userName'] as String,
    profilePicture: json['profilePicture'] as String,
    createdAt: (json['createdAt'] as Timestamp).toDate(),
  );
}

