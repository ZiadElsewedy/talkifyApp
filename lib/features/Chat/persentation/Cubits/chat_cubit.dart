import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Chat/domain/repo/chat_repo.dart';
import 'package:talkifyapp/features/Chat/domain/entite/chat_room.dart';
import 'package:talkifyapp/features/Chat/domain/entite/message.dart';
import 'package:talkifyapp/features/Chat/persentation/Cubits/chat_states.dart';
import 'package:talkifyapp/features/Chat/Data/firebase_chat_repo.dart';
import 'package:talkifyapp/features/Chat/Utils/audio_handler.dart';
import 'package:talkifyapp/features/Chat/Utils/message_type_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepo chatRepo;
  StreamSubscription<List<ChatRoom>>? _chatRoomsSubscription;
  StreamSubscription<List<Message>>? _messagesSubscription;
  StreamSubscription<Map<String, bool>>? _typingSubscription;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ChatCubit({required this.chatRepo}) : super(ChatInitial());

  @override
  Future<void> close() {
    _chatRoomsSubscription?.cancel();
    _messagesSubscription?.cancel();
    _typingSubscription?.cancel();
    return super.close();
  }

  // Safe emit method that checks if cubit is closed
  void safeEmit(ChatState state) {
    if (!isClosed) {
      emit(state);
    }
  }

  // Load user's chat rooms
  Future<void> loadUserChatRooms(String userId) async {
    if (isClosed) return;
    safeEmit(ChatRoomsLoading());
    try {
      _chatRoomsSubscription?.cancel();
      _chatRoomsSubscription = chatRepo.getUserChatRooms(userId).listen(
        (chatRooms) {
          if (isClosed) return;
          print('ChatCubit: received ${chatRooms.length} chat rooms for user $userId');
          for (var cr in chatRooms) {
            print('  chatRoom ${cr.id} participants=${cr.participants} lastMessage=${cr.lastMessage}');
          }
          safeEmit(ChatRoomsLoaded(chatRooms));
        },
        onError: (error) {
          if (isClosed) return;
          safeEmit(ChatRoomsError('Failed to load chat rooms: $error'));
        },
      );
    } catch (e) {
      if (isClosed) return;
      safeEmit(ChatRoomsError('Failed to load chat rooms: $e'));
    }
  }

  // Clean up duplicate chat rooms for a user
  Future<void> cleanupDuplicateChatRooms(String userId) async {
    if (isClosed) return;
    try {
      print('ChatCubit: Starting cleanup of duplicate chat rooms for user: $userId');
      await chatRepo.cleanupDuplicateChatRooms(userId);
      print('ChatCubit: Cleanup completed successfully');
      
      // Reload chat rooms after cleanup
      if (!isClosed) {
        await loadUserChatRooms(userId);
      }
    } catch (e) {
      if (isClosed) return;
      print('ChatCubit: Error during cleanup: $e');
      safeEmit(ChatError('Failed to cleanup duplicate chats: $e'));
    }
  }

  // Load messages for a specific chat room
  Future<void> loadMessages(String chatRoomId) async {
    if (isClosed) return;
    emit(MessagesLoading());
    try {
      _messagesSubscription?.cancel();
      _messagesSubscription = chatRepo.getChatMessages(chatRoomId).listen(
        (messages) {
          if (isClosed) return;
          emit(MessagesLoaded(messages));
        },
        onError: (error) {
          if (isClosed) return;
          emit(MessagesError('Failed to load messages: $error'));
        },
      );
    } catch (e) {
      if (isClosed) return;
      emit(MessagesError('Failed to load messages: $e'));
    }
  }

  // Load messages for a specific chat room for a specific user (excludes deleted messages)
  Future<void> loadChatMessagesForUser(String chatRoomId, String userId) async {
    if (isClosed) return;
    emit(MessagesLoading());
    try {
      _messagesSubscription?.cancel();
      _messagesSubscription = chatRepo.getChatMessagesForUser(chatRoomId, userId).listen(
        (messages) {
          if (isClosed) return;
          emit(MessagesLoaded(messages));
        },
        onError: (error) {
          if (isClosed) return;
          emit(MessagesError('Failed to load messages: $error'));
        },
      );
    } catch (e) {
      if (isClosed) return;
      emit(MessagesError('Failed to load messages: $e'));
    }
  }

  // Create a new chat room
  Future<void> createChatRoom({
    required List<String> participantIds,
    required Map<String, String> participantNames,
    required Map<String, String> participantAvatars,
    List<String>? adminIds,
  }) async {
    if (isClosed) return;
    emit(ChatLoading());
    try {
      final chatRoom = await chatRepo.createChatRoom(
        participantIds: participantIds,
        participantNames: participantNames,
        participantAvatars: participantAvatars,
        adminIds: adminIds,
      );
      if (isClosed) return;
      emit(ChatRoomCreated(chatRoom));
    } catch (e) {
      if (isClosed) return;
      emit(ChatError('Failed to create chat room: $e'));
    }
  }

  // Find or create chat room between users
  Future<ChatRoom?> findOrCreateChatRoom({
    required List<String> participantIds,
    required Map<String, String> participantNames,
    required Map<String, String> participantAvatars,
    List<String>? adminIds,
  }) async {
    try {
      final bool isGroupChat = participantIds.length > 2;
      final bool hasCustomGroupName = participantNames.containsKey('groupName') && 
                                     participantNames['groupName']!.isNotEmpty;
      
      // Always try to find existing chat rooms first (except for custom named groups)
      if (!hasCustomGroupName) {
        print('ChatCubit: Looking for existing chat room between users: $participantIds');
        final existingChatRoom = await chatRepo.findChatRoomBetweenUsers(participantIds);
        if (existingChatRoom != null) {
          print('ChatCubit: Found existing chat room: ${existingChatRoom.id}');
          return existingChatRoom;
        }
        print('ChatCubit: No existing chat room found, creating new one');
      }

      // If no existing chat room found, or if it's a group chat with a custom name,
      // create a new one
      final chatRoom = await chatRepo.createChatRoom(
        participantIds: participantIds,
        participantNames: participantNames,
        participantAvatars: participantAvatars,
        adminIds: adminIds,
      );
      print('ChatCubit: Created new chat room: ${chatRoom.id}');
      return chatRoom;
    } catch (e) {
      print('ChatCubit: Error in findOrCreateChatRoom: $e');
      if (!isClosed) {
        emit(ChatError('Failed to find or create chat room: $e'));
      }
      return null;
    }
  }

  // Send a message
  Future<void> sendMessage({
    required ChatRoom chatRoom,
    required String content,
    required String senderId,
    required String senderName,
    required MessageType type,
    String? fileUrl,
    String? fileName,
    String? replyToMessageId,
  }) async {
    if (isClosed) return;
    try {
      // Get current messages if any
      List<Message> currentMessages = [];
      if (state is MessagesLoaded) {
        currentMessages = (state as MessagesLoaded).messages;
      }
      
      // Update UI immediately with temp message
      emit(MessageSending(currentMessages));
      
      // Send the message
      await chatRepo.sendMessage(
        chatRoomId: chatRoom.id,
        senderId: senderId,
        senderName: senderName,
        senderAvatar: chatRoom.participantAvatars[senderId] ?? '',
        content: content,
        type: type,
        fileUrl: fileUrl,
        fileName: fileName,
        replyToMessageId: replyToMessageId,
      );
      
      // The real-time listener will update the UI with the actual message
    } catch (e) {
      if (isClosed) return;
      emit(SendMessageError('Failed to send message: $e'));
    }
  }

  // Send a media message
  Future<void> sendMediaMessage({
    required String chatRoomId,
    required String senderId,
    required String senderName,
    required String senderAvatar,
    required String filePath,
    required String fileName,
    required MessageType type,
    String? content,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  }) async {
    if (isClosed) return;
    emit(UploadingMedia());
    
    // Generate a temporary message ID to track this upload
    final temporaryMessageId = DateTime.now().millisecondsSinceEpoch.toString();
    
    try {
      // Check if we need to determine the file type based on extension
      MessageType finalType = type;
      if ((type == MessageType.file || type == MessageType.document) && fileName.contains('.')) {
        final extension = fileName.split('.').last.toLowerCase();
        finalType = MessageTypeHelper.getTypeFromFileExtension(extension);
        
        // Force document type for PDFs and documents
        if (extension == 'pdf' || 
            extension == 'doc' || 
            extension == 'docx' || 
            extension == 'txt' || 
            extension == 'ppt' || 
            extension == 'pptx' || 
            extension == 'xls' || 
            extension == 'xlsx') {
          finalType = MessageType.document;
        }
        
        // Update metadata with file type info
        metadata ??= {};
        metadata['fileExtension'] = extension;
          metadata['documentType'] = MessageTypeHelper.getFileIconName(finalType, extension);
      }

      // If the file path is already a URL (starting with http/https), don't upload again
      String fileUrl;
      if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
        fileUrl = filePath;
        safeEmit(MediaUploaded(fileUrl, fileName, temporaryMessageId));
      } else {
        // For video files specifically, show progress during upload
        if (finalType == MessageType.video) {
          // Set up a listener for upload progress
          final progressSubscription = chatRepo.uploadProgressStream.listen((progress) {
            safeEmit(UploadingMediaProgress(
              progress: progress,
              localFilePath: filePath,
              messageId: temporaryMessageId,
              type: finalType,
              isFromCurrentUser: true,
              caption: content,
            ));
          });
          
          try {
            // Upload media with progress tracking
            fileUrl = await chatRepo.uploadChatMediaWithProgress(
              filePath: filePath,
              chatRoomId: chatRoomId,
              fileName: fileName,
            );
            
            // Cancel the progress subscription
            await progressSubscription.cancel();
            
            // Emit final success state
            safeEmit(MediaUploaded(fileUrl, fileName, temporaryMessageId));
          } catch (e) {
            await progressSubscription.cancel();
            throw e;
          }
        } else {
          // For non-video files, use the original upload method
          fileUrl = await chatRepo.uploadChatMedia(
            filePath: filePath,
            chatRoomId: chatRoomId,
            fileName: fileName,
          );
          safeEmit(MediaUploaded(fileUrl, fileName, temporaryMessageId));
        }
      }

      // Then send message with media URL
      if (isClosed) return;
      safeEmit(SendingMessage());
      final message = await chatRepo.sendMessage(
        chatRoomId: chatRoomId,
        senderId: senderId,
        senderName: senderName,
        senderAvatar: senderAvatar,
        content: content ?? fileName,
        type: finalType,
        fileUrl: fileUrl,
        fileName: fileName,
        fileSize: metadata?['fileSize'],
        replyToMessageId: replyToMessageId,
        metadata: metadata,
      );
      print('ChatCubit: Message sent: ${message.id}');  
      safeEmit(MessageSent([message]));
    } catch (e) {
      safeEmit(MediaUploadError('Failed to send media: $e', temporaryMessageId, filePath));
    }
  }

  // Send a message with an existing media URL (for sharing content)
  Future<void> sendMediaUrlMessage({
    required String chatRoomId,
    required String senderId,
    required String senderName,
    required String senderAvatar,
    required String mediaUrl,
    required String displayName,
    required MessageType type,
    required String content,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  }) async {
    if (isClosed) return;
    safeEmit(SendingMessage());
    try {
      final message = await chatRepo.sendMessage(
        chatRoomId: chatRoomId,
        senderId: senderId,
        senderName: senderName,
        senderAvatar: senderAvatar,
        content: content,
        type: type,
        fileUrl: mediaUrl,
        fileName: displayName,
        replyToMessageId: replyToMessageId,
        metadata: metadata,
      );
      print('ChatCubit: Media URL message sent: ${message.id}');
      safeEmit(MessageSent([message]));
    } catch (e) {
      safeEmit(SendMessageError('Failed to send media message: $e'));
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead({
    required String chatRoomId,
    required String userId,
  }) async {
    try {
      await chatRepo.markMessagesAsRead(
        chatRoomId: chatRoomId,
        userId: userId,
      );
      emit(MessagesMarkedAsRead(chatRoomId));
    } catch (e) {
      emit(ChatError('Failed to mark messages as read: $e'));
    }
  }

  // Set typing status
  Future<void> setTypingStatus({
    required String chatRoomId,
    required String userId,
    required bool isTyping,
  }) async {
    try {
      await chatRepo.setTypingStatus(
        chatRoomId: chatRoomId,
        userId: userId,
        isTyping: isTyping,
      );
    } catch (e) {
      // Don't emit error for typing status failures
    }
  }

  // Listen to typing status
  void listenToTypingStatus(String chatRoomId) {
    _typingSubscription?.cancel();
    _typingSubscription = chatRepo.getTypingStatus(chatRoomId).listen(
      (typingStatus) {
        emit(TypingStatusUpdated(chatRoomId, typingStatus));
      },
    );
  }

  // Edit message
  Future<void> editMessage({
    required String messageId,
    required String newContent,
  }) async {
    try {
      await chatRepo.editMessage(
        messageId: messageId,
        newContent: newContent,
      );
      // Note: The message update will be received through the stream
    } catch (e) {
      emit(ChatError('Failed to edit message: $e'));
    }
  }

  // Delete message
  Future<void> deleteMessage(String messageId) async {
    try {
      // Delete the message from the repository first
      await chatRepo.deleteMessage(messageId);
      
      // Get current messages
      List<Message> currentMessages = [];
      if (state is MessagesLoaded) {
        currentMessages = List.from((state as MessagesLoaded).messages)
          ..removeWhere((m) => m.id == messageId);
      }
      
      // Emit the updated message list with the deleted message removed
      emit(MessageDeleted(currentMessages));
      
      // Always emit MessagesLoaded state after deletion to ensure UI consistency
      // This will handle both empty and non-empty lists properly
      emit(MessagesLoaded(currentMessages));
      
      // Get the audio handler and clean up after message deletion is complete
      // Use microtask to ensure this happens after the current execution
      Future.microtask(() {
        final audioHandler = AudioHandler();
        audioHandler.handleVoiceNoteDeleted(messageId);
      });
    } catch (e) {
      emit(ChatError('Failed to delete message: $e'));
    }
  }

  // Delete chat room
  Future<void> deleteChatRoom(String chatRoomId) async {
    if (isClosed) return; // Don't proceed if cubit is closed
    
    // Emit deleting state to show progress
    emit(DeletingChatRoom(chatRoomId));
    
    try {
      // Get current user ID from auth
      final currentUserId = await _getCurrentUserId();
      if (currentUserId == null) {
        emit(ChatError('Unable to identify current user'));
        return;
      }
      
      // Get the chat room details
      final currentChatRoom = getChatRoomById(chatRoomId);
      
      if (currentChatRoom == null) {
        // If we can't find the chat room locally, try to fetch it from the repository
        try {
          final chatRoom = await chatRepo.getChatRoom(chatRoomId);
          if (chatRoom == null) {
            emit(ChatError('Chat room not found'));
            return;
          }
          
          // Use the fetched chat room for deletion logic
          await _performChatDeletion(chatRoom, currentUserId);
        } catch (e) {
          emit(ChatError('Failed to fetch chat room details: $e'));
        }
        return;
      }
      
      // Perform deletion with the current chat room
      await _performChatDeletion(currentChatRoom, currentUserId);
      
    } catch (e) {
      if (!isClosed) {
        emit(ChatError('Failed to delete chat room: $e'));
      }
    }
  }
  
  // Helper method to perform the actual chat deletion logic
  Future<void> _performChatDeletion(ChatRoom chatRoom, String currentUserId) async {
    try {
      // For community chats, use hideChatForUser instead (communities are handled separately)
      if (chatRoom.isCommunityChat) {
        await chatRepo.hideChatForUser(
          chatRoomId: chatRoom.id,
          userId: currentUserId,
        );
        
        // Emit the hidden chat state after successful hiding
        if (!isClosed) {
          emit(ChatHiddenForUser(chatRoom.id));
        }
      } else {
        // For all other chats (individual and group chats), actually delete the chat room
        // This now supports "Delete group for everyone" functionality
        await chatRepo.deleteChatRoom(chatRoom.id);
        
        // Emit the deleted state after successful deletion
        if (!isClosed) {
          emit(ChatRoomDeleted(chatRoom.id));
        }
      }
    } catch (e) {
      if (!isClosed) {
        // If the error suggests using hideChatForUser, do that instead
        if (e.toString().contains('Use hideChatForUser')) {
          await chatRepo.hideChatForUser(
            chatRoomId: chatRoom.id,
            userId: currentUserId,
          );
          
          if (!isClosed) {
            emit(ChatHiddenForUser(chatRoom.id));
          }
        } else {
          emit(ChatError('Failed to delete chat room: $e'));
        }
      }
    }
  }
  
  // Helper method to get current user ID
  Future<String?> _getCurrentUserId() async {
    try {
      // Try to get from Firebase Auth first
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return user.uid;
      }
      
      // Fallback: Try to get from current state
      if (state is ChatRoomsLoaded) {
        final chatRoomsState = state as ChatRoomsLoaded;
        if (chatRoomsState.chatRooms.isNotEmpty) {
          // Get user ID from the first chat room's participants
          final firstRoom = chatRoomsState.chatRooms.first;
          // Return the first participant as a fallback
          return firstRoom.participants.first;
        }
      }
      
      return null;
    } catch (e) {
      print('Error getting current user ID: $e');
      return null;
    }
  }
  
  // Leave group chat
  Future<void> leaveGroupChat({
    required String chatRoomId,
    required String userId,
    required String userName,
  }) async {
    if (isClosed) return; // Don't proceed if cubit is closed
    
    // Emit deleting state to show progress
    emit(DeletingChatRoom(chatRoomId));
    
    try {
      await chatRepo.leaveGroupChat(
        chatRoomId: chatRoomId,
        userId: userId,
        userName: userName,
      );
      
      // Emit the left group state if cubit is still active
      if (!isClosed) {
        emit(GroupChatLeft(chatRoomId));
      }
    } catch (e) {
      if (!isClosed) {
        emit(ChatError('Failed to leave group chat: $e'));
      }
    }
  }
  
  // Hide chat for user
  Future<void> hideChatForUser({
    required String chatRoomId,
    required String userId,
  }) async {
    if (isClosed) return; // Don't proceed if cubit is closed
    
    // Emit deleting state to show progress
    emit(DeletingChatRoom(chatRoomId));
    
    try {
      await chatRepo.hideChatForUser(
        chatRoomId: chatRoomId,
        userId: userId,
      );
      
      // Emit the hidden chat state
      if (!isClosed) {
        emit(ChatHiddenForUser(chatRoomId));
      }
    } catch (e) {
      if (!isClosed) {
        emit(ChatError('Failed to hide chat: $e'));
      }
    }
  }
  
  // Hide chat and delete message history for user
  Future<void> hideChatAndDeleteHistoryForUser({
    required String chatRoomId,
    required String userId,
  }) async {
    if (isClosed) return; // Don't proceed if cubit is closed
    
    // Emit deleting state to show progress
    emit(DeletingChatRoom(chatRoomId));
    
    try {
      await chatRepo.hideChatAndDeleteHistoryForUser(
        chatRoomId: chatRoomId,
        userId: userId,
      );
      
      // Emit the hidden chat state
      if (!isClosed) {
        emit(ChatHistoryDeletedForUser(chatRoomId));
      }
    } catch (e) {
      if (!isClosed) {
        emit(ChatError('Failed to hide chat and delete history: $e'));
      }
    }
  }
  
  // Delete a message for a specific user
  Future<void> deleteMessageForUser({
    required String messageId,
    required String userId,
  }) async {
    try {
      await chatRepo.deleteMessageForUser(
        messageId: messageId,
        userId: userId,
      );
      emit(MessageDeletedForUser(messageId, userId));
    } catch (e) {
      emit(ChatError('Failed to delete message for user: $e'));
    }
  }
  
  // Add group chat admin
  Future<void> addGroupAdmin({
    required String chatRoomId,
    required String userId,
  }) async {
    try {
      await chatRepo.addGroupChatAdmin(
        chatRoomId: chatRoomId,
        userId: userId,
      );
      emit(GroupAdminAdded(chatRoomId, userId));
    } catch (e) {
      emit(ChatError('Failed to add admin: $e'));
    }
  }
  
  // Remove group chat admin
  Future<void> removeGroupAdmin({
    required String chatRoomId,
    required String userId,
  }) async {
    try {
      await chatRepo.removeGroupChatAdmin(
        chatRoomId: chatRoomId,
        userId: userId,
      );
      emit(GroupAdminRemoved(chatRoomId, userId));
    } catch (e) {
      emit(ChatError('Failed to remove admin: $e'));
    }
  }
  
  // Send system message
  Future<void> sendSystemMessage({
    required String chatRoomId,
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await chatRepo.sendSystemMessage(
        chatRoomId: chatRoomId,
        content: content,
        metadata: metadata,
      );
      // System message will be received through the stream
    } catch (e) {
      emit(ChatError('Failed to send system message: $e'));
    }
  }

  // Search messages
  Future<void> searchMessages({
    required String chatRoomId,
    required String query,
  }) async {
    emit(SearchingMessages());
    try {
      final searchResults = await chatRepo.searchMessages(
        chatRoomId: chatRoomId,
        query: query,
      );
      emit(MessagesSearchResult(searchResults, query));
    } catch (e) {
      emit(MessageSearchError('Failed to search messages: $e'));
    }
  }

  // Get unread message count
  Future<int> getUnreadMessageCount({
    required String chatRoomId,
    required String userId,
  }) async {
    try {
      return await chatRepo.getUnreadMessageCount(
        chatRoomId: chatRoomId,
        userId: userId,
      );
    } catch (e) {
      return 0;
    }
  }

  // Update message status
  Future<void> updateMessageStatus({
    required String messageId,
    required MessageStatus status,
  }) async {
    try {
      await chatRepo.updateMessageStatus(
        messageId: messageId,
        status: status,
      );
    } catch (e) {
      // Don't emit error for status update failures
    }
  }

  // Initialize chat functionality and perform migrations if needed
  Future<void> initialize() async {
    try {
      // Cast to FirebaseChatRepo to access migration method
      if (chatRepo is FirebaseChatRepo) {
        await (chatRepo as FirebaseChatRepo).migrateOldChatRooms();
      }
    } catch (e) {
      print('Error initializing chat: $e');
    }
  }

  // Get a specific chat room by ID
  ChatRoom? getChatRoomById(String chatRoomId) {
    if (state is ChatRoomsLoaded) {
      final chatRoomsState = state as ChatRoomsLoaded;
      try {
        return chatRoomsState.chatRooms.firstWhere(
          (room) => room.id == chatRoomId,
        );
      } catch (e) {
        // If no matching chat room is found, return null
        return null;
      }
    }
    return null;
  }

  // Community chat methods
  Future<void> getChatRoomForCommunity(String communityId) async {
    print("DEBUG: ChatCubit.getChatRoomForCommunity called with ID: $communityId");
    emit(ChatRoomForCommunityLoading());
    try {
      print("DEBUG: Calling chatRepo.getChatRoomForCommunity");
      final chatRoom = await chatRepo.getChatRoomForCommunity(communityId);
      print("DEBUG: Result from chatRepo.getChatRoomForCommunity: ${chatRoom != null ? 'Found' : 'Not Found'}");
      
      if (chatRoom != null) {
        print("DEBUG: Chat room found, ID: ${chatRoom.id}, participants: ${chatRoom.participants.length}");
        emit(ChatRoomForCommunityLoaded(chatRoom));
      } else {
        print("DEBUG: Chat room not found for community: $communityId");
        emit(ChatRoomForCommunityNotFound(communityId));
      }
    } catch (e, stackTrace) {
      print("DEBUG: Error in getChatRoomForCommunity: $e");
      print("DEBUG: Stack trace: $stackTrace");
      emit(ChatRoomForCommunityError('Failed to load community chat: $e'));
    }
  }

  Future<void> createGroupChatRoom({
    required List<String> participants,
    required Map<String, String> participantNames,
    required Map<String, String> participantAvatars,
    required Map<String, int> unreadCount,
    required String groupName,
    String? communityId,
  }) async {
    emit(ChatRoomCreating());
    try {
      print('Starting chat room creation process for community: $communityId');
      print('Participants: $participants');
      
      // Add groupName to the participant names map
      participantNames['groupName'] = groupName;
      
      // Create admin list with the first participant as admin
      final List<String> admins = [participants.first];
      
      // Create chat room
      final chatRoom = await chatRepo.createChatRoom(
        participantIds: participants,
        participantNames: participantNames,
        participantAvatars: participantAvatars,
        adminIds: admins,
        unreadCount: unreadCount,
        communityId: communityId,
      );
      
      print('Chat room created successfully: ${chatRoom.id}');
      emit(ChatRoomCreated(chatRoom));
    } catch (e, stackTrace) {
      print('Error creating group chat room: $e');
      print('Stack trace: $stackTrace');
      emit(ChatRoomCreationError('Failed to create group: $e'));
    }
  }

  // Update chat room metadata (e.g., group name)
  Future<void> updateChatRoomMetadata({
    required String chatRoomId,
    required Map<String, dynamic> metadata,
  }) async {
    if (isClosed) return; // Don't proceed if cubit is closed
    
    try {
      // Get the current chat room
      final chatRoomRef = _firestore.collection('chatRooms').doc(chatRoomId);
      final chatRoomDoc = await chatRoomRef.get();
      
      if (!chatRoomDoc.exists) {
        throw Exception('Chat room does not exist');
      }
      
      // Prepare updates - focus on updating the participantNames map
      Map<String, dynamic> updates = {};
      
      // Handle updating group name
      if (metadata.containsKey('groupName')) {
        final String groupName = metadata['groupName'];
        
        // Update in participantNames map
        updates['participantNames.groupName'] = groupName;
        
        // Also update the lastUpdated timestamp
        updates['updatedAt'] = FieldValue.serverTimestamp();
        
        // Apply the updates
        await chatRoomRef.update(updates);
        
        // Notify all users with a system message
        await chatRepo.sendSystemMessage(
          chatRoomId: chatRoomId,
          content: 'Group name changed to "$groupName"',
        );
      }
      
      // Emit a success state
      if (!isClosed) {
        emit(ChatRoomUpdated(chatRoomId));
      }
    } catch (e) {
      if (!isClosed) {
        emit(ChatError('Failed to update chat room: $e'));
      }
    }
  }
} 