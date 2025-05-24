import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Chat/domain/repo/chat_repo.dart';
import 'package:talkifyapp/features/Chat/domain/entite/chat_room.dart';
import 'package:talkifyapp/features/Chat/domain/entite/message.dart';
import 'package:talkifyapp/features/Chat/persentation/Cubits/chat_states.dart';

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
  }) async {
    emit(ChatLoading());
    try {
      final chatRoom = await chatRepo.createChatRoom(
        participantIds: participantIds,
        participantNames: participantNames,
        participantAvatars: participantAvatars,
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
      await chatRepo.deleteMessage(messageId);
      emit(MessageDeleted(messageId));
    } catch (e) {
      emit(ChatError('Failed to delete message: $e'));
    }
  }

  // Delete chat room
  Future<void> deleteChatRoom(String chatRoomId) async {
    emit(ChatLoading());
    try {
      await chatRepo.deleteChatRoom(chatRoomId);
      emit(ChatRoomDeleted(chatRoomId));
    } catch (e) {
      emit(ChatError('Failed to delete chat room: $e'));
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
} 