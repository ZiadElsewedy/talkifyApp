import 'package:cloud_firestore/cloud_firestore.dart';

class Reply {
  final String replyId;
  final String content;
  final String userId;
  final String userName;
  final String profilePicture;
  final DateTime createdAt;
  final List<String> likes;

  Reply({
    required this.replyId,
    required this.content,
    required this.userId,
    required this.userName,
    required this.profilePicture,
    required this.createdAt,
    required this.likes,
  });

  Map<String, dynamic> toJson() => {
    'replyId': replyId,
    'content': content,
    'userId': userId,
    'userName': userName,
    'profilePicture': profilePicture,
    'createdAt': Timestamp.fromDate(createdAt),
    'likes': likes,
  };

  factory Reply.fromJson(Map<String, dynamic> json) => Reply(
    replyId: json['replyId'] as String,
    content: json['content'] as String,
    userId: json['userId'] as String,
    userName: json['userName'] as String,
    profilePicture: json['profilePicture'] as String,
    createdAt: (json['createdAt'] as Timestamp).toDate(),
    likes: List<String>.from(json['likes'] ?? []),
  );
}

class Comments {
  final String commentId;
  final String content;
  final String postId;
  final String userId;
  final String userName;
  final String profilePicture;
  final DateTime createdAt;
  final List<String> likes;
  final List<Reply> replies;

  Comments({
    required this.commentId,
    required this.content,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.profilePicture,
    required this.createdAt,
    this.likes = const [],
    this.replies = const [],
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
    'likes': likes,
    'replies': replies.map((reply) => reply.toJson()).toList(),
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
    likes: List<String>.from(json['likes'] ?? []),
    replies: json['replies'] != null 
        ? List<Reply>.from((json['replies'] as List).map((x) => Reply.fromJson(x)))
        : [],
  );
}

