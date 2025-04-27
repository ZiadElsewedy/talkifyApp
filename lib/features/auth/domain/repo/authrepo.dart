import 'package:talkifyapp/features/auth/domain/entities/AppUser.dart';

// all opration for auth
abstract class AuthRepo {
  Future<AppUser> loginWithEmailPassword({
    required String email,
    required String password,
  });

  Future<AppUser> registerWithEmailPassword({
    required String email,
    required String password,
  });

  Future<void> LogOut();

  Future<AppUser> GetCurrentUser();
}