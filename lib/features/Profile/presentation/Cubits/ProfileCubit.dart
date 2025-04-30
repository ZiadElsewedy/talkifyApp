import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Profile/domain/Profile%20repo/ProfileRepo.dart';
import 'package:talkifyapp/features/Profile/presentation/Profile_states.dart';

class ProfileCubit extends Cubit<ProfileStates> {
  final ProfileRepo profileRepo;
  ProfileCubit(this.profileRepo) : super(ProfileInitialState());
  // Fetch user profile
  void fetchUserProfile( String id ) async {
    emit(ProfileLoadingState());
    try {
      final user = await profileRepo.fetchUserProfile(id);
      // Fetch the user profile from the repository
      if (user != null) {
        emit(ProfileLoadedState(user)); // Emit the loaded state with the user profile
        // Emit the loaded state with the user profile
      } else {
        emit(ProfileErrorState("Failed to load user profile"));
      }
    } catch (e) {
      emit(ProfileErrorState(e.toString()));
    }
  }
  // Using the repo to fetch the user profile
  // and update the bio and Profile picture

  
}