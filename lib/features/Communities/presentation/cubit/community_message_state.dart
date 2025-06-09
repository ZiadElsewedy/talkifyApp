import '../../domain/Entites/community_message.dart';

abstract class CommunityMessageState {
  const CommunityMessageState();

  List<Object?> get props => [];
}

class CommunityMessageInitial extends CommunityMessageState {}

// For getting messages
class CommunityMessagesLoading extends CommunityMessageState {}

class CommunityMessagesLoaded extends CommunityMessageState {
  final List<CommunityMessage> messages;

  const CommunityMessagesLoaded(this.messages);

  @override
  List<Object?> get props => [messages];
}

// For sending a message
class SendingMessage extends CommunityMessageState {}

class MessageSentSuccessfully extends CommunityMessageState {
  final CommunityMessage message;

  const MessageSentSuccessfully(this.message);

  @override
  List<Object?> get props => [message];
}

// For pinning messages
class PinningMessage extends CommunityMessageState {}

class MessagePinnedSuccessfully extends CommunityMessageState {}

// For loading pinned messages
class LoadingPinnedMessages extends CommunityMessageState {}

class PinnedMessagesLoaded extends CommunityMessageState {
  final List<CommunityMessage> pinnedMessages;

  const PinnedMessagesLoaded(this.pinnedMessages);

  @override
  List<Object?> get props => [pinnedMessages];
}

// For error states
class CommunityMessageError extends CommunityMessageState {
  final String message;

  const CommunityMessageError(this.message);

  @override
  List<Object?> get props => [message];
} 