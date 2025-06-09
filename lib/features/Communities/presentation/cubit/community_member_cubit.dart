import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/Entites/community_member.dart';
import '../../domain/repo/community_repository.dart';
import 'community_member_state.dart';
import 'dart:developer' as developer;

class CommunityMemberCubit extends Cubit<CommunityMemberState> {
  final CommunityRepository _repository;

  CommunityMemberCubit({required CommunityRepository repository})
      : _repository = repository,
        super(CommunityMemberInitial());

  Future<void> getCommunityMembers(String communityId) async {
    emit(CommunityMembersLoading());
    try {
      developer.log('Fetching members for community: $communityId', name: 'CommunityMemberCubit');
      
      final members = await _repository.getCommunityMembers(communityId);
      
      developer.log('Fetched ${members.length} members for community: $communityId', name: 'CommunityMemberCubit');
      
      // Log details of each member for debugging
      for (var member in members) {
        developer.log('Member: ${member.userName} (${member.userId}), Role: ${member.role}, Avatar: ${member.userAvatar.isNotEmpty ? 'Has avatar' : 'No avatar'}', 
          name: 'CommunityMemberCubit');
      }
      
      emit(CommunityMembersLoaded(members));
    } catch (e) {
      developer.log('Error fetching members: $e', name: 'CommunityMemberCubit', error: e);
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
      developer.log('Error joining community: $e', name: 'CommunityMemberCubit', error: e);
      emit(CommunityMemberError(e.toString()));
    }
  }

  Future<void> leaveCommunity(String communityId, String userId) async {
    emit(LeavingCommunity());
    try {
      await _repository.leaveCommunity(communityId, userId);
      emit(LeftCommunitySuccessfully());
      
      // Reload the member list
      getCommunityMembers(communityId);
    } catch (e) {
      developer.log('Error leaving community: $e', name: 'CommunityMemberCubit', error: e);
      emit(CommunityMemberError(e.toString()));
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
      developer.log('Error updating member role: $e', name: 'CommunityMemberCubit', error: e);
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