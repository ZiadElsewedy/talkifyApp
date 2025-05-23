import 'package:talkifyapp/features/Chat/domain/entite/message.dart';
import 'package:talkifyapp/features/Chat/domain/entite/chat_room.dart';

abstract class ChatRepo {
  // Chat Room operations
  Future<ChatRoom> createChatRoom({
    required List<String> participantIds,
    required Map<String, String> participantNames,
    required Map<String, String> participantAvatars,
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
  
  Future<void> updateMessageStatus({
    required String messageId,
    required MessageStatus status,
  });
  
  Future<void> editMessage({
    required String messageId,
    required String newContent,
  });
  
  Future<void> deleteMessage(String messageId);
  
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