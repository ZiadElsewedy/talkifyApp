import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:talkifyapp/features/Chat/domain/repo/chat_repo.dart';
import 'package:talkifyapp/features/Chat/domain/entite/chat_room.dart';
import 'package:talkifyapp/features/Chat/domain/entite/message.dart';
import 'package:flutter/foundation.dart';

class FirebaseChatRepo implements ChatRepo {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collections
  static const String _chatRoomsCollection = 'chatRooms';
  static const String _messagesCollection = 'messages';
  static const String _typingCollection = 'typing';

  // Stream controller for upload progress
  final _uploadProgressController = StreamController<double>.broadcast();
  
  @override
  Stream<double> get uploadProgressStream => _uploadProgressController.stream;

  @override
  Future<ChatRoom> createChatRoom({
    required List<String> participantIds,
    required Map<String, String> participantNames,
    required Map<String, String> participantAvatars,
    List<String>? adminIds,
    Map<String, int>? unreadCount,
    String? communityId,
  }) async {
    try {
      print('DEBUG: FirebaseChatRepo: Creating chat room with communityId: $communityId');
      
      // Initialize unread count if not provided
      final Map<String, int> initialUnreadCount = unreadCount ?? {};
      
      // Ensure all participants have an unread count entry
      for (final userId in participantIds) {
        if (!initialUnreadCount.containsKey(userId)) {
          initialUnreadCount[userId] = 0;
        }
      }
      
      // Create a new chat room document
      final chatRoomRef = _firestore.collection('chatRooms').doc();
      final chatRoomId = chatRoomRef.id;
      
      print('DEBUG: FirebaseChatRepo: Generated new chat room ID: $chatRoomId');
      
      // Initialize left participants map
      final Map<String, bool> leftParticipants = {};
      
      // Create chat room object with communityId included directly in constructor
      final chatRoom = ChatRoom(
        id: chatRoomId,
        participants: participantIds,
        participantNames: participantNames,
        participantAvatars: participantAvatars,
        unreadCount: initialUnreadCount,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        admins: adminIds ?? [],
        leftParticipants: leftParticipants,
        communityId: communityId, // Pass directly to constructor
      );
      
      // Convert to JSON
      final chatRoomData = chatRoom.toJson();
      
      // IMPORTANT: Double-check that communityId is in the data
      if (communityId != null && !chatRoomData.containsKey('communityId')) {
        print('DEBUG: WARNING: communityId missing from chatRoomData, adding it explicitly');
        chatRoomData['communityId'] = communityId;
      }
      
      print('DEBUG: FirebaseChatRepo: Saving chat room data to Firestore with fields: ${chatRoomData.keys.toList()}');
      
      // Store the chat room in Firestore
      await chatRoomRef.set(chatRoomData);
      
      // Verify the chat room was created properly with communityId
      final verificationDoc = await chatRoomRef.get();
      if (verificationDoc.exists) {
        final data = verificationDoc.data();
        if (communityId != null && data?['communityId'] != communityId) {
          print('DEBUG: ERROR: communityId not saved correctly. Attempting fix...');
          await chatRoomRef.update({'communityId': communityId});
        }
      }
      
      // Create a system message
      String systemMessage;
      if (communityId != null) {
        systemMessage = "Community chat created";
      } else if (participantIds.length > 2) {
        systemMessage = "Group chat created";
      } else {
        systemMessage = "Chat started";
      }
      
      await sendSystemMessage(
        chatRoomId: chatRoomId,
        content: systemMessage,
      );
      
      print('DEBUG: FirebaseChatRepo: Chat room created successfully');
      
      // Return the chat room with guaranteed communityId
      return chatRoom.copyWith(communityId: communityId);
    } catch (e) {
      print("DEBUG: Error creating chat room: $e");
      rethrow;
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
      // For 1-on-1 chats, find exact matches
      if (userIds.length == 2) {
        final snapshot = await _firestore
            .collection(_chatRoomsCollection)
            .where('participants', arrayContainsAny: userIds)
            .get();
        
        // Find the chat room where participants are exactly these users
        for (var doc in snapshot.docs) {
          final chatRoom = ChatRoom.fromJson(doc.data());
          final participants = chatRoom.participants;
          
          // Check if this chat room contains exactly the two users
          if (participants.length == 2 && 
              participants.contains(userIds[0]) && 
              participants.contains(userIds[1])) {
            
            // Check if any of the users has deleted this chat
            final String currentUserId = userIds[0]; // Assuming the first ID is the current user
            if (chatRoom.leftParticipants.containsKey(currentUserId) &&
                chatRoom.leftParticipants[currentUserId] == true) {
              // Current user has previously deleted this chat, don't return it
              continue;
            }
            
            return chatRoom;
          }
        }
      } else {
        // For group chats, we need exact participant matches
        // This is more complex as we need to find a room with exactly these participants
        final snapshot = await _firestore
            .collection(_chatRoomsCollection)
            .where('participants', arrayContains: userIds[0])
            .get();
        
        for (var doc in snapshot.docs) {
          final chatRoom = ChatRoom.fromJson(doc.data());
          final participants = Set.from(chatRoom.participants);
          final targetUsers = Set.from(userIds);
          
          // Check if both sets have exactly the same members
          if (participants.length == targetUsers.length && 
              participants.containsAll(targetUsers)) {
            // Check if current user has deleted this chat
            final String currentUserId = userIds[0]; // Assuming first ID is current user
            if (chatRoom.leftParticipants.containsKey(currentUserId) &&
                chatRoom.leftParticipants[currentUserId] == true) {
              // Current user has deleted this chat, don't return it
              continue;
            }
            
            return chatRoom;
          }
        }
      }
      
      // No matching chat room found
      return null;
    } catch (e) {
      throw Exception('Failed to find chat room between users: $e');
    }
  }

  @override
  Stream<List<ChatRoom>> getUserChatRooms(String userId) {
    return _firestore
        .collection(_chatRoomsCollection)
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      List<ChatRoom> chatRooms = [];
      
      for (var doc in snapshot.docs) {
        try {
          final chatRoom = ChatRoom.fromJson(doc.data());
          
          // Skip this chat room if the user has marked it as left/hidden
          if (chatRoom.leftParticipants.containsKey(userId) && 
              chatRoom.leftParticipants[userId] == true) {
            // User has left or hidden this chat, don't include it
            continue;
          }
          
          chatRooms.add(chatRoom);
        } catch (e) {
          print('Error parsing chat room: $e');
        }
      }
      
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
      final now = DateTime.now();
      
      for (final doc in messagesQuery.docs) {
        batch.update(doc.reference, {
          'status': MessageStatus.read.name,
          'readBy': FieldValue.arrayUnion([userId]),
        });
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
      rethrow;
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
      // First, always get the latest profile picture from users collection
      String updatedAvatar = senderAvatar;
      try {
        final userDoc = await _firestore.collection('users').doc(senderId).get();
        if (userDoc.exists && userDoc.data()!.containsKey('profilePictureUrl')) {
          final profilePicture = userDoc.data()!['profilePictureUrl'] as String?;
          if (profilePicture != null && profilePicture.isNotEmpty) {
            updatedAvatar = profilePicture;
            print("DEBUG: Using updated avatar URL from users collection: $updatedAvatar");
          }
        }
      } catch (e) {
        print("DEBUG: Error fetching user profile: $e - will use provided avatar");
      }
      
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
        senderAvatar: updatedAvatar, // Use the updated avatar
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
        
        // Also update the participant avatar in the chat room
        if (updatedAvatar != senderAvatar) {
          batch.update(chatRoomRef, {
            'participantAvatars.$senderId': updatedAvatar
          });
        }
        
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
    return _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .collection(_messagesCollection)
        .orderBy('timestamp', descending: false)  // Changed to ascending order
        .snapshots()
        .map((snapshot) {
      final messages = snapshot.docs
          .map((doc) => Message.fromJson(doc.data()))
          .toList();
      
      // Messages are already in timestamp order (oldest to newest)
      return messages;
    });
  }

  @override
  Stream<List<Message>> getChatMessagesForUser(String chatRoomId, String userId) {
    // First get the chat room to check if the user has deleted message history
    return _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .snapshots()
        .asyncMap((chatRoomSnapshot) async {
          if (!chatRoomSnapshot.exists) {
            return <Message>[];
          }
          
          final chatRoom = ChatRoom.fromJson(chatRoomSnapshot.data()!);
          DateTime? deletedAt = chatRoom.messageHistoryDeletedAt[userId];
          
          // Get messages, potentially filtered by deletion timestamp
          var query = _firestore
              .collection(_chatRoomsCollection)
              .doc(chatRoomId)
              .collection(_messagesCollection)
              .orderBy('timestamp', descending: false);  // Changed to ascending order
              
          // If user has deleted history, only get messages after that time
          if (deletedAt != null) {
            query = query.where('timestamp', isGreaterThan: deletedAt);
          }
          
          final messagesSnapshot = await query.get();
          
          // Filter out messages marked as deleted for this user
          final messages = messagesSnapshot.docs
              .map((doc) => Message.fromJson(doc.data()))
              .where((message) => !message.deletedForUsers.contains(userId))
              .toList();
          
          // Messages are already in timestamp order (oldest to newest)
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
            // We still need descending order here to get the latest message
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
      final chatRoomDoc = await chatRoomRef.get();
      
      if (!chatRoomDoc.exists) {
        throw Exception('Chat room does not exist');
      }
      
      // Get all messages in the chat room
      final messagesSnapshot = await chatRoomRef.collection(_messagesCollection).get();
      
      // Create a batch for more efficient updates
      final batch = _firestore.batch();
      
      // Delete all associated media files first
      for (final messageDoc in messagesSnapshot.docs) {
        final messageData = messageDoc.data();
        
        // Check if the message has media that needs to be deleted
        if (messageData['fileUrl'] != null && messageData['fileUrl'].toString().isNotEmpty) {
          try {
            // Extract the file path from the URL
            final String fileUrl = messageData['fileUrl'];
            
            // Get the storage reference from the URL
            final ref = _storage.refFromURL(fileUrl);
            
            // Delete the file from storage
            await ref.delete();
            print('Deleted media file: ${ref.fullPath}');
          } catch (storageError) {
            // Continue even if media deletion fails
            print('Warning: Unable to delete media file: $storageError');
          }
        }
        
        // Add message to batch for deletion
        batch.delete(messageDoc.reference);
      }
      
      // Delete any typing indicators
      final typingSnapshot = await chatRoomRef.collection(_typingCollection).get();
      for (final typingDoc in typingSnapshot.docs) {
        batch.delete(typingDoc.reference);
      }
      
      // Delete the chat room document itself
      batch.delete(chatRoomRef);
      
      // Execute the batch
      await batch.commit();
      
      print('Successfully deleted chat room: $chatRoomId');
    } catch (e) {
      print('Error deleting chat room: $e');
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
  Future<String> uploadChatMediaWithProgress({
    required String filePath,
    required String chatRoomId,
    required String fileName,
  }) async {
    try {
      final file = File(filePath);
      final ref = _storage.ref().child('chat_media/$chatRoomId/$fileName');
      
      // Add timestamp to filename to avoid cache issues
      final timestampedFileName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final videoRef = _storage.ref().child('chat_media/$chatRoomId/$timestampedFileName');
      
      final uploadTask = videoRef.putFile(file);
      
      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        _uploadProgressController.add(progress);
      });
      
      // Wait for upload to complete
      final snapshot = await uploadTask;
      
      // Add final 100% progress
      _uploadProgressController.add(1.0);
      
      // Get download URL
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      // Send error progress
      _uploadProgressController.add(0);
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
  Future<Map<String, DateTime>> getMessageReadStatus(String messageId) async {
    try {
      // Find which chat room contains this message
      final chatRoomsSnapshot = await _firestore.collection(_chatRoomsCollection).get();
      
      for (final chatRoomDoc in chatRoomsSnapshot.docs) {
        final chatRoomId = chatRoomDoc.id;
        final messageRef = chatRoomDoc.reference
            .collection(_messagesCollection)
            .doc(messageId);
        
        final messageDoc = await messageRef.get();
        if (messageDoc.exists) {
          final Map<String, dynamic>? messageData = messageDoc.data();
          
          if (messageData != null && messageData.containsKey('readBy')) {
            final Map<String, dynamic> readByData = messageData['readBy'] ?? {};
            Map<String, DateTime> readBy = {};
            
            readByData.forEach((userId, timestampValue) {
              if (timestampValue is Timestamp) {
                readBy[userId] = timestampValue.toDate();
              } else if (timestampValue is String) {
                try {
                  readBy[userId] = DateTime.parse(timestampValue);
                } catch (e) {
                  // Skip invalid timestamp values
                }
              }
            });
            
            return readBy;
          }
          return {};
        }
      }
      
      return {};
    } catch (e) {
      throw Exception('Failed to get message read status: $e');
    }
  }

  @override
  Future<void> markMessageAsRead({
    required String messageId,
    required String userId,
    required DateTime timestamp,
  }) async {
    try {
      // Find which chat room contains this message
      final chatRoomsSnapshot = await _firestore.collection(_chatRoomsCollection).get();
      
      for (final chatRoomDoc in chatRoomsSnapshot.docs) {
        final chatRoomId = chatRoomDoc.id;
        final messageRef = chatRoomDoc.reference
            .collection(_messagesCollection)
            .doc(messageId);
        
        final messageDoc = await messageRef.get();
        if (messageDoc.exists) {
          // Update the message with the read timestamp
          await messageRef.update({
            'readBy.$userId': timestamp,
            'status': MessageStatus.read.name,
          });
          
          return;
        }
      }
    } catch (e) {
      throw Exception('Failed to mark message as read: $e');
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

  @override
  Future<void> leaveGroupChat({
    required String chatRoomId,
    required String userId,
    required String userName,
  }) async {
    try {
      // Get reference to the chat room
      final chatRoomRef = _firestore.collection(_chatRoomsCollection).doc(chatRoomId);
      final chatRoomDoc = await chatRoomRef.get();
      
      if (!chatRoomDoc.exists) {
        throw Exception('Chat room does not exist');
      }
      
      final chatRoom = ChatRoom.fromJson(chatRoomDoc.data()!);
      
      // Verify this is a group chat
      if (chatRoom.participants.length <= 2) {
        throw Exception('Cannot leave a one-on-one chat');
      }
      
      // Prepare all updates
      Map<String, dynamic> updates = {};
      
      // Update the leftParticipants map
      Map<String, bool> leftParticipants = Map<String, bool>.from(chatRoom.leftParticipants);
      leftParticipants[userId] = true;
      updates['leftParticipants'] = leftParticipants;
      
      // If user is an admin and the only admin, assign admin role to oldest member
      List<String> admins = List<String>.from(chatRoom.admins);
      
      if (chatRoom.isUserAdmin(userId) && admins.length == 1) {
        // Find the oldest member who hasn't left
        final remainingParticipants = chatRoom.participants
            .where((id) => id != userId && !(chatRoom.leftParticipants[id] ?? false))
            .toList();
            
        if (remainingParticipants.isNotEmpty) {
          admins.add(remainingParticipants.first);
        }
      }
      
      // Remove user from admins if they are an admin
      admins.remove(userId);
      updates['admins'] = admins;
      
      // Update the chat room document
      await chatRoomRef.update(updates);
      
      // Send system message about user leaving
      await sendSystemMessage(
        chatRoomId: chatRoomId,
        content: '$userName left the group',
      );
      
      print('User $userId (${userName}) left group chat: $chatRoomId');
    } catch (e) {
      print('Error leaving group chat: $e');
      throw Exception('Failed to leave group chat: $e');
    }
  }
  
  @override
  Future<void> hideChatForUser({
    required String chatRoomId,
    required String userId,
  }) async {
    try {
      // Get reference to the chat room
      final chatRoomRef = _firestore.collection(_chatRoomsCollection).doc(chatRoomId);
      final chatRoomDoc = await chatRoomRef.get();
      
      if (!chatRoomDoc.exists) {
        throw Exception('Chat room does not exist');
      }
      
      // For one-on-one chats, we mark as hidden differently than group chats
      final chatRoom = ChatRoom.fromJson(chatRoomDoc.data()!);
      
      // Update the leftParticipants map to mark this chat as hidden for this user
      Map<String, dynamic> updates = {};
      
      // Handle existing leftParticipants field or create it if it doesn't exist
      Map<String, bool> leftParticipants = Map<String, bool>.from(chatRoom.leftParticipants);
      leftParticipants[userId] = true;
      updates['leftParticipants'] = leftParticipants;
      
      // Update the document
      await chatRoomRef.update(updates);
      
      print('Chat hidden successfully for user $userId: $chatRoomId');
    } catch (e) {
      print('Error hiding chat: $e');
      throw Exception('Failed to hide chat for user: $e');
    }
  }
  
  @override
  Future<void> hideChatAndDeleteHistoryForUser({
    required String chatRoomId,
    required String userId,
  }) async {
    try {
      // Get reference to the chat room
      final chatRoomRef = _firestore.collection(_chatRoomsCollection).doc(chatRoomId);
      final chatRoomDoc = await chatRoomRef.get();
      
      if (!chatRoomDoc.exists) {
        throw Exception('Chat room does not exist');
      }
      
      final chatRoom = ChatRoom.fromJson(chatRoomDoc.data()!);
      
      // Create a batch for more efficient updates
      final batch = _firestore.batch();
      
      // 1. Mark all existing messages as deleted for this user
      final messagesSnapshot = await chatRoomRef.collection(_messagesCollection).get();
      for (final messageDoc in messagesSnapshot.docs) {
        final message = Message.fromJson(messageDoc.data());
        if (!message.deletedForUsers.contains(userId)) {
          List<String> updatedDeletedForUsers = List.from(message.deletedForUsers)..add(userId);
          batch.update(messageDoc.reference, {
            'deletedForUsers': updatedDeletedForUsers,
          });
        }
      }
      
      // 2. Update the chat room document to mark it as hidden and record message history deletion time
      Map<String, bool> leftParticipants = Map<String, bool>.from(chatRoom.leftParticipants);
      leftParticipants[userId] = true;
      
      Map<String, dynamic> messageHistoryDeletedAt = {};
      chatRoom.messageHistoryDeletedAt.forEach((key, value) {
        messageHistoryDeletedAt[key] = value;
      });
      messageHistoryDeletedAt[userId] = FieldValue.serverTimestamp();
      
      batch.update(chatRoomRef, {
        'leftParticipants': leftParticipants,
        'messageHistoryDeletedAt': messageHistoryDeletedAt,
      });
      
      // Execute the batch
      await batch.commit();
      
      print('Chat hidden and history deleted for user $userId: $chatRoomId');
    } catch (e) {
      print('Error hiding chat and deleting history: $e');
      throw Exception('Failed to hide chat and delete history for user: $e');
    }
  }

  @override
  Future<void> addGroupChatAdmin({
    required String chatRoomId,
    required String userId,
  }) async {
    try {
      final chatRoomRef = _firestore.collection(_chatRoomsCollection).doc(chatRoomId);
      final chatRoomDoc = await chatRoomRef.get();
      
      if (!chatRoomDoc.exists) {
        throw Exception('Chat room does not exist');
      }
      
      final chatRoom = ChatRoom.fromJson(chatRoomDoc.data()!);
      
      // Check if the user is already an admin
      if (chatRoom.admins.contains(userId)) {
        return; // Already an admin, nothing to do
      }
      
      // Add user to admins
      List<String> updatedAdmins = List.from(chatRoom.admins)..add(userId);
      
      await chatRoomRef.update({
        'admins': updatedAdmins,
      });
      
      // Add system message
      final userName = chatRoom.participantNames[userId] ?? 'Someone';
      await sendSystemMessage(
        chatRoomId: chatRoomId,
        content: '$userName is now an admin',
      );
    } catch (e) {
      throw Exception('Failed to add admin: $e');
    }
  }
  
  @override
  Future<void> removeGroupChatAdmin({
    required String chatRoomId,
    required String userId,
  }) async {
    try {
      final chatRoomRef = _firestore.collection(_chatRoomsCollection).doc(chatRoomId);
      final chatRoomDoc = await chatRoomRef.get();
      
      if (!chatRoomDoc.exists) {
        throw Exception('Chat room does not exist');
      }
      
      final chatRoom = ChatRoom.fromJson(chatRoomDoc.data()!);
      
      // Check if the user is not an admin
      if (!chatRoom.admins.contains(userId)) {
        return; // Not an admin, nothing to do
      }
      
      // Make sure there will be at least one admin left
      if (chatRoom.admins.length <= 1) {
        throw Exception('Cannot remove the last admin');
      }
      
      // Remove user from admins
      List<String> updatedAdmins = List.from(chatRoom.admins)..remove(userId);
      
      await chatRoomRef.update({
        'admins': updatedAdmins,
      });
      
      // Add system message
      final userName = chatRoom.participantNames[userId] ?? 'Someone';
      await sendSystemMessage(
        chatRoomId: chatRoomId,
        content: '$userName is no longer an admin',
      );
    } catch (e) {
      throw Exception('Failed to remove admin: $e');
    }
  }
  
  @override
  Future<Message> sendSystemMessage({
    required String chatRoomId,
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final chatRoomRef = _firestore.collection(_chatRoomsCollection).doc(chatRoomId);
      final chatRoomDoc = await chatRoomRef.get();
      
      if (!chatRoomDoc.exists) {
        throw Exception('Chat room does not exist');
      }
      
      // Create a new message document
      final messageRef = chatRoomRef.collection(_messagesCollection).doc();
      final now = DateTime.now();
      
      // Create system message
      final message = Message(
        id: messageRef.id,
        chatRoomId: chatRoomId,
        senderId: 'system',  // Special sender ID for system messages
        senderName: 'System',
        senderAvatar: '',
        content: content,
        timestamp: now,
        type: MessageType.system,
        status: MessageStatus.sent,
        readBy: [],
        metadata: metadata ?? {},
      );
      
      // Save message to Firestore
      await messageRef.set(message.toJson());
      
      // Update chat room's last message
      await chatRoomRef.update({
        'lastMessage': content,
        'lastMessageSenderId': 'system',
        'lastMessageTime': now,
        'updatedAt': now,
      });
      
      return message;
    } catch (e) {
      throw Exception('Failed to send system message: $e');
    }
  }

  // Migration helper method to update old chat rooms
  Future<void> migrateOldChatRooms() async {
    try {
      // Get all chat rooms
      final chatRoomsSnapshot = await _firestore.collection(_chatRoomsCollection).get();
      
      final batch = _firestore.batch();
      
      for (final doc in chatRoomsSnapshot.docs) {
        final data = doc.data();
        
        // Check if admins field is missing
        if (!data.containsKey('admins') || data['admins'] == null) {
          // Set the first participant as admin by default
          final List<String> participants = List<String>.from(data['participants'] ?? []);
          final List<String> admins = participants.isNotEmpty ? [participants.first] : [];
          
          batch.update(doc.reference, {
            'admins': admins,
          });
        }
        
        // Check if leftParticipants field is missing
        if (!data.containsKey('leftParticipants') || data['leftParticipants'] == null) {
          batch.update(doc.reference, {
            'leftParticipants': {},
          });
        }
      }
      
      // Commit all updates
      await batch.commit();
      print('Migrated old chat rooms to new format');
    } catch (e) {
      print('Error migrating old chat rooms: $e');
    }
  }

  @override
  Future<void> deleteMessageForUser({
    required String messageId,
    required String userId,
  }) async {
    try {
      // Find the message first
      QuerySnapshot messageQuery = await _firestore
          .collectionGroup(_messagesCollection)
          .where('id', isEqualTo: messageId)
          .limit(1)
          .get();
      
      if (messageQuery.docs.isEmpty) {
        throw Exception('Message not found');
      }
      
      final messageDoc = messageQuery.docs.first;
      final message = Message.fromJson(messageDoc.data() as Map<String, dynamic>);
      
      // Add this user to the deletedForUsers list
      if (!message.deletedForUsers.contains(userId)) {
        List<String> updatedDeletedForUsers = List.from(message.deletedForUsers)..add(userId);
        await messageDoc.reference.update({
          'deletedForUsers': updatedDeletedForUsers,
        });
      }
    } catch (e) {
      throw Exception('Failed to delete message for user: $e');
    }
  }

  @override
  Future<ChatRoom?> getChatRoomForCommunity(String communityId) async {
    try {
      print("DEBUG: FirebaseChatRepo.getChatRoomForCommunity called with ID: $communityId");
      print("DEBUG: Querying Firestore collection 'chatRooms' with filter communityId == $communityId");
      
      final querySnapshot = await _firestore
          .collection('chatRooms')
          .where('communityId', isEqualTo: communityId)
          .limit(1)
          .get();
      
      print("DEBUG: Query completed. Found ${querySnapshot.docs.length} matching documents");
      
      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        print("DEBUG: Document found with ID: ${doc.id}");
        print("DEBUG: Document data: $data");
        
        // Check if communityId is correctly stored in the document
        if (data['communityId'] == null) {
          print("DEBUG: WARNING - communityId is null in the found document");
        } else {
          print("DEBUG: communityId in document: ${data['communityId']}");
        }
        
        return ChatRoom.fromJson(data);
      }
      
      print("DEBUG: No chat room found for community: $communityId");
      return null;
    } catch (e, stackTrace) {
      print("DEBUG: Error getting chat room for community: $e");
      print("DEBUG: Stack trace: $stackTrace");
      rethrow;
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