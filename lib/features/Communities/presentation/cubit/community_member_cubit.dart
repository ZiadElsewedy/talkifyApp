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
      // Check if the user is already a member
      final members = await _repository.getCommunityMembers(communityId);
      final existingMember = members.where((member) => member.userId == userId).toList();
      
      if (existingMember.isNotEmpty) {
        // User is already a member
        emit(JoinedCommunitySuccessfully(existingMember.first));
        return;
      }
      
      final member = await _repository.joinCommunity(communityId, userId);
      emit(JoinedCommunitySuccessfully(member));
      
      // Reload the member list
      getCommunityMembers(communityId);
    } catch (e) {
      emit(CommunityMemberError(e.toString()));
    }
  }

  Future<void> leaveCommunity(String communityId, String userId) async {
    emit(LeavingCommunity());
    
    try {
      // Optimistic update - emit success immediately
      emit(LeftCommunitySuccessfully());
      
      // Then perform the actual operation
      await _repository.leaveCommunity(communityId, userId);
      
      // Reload the member list in the background
      _repository.getCommunityMembers(communityId).then((members) {
        emit(CommunityMembersLoaded(members));
      }).catchError((_) {
        // Ignore errors from background refresh
      });
    } catch (e) {
      // If there's an error, emit the error state
      emit(CommunityMemberError(e.toString()));
      
      // Then reload the member list to ensure UI is in sync
      try {
        final members = await _repository.getCommunityMembers(communityId);
        emit(CommunityMembersLoaded(members));
      } catch (_) {
        // If this also fails, at least we showed the error
      }
    }
  }

  Future<void> updateMemberRole(String communityId, String userId, MemberRole role) async {
    emit(UpdatingMemberRole());
    try {
      await _repository.updateMemberRole(communityId, userId, role);
      emit(MemberRoleUpdatedSuccessfully());
      
      // Reload the member list
      getCommunityMembers(communityId);
    } catch (e) {
      emit(CommunityMemberError(e.toString()));
    }
  }

  Future<bool> isUserMember(String communityId, String userId) async {
    try {
      final members = await _repository.getCommunityMembers(communityId);
      return members.any((member) => member.userId == userId);
    } catch (e) {
      return false;
    }
  }
  
  Future<MemberRole?> getUserRole(String communityId, String userId) async {
    try {
      final members = await _repository.getCommunityMembers(communityId);
      final member = members.firstWhere(
        (member) => member.userId == userId,
        orElse: () => throw Exception('User is not a member'),
      );
      return member.role;
    } catch (e) {
      return null;
    }
  }
} 