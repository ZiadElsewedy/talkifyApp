// step 4 : create the auth states
// the states will define the different states of the authentication process
// auth states
abstract class AuthStates {}

// initial state
class AuthInitialState extends AuthStates {}

// loading state
class AuthLoadingState extends AuthStates {}

// email verification state
class EmailVerificationState extends AuthStates {
  final String message;
  EmailVerificationState(this.message);
}

// email verified state
class EmailVerifiedState extends AuthStates {
  final String message;
  EmailVerifiedState(this.message);
}

// unverified state
class UnverifiedState extends AuthStates {
  final String message;
  UnverifiedState(this.message);
}

// authenticated state
class Authanticated extends AuthStates {
  final String message;
  Authanticated(this.message);
}

// unauthenticated state
class UnAuthanticated extends AuthStates {}

// error state
class AuthErrorState extends AuthStates {
  final String error;
  AuthErrorState(this.error);
}
