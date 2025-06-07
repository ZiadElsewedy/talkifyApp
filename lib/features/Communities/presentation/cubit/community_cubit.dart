import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/Entites/community.dart';
import '../../domain/repo/community_repository.dart';
import 'community_state.dart';

class CommunityCubit extends Cubit<CommunityState> {
  final CommunityRepository _repository;

  CommunityCubit({required CommunityRepository repository})
      : _repository = repository,
        super(CommunityInitial());

  Future<void> getAllCommunities() async {
    emit(CommunitiesLoading());
    try {
      final communities = await _repository.getCommunities();
      emit(CommunitiesLoaded(communities));
    } catch (e) {
      emit(CommunityError(e.toString()));
    }
  }

  Future<void> getTrendingCommunities() async {
    emit(CommunitiesLoading());
    try {
      final communities = await _repository.getTrendingCommunities();
      emit(CommunitiesLoaded(communities));
    } catch (e) {
      emit(CommunityError(e.toString()));
    }
  }

  Future<void> searchCommunities(String query) async {
    emit(CommunitiesLoading());
    try {
      final communities = await _repository.searchCommunities(query);
      emit(CommunitiesLoaded(communities));
    } catch (e) {
      emit(CommunityError(e.toString()));
    }
  }

  Future<void> getCommunityById(String id) async {
    emit(CommunityDetailLoading());
    try {
      final community = await _repository.getCommunityById(id);
      emit(CommunityDetailLoaded(community));
    } catch (e) {
      emit(CommunityError(e.toString()));
    }
  }

  Future<void> createCommunity(Community community) async {
    emit(CommunityCreating());
    try {
      final newCommunity = await _repository.createCommunity(community);
      emit(CommunityCreatedSuccessfully(newCommunity));
    } catch (e) {
      emit(CommunityError(e.toString()));
    }
  }

  Future<void> updateCommunity(Community community) async {
    emit(CommunityUpdating());
    try {
      await _repository.updateCommunity(community);
      emit(CommunityUpdatedSuccessfully());
    } catch (e) {
      emit(CommunityError(e.toString()));
    }
  }

  Future<void> deleteCommunity(String id) async {
    emit(CommunityDeleting());
    try {
      await _repository.deleteCommunity(id);
      emit(CommunityDeletedSuccessfully());
    } catch (e) {
      emit(CommunityError(e.toString()));
    }
  }
} 