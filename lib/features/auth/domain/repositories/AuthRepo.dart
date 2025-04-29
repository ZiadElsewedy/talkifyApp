import 'package:talkifyapp/features/auth/domain/entities/AppUser.dart';

abstract class AuthRepo {
  Future<AppUser> registerWithEmailPassword({
    required String email, 
    required String password,
    required String name,
  });
  Future<AppUser> loginWithEmailPassword({required String email, required String password});
  Future<void> logout();
  Future<AppUser?> getCurrentUser();
} 