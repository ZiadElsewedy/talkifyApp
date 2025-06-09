import '../../domain/Entites/community_member.dart';

abstract class CommunityMemberState {
  const CommunityMemberState();

  List<Object?> get props => [];
}

class CommunityMemberInitial extends CommunityMemberState {}

// For getting members
class CommunityMembersLoading extends CommunityMemberState {}

class CommunityMembersLoaded extends CommunityMemberState {
  final List<CommunityMember> members;

  const CommunityMembersLoaded(this.members);

  @override
  List<Object?> get props => [members];
}

// For joining a community
class JoiningCommunity extends CommunityMemberState {}

class JoinedCommunitySuccessfully extends CommunityMemberState {
  final CommunityMember member;

  const JoinedCommunitySuccessfully(this.member);

  @override
  List<Object?> get props => [member];
}

// For leaving a community
class LeavingCommunity extends CommunityMemberState {}

class LeftCommunitySuccessfully extends CommunityMemberState {}

// For updating member role
class UpdatingMemberRole extends CommunityMemberState {}

class MemberRoleUpdatedSuccessfully extends CommunityMemberState {}

// For error states
class CommunityMemberError extends CommunityMemberState {
  final String message;

  const CommunityMemberError(this.message);

  @override
  List<Object?> get props => [message];
} 