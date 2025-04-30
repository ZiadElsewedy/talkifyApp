// Profile repository
// This repository handles the profile-related operations, such as fetching and updating user profiles.
import 'package:talkifyapp/features/auth/domain/entities/AppUser.dart';

abstract class ProfileRepo {
  // Fetches the current user's profile
  Future<AppUser?> FettchUserProfile();
  // Updates the user's profile with new data
  Future<void> updateUserProfile(AppUser UpdateProfile);
}