import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String id;
  final List<String> participants; // List of user IDs
  final Map<String, String> participantNames; // Map of userId -> name
  final Map<String, String> participantAvatars; // Map of userId -> avatar URL
  final String? lastMessage;
  final String? lastMessageSenderId;
  final DateTime? lastMessageTime;
  final Map<String, int> unreadCount; // Map of userId -> unread count
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> admins; // List of admin user IDs
  final Map<String, bool> leftParticipants; // Map of userId -> left status (to track users who left)

  ChatRoom({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.participantAvatars,
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageTime,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
    List<String>? admins,
    Map<String, bool>? leftParticipants,
  }) : this.admins = admins ?? [],
       this.leftParticipants = leftParticipants ?? {};

  // Convert ChatRoom to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participants': participants,
      'participantNames': participantNames,
      'participantAvatars': participantAvatars,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageTime': lastMessageTime,
      'unreadCount': unreadCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'admins': admins,
      'leftParticipants': leftParticipants,
    };
  }

  // Convert JSON to ChatRoom
  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] as String,
      participants: List<String>.from(json['participants'] ?? []),
      participantNames: Map<String, String>.from(json['participantNames'] ?? {}),
      participantAvatars: Map<String, String>.from(json['participantAvatars'] ?? {}),
      lastMessage: json['lastMessage'] as String?,
      lastMessageSenderId: json['lastMessageSenderId'] as String?,
      lastMessageTime: json['lastMessageTime'] != null 
        ? (json['lastMessageTime'] as Timestamp).toDate() 
        : null,
      unreadCount: Map<String, int>.from(json['unreadCount'] ?? {}),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      admins: json['admins'] != null ? List<String>.from(json['admins']) : [],
      leftParticipants: json['leftParticipants'] != null 
        ? Map<String, bool>.from(json['leftParticipants']) 
        : {},
    );
  }

  // Copy with method for updates
  ChatRoom copyWith({
    String? id,
    List<String>? participants,
    Map<String, String>? participantNames,
    Map<String, String>? participantAvatars,
    String? lastMessage,
    String? lastMessageSenderId,
    DateTime? lastMessageTime,
    Map<String, int>? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? admins,
    Map<String, bool>? leftParticipants,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      participantNames: participantNames ?? this.participantNames,
      participantAvatars: participantAvatars ?? this.participantAvatars,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      admins: admins ?? this.admins,
      leftParticipants: leftParticipants ?? this.leftParticipants,
    );
  }

  // Check if a user is an admin
  bool isUserAdmin(String userId) {
    // For backward compatibility with older records
    if (admins.isEmpty) {
      // Default: creator (first participant) is admin
      return participants.isNotEmpty && participants.first == userId;
    }
    return admins.contains(userId);
  }
  
  // Check if this is a group chat (more than 2 participants)
  bool get isGroupChat => participants.length > 2;

  @override
  String toString() {
    return 'ChatRoom{id: $id, participants: $participants, lastMessage: $lastMessage}';
  }
} 