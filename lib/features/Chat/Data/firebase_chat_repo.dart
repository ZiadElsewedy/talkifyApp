import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:talkifyapp/features/Chat/domain/repo/chat_repo.dart';
import 'package:talkifyapp/features/Chat/domain/entite/chat_room.dart';
import 'package:talkifyapp/features/Chat/domain/entite/message.dart';

class FirebaseChatRepo implements ChatRepo {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collections
  static const String _chatRoomsCollection = 'chatRooms';
  static const String _messagesCollection = 'messages';
  static const String _typingCollection = 'typing';

  @override
  Future<ChatRoom> createChatRoom({
    required List<String> participantIds,
    required Map<String, String> participantNames,
    required Map<String, String> participantAvatars,
  }) async {
    try {
      // Check if chat room already exists between these users
      // For 1-on-1 chats, we should find existing rooms to avoid duplicates
      // For group chats (with a group name), we should allow creating new ones
      final bool isGroupChat = participantIds.length > 2;
      final bool hasCustomGroupName = participantNames.containsKey('groupName') && 
                                      participantNames['groupName']!.isNotEmpty;
      
      // Only search for existing chat rooms if this is a 1-on-1 chat
      // or if it's a group without a custom name
      if (!isGroupChat || (isGroupChat && !hasCustomGroupName)) {
        final existingChatRoom = await findChatRoomBetweenUsers(participantIds);
        if (existingChatRoom != null) {
          // For 1-on-1 chats, always return the existing chat room
          // For groups without custom names, also return existing chat room
          return existingChatRoom;
        }
      }

      final chatRoomRef = _firestore.collection(_chatRoomsCollection).doc();
      final now = DateTime.now();

      // Initialize unread count for all participants
      Map<String, int> unreadCount = {};
      for (String participantId in participantIds) {
        unreadCount[participantId] = 0;
      }

      final chatRoom = ChatRoom(
        id: chatRoomRef.id,
        participants: participantIds,
        participantNames: participantNames,
        participantAvatars: participantAvatars,
        unreadCount: unreadCount,
        createdAt: now,
        updatedAt: now,
      );

      await chatRoomRef.set(chatRoom.toJson());
      return chatRoom;
    } catch (e) {
      throw Exception('Failed to create chat room: $e');
    }
  }

  @override
  Future<ChatRoom?> getChatRoom(String chatRoomId) async {
    try {
      final doc = await _firestore.collection(_chatRoomsCollection).doc(chatRoomId).get();
      if (!doc.exists) return null;
      
      return ChatRoom.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get chat room: $e');
    }
  }

  @override
  Future<ChatRoom?> findChatRoomBetweenUsers(List<String> userIds) async {
    try {
      final sortedUserIds = List<String>.from(userIds)..sort();
      
      final querySnapshot = await _firestore
          .collection(_chatRoomsCollection)
          .where('participants', arrayContainsAny: sortedUserIds)
          .get();

      for (final doc in querySnapshot.docs) {
        final chatRoom = ChatRoom.fromJson(doc.data());
        final chatParticipants = List<String>.from(chatRoom.participants)..sort();
        
        if (chatParticipants.length == sortedUserIds.length &&
            chatParticipants.every((id) => sortedUserIds.contains(id))) {
          return chatRoom;
        }
      }
      
      return null;
    } catch (e) {
      throw Exception('Failed to find chat room: $e');
    }
  }

