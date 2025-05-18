import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:talkifyapp/features/Profile/domain/Profile%20repo/ProfileRepo.dart';
import 'package:talkifyapp/features/Profile/domain/entites/ProfileUser.dart';

class FirebaseProfileRepo implements ProfileRepo {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Future<ProfileUser?> fetchUserProfile(String id) async {
    try {
      // Get the current user's ID from Firebase Auth
      final userDoc = await firestore.collection('users').doc(id).get();
      // Fetch the user document from Firestore
      // Replace "id" with the actual user ID you want to fetch
      // For example, if you are using Firebase Auth, you can get the current user's ID like this:
      // final userId = FirebaseAuth.instance.currentUser?.uid;


      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          // get followers and following of the user
          final followers = userData['followers'] ?? [];
          final following = userData['following'] ?? [];
          return ProfileUser(
            id: id,
            name: userData['name'],
            email: userData['email'] ,
            phoneNumber: userData['phoneNumber'] ,
            bio: userData['bio'] ?? '',
            backgroundprofilePictureUrl: userData['backgroundprofilePictureUrl'].toString(),
            profilePictureUrl: userData['profilePictureUrl'].toString(),
            HintDescription: userData['HintDescription'] ?? '',
            followers: followers,
            following: following, 
          );
        }
      }
       return null;
    } catch (e) {
      print('Error fetching user profile: $e');
      // Handle the error as needed
    }

    return null;
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
    // check if the user is already following the other user
   try {
     final currentUserDoc = await firestore.collection('users').doc(currentUserId).get();
     final otherUserDoc = await firestore.collection('users').doc(otherUserId).get();
     if (currentUserDoc.exists && otherUserDoc.exists) {
      // check if the user is already following the other user
      final currentUserFollowing = currentUserDoc.data()?['following'] ?? [];
      final otherUserFollowers = otherUserDoc.data()?['followers'] ?? [];

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

     }
   } catch (e) {
     print('Error toggling follow: $e');
   }

  }
}
