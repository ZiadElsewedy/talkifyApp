import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:talkifyapp/features/Profile/domain/Profile%20repo/ProfileRepo.dart';
import 'package:talkifyapp/features/Profile/domain/entites/ProfileUser.dart';

class FirebaseProfileRepo implements ProfileRepo {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Future<ProfileUser?> fetchUserProfile(String id) async {
    try {
      if (id.isEmpty) {
        print('Cannot fetch profile: Empty user ID provided');
        return null;
      }
      
      // Get the current user's ID from Firebase Auth
      final userDoc = await firestore.collection('users').doc(id).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          // get followers and following of the user and ensure they're properly converted to List<String>
          final followers = List<String>.from(userData['followers'] ?? []);
          final following = List<String>.from(userData['following'] ?? []);
          
          print('Successfully fetched profile for ID: $id');
          
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
        } else {
          print('User document exists but data is null for ID: $id');
        }
      } else {
        print('User document not found for ID: $id');
      }
      return null;
    } catch (e, stackTrace) {
      print('Error fetching user profile for ID $id: $e');
      print('Stack trace: $stackTrace');
      // Handle the error as needed
      return null;
    }
  }

  @override
  Future<void> updateUserProfile (ProfileUser updateProfile) async {
    try {
      await firestore.collection('users').doc(updateProfile.id).update({
        'bio': updateProfile.bio,
        'name': updateProfile.name,
        'backgroundprofilePictureUrl': updateProfile.backgroundprofilePictureUrl,
        'profilePictureUrl': updateProfile.profilePictureUrl,
        'HintDescription': updateProfile.HintDescription,
        'followers': updateProfile.followers,
        'following': updateProfile.following,
      })
      .then((_) {
        print('User profile updated successfully');
      })
      .catchError((error) {
        
      });
} on Exception catch (e) {
    print('Error updating user profile: $e');
    // Handle the error as needed

}
  }
  
  @override
  ToggleFollow(String currentUserId, String otherUserId) async {
    try {
      final currentUserDoc = await firestore.collection('users').doc(currentUserId).get();
      final otherUserDoc = await firestore.collection('users').doc(otherUserId).get();
      
      if (!currentUserDoc.exists) {
        throw Exception("Current user document not found");
      }
      
      if (!otherUserDoc.exists) {
        throw Exception("Target user document not found");
      }
      
      if (currentUserDoc.exists && otherUserDoc.exists) {
        // check if the user is already following the other user
        final currentUserFollowing = List<String>.from(currentUserDoc.data()?['following'] ?? []);
        final otherUserFollowers = List<String>.from(otherUserDoc.data()?['followers'] ?? []);

        if (currentUserFollowing.contains(otherUserId)) {
          //unfollow the user
          print('Unfollowing user: $otherUserId');
          currentUserFollowing.remove(otherUserId);
          otherUserFollowers.remove(currentUserId);
        } else {
          //follow the user
          currentUserFollowing.add(otherUserId);
          otherUserFollowers.add(currentUserId);
          print('Following user: $otherUserId');
        }
        
        // Update both users in Firestore
        await firestore.collection('users').doc(currentUserId).update({
          'following': currentUserFollowing,
        });
        
        await firestore.collection('users').doc(otherUserId).update({
          'followers': otherUserFollowers,
        });
      }
    } catch (e, stackTrace) {
      print('Error toggling follow relationship: $e');
      print('Stack trace: $stackTrace');
      throw e; // Rethrow to let the cubit handle it
    }
  }
}
