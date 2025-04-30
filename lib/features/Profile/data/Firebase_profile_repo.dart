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
          return ProfileUser(
            id: id,
            name: userData['name'],
            email: userData['email'] ,
            phoneNumber: userData['phoneNumber'] ,
            profilePictureUrl: userData['profilePictureUrl'].toString() ,
            bio: userData['bio'],
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
        'profilePictureUrl': updateProfile.profilePictureUrl,
        'bio': updateProfile.bio,
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
}
