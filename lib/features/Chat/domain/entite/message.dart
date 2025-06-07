import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  file,
  audio,
  video,
  document, // Added document type specifically for viewable documents like PDFs
  system, // For system notifications (user joined, left, etc.)
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

class Message {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final DateTime? editedAt;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? replyToMessageId;
  final Map<String, dynamic>? metadata; // For additional data like image dimensions, audio duration, etc.
  final List<String> readBy; // List of user IDs who have read the message
  final List<String> deletedForUsers; // Users who have deleted this message

  Message({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.content,
    required this.type,
    required this.status,
    required this.timestamp,
    this.editedAt,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.replyToMessageId,
    this.metadata,
    List<String>? readBy,
    List<String>? deletedForUsers,
  }) : this.readBy = readBy ?? [],
      this.deletedForUsers = deletedForUsers ?? [];

  // Convert Message to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'content': content,
      'type': type.name,
      'status': status.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'replyToMessageId': replyToMessageId,
      'metadata': metadata,
      'readBy': readBy,
      'deletedForUsers': deletedForUsers,
    };
  }

  // Convert JSON to Message
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      chatRoomId: json['chatRoomId'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      senderAvatar: json['senderAvatar'] as String? ?? '',
      content: json['content'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      editedAt: json['editedAt'] != null 
        ? (json['editedAt'] as Timestamp).toDate() 
        : null,
      fileUrl: json['fileUrl'] as String?,
      fileName: json['fileName'] as String?,
      fileSize: json['fileSize'] as int?,
      replyToMessageId: json['replyToMessageId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      readBy: json['readBy'] != null 
        ? List<String>.from(json['readBy']) 
        : [],
      deletedForUsers: json['deletedForUsers'] != null 
        ? List<String>.from(json['deletedForUsers']) 
        : [],
    );
  }

  // Copy with method for updates
  Message copyWith({
    String? id,
    String? chatRoomId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? timestamp,
    DateTime? editedAt,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
    List<String>? readBy,
    List<String>? deletedForUsers,
  }) {
    return Message(
      id: id ?? this.id,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      editedAt: editedAt ?? this.editedAt,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      metadata: metadata ?? this.metadata,
      readBy: readBy ?? this.readBy,
      deletedForUsers: deletedForUsers ?? this.deletedForUsers,
    );
  }

  // Check if message is from current user
  bool isFromCurrentUser(String currentUserId) {
    return senderId == currentUserId;
  }

  // Check if message has been edited
  bool get isEdited => editedAt != null;

  // Check if message is a reply
  bool get isReply => replyToMessageId != null;

  // Check if message has media content
  bool get hasMedia => type != MessageType.text && type != MessageType.system;
  
  // Check if message is a system message
  bool get isSystemMessage => type == MessageType.system;

  @override
  String toString() {
    return 'Message{id: $id, senderId: $senderId, content: $content, type: $type, status: $status}';
  }
} 