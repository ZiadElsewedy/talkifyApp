import 'package:talkifyapp/features/Chat/domain/entite/message.dart';
import 'package:talkifyapp/features/Chat/domain/entite/chat_room.dart';

// Base Chat State
abstract class ChatState {}

// Initial state
class ChatInitial extends ChatState {}

// Loading states
class ChatLoading extends ChatState {}
class ChatRoomsLoading extends ChatState {}
class MessagesLoading extends ChatState {}
class SendingMessage extends ChatState {}

// Success states
class ChatRoomsLoaded extends ChatState {
  final List<ChatRoom> chatRooms;
  
  ChatRoomsLoaded(this.chatRooms);
}

class MessagesLoaded extends ChatState {
  final List<Message> messages;
  final String chatRoomId;
  
  MessagesLoaded(this.messages, this.chatRoomId);
}

class MessageSent extends ChatState {
  final Message message;
  
  MessageSent(this.message);
}

class ChatRoomCreated extends ChatState {
  final ChatRoom chatRoom;
  
  ChatRoomCreated(this.chatRoom);
}

class ChatRoomDeleted extends ChatState {
  final String chatRoomId;
  
  ChatRoomDeleted(this.chatRoomId);
}

class MessageUpdated extends ChatState {
  final Message message;
  
  MessageUpdated(this.message);
}

class MessageDeleted extends ChatState {
  final String messageId;
  
  MessageDeleted(this.messageId);
}

class MessagesMarkedAsRead extends ChatState {
  final String chatRoomId;
  
  MessagesMarkedAsRead(this.chatRoomId);
}

// Group chat states
class GroupChatLeft extends ChatState {
  final String chatRoomId;
  
  GroupChatLeft(this.chatRoomId);
}

// Hidden chat state
class ChatHiddenForUser extends ChatState {
  final String chatRoomId;
  
  ChatHiddenForUser(this.chatRoomId);
}

// Chat history deleted for user state
class ChatHistoryDeletedForUser extends ChatState {
  final String chatRoomId;
  
  ChatHistoryDeletedForUser(this.chatRoomId);
}

// Message deleted for user state
class MessageDeletedForUser extends ChatState {
  final String messageId;
  final String userId;
  
  MessageDeletedForUser(this.messageId, this.userId);
}

class GroupAdminAdded extends ChatState {
  final String chatRoomId;
  final String userId;
  
  GroupAdminAdded(this.chatRoomId, this.userId);
}

class GroupAdminRemoved extends ChatState {
  final String chatRoomId;
  final String userId;
  
  GroupAdminRemoved(this.chatRoomId, this.userId);
}

// Typing states
class TypingStatusUpdated extends ChatState {
  final String chatRoomId;
  final Map<String, bool> typingStatus;
  
  TypingStatusUpdated(this.chatRoomId, this.typingStatus);
}

// Error states
class ChatError extends ChatState {
  final String message;
  
  ChatError(this.message);
}

class ChatRoomsError extends ChatState {
  final String message;
  
  ChatRoomsError(this.message);
}

class MessagesError extends ChatState {
  final String message;
  
  MessagesError(this.message);
}

class SendMessageError extends ChatState {
  final String message;
  
  SendMessageError(this.message);
}

// Media upload states
class UploadingMedia extends ChatState {}

class MediaUploaded extends ChatState {
  final String fileUrl;
  final String fileName;
  
  MediaUploaded(this.fileUrl, this.fileName);
}

class MediaUploadError extends ChatState {
  final String message;
  
  MediaUploadError(this.message);
}

// Search states
class SearchingMessages extends ChatState {}

class MessagesSearchResult extends ChatState {
  final List<Message> searchResults;
  final String query;
  
  MessagesSearchResult(this.searchResults, this.query);
}

class MessageSearchError extends ChatState {
  final String message;
  
  MessageSearchError(this.message);
} 