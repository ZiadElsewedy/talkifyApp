import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/Storage/Domain/Storage_repo.dart';
import 'package:talkifyapp/features/Profile/domain/Profile%20repo/ProfileRepo.dart';
import 'package:talkifyapp/features/Profile/presentation/Cubits/Profile_states.dart';

class ProfileCubit extends Cubit<ProfileStates> {
  final StorageRepo Storage; // Interface to upload images (web or mobile)
  final ProfileRepo profileRepo; // Interface to handle user profile data
  ProfileCubit({ required this.profileRepo, required this.Storage}) : super(ProfileInitialState());
  
  // Fetch user profile
  void fetchUserProfile( String id ) async {
    emit(ProfileLoadingState()); // Emit loading state
    try {
      final user = await profileRepo.fetchUserProfile(id); // Fetch user profile by ID
      // Fetch the user profile from the repository
      if (user != null) {
        emit(ProfileLoadedState(user)); // Emit the loaded state with the user profile
        // Emit the loaded state with the user profile
      } else {
        emit(ProfileErrorState("Failed to find the  user profile")); // Emit error if user not found
      }
    } catch (e) {
      emit(ProfileErrorState(e.toString())); // Emit error if exception occurs
    }
  }

  // Using the repo to fetch the user profile
  // and update the bio or Profile picture
  void updateUserProfile({ required String id,  String? newBio, Uint8List? ImageWebByter , String? imageMobilePath , String? newName , String? newbackgroundprofilePictureUrl}) async {
    emit(ProfileLoadingState()); // Emit loading state while updating
    try {
      final currentUser = await profileRepo.fetchUserProfile(id); // Get the current user profile
      String? imageDowloadUrl; // Will hold the download URL of the uploaded image

      if (ImageWebByter != null) {
        imageDowloadUrl = await Storage.uploadProfileImageWeb(ImageWebByter, id);
      } else if (imageMobilePath != null) {
        imageDowloadUrl = await Storage.uploadProfileImageMobile(imageMobilePath, id);
      }

      if (currentUser != null) {
        final updatedUser = currentUser.copywith(
          newName: newName,
          newBio: newBio,
          newprofilePictureUrl: imageDowloadUrl ?? currentUser.profilePictureUrl,
          newbackgroundprofilePictureUrl: newbackgroundprofilePictureUrl ?? currentUser.backgroundprofilePictureUrl,  
        );
        await profileRepo.updateUserProfile(updatedUser); // Save updated profile
        emit(ProfileLoadedState(updatedUser)); // Emit updated state
      } else {
        emit(ProfileErrorState("Failed to update the user profile")); // Emit error if user not found
      }
    }catch (e) {
      emit(ProfileErrorState(e.toString())); // Emit error if exception occurs
  }}}
