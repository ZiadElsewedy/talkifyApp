import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/Entites/community_member.dart';
import '../../domain/repo/community_repository.dart';
import 'community_member_state.dart';

class CommunityMemberCubit extends Cubit<CommunityMemberState> {
  final CommunityRepository _repository;

  CommunityMemberCubit({required CommunityRepository repository})
      : _repository = repository,
        super(CommunityMemberInitial());

  Future<void> getCommunityMembers(String communityId) async {
    emit(CommunityMembersLoading());
    try {
      final members = await _repository.getCommunityMembers(communityId);
      emit(CommunityMembersLoaded(members));
    } catch (e) {
      emit(CommunityMemberError(e.toString()));
    }
  }

  Future<void> joinCommunity(String communityId, String userId) async {
    emit(JoiningCommunity());
    try {
      final member = await _repository.joinCommunity(communityId, userId);
      emit(JoinedCommunitySuccessfully(member));
    } catch (e) {
      emit(CommunityMemberError(e.toString()));
    }
  }

  Future<void> leaveCommunity(String communityId, String userId) async {
    emit(LeavingCommunity());
    try {
      await _repository.leaveCommunity(communityId, userId);
      emit(LeftCommunitySuccessfully());
    } catch (e) {
      emit(CommunityMemberError(e.toString()));
    }
  }

  Future<void> updateMemberRole(String communityId, String userId, MemberRole role) async {
    emit(UpdatingMemberRole());
    try {
      await _repository.updateMemberRole(communityId, userId, role);
      emit(MemberRoleUpdatedSuccessfully());
    } catch (e) {
      emit(CommunityMemberError(e.toString()));
    }
  }
} 