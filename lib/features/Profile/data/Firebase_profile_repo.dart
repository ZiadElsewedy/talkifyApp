import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:talkifyapp/features/Profile/domain/Profile%20repo/ProfileRepo.dart';
import 'package:talkifyapp/features/Profile/domain/entites/ProfileUser.dart';

class FirebaseProfileRepo implements ProfileRepo {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Future<ProfileUser?> fetchUserProfile(String id) async {
    try {
      if (id.isEmpty) {
        throw Exception('Cannot fetch profile: Empty user ID provided');
      }
      
      final userDoc = await firestore.collection('users').doc(id).get();
      
      if (!userDoc.exists) {
        throw Exception('User document not found for ID: $id');
      }

      final userData = userDoc.data();
      if (userData == null) {
        throw Exception('User document exists but data is null for ID: $id');
      }

      return _mapDocumentToProfileUser(id, userData);
    } catch (e, stackTrace) {
      print('Error fetching user profile for ID $id: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  ProfileUser _mapDocumentToProfileUser(String id, Map<String, dynamic> userData) {
    final followers = List<String>.from(userData['followers'] ?? []);
    final following = List<String>.from(userData['following'] ?? []);
    
    return ProfileUser(
      id: id,
      name: userData['name'] ?? '',
      email: userData['email'] ?? '',
      phoneNumber: userData['phoneNumber'] ?? '',
      bio: userData['bio'] ?? '',
      backgroundprofilePictureUrl: userData['backgroundprofilePictureUrl']?.toString() ?? '',
      profilePictureUrl: userData['profilePictureUrl']?.toString() ?? '',
      HintDescription: userData['HintDescription'] ?? '',
      followers: followers,
      following: following,
    );
  }

  @override
  Future<void> updateUserProfile(ProfileUser updateProfile) async {
    try {
      if (updateProfile.id.isEmpty) {
        throw Exception('Cannot update profile: Empty user ID provided');
      }

      final userDoc = await firestore.collection('users').doc(updateProfile.id).get();
      if (!userDoc.exists) {
        throw Exception('User document not found for ID: ${updateProfile.id}');
      }

      await firestore.collection('users').doc(updateProfile.id).update({
        'bio': updateProfile.bio,
        'name': updateProfile.name,
        'backgroundprofilePictureUrl': updateProfile.backgroundprofilePictureUrl,
        'profilePictureUrl': updateProfile.profilePictureUrl,
        'HintDescription': updateProfile.HintDescription,
        'followers': updateProfile.followers,
        'following': updateProfile.following,
      });
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }
  
  @override
  Future<bool> ToggleFollow(String currentUserId, String otherUserId) async {
    try {
      // Validate inputs
      if (currentUserId.isEmpty || otherUserId.isEmpty) {
        throw Exception("User IDs cannot be empty");
      }

      // Prevent self-following
      if (currentUserId == otherUserId) {
        throw Exception("Users cannot follow themselves");
      }

      bool isFollowing = false;

      // Use a transaction to ensure atomic updates
      await firestore.runTransaction((transaction) async {
        // Get both user documents
        final currentUserDoc = await transaction.get(firestore.collection('users').doc(currentUserId));
        final otherUserDoc = await transaction.get(firestore.collection('users').doc(otherUserId));
        
        if (!currentUserDoc.exists || !otherUserDoc.exists) {
          throw Exception("One or both user documents not found");
        }

        // Get current following/followers lists
        final currentUserFollowing = List<String>.from(currentUserDoc.data()?['following'] ?? []);
        final otherUserFollowers = List<String>.from(otherUserDoc.data()?['followers'] ?? []);

        // Clean up any self-following that might exist
        currentUserFollowing.remove(currentUserId);
        otherUserFollowers.remove(otherUserId);

        // Determine if we're following or unfollowing
        isFollowing = currentUserFollowing.contains(otherUserId);

        if (isFollowing) {
          // Unfollow: Remove from both lists
          currentUserFollowing.remove(otherUserId);
          otherUserFollowers.remove(currentUserId);
        } else {
          // Follow: Add to both lists
          currentUserFollowing.add(otherUserId);
          otherUserFollowers.add(currentUserId);
        }

        // Update both documents atomically
        transaction.update(firestore.collection('users').doc(currentUserId), {
          'following': currentUserFollowing,
        });

        transaction.update(firestore.collection('users').doc(otherUserId), {
          'followers': otherUserFollowers,
        });
      });

      return !isFollowing; // Return true if now following, false if now unfollowing
    } catch (e, stackTrace) {
      print('Error toggling follow relationship: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<bool> isFollowing(String currentUserId, String otherUserId) async {
    try {
      if (currentUserId.isEmpty || otherUserId.isEmpty) {
        throw Exception("User IDs cannot be empty");
      }

      final userDoc = await firestore.collection('users').doc(otherUserId).get();
      if (!userDoc.exists) {
        throw Exception("User document not found");
      }

      final followers = List<String>.from(userDoc.data()?['followers'] ?? []);
      return followers.contains(currentUserId);
    } catch (e) {
      print('Error checking follow status: $e');
      rethrow;
    }
  }
}