  @override
  Stream<List<ChatRoom>> getUserChatRooms(String userId) {
    return _firestore
        .collection(_chatRoomsCollection)
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      final chatRooms = snapshot.docs
          .map((doc) => ChatRoom.fromJson(doc.data()))
          .toList();
      
      // Sort by updatedAt in memory instead of in query to avoid index requirement
      chatRooms.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      return chatRooms;
    });
  }

  @override
  Future<void> updateChatRoomLastMessage({
    required String chatRoomId,
    required String lastMessage,
    required String senderId,
    required DateTime timestamp,
  }) async {
    try {
      await _firestore.collection(_chatRoomsCollection).doc(chatRoomId).update({
        'lastMessage': lastMessage,
        'lastMessageSenderId': senderId,
        'lastMessageTime': timestamp,
        'updatedAt': timestamp,
      });
    } catch (e) {
      throw Exception('Failed to update chat room: $e');
    }
  }

  @override
  Future<void> markMessagesAsRead({
    required String chatRoomId,
    required String userId,
  }) async {
    try {
      // Update unread count in chat room
      await _firestore.collection(_chatRoomsCollection).doc(chatRoomId).update({
        'unreadCount.$userId': 0,
      });

      // Update message status to read for messages not sent by this user
      final messagesQuery = await _firestore
          .collection(_chatRoomsCollection)
          .doc(chatRoomId)
          .collection(_messagesCollection)
          .where('senderId', isNotEqualTo: userId)
          .where('status', whereIn: ['sent', 'delivered'])
          .get();

      final batch = _firestore.batch();
      for (final doc in messagesQuery.docs) {
        batch.update(doc.reference, {'status': MessageStatus.read.name});
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  @override
  Future<Message> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String senderName,
    required String senderAvatar,
    required String content,
    required MessageType type,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final messageRef = _firestore
          .collection(_chatRoomsCollection)
          .doc(chatRoomId)
          .collection(_messagesCollection)
          .doc();
      
      final now = DateTime.now();

      final message = Message(
        id: messageRef.id,
        chatRoomId: chatRoomId,
        senderId: senderId,
        senderName: senderName,
        senderAvatar: senderAvatar,
        content: content,
        type: type,
        status: MessageStatus.sent,
        timestamp: now,
        fileUrl: fileUrl,
        fileName: fileName,
        fileSize: fileSize,
        replyToMessageId: replyToMessageId,
        metadata: metadata,
      );

      await messageRef.set(message.toJson());
      
      // Update chat room with last message
      await updateChatRoomLastMessage(
        chatRoomId: chatRoomId,
        lastMessage: type == MessageType.text ? content : '${type.name.capitalize()} message',
        senderId: senderId,
        timestamp: now,
      );

      // Update unread count for other participants
      final chatRoom = await getChatRoom(chatRoomId);
      if (chatRoom != null) {
        final batch = _firestore.batch();
        final chatRoomRef = _firestore.collection(_chatRoomsCollection).doc(chatRoomId);
        
        for (final participantId in chatRoom.participants) {
          if (participantId != senderId) {
            final currentUnread = chatRoom.unreadCount[participantId] ?? 0;
            batch.update(chatRoomRef, {
              'unreadCount.$participantId': currentUnread + 1,
            });
          }
        }
        await batch.commit();
      }

      return message;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  @override
  Stream<List<Message>> getChatMessages(String chatRoomId) {
    print('FCR: Subscribing to messages for chatRoomId: $chatRoomId');
    return _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .collection(_messagesCollection)
        .snapshots()
        .map((snapshot) {
      print('FCR: Received snapshot with ${snapshot.docs.length} docs for chatRoomId: $chatRoomId');
      List<Message> messages = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          final message = Message.fromJson(data);
          messages.add(message);
        } catch (e) {
          print('FCR: Error parsing message doc ${doc.id}: $e');
        }
      }
      // sort by timestamp ascending
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    });
  }

  @override
  Future<void> updateMessageStatus({
    required String messageId,
    required MessageStatus status,
  }) async {
    try {
      // This would require finding the message across all chat rooms
      // For efficiency, we should pass chatRoomId as well
      // For now, implementing a basic version
      
      final chatRoomsSnapshot = await _firestore.collection(_chatRoomsCollection).get();
      
      for (final chatRoomDoc in chatRoomsSnapshot.docs) {
        final messageRef = chatRoomDoc.reference
            .collection(_messagesCollection)
            .doc(messageId);
        
        final messageDoc = await messageRef.get();
        if (messageDoc.exists) {
          await messageRef.update({'status': status.name});
          return;
        }
      }
    } catch (e) {
      throw Exception('Failed to update message status: $e');
    }
  }

  @override
  Future<void> editMessage({
    required String messageId,
    required String newContent,
  }) async {
    try {
      final chatRoomsSnapshot = await _firestore.collection(_chatRoomsCollection).get();
      
      for (final chatRoomDoc in chatRoomsSnapshot.docs) {
        final messageRef = chatRoomDoc.reference
            .collection(_messagesCollection)
            .doc(messageId);
        
        final messageDoc = await messageRef.get();
        if (messageDoc.exists) {
          await messageRef.update({
            'content': newContent,
            'editedAt': DateTime.now(),
          });
          return;
        }
      }
    } catch (e) {
      throw Exception('Failed to edit message: $e');
    }
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    try {
      final chatRoomsSnapshot = await _firestore.collection(_chatRoomsCollection).get();
      
      for (final chatRoomDoc in chatRoomsSnapshot.docs) {
        final chatRoomId = chatRoomDoc.id;
        final messageRef = chatRoomDoc.reference
            .collection(_messagesCollection)
            .doc(messageId);
        
        final messageDoc = await messageRef.get();
        if (messageDoc.exists) {
          final messageData = messageDoc.data();
          
          // Check if there's media to delete
          if (messageData != null && 
              messageData['fileUrl'] != null && 
              messageData['fileUrl'].toString().isNotEmpty) {
            
            try {
              // Extract the file path from the URL
              final String fileUrl = messageData['fileUrl'];
              
              // Get the storage reference from the URL
              final ref = _storage.refFromURL(fileUrl);
              
              // Delete the file from storage
              await ref.delete();
              print('Deleted media file: ${ref.fullPath}');
            } catch (storageError) {
              print('Warning: Unable to delete media file: $storageError');
              // Continue with message deletion even if media deletion fails
            }
          }
          
          // Check if this was the last message in the chat room
          final chatRoom = ChatRoom.fromJson(chatRoomDoc.data());
          final messageTimestamp = messageData != null ? 
              (messageData['timestamp'] is Timestamp ? 
                  (messageData['timestamp'] as Timestamp).toDate() : 
                  DateTime.parse(messageData['timestamp'].toString())) : 
              null;
          
          var isLastMessage = messageTimestamp != null && 
              chatRoom.lastMessageSenderId == messageData!['senderId'];
          
          // For additional verification, also check content if it's a text message
          if (isLastMessage && messageData['type'] == 'text') {
            if (chatRoom.lastMessage != messageData['content']) {
              // If content doesn't match, it's not the last message
              isLastMessage = false;
            }
          }
          
          // Delete the message from Firestore
          await messageRef.delete();
          print('Deleted message: $messageId from chat room: $chatRoomId');
          
          // If this was the last message, update the chat room's last message
          if (isLastMessage) {
            // Get the previous message (now the latest message)
            final latestMessagesQuery = await chatRoomDoc.reference
                .collection(_messagesCollection)
                .orderBy('timestamp', descending: true)
                .limit(1)
                .get();
            
            if (latestMessagesQuery.docs.isNotEmpty) {
              // Found a previous message, update the chat room with this as the last message
              final latestMessage = latestMessagesQuery.docs.first.data();
              await chatRoomDoc.reference.update({
                'lastMessage': latestMessage['type'] == MessageType.text.name 
                    ? latestMessage['content'] 
                    : '${latestMessage['type'].toString().split('.').last.capitalize()} message',
                'lastMessageSenderId': latestMessage['senderId'],
                'lastMessageTime': latestMessage['timestamp'],
              });
            } else {
              // No messages left, clear the last message
              await chatRoomDoc.reference.update({
                'lastMessage': '',
                'lastMessageSenderId': '',
                'lastMessageTime': FieldValue.serverTimestamp(),
              });
            }
          }
          
          return;
        }
      }
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  @override
  Future<void> deleteChatRoom(String chatRoomId) async {
    try {
      // Get reference to the chat room
      final chatRoomRef = _firestore.collection(_chatRoomsCollection).doc(chatRoomId);
      
      // Get all messages in the chat room
      final messagesSnapshot = await chatRoomRef.collection(_messagesCollection).get();
      
      // Use a batch to delete all messages
      final batch = _firestore.batch();
      
      // Add all message deletions to the batch
      for (final messageDoc in messagesSnapshot.docs) {
        batch.delete(messageDoc.reference);
      }
      
      // Delete any typing indicators
      final typingSnapshot = await chatRoomRef.collection(_typingCollection).get();
      for (final typingDoc in typingSnapshot.docs) {
        batch.delete(typingDoc.reference);
      }
      
      // Execute the batch
      await batch.commit();
      
      // Finally, delete the chat room itself
      await chatRoomRef.delete();
    } catch (e) {
      throw Exception('Failed to delete chat room: $e');
    }
  }

  @override
  Future<void> setTypingStatus({
    required String chatRoomId,
    required String userId,
    required bool isTyping,
  }) async {
    try {
      final typingRef = _firestore
          .collection(_chatRoomsCollection)
          .doc(chatRoomId)
          .collection(_typingCollection)
          .doc(userId);

      if (isTyping) {
        await typingRef.set({
          'isTyping': true,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        await typingRef.delete();
      }
    } catch (e) {
      throw Exception('Failed to set typing status: $e');
    }
  }

  @override
  Stream<Map<String, bool>> getTypingStatus(String chatRoomId) {
    return _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .collection(_typingCollection)
        .snapshots()
        .map((snapshot) {
      Map<String, bool> typingStatus = {};
      for (final doc in snapshot.docs) {
        typingStatus[doc.id] = doc.data()['isTyping'] ?? false;
      }
      return typingStatus;
    });
  }

  @override
  Future<String> uploadChatMedia({
    required String filePath,
    required String chatRoomId,
    required String fileName,
  }) async {
    try {
      final file = File(filePath);
      final ref = _storage.ref().child('chat_media/$chatRoomId/$fileName');
      
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload media: $e');
    }
  }

  @override
  Future<int> getUnreadMessageCount({
    required String chatRoomId,
    required String userId,
  }) async {
    try {
      final chatRoom = await getChatRoom(chatRoomId);
      return chatRoom?.unreadCount[userId] ?? 0;
    } catch (e) {
      throw Exception('Failed to get unread message count: $e');
    }
  }

  @override
  Future<List<Message>> searchMessages({
    required String chatRoomId,
    required String query,
  }) async {
    try {
      // Note: Firestore doesn't support full-text search natively
      // This is a basic implementation that searches for exact matches
      final snapshot = await _firestore
          .collection(_chatRoomsCollection)
          .doc(chatRoomId)
          .collection(_messagesCollection)
          .where('content', isGreaterThanOrEqualTo: query)
          .where('content', isLessThan: query + 'z')
          .get();

      return snapshot.docs
          .map((doc) => Message.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to search messages: $e');
    }
  }
}

// Extension to capitalize strings
extension StringCapitalization on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
} 