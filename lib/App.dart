import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Storage/Data/Filebase_Storage_repo.dart';
import 'package:talkifyapp/features/Profile/data/Firebase_profile_repo.dart';
import 'package:talkifyapp/features/Profile/presentation/Cubits/ProfileCubit.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/AuthStates.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/Auth_screens/AuthPage.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/Posts/presentation/HomePage.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/Auth_screens/VerificationEmail.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/Posts/data/firebase_post_repo.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/Posts/presentation/cubits/post_cubit.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/LOADING!.dart';
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
   // 
  final FirebaseprofileRepo =  FirebaseProfileRepo();
  final FirebasestorageRepo = FirebaseStorageRepo();
  final FirebaseauthRepo = FirebaseAuthRepo();
  final firebasePostRepo = FirebasePostRepo();
  // Initialize the ProfileRepo
  // Initialize the AuthRepo
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (context) => AuthCubit(FirebaseauthRepo)..checkAuth(),
        ),
        BlocProvider<ProfileCubit>(
          create: (context) => ProfileCubit(
            profileRepo: FirebaseprofileRepo,
            Storage: FirebasestorageRepo ) // Pass the StorageRepo to ProfileCubit),
           // Pass the authRepo to ProfileCubit
        ),

        // post cubit 
        BlocProvider<PostCubit>(
          create: (context) => PostCubit(postRepo: firebasePostRepo, storageRepo: FirebasestorageRepo)
        )
      ],
    
     child: MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Talkify',
      home: BlocConsumer<AuthCubit, AuthStates>(
        // listen to the auth cubit state changes
        // this will be used to show the snackbar when there is an error
        listener: (context, state) {
          if (state is AuthErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          } else if (state is UnverifiedState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          } else if (state is EmailVerificationState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 3),
              ),
            );
          } else if (state is Authanticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is Authanticated) {
            return  HomePage();
          } else if (state is UnverifiedState || state is EmailVerificationState) {
            return const VerificationEmail();
          } else if (state is UnAuthanticated || state is AuthErrorState) {
            return const AuthPage();
          } else if (state is AuthLoadingState) {
            return const Scaffold(
              body: Center(
                child: ProfessionalCircularProgress(),
              ),
            );
          }
          return const AuthPage();
        }
      )
    ));
  }
}
