import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/AuthStates.dart';
import 'package:talkifyapp/features/auth/domain/entities/AppUser.dart';
import 'package:talkifyapp/features/auth/domain/repo/authrepo.dart';

/// AuthCubit: Manages authentication-related states and actions
class AuthCubit extends Cubit<AuthStates> {
  // Auth repository to perform backend operations (login, register, etc.)
  final AuthRepo authRepo;

  // The currently authenticated user, if any
  AppUser? user;

  // Constructor: Requires AuthRepo and sets the initial state
  AuthCubit(this.authRepo) : super(AuthInitialState());

  /// Check if the user is currently authenticated
  void checkAuth() async {
    try {
      emit(AuthLoadingState()); // Show loading while checking auth
      final AppUser? user = await authRepo.GetCurrentUser(); // Get current user
      if (user != null) {
        this.user = user;
        emit(Authanticated('User is authenticated')); // Emit success if user exists
      } else {
        emit(UnAuthanticated()); // Emit unauthenticated if no user
      }
    } catch (e) {
      emit(UnAuthanticated()); // Emit unauthenticated on error
    }
  }

  /// Log in using email and password
  Future<void> login({
    required String EMAIL,
    required String PASSWORD,
  }) async {
    try {
      emit(AuthLoadingState()); // Show loading during login
      user = await authRepo.loginWithEmailPassword(
        email: EMAIL,
        password: PASSWORD,
      );
      emit(Authanticated('User is authenticated')); // Emit success after login
    } catch (e) {
      emit(AuthErrorState(e.toString())); // Emit error if login fails
    }
  }

  /// Register a new user using name, email, and password
  Future<void> register({
    required String NAME,
    required String EMAIL,
    required String PASSWORD,
  }) async {
    try {
      emit(AuthLoadingState()); // Show loading during registration
      user = await authRepo.registerWithEmailPassword(
        email: EMAIL,
        password: PASSWORD,
      );
      emit(Authanticated('User is authenticated')); // Emit success after registration
    } catch (e) {
      emit(AuthErrorState(e.toString())); // Emit error if registration fails
    }
  }

  /// Log out the currently authenticated user
  Future<void> logout() async {
    try {
      emit(AuthLoadingState()); // Show loading during logout
      await authRepo.LogOut();
      emit(UnAuthanticated()); // Emit unauthenticated after logout
    } catch (e) {
      emit(AuthErrorState(e.toString())); // Emit error if logout fails
    }
  }
}
