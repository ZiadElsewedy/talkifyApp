// all opration for auth
abstract class AuthRepo {
  Future<void> loginWithEmailPassword({
    required String email,
    required String password,
  });

  Future<void> registerWithEmailPassword({
    required String email,
    required String password,
  });

  Future<void> LogOut();

Future<void> GetCurrentUser();
}