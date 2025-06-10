import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:talkifyapp/features/Chat/domain/entite/message.dart';
import 'package:talkifyapp/features/Chat/domain/entite/chat_room.dart';
import 'package:talkifyapp/features/Chat/Data/firebase_chat_repo.dart';
import 'package:talkifyapp/features/Chat/service/chat_notification_service.dart';

/// A service that listens for new chat messages and shows notifications
class ChatMessageListener {
  final FirebaseChatRepo _chatRepo = FirebaseChatRepo();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  
  // Keep track of active subscriptions
  final Map<String, StreamSubscription> _messageSubscriptions = {};
  
  // Keep track of currently viewed chat room
  String? _currentChatRoomId;
  
  // BuildContext for showing notifications
  BuildContext? _context;
  
  // Singleton pattern
  static final ChatMessageListener _instance = ChatMessageListener._internal();
  
  factory ChatMessageListener() {
    return _instance;
  }
  
  ChatMessageListener._internal();
  
  /// Initialize the listener with a context
  void initialize(BuildContext context) {
    _context = context;
    
    // Start listening to user's chat rooms
    _startListeningToUserChats();
  }
  
  /// Set the current chat room ID to avoid showing notifications for viewed chat
  void setCurrentChatRoomId(String? chatRoomId) {
    _currentChatRoomId = chatRoomId;
  }
  
  /// Get the current chat room ID
  String? getCurrentChatRoomId() {
    return _currentChatRoomId;
  }
  
  /// Check if the user is currently viewing a specific chat room
  bool isViewingChatRoom(String chatRoomId) {
    return _currentChatRoomId == chatRoomId;
  }
  
  /// Start listening to all user's chat rooms
  void _startListeningToUserChats() {
    if (_currentUserId.isEmpty) return;
    
    // Get all chat rooms for the current user
    FirebaseFirestore.instance
        .collection('chatRooms')
        .where('participants', arrayContains: _currentUserId)
        .snapshots()
        .listen((snapshot) {
      final chatRoomIds = snapshot.docs.map((doc) => doc.id).toList();
      
      // Start listening to each chat room
      for (final chatRoomId in chatRoomIds) {
        _listenToNewMessages(chatRoomId);
      }
      
      // Remove subscriptions for chat rooms that no longer exist
      _messageSubscriptions.keys.toList().forEach((subId) {
        if (!chatRoomIds.contains(subId)) {
          _messageSubscriptions[subId]?.cancel();
          _messageSubscriptions.remove(subId);
        }
      });
    });
  }
  
  /// Listen to new messages in a specific chat room
  void _listenToNewMessages(String chatRoomId) {
    // Skip if already listening to this chat room
    if (_messageSubscriptions.containsKey(chatRoomId)) return;
    
    // Listen to new messages
    final subscription = FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) async {
      // Skip if empty or if the user is already viewing this chat room
      if (snapshot.docs.isEmpty || chatRoomId == _currentChatRoomId) return;
      
      // Get chat room details first to check if user has left
      final chatRoomDoc = await FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(chatRoomId)
          .get();
          
      if (!chatRoomDoc.exists) return;
      
      final chatRoom = ChatRoom.fromJson(chatRoomDoc.data()!);
      
      // Skip if the user has left this chat room
      if (chatRoom.leftParticipants.containsKey(_currentUserId) && 
          chatRoom.leftParticipants[_currentUserId] == true) {
        // User has left this chat, don't show notifications
        return;
      }
      
      final messageData = snapshot.docs.first.data();
      final message = Message.fromJson(messageData);
      
      // Skip if message is from current user or if it's older than 30 seconds
      if (message.senderId == _currentUserId) return;
      
      final now = DateTime.now();
      final messageTime = message.timestamp;
      final difference = now.difference(messageTime).inSeconds;
      
      // Only show notification for recent messages (within last 30 seconds)
      if (difference > 30) return;
      
      if (_context == null) return;
      
      // Show notification
      ChatNotificationService.showChatMessageNotification(
        context: _context!,
        senderName: message.senderName,
        messageText: message.content,
        senderId: message.senderId,
        chatRoomId: chatRoomId,
        senderAvatar: message.senderAvatar,
        chatRoomName: chatRoom.isGroupChat ? _getGroupChatName(chatRoom) : null,
        isGroupChat: chatRoom.isGroupChat,
        chatRoom: chatRoom,
      );
    });
    
    _messageSubscriptions[chatRoomId] = subscription;
  }
  
  /// Get the group chat name from the chat room
  String _getGroupChatName(ChatRoom chatRoom) {
    // Check if there's a dedicated group name
    if (chatRoom.participantNames.containsKey('groupName') && 
        chatRoom.participantNames['groupName']!.isNotEmpty) {
      return chatRoom.participantNames['groupName']!;
    }
    
    // Otherwise return generic group chat name
    return 'Group Chat';
  }
  
  /// Clean up resources
  void dispose() {
    for (final subscription in _messageSubscriptions.values) {
      subscription.cancel();
    }
    _messageSubscriptions.clear();
  }
} 