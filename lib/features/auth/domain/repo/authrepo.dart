import 'package:talkifyapp/features/auth/domain/entities/AppUser.dart';
// step 1 : create the auth repo interface
// the interface will define all the operations that can be performed on the auth service
// all opration for auth
abstract class AuthRepo {
  Future<AppUser> loginWithEmailPassword({
    required String email,
    required String password,
  });

  Future<AppUser> registerWithEmailPassword({
    required String email,
    required String password,
    required String name,
  });

  Future<void> LogOut();

  Future<AppUser> GetCurrentUser();
}