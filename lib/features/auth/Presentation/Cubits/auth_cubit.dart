// auth cubit = state management
// HOW ITS WORKS
// Cubit	Class that manages one simple piece of state
// emit()	Tell Flutter: "Hey, here's a new state!" 
// BlocProvider	Makes a Cubit available to widgets
//BlocBuilder	Rebuilds UI based on Cubit's state changes 
// BlocListener	Responds to Cubit's state changes (e.g., show a snackbar)
// BlocConsumer	Combines BlocBuilder and BlocListener 
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/AuthStates.dart';
import 'package:talkifyapp/features/auth/domain/entities/AppUser.dart';
import 'package:talkifyapp/features/auth/domain/repo/authrepo.dart';

class AuthCubit extends Cubit<AuthStates> {
  // auth repo
  // this is the repository that will be used to authenticate the user
  // it will be used to call the methods in the repository
  // and return the result to the cubit
  
  final AuthRepo authRepo;

  
  
  AppUser? user;
// constructor
  // this is the constructor that will be used to initialize the cubit
  // it will take the auth repo as a parameter
  // and call the super constructor with the initial state
  AuthCubit(this.authRepo) : super(AuthInitialState());
  // check if the user is authenticated
  void checkAuth() async {
    emit(AuthLoadingState());
    final AppUser? user = await authRepo.GetCurrentUser();
    if (user != null) {
      emit(Authanticated('User is authenticated'));
    } else {
      emit(UnAuthanticated());
    }
  }

  Future<void> login({
    required String EMAIL,
    required String PASSWORD,
  }) async {
    try {
      emit(AuthLoadingState());
      // call the login method in the auth repo
      user = await authRepo.loginWithEmailPassword(
        email: EMAIL,
        password: PASSWORD,
      );
      emit(Authanticated('User is authenticated'));
    } catch (e) {
      emit(AuthErrorState(e.toString()));
    }
  }

  // register with email and password
  Future<void> register({
    required String NAME,
    required String EMAIL,
    required String PASSWORD,
  }) async {
    try {
      emit(AuthLoadingState());
      // call the register method in the auth repo
      user = await authRepo.registerWithEmailPassword(
        email: EMAIL,
        password: PASSWORD,
      );
      emit(Authanticated('User is authenticated'));
    } catch (e) {
      emit(AuthErrorState(e.toString()));
    }
  }
  // logout
  Future<void> logout() async {
    // call the logout method in the auth repo
    // and emit the unauthenticated state
    // this will be used to log out the user
    try {
      emit(AuthLoadingState());
      await authRepo.LogOut();
      emit(UnAuthanticated());
    } catch (e) {
      emit(AuthErrorState(e.toString()));
    }
  }
}
  // login with email and password
  
  