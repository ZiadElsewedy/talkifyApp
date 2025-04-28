import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/AuthStates.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/AuthPage.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/Posts/HomePage.dart';
import 'package:talkifyapp/features/auth/data/FireBase_Auth_repo.dart';
// things need to do ! 
// 1. add firebase options
// bloc providers for state management
// - auth 
// - chat 
// profile 
// search 
// Theme






class MyApp extends StatelessWidget {
   MyApp({super.key});
  final authRepo = FirebaseAuthRepo();
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // provide the auth cubit to the widget tree
      // this cubit will handle the authentication process

      create: (context) => AuthCubit(authRepo)..checkAuth(),

      child: MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Talkify',
      home: BlocBuilder<AuthCubit, AuthStates>(
        builder: (context, state) {
          if (state is Authanticated) {
            return const HomePage();
          } else if (state is UnAuthanticated) {
            return AuthPage();
          } else if (state is AuthLoadingState) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else if (state is AuthErrorState) {
            return Scaffold(
              body: Center(
                child: Text(state.error),
              ),
            );
          }
          print('state is $state');
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      )
    ),
    );
  }
}