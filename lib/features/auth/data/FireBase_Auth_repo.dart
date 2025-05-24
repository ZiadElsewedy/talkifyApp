import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:talkifyapp/features/auth/domain/entities/AppUser.dart';
import 'package:talkifyapp/features/auth/domain/repo/authrepo.dart';
// step 2 : implement the auth repo interface
// all operations in the interface will be implemented here 
class FirebaseAuthRepo implements AuthRepo {
  //Get me the one and only object (singleton instance) of this class
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore  firestore = FirebaseFirestore.instance;

  @override
  User? get currentUser => firebaseAuth.currentUser;

  @override
  Future<AppUser> loginWithEmailPassword({required String email, required String password}) async {
    try {
      // attempt to sign in the user with email and password
      UserCredential userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: email, 
        password: password,
      );
      await firestore.collection('users').doc(userCredential.user!.uid).update({
        'isOnline': true,
      });

      // check if the user is signed in
      if (userCredential.user?.emailVerified == true) {
        DocumentSnapshot doc = await firestore.collection('users').doc(userCredential.user!.uid).get();
        if (!doc.exists) {
          throw Exception('User data not found. Please contact support.');
        }
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return AppUser.fromJson(data);
      }
      // If not verified, return basic user info
      AppUser user = AppUser(
        id: userCredential.user!.uid,
        name: '',
        email: email,
        phoneNumber: userCredential.user!.phoneNumber ?? '',
        profilePictureUrl: userCredential.user!.photoURL ?? '',
      );
      return user;
    } catch (e) {
      // handle error
      throw Exception('Failed to login: $e');
      
    }
    
  }

  @override
  Future<AppUser> registerWithEmailPassword({
    required String phoneNumber,
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Create user account
      UserCredential userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send verification email
      await userCredential.user?.sendEmailVerification();

      // Create user object but don't save to Firestore yet
      AppUser user = AppUser(
        id: userCredential.user!.uid,
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        profilePictureUrl: userCredential.user!.photoURL ?? '',
      );

      return user;
    } catch (e) {
      throw Exception('Failed to register: $e');
    }
  }

  @override
  Future<void> saveUserToFirestore(AppUser user) async {
    try {
      await firestore.collection('users').doc(user.id).set({
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'phoneNumber': user.phoneNumber,
        'profilePictureUrl': user.profilePictureUrl,
        'isVerified': false,
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to save user data: $e');
    }
  }

  @override
  Future<void> updateUserVerificationStatus(AppUser user) async {
    try {
      await firestore.collection('users').doc(user.id).update({
        'isVerified': true,
        'verifiedAt': FieldValue.serverTimestamp(),

      });
    } catch (e) {
      throw Exception('Failed to update user verification status: $e');
    }
  }

  @override
  Future<void> checkEmailVerification() async {
    await firebaseAuth.currentUser?.reload();
  }

  @override
  Future<void> sendVerificationEmail() async {
    await firebaseAuth.currentUser?.sendEmailVerification();
  }

  @override
  Future<void> LogOut() async {
    try {
      // Get the current user ID before signing out
      final userId = firebaseAuth.currentUser?.uid;
      
      // Update online status if user ID exists
      if (userId != null) {
        // Use a try-catch here to ensure we still log out even if Firestore update fails
        try {
          await firestore.collection('users').doc(userId).update({
            'isOnline': false,
            'lastSeen': FieldValue.serverTimestamp(),
          });
          print('User status updated to offline');
        } catch (firestoreError) {
          // Log error but continue with sign out
          print('Failed to update online status: $firestoreError');
        }
      }
      
      // Sign out from Firebase Auth
      await firebaseAuth.signOut();
      print('Logged out successfully');
    } catch (e) {
      print('Logout error: $e');
      throw Exception('Logout failed: $e');
    }
  }

  @override
  Future<AppUser?> GetCurrentUser() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) return null;

      // Update online status when getting current user
      await firestore.collection('users').doc(user.uid).update({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });

      final userData = await firestore.collection('users').doc(user.uid).get();
      if (!userData.exists) return null;

      final data = userData.data()!;
      
      return AppUser(
        id: user.uid,
        name: data['name'] ?? '',
        email: user.email ?? '',
        phoneNumber: data['phoneNumber'] ?? '',
        profilePictureUrl: data['profilePictureUrl'] ?? '',
        isOnline: data['isOnline'] ?? false,
        lastSeen: data['lastSeen'] != null ? (data['lastSeen'] as Timestamp).toDate() : null,
      );
    } catch (e) {
      throw Exception('Failed to get current user: $e');
    }
  }
}
// UnimplementedError() mean? It's a placeholder saying: "Hey, I will write the real code later!"