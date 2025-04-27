import 'package:firebase_auth/firebase_auth.dart';
import 'package:talkifyapp/features/auth/domain/repo/authrepo.dart';

class FirebaseAuthRepo implements AuthRepo {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;


  @override
  Future<void> loginWithEmailPassword({required String email, required String password}) async {
    try {
      // attempt to sign in the user with email and password
      UserCredential userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      
    }
    throw UnimplementedError();
  }
  @override
  Future<void> registerWithEmailPassword({required String email, required String password}) {
    // TODO: implement registerWithEmailPassword
    throw UnimplementedError();
  }
  @override
  Future<void> LogOut() {
    // TODO: implement LogOut
    throw UnimplementedError();
  }
  @override
  Future<void> GetCurrentUser() {
    // TODO: implement GetCurrentUser
    throw UnimplementedError();
  }
}
// UnimplementedError() mean? It’s a placeholder saying: "Hey, I will write the real code later!"