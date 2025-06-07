import 'package:firebase_auth/firebase_auth.dart';
import 'package:talkifyapp/features/auth/domain/entities/AppUser.dart';
// step 1 : create the auth repo interface
// the interface will define all the operations that can be performed on the auth service
// all opration for auth
abstract class AuthRepo {
  Future<AppUser?> GetCurrentUser();

  Future<AppUser> loginWithEmailPassword({
    required String email,
    required String password,
  });

  Future<AppUser> registerWithEmailPassword({
    required String phoneNumber,
    required String email,
    required String password,
    required String name,
  });

  Future<void> LogOut();

  Future<void> sendVerificationEmail();

  Future<void> checkEmailVerification();

  Future<void> saveUserToFirestore(AppUser user);

  Future<void> updateUserVerificationStatus(AppUser user);

  Future<void> deleteAccount(String password);

  User? get currentUser;
}