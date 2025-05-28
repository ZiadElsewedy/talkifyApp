import 'package:talkifyapp/features/Chat/domain/entite/message.dart';
import 'package:talkifyapp/features/Chat/domain/entite/chat_room.dart';

abstract class ChatRepo {
  // Chat Room operations
  Future<ChatRoom> createChatRoom({
    required List<String> participantIds,
    required Map<String, String> participantNames,
    required Map<String, String> participantAvatars,
    List<String>? adminIds,
  });
  
  Future<ChatRoom?> getChatRoom(String chatRoomId);
  
  Future<ChatRoom?> findChatRoomBetweenUsers(List<String> userIds);
  
  Stream<List<ChatRoom>> getUserChatRooms(String userId);
  
  Future<void> updateChatRoomLastMessage({
    required String chatRoomId,
    required String lastMessage,
    required String senderId,
    required DateTime timestamp,
  });
  
  Future<void> markMessagesAsRead({
    required String chatRoomId,
    required String userId,
  });
  
  Future<void> deleteChatRoom(String chatRoomId);
  
  // New methods for group chat management
  Future<void> leaveGroupChat({
    required String chatRoomId,
    required String userId,
    required String userName,
  });
  
  Future<void> addGroupChatAdmin({
    required String chatRoomId,
    required String userId,
  });
  
  Future<void> removeGroupChatAdmin({
    required String chatRoomId, 
    required String userId,
  });
  
  Future<void> hideChatForUser({
    required String chatRoomId,
    required String userId,
  });
  
  // New method to hide chat and delete message history for a user
  Future<void> hideChatAndDeleteHistoryForUser({
    required String chatRoomId,
    required String userId,
  });
  
  Future<Message> sendSystemMessage({
    required String chatRoomId,
    required String content,
    Map<String, dynamic>? metadata,
  });
  
  // Message operations
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
  });
  
  Stream<List<Message>> getChatMessages(String chatRoomId);
  
  // New method to get messages excluding those deleted by a specific user
  Stream<List<Message>> getChatMessagesForUser(String chatRoomId, String userId);
  
  Future<void> updateMessageStatus({
    required String messageId,
    required MessageStatus status,
  });
  
  Future<void> editMessage({
    required String messageId,
    required String newContent,
  });
  
  Future<void> deleteMessage(String messageId);
  
  // New method to mark a message as deleted for a specific user
  Future<void> deleteMessageForUser({
    required String messageId,
    required String userId,
  });
  
  // Typing indicator
  Future<void> setTypingStatus({
    required String chatRoomId,
    required String userId,
    required bool isTyping,
  });
  
  Stream<Map<String, bool>> getTypingStatus(String chatRoomId);
  
  // Media upload
  Future<String> uploadChatMedia({
    required String filePath,
    required String chatRoomId,
    required String fileName,
  });
  
  // Unread count
  Future<int> getUnreadMessageCount({
    required String chatRoomId,
    required String userId,
  });
  
  // Search messages
  Future<List<Message>> searchMessages({
    required String chatRoomId,
    required String query,
  });
} 