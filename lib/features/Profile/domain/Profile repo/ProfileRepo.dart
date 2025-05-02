// Profile repository
// This repository handles the profile-related operations, such as fetching and updating user profiles.
import 'package:talkifyapp/features/Profile/domain/entites/ProfileUser.dart';

abstract class ProfileRepo {
  // Fetches the current user's profile
  Future<ProfileUser?> fetchUserProfile(
    String id,
  );
  // Updates the user's profile with new data
  Future<void> updateUserProfile(ProfileUser UpdateProfile);
}