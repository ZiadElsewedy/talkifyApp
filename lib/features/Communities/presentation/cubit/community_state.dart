import '../../domain/Entites/community.dart';

abstract class CommunityState {
  const CommunityState();

  List<Object?> get props => [];
}

class CommunityInitial extends CommunityState {}

// For getting all communities
class CommunitiesLoading extends CommunityState {}

class CommunitiesLoaded extends CommunityState {
  final List<Community> communities;

  const CommunitiesLoaded(this.communities);

  @override
  List<Object?> get props => [communities];
}

// For single community details
class CommunityDetailLoading extends CommunityState {}

class CommunityDetailLoaded extends CommunityState {
  final Community community;

  const CommunityDetailLoaded(this.community);

  @override
  List<Object?> get props => [community];
}

// For creating a community
class CommunityCreating extends CommunityState {}

class CommunityCreatedSuccessfully extends CommunityState {
  final Community? community;

  const CommunityCreatedSuccessfully([this.community]);

  @override
  List<Object?> get props => [community];
}

// For updating a community
class CommunityUpdating extends CommunityState {}

class CommunityUpdatedSuccessfully extends CommunityState {}

// For deleting a community
class CommunityDeleting extends CommunityState {}

class CommunityDeletedSuccessfully extends CommunityState {}

// For error states
class CommunityError extends CommunityState {
  final String message;

  const CommunityError(this.message);

  @override
  List<Object?> get props => [message];
} 