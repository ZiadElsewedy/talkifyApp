import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Profile/domain/entites/ProfileUser.dart';
import 'package:talkifyapp/features/Storage/Domain/Storage_repo.dart';
import 'package:talkifyapp/features/Profile/domain/Profile%20repo/ProfileRepo.dart';
import 'package:talkifyapp/features/Profile/presentation/Cubits/Profile_states.dart';

class ProfileCubit extends Cubit<ProfileStates> {
  final StorageRepo Storage; // Interface to upload images (web or mobile)
  final ProfileRepo profileRepo; // Interface to handle user profile data
  ProfileCubit({ required this.profileRepo, required this.Storage}) : super(ProfileInitialState());
  
  // Fetch user profile
  Future<void> fetchUserProfile( String id ) async {
    if (id.isEmpty) {
      emit(ProfileErrorState("Invalid user ID"));
      return;
    }

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

  Future<ProfileUser?> GetUserProfileByUsername ( String username ) async {
      final user = await profileRepo.fetchUserProfile(username); // Fetch user profile by username
      return user;
  }


  // Using the repo to fetch the user profile
  // and update the bio or Profile picture
  void updateUserProfile({ required String id,  String? newBio, Uint8List? ImageWebByter , String? imageMobilePath , String? newName , String? newbackgroundprofilePictureUrl , Uint8List? backgroundImageWebBytes , String? backgroundImageMobilePath , String? newHintDescription }) async {
    emit(ProfileLoadingState()); // Emit loading state while updating
    try {
      final currentUser = await profileRepo.fetchUserProfile(id); // Get the current user profile
      String? imageDowloadUrl; // Will hold the download URL of the uploaded image
      String? backgroundImageDownloadUrl; // Will hold the download URL of the uploaded background image

      // Handle profile picture upload
      if (ImageWebByter != null) {
        imageDowloadUrl = await Storage.uploadProfileImageWeb(ImageWebByter, id);
      } else if (imageMobilePath != null) {
        imageDowloadUrl = await Storage.uploadProfileImageMobile(imageMobilePath, id);
      }

      // Handle background image upload
      if (backgroundImageWebBytes != null) {
        backgroundImageDownloadUrl = await Storage.uploadProfileImageWeb(backgroundImageWebBytes, "${id}_background");
      } else if (backgroundImageMobilePath != null) {
        backgroundImageDownloadUrl = await Storage.uploadProfileImageMobile(backgroundImageMobilePath, "${id}_background");
      }

      if (currentUser != null) {
        final updatedUser = currentUser.copywith(
          newName: newName,
          newBio: newBio,
          newprofilePictureUrl: imageDowloadUrl ?? currentUser.profilePictureUrl,
          newbackgroundprofilePictureUrl: backgroundImageDownloadUrl ?? currentUser.backgroundprofilePictureUrl,  
          newHintDescription: newHintDescription ?? currentUser.HintDescription,
        );
        await profileRepo.updateUserProfile(updatedUser); // Save updated profile
        emit(ProfileLoadedState(updatedUser)); // Emit updated state
      } else {
        emit(ProfileErrorState("Failed to update the user profile")); // Emit error if user not found
      }
    }catch (e) {
      emit(ProfileErrorState(e.toString())); // Emit error if exception occurs
  }}

  // Toggle follow
Future<void> toggleFollow(String currentUserId, String otherUserId) async {
  try {
    await profileRepo.ToggleFollow(currentUserId, otherUserId);
  } catch (e) {
    emit(ProfileErrorState(e.toString())); // Emit error if exception occurs
  }
}

// Check if a user is following another user
Future<bool> isFollowing(String currentUserId, String otherUserId) async {
  try {
    return await profileRepo.isFollowing(currentUserId, otherUserId);
  } catch (e) {
    print('Error checking follow status in cubit: $e');
    return false; // Default to not following if there's an error
  }
}

// Get mutual friends between two users
Future<List<ProfileUser>> getMutualFriends(String currentUserId, String otherUserId) async {
  try {
    return await profileRepo.getMutualFriends(currentUserId, otherUserId);
  } catch (e) {
    print('Error getting mutual friends in cubit: $e');
    return []; // Return empty list on error
  }
}

// Get suggested users to follow
Future<List<ProfileUser>> getSuggestedUsers(String userId, {int limit = 5}) async {
  try {
    return await profileRepo.getSuggestedUsers(userId, limit: limit);
  } catch (e) {
    print('Error getting suggested users in cubit: $e');
    return []; // Return empty list on error
  }
}
} 
