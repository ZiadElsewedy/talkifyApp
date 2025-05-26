import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Chat/domain/repo/chat_repo.dart';
import 'package:talkifyapp/features/Chat/domain/entite/chat_room.dart';
import 'package:talkifyapp/features/Chat/domain/entite/message.dart';
import 'package:talkifyapp/features/Chat/persentation/Cubits/chat_states.dart';
import 'package:talkifyapp/features/Chat/Data/firebase_chat_repo.dart';
import 'package:talkifyapp/features/Chat/Utils/audio_handler.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepo chatRepo;
  StreamSubscription<List<ChatRoom>>? _chatRoomsSubscription;
  StreamSubscription<List<Message>>? _messagesSubscription;
  StreamSubscription<Map<String, bool>>? _typingSubscription;

  ChatCubit({required this.chatRepo}) : super(ChatInitial());

  @override
  Future<void> close() {
    _chatRoomsSubscription?.cancel();
    _messagesSubscription?.cancel();
    _typingSubscription?.cancel();
    return super.close();
  }

  // Load user's chat rooms
  Future<void> loadUserChatRooms(String userId) async {
    emit(ChatRoomsLoading());
    try {
      _chatRoomsSubscription?.cancel();
      _chatRoomsSubscription = chatRepo.getUserChatRooms(userId).listen(
        (chatRooms) {
          print('ChatCubit: received ${chatRooms.length} chat rooms for user $userId');
          for (var cr in chatRooms) {
            print('  chatRoom ${cr.id} participants=${cr.participants} lastMessage=${cr.lastMessage}');
          }
          emit(ChatRoomsLoaded(chatRooms));
        },
        onError: (error) {
          emit(ChatRoomsError('Failed to load chat rooms: $error'));
        },
      );
    } catch (e) {
      emit(ChatRoomsError('Failed to load chat rooms: $e'));
    }
  }

  // Load messages for a specific chat room
  Future<void> loadChatMessages(String chatRoomId) async {
    emit(MessagesLoading());
    try {
      _messagesSubscription?.cancel();
      _messagesSubscription = chatRepo.getChatMessages(chatRoomId).listen(
        (messages) {
          emit(MessagesLoaded(messages, chatRoomId));
        },
        onError: (error) {
          emit(MessagesError('Failed to load messages: $error'));
        },
      );
    } catch (e) {
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
    emit(ChatLoading());
    try {
      final chatRoom = await chatRepo.createChatRoom(
        participantIds: participantIds,
        participantNames: participantNames,
        participantAvatars: participantAvatars,
        adminIds: adminIds,
      );
      emit(ChatRoomCreated(chatRoom));
    } catch (e) {
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
      
      // For 1-on-1 chats or group chats without custom names, try to find existing ones
      if (!isGroupChat || (isGroupChat && !hasCustomGroupName)) {
        final existingChatRoom = await chatRepo.findChatRoomBetweenUsers(participantIds);
        if (existingChatRoom != null) {
          return existingChatRoom;
        }
      }

      // If no existing chat room found, or if it's a group chat with a custom name,
      // create a new one
      final chatRoom = await chatRepo.createChatRoom(
        participantIds: participantIds,
        participantNames: participantNames,
        participantAvatars: participantAvatars,
        adminIds: adminIds,
      );
      return chatRoom;
    } catch (e) {
      emit(ChatError('Failed to find or create chat room: $e'));
      return null;
    }
  }

  // Send a text message
  Future<void> sendTextMessage({
    required String chatRoomId,
    required String senderId,
    required String senderName,
    required String senderAvatar,
    required String content,
    String? replyToMessageId,
  }) async {
    emit(SendingMessage());
    try {
      final message = await chatRepo.sendMessage(
        chatRoomId: chatRoomId,
        senderId: senderId,
        senderName: senderName,
        senderAvatar: senderAvatar,
        content: content,
        type: MessageType.text,
        replyToMessageId: replyToMessageId,
      );
      emit(MessageSent(message));
    } catch (e) {
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
    emit(UploadingMedia());
    try {
      // Upload media first
      final fileUrl = await chatRepo.uploadChatMedia(
        filePath: filePath,
        chatRoomId: chatRoomId,
        fileName: fileName,
      );

      emit(MediaUploaded(fileUrl, fileName));

      // Then send message with media URL
      emit(SendingMessage());
      final message = await chatRepo.sendMessage(
        chatRoomId: chatRoomId,
        senderId: senderId,
        senderName: senderName,
        senderAvatar: senderAvatar,
        content: content ?? fileName,
        type: type,
        fileUrl: fileUrl,
        fileName: fileName,
        replyToMessageId: replyToMessageId,
        metadata: metadata,
      );
      print('ChatCubit: Message sent: ${message.id}');  
      emit(MessageSent(message));
    } catch (e) {
      emit(MediaUploadError('Failed to send media: $e'));
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
      emit(MessageDeleted(messageId));
      
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
    emit(ChatLoading());
    try {
      await chatRepo.deleteChatRoom(chatRoomId);
      
      // Emit the deleted state after successful deletion
      emit(ChatRoomDeleted(chatRoomId));
      
      // After a short delay, refresh the chat rooms list
      await Future.delayed(const Duration(milliseconds: 300));
      final currentState = state;
      if (currentState is ChatRoomDeleted) {
        emit(ChatRoomsLoading());
      }
    } catch (e) {
      emit(ChatError('Failed to delete chat room: $e'));
    }
  }
  
  // Leave group chat
  Future<void> leaveGroupChat({
    required String chatRoomId,
    required String userId,
    required String userName,
  }) async {
    emit(ChatLoading());
    try {
      await chatRepo.leaveGroupChat(
        chatRoomId: chatRoomId,
        userId: userId,
        userName: userName,
      );
      
      // Emit the left group state
      emit(GroupChatLeft(chatRoomId));
      
      // After a short delay, refresh the chat rooms list
      await Future.delayed(const Duration(milliseconds: 300));
      final currentState = state;
      if (currentState is GroupChatLeft) {
        emit(ChatRoomsLoading());
      }
    } catch (e) {
      emit(ChatError('Failed to leave group chat: $e'));
    }
  }
  
  // Hide chat for user
  Future<void> hideChatForUser({
    required String chatRoomId,
    required String userId,
  }) async {
    emit(ChatLoading());
    try {
      await chatRepo.hideChatForUser(
        chatRoomId: chatRoomId,
        userId: userId,
      );
      
      // Emit the hidden chat state
      emit(ChatHiddenForUser(chatRoomId));
      
      // After a short delay, refresh the chat rooms list
      await Future.delayed(const Duration(milliseconds: 300));
      final currentState = state;
      if (currentState is ChatHiddenForUser) {
        emit(ChatRoomsLoading());
      }
    } catch (e) {
      emit(ChatError('Failed to hide chat: $e'));
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
} 