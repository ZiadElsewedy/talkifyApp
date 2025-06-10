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

  // Follow a user
  Future<bool> ToggleFollow(String currentUserId, String otherUserId);

  // Check if a user is following another user
  Future<bool> isFollowing(String currentUserId, String otherUserId);
  
  // Get mutual friends between two users
  Future<List<ProfileUser>> getMutualFriends(String userId1, String userId2);
  
  // Get suggested users to follow based on current user's network
  Future<List<ProfileUser>> getSuggestedUsers(String userId, {int limit = 5});
}