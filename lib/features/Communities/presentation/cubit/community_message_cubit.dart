import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/Entites/community_message.dart';
import '../../domain/repo/community_repository.dart';
import 'community_message_state.dart';

class CommunityMessageCubit extends Cubit<CommunityMessageState> {
  final CommunityRepository _repository;

  CommunityMessageCubit({required CommunityRepository repository})
      : _repository = repository,
        super(CommunityMessageInitial());

  Future<void> getCommunityMessages(String communityId) async {
    emit(CommunityMessagesLoading());
    try {
      final messages = await _repository.getCommunityMessages(communityId);
      emit(CommunityMessagesLoaded(messages));
    } catch (e) {
      emit(CommunityMessageError(e.toString()));
    }
  }

  Future<void> sendMessage(CommunityMessage message) async {
    emit(SendingMessage());
    try {
      final sentMessage = await _repository.sendMessage(message);
      emit(MessageSentSuccessfully(sentMessage));
    } catch (e) {
      emit(CommunityMessageError(e.toString()));
    }
  }

  Future<void> pinMessage(String messageId, bool isPinned) async {
    emit(PinningMessage());
    try {
      await _repository.pinMessage(messageId, isPinned);
      emit(MessagePinnedSuccessfully());
    } catch (e) {
      emit(CommunityMessageError(e.toString()));
    }
  }

  Future<void> getPinnedMessages(String communityId) async {
    emit(LoadingPinnedMessages());
    try {
      final pinnedMessages = await _repository.getPinnedMessages(communityId);
      emit(PinnedMessagesLoaded(pinnedMessages));
    } catch (e) {
      emit(CommunityMessageError(e.toString()));
    }
  }
} 