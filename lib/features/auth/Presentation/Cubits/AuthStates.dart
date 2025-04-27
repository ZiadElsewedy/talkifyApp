// auth states
abstract class AuthStates {}
// initial state
class AuthInitialState extends AuthStates {}
// loading state
class AuthLoadingState extends AuthStates {}
// login state

class Authanticated extends AuthStates {
  final String message;
  Authanticated(this.message);
}
class UnAuthanticated extends AuthStates {}

// error state
class AuthErrorState extends AuthStates {
  final String error;
  AuthErrorState(this.error);
}
