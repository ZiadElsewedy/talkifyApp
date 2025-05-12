import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/AuthStates.dart';
import 'package:talkifyapp/features/auth/domain/entities/AppUser.dart';
import 'package:talkifyapp/features/auth/domain/repo/authrepo.dart';
// step 3 : create the auth cubit
// the cubit will manage the authentication-related states and actions
/// AuthCubit: Manages authentication-related states and actions
class AuthCubit extends Cubit<AuthStates> {
  // Auth repository to perform backend operations (login, register, etc.)
  // ana baklm el auth repo bl cubit 
  final AuthRepo authRepo;

  // The currently authenticated user, if any
  AppUser? user;

  // Constructor: Requires AuthRepo and sets the initial state
  AuthCubit(this.authRepo) : super(AuthInitialState());

  /// Check if the user is currently authenticated
  void checkAuth() async {
    try {
      emit(AuthLoadingState());
      final AppUser? user = await authRepo.GetCurrentUser();
      if (user != null) {
        this.user = user;
        if (authRepo.currentUser?.emailVerified == true) {
          emit(Authanticated('User is authenticated'));
        } else {
          emit(UnverifiedState('Please verify your email to continue'));
        }
      } else {
        emit(UnAuthanticated());
      }
    } catch (e) {
      emit(AuthErrorState('Failed to check authentication: $e'));
    }
  }

  /// Log in using email and password
  Future<void> login({
    required String EMAIL,
    required String PASSWORD,
  }) async {
    try {
      emit(AuthLoadingState());
      user = await authRepo.loginWithEmailPassword(
        email: EMAIL,
        password: PASSWORD,
      );
      
      if (user == null) {
        emit(UnAuthanticated());
        return;
      }
      
      if (authRepo.currentUser?.emailVerified == true) {
        emit(Authanticated('User is authenticated'));
      } else {
        emit(UnverifiedState('Please verify your email to continue'));
      }
    } catch (e) {
      emit(UnAuthanticated());
      emit(AuthErrorState('Invalid email or password'));
    }
  }

  /// Register a new user using name, email, and password
  Future<void> register({
    required String NAME,
    required String EMAIL,
    required String PASSWORD,
    required String CONFIRMPASSWORD,
    required String PHONENUMBER,
  }) async {
    try {
      emit(AuthLoadingState());

      // Register user
      user = await authRepo.registerWithEmailPassword(
        phoneNumber: PHONENUMBER,
        email: EMAIL,
        password: PASSWORD,
        name: NAME,
      );

      // Save user data to Firestore immediately with isVerified = false
      if (user != null) {
        await authRepo.saveUserToFirestore(user!);
      }

      // Send verification email
      
      // Emit UnverifiedState instead of EmailVerificationState
      emit(UnverifiedState('Please verify your email to continue. Check your inbox for the verification link.'));

    } catch (e) {
      emit(AuthErrorState('Registration failed: $e'));
    }
  }

  Future<void> checkEmailVerification() async {
    try {
      emit(AuthLoadingState());
      await authRepo.checkEmailVerification();
      
      if (authRepo.currentUser?.emailVerified == true) {
        // Update user data in Firestore to mark as verified
        if (user != null) {
          await authRepo.updateUserVerificationStatus(user!);
        }
        emit(EmailVerifiedState('Email verified successfully!'));
        emit(Authanticated('Welcome to Talkify!'));
      } else {
        emit(UnverifiedState('Email not yet verified. Please check your inbox and click the verification link.'));
      }
    } catch (e) {
      emit(AuthErrorState("Failed to check verification: $e"));
    }
  }

  Future<void> sendVerificationEmail() async {
    try {
      emit(AuthLoadingState());
      await authRepo.sendVerificationEmail();
      emit(EmailVerificationState('Verification email resent. Please check your inbox.'));
    } catch (e) {
      emit(AuthErrorState("Failed to resend verification email: $e"));
    }
  }

  /// Log out the currently authenticated user
  Future<void> logout() async {
    try {
      emit(AuthLoadingState());
      await authRepo.LogOut();
      user = null;
      emit(UnAuthanticated());
    } catch (e) {
      emit(AuthErrorState('Logout failed: $e'));
    }
  }
  /// Get the currently authenticated user
  AppUser? GetCurrentUser() {
    return user; // Return the current user
  }
}
