import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/Storage/Domain/Storage_repo.dart';
import 'package:talkifyapp/features/Profile/domain/Profile%20repo/ProfileRepo.dart';
import 'package:talkifyapp/features/Profile/presentation/Profile_states.dart';

class ProfileCubit extends Cubit<ProfileStates> {
  final StorageRepo Storage;
  final ProfileRepo profileRepo;
  ProfileCubit({ required this.profileRepo, required this.Storage}) : super(ProfileInitialState());
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
        emit(ProfileErrorState("Failed to find the  user profile"));
      }
    } catch (e) {
      emit(ProfileErrorState(e.toString()));
    }
  }
  // Using the repo to fetch the user profile
  // and update the bio or Profile picture
  void updateUserProfile({ required String id,  String? newBio, Uint8List? ImageWebByter , String? imageMobilePath}) async {
    emit(ProfileLoadingState());
    try {
      final currentUser = await profileRepo.fetchUserProfile(id);
      String? imageDowloadUrl;
      if (ImageWebByter != null) {
        imageDowloadUrl = await Storage.uploadProfileImageWeb(ImageWebByter, id);
      } else if (imageMobilePath != null) {
        imageDowloadUrl = await Storage.uploadProfileImageMobile(imageMobilePath, id);
      } else if  ( imageDowloadUrl == null) {
        emit(ProfileErrorState("Failed to upload the image"));
        return;
        
      }

      if (currentUser != null) {
        final updatedUser = currentUser.copywith(
          newBio: newBio,
        );
        await profileRepo.updateUserProfile(updatedUser);
        emit(ProfileLoadedState(updatedUser));
      } else {
        emit(ProfileErrorState("Failed to update the user profile"));
      }
    }catch (e) {
      emit(ProfileErrorState(e.toString()));
  }}}