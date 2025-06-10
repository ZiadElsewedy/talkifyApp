import 'package:equatable/equatable.dart';
import 'package:talkifyapp/features/Chat/domain/entite/message.dart';
import 'package:talkifyapp/features/Chat/domain/entite/chat_room.dart';

// Base Chat State
abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

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
  
  const ChatRoomsLoaded(this.chatRooms);

  @override
  List<Object?> get props => [chatRooms];
}

class MessagesLoaded extends ChatState {
  final List<Message> messages;

  const MessagesLoaded(this.messages);

  @override
  List<Object?> get props => [messages];
}

class MessageSent extends ChatState {
  final List<Message> messages;
  
  const MessageSent(this.messages);

  @override
  List<Object?> get props => [messages];
}

class ChatRoomCreated extends ChatState {
  final ChatRoom chatRoom;
  
  const ChatRoomCreated(this.chatRoom);

  @override
  List<Object?> get props => [chatRoom];
}

class ChatRoomDeleted extends ChatState {
  final String chatRoomId;
  
  const ChatRoomDeleted(this.chatRoomId);

  @override
  List<Object?> get props => [chatRoomId];
}

class MessageUpdated extends ChatState {
  final Message message;
  
  const MessageUpdated(this.message);

  @override
  List<Object?> get props => [message];
}

class MessageDeleted extends ChatState {
  final List<Message> messages;
  
  const MessageDeleted(this.messages);

  @override
  List<Object?> get props => [messages];
}

class MessagesMarkedAsRead extends ChatState {
  final String chatRoomId;
  
  const MessagesMarkedAsRead(this.chatRoomId);

  @override
  List<Object?> get props => [chatRoomId];
}

// Group chat states
class GroupChatLeft extends ChatState {
  final String chatRoomId;
  
  const GroupChatLeft(this.chatRoomId);

  @override
  List<Object?> get props => [chatRoomId];
}

// Hidden chat state
class ChatHiddenForUser extends ChatState {
  final String chatRoomId;
  
  const ChatHiddenForUser(this.chatRoomId);

  @override
  List<Object?> get props => [chatRoomId];
}

// Chat history deleted for user state
class ChatHistoryDeletedForUser extends ChatState {
  final String chatRoomId;
  
  const ChatHistoryDeletedForUser(this.chatRoomId);

  @override
  List<Object?> get props => [chatRoomId];
}

// Message deleted for user state
class MessageDeletedForUser extends ChatState {
  final String messageId;
  final String userId;
  
  const MessageDeletedForUser(this.messageId, this.userId);

  @override
  List<Object?> get props => [messageId, userId];
}

class GroupAdminAdded extends ChatState {
  final String chatRoomId;
  final String userId;
  
  const GroupAdminAdded(this.chatRoomId, this.userId);

  @override
  List<Object?> get props => [chatRoomId, userId];
}

class GroupAdminRemoved extends ChatState {
  final String chatRoomId;
  final String userId;
  
  const GroupAdminRemoved(this.chatRoomId, this.userId);

  @override
  List<Object?> get props => [chatRoomId, userId];
}

// Typing states
class TypingStatusUpdated extends ChatState {
  final String chatRoomId;
  final Map<String, bool> typingStatus;
  
  const TypingStatusUpdated(this.chatRoomId, this.typingStatus);

  @override
  List<Object?> get props => [chatRoomId, typingStatus];
}

// Error states
class ChatError extends ChatState {
  final String message;
  
  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}

class ChatRoomsError extends ChatState {
  final String message;
  
  const ChatRoomsError(this.message);

  @override
  List<Object?> get props => [message];
}

class MessagesError extends ChatState {
  final String message;

  const MessagesError(this.message);

  @override
  List<Object?> get props => [message];
}

class SendMessageError extends ChatState {
  final String message;
  
  const SendMessageError(this.message);

  @override
  List<Object?> get props => [message];
}

// Media upload states
class UploadingMedia extends ChatState {}

class UploadingMediaProgress extends ChatState {
  final double progress;
  final String localFilePath;
  final String messageId;
  final MessageType type;
  final String? caption;
  final bool isFromCurrentUser;
  
  const UploadingMediaProgress({
    required this.progress,
    required this.localFilePath,
    required this.messageId,
    required this.type, 
    required this.isFromCurrentUser,
    this.caption,
  });

  @override
  List<Object?> get props => [progress, localFilePath, messageId, type, isFromCurrentUser, caption];
}

class MediaUploaded extends ChatState {
  final String fileUrl;
  final String fileName;
  final String messageId;
  
  const MediaUploaded(this.fileUrl, this.fileName, this.messageId);

  @override
  List<Object?> get props => [fileUrl, fileName, messageId];
}

class MediaUploadError extends ChatState {
  final String message;
  final String messageId;
  final String localFilePath;
  
  const MediaUploadError(this.message, this.messageId, this.localFilePath);

  @override
  List<Object?> get props => [message, messageId, localFilePath];
}

// Search states
class SearchingMessages extends ChatState {}

class MessagesSearchResult extends ChatState {
  final List<Message> searchResults;
  final String query;
  
  const MessagesSearchResult(this.searchResults, this.query);

  @override
  List<Object?> get props => [searchResults, query];
}

class MessageSearchError extends ChatState {
  final String message;
  
  const MessageSearchError(this.message);

  @override
  List<Object?> get props => [message];
}

// New states for Communities integration
class ChatRoomForCommunityLoading extends ChatState {}

class ChatRoomForCommunityLoaded extends ChatState {
  final ChatRoom chatRoom;
  
  const ChatRoomForCommunityLoaded(this.chatRoom);

  @override
  List<Object?> get props => [chatRoom];
}

class ChatRoomForCommunityNotFound extends ChatState {
  final String communityId;
  
  const ChatRoomForCommunityNotFound(this.communityId);

  @override
  List<Object?> get props => [communityId];
}

class ChatRoomForCommunityError extends ChatState {
  final String message;
  
  const ChatRoomForCommunityError(this.message);

  @override
  List<Object?> get props => [message];
}

class ChatRoomCreating extends ChatState {}

class ChatRoomCreationError extends ChatState {
  final String message;
  
  const ChatRoomCreationError(this.message);

  @override
  List<Object?> get props => [message];
}

class MessageSending extends ChatState {
  final List<Message> messages;

  const MessageSending(this.messages);

  @override
  List<Object?> get props => [messages];
}

class ChatRoomUpdated extends ChatState {
  final String chatRoomId;
  
  const ChatRoomUpdated(this.chatRoomId);

  @override
  List<Object?> get props => [chatRoomId];
} 