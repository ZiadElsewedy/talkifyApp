import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:talkifyapp/features/auth/domain/entities/AppUser.dart';
import 'package:talkifyapp/features/auth/domain/repo/authrepo.dart';

class FirebaseAuthRepo implements AuthRepo {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore  firestore = FirebaseFirestore.instance;

  @override
  Future<AppUser> loginWithEmailPassword({required String email, required String password}) async {
    try {
      // attempt to sign in the user with email and password
      UserCredential userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // check if the user is signed in
      AppUser user = AppUser(
        id: userCredential.user!.uid,
        name: '',
        email: email , 
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
  Future<AppUser> registerWithEmailPassword({required String email, required String password}) async {
   try {
      // attempt to sign up the user with email and password

      UserCredential userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
     
      AppUser user = AppUser(
        id: userCredential.user!.uid,
        name: '',
        email: email , 
        phoneNumber: userCredential.user!.phoneNumber ?? '',
        profilePictureUrl: userCredential.user!.photoURL ?? '',

      );
      // save the user details to the database
      // you can use Firestore or Realtime Database for this
      await firestore.collection('users').doc(user.id).set(user.toJson());
    return user;
    } catch (e) {
      // handle error
      throw Exception('Failed to login: $e');
      
    }
  }
  @override
  Future<void> LogOut() async {
  await firebaseAuth.signOut();
  // handle any additional logout logic here
  }
  @override
  Future<AppUser> GetCurrentUser() async {
   // get the current user from Firebase
   final firebaseUser = firebaseAuth.currentUser;
    if (firebaseUser != null) {
      // if the user is signed in, return their details
      return AppUser(
        id: firebaseUser.uid,
        name: '',
        email: firebaseUser.email ?? '',
        phoneNumber: firebaseUser.phoneNumber ?? '',
        profilePictureUrl: firebaseUser.photoURL ?? '',
      );
    } else {
      // if the user is not signed in, return null or throw an error
      throw Exception('No user is currently signed in');
    }
  }

}
// UnimplementedError() mean? It's a placeholder saying: "Hey, I will write the real code later!"