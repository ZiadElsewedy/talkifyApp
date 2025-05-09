import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/Storage/Data/Filebase_Storage_repo.dart';
import 'package:talkifyapp/Storage/Domain/Storage_repo.dart';
import 'package:talkifyapp/features/Profile/data/Firebase_profile_repo.dart';
import 'package:talkifyapp/features/Profile/presentation/Cubits/ProfileCubit.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/AuthStates.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/AuthPage.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/Posts/HomePage.dart';
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
  final FirebaseprofileRepo =  FirebaseProfileRepo();
  final FirebasestorageRepo = FirebaseStorageRepo();
  final FirebaseauthRepo = FirebaseAuthRepo();
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
                content: Text("Invalid Password or Email ! "),
                backgroundColor: Colors.red,
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
            return const HomePage();
          } else if (state is UnAuthanticated) {
            return AuthPage();
          } else if (state is AuthLoadingState) {
            return const Scaffold(
              body: Center(
                child: ProfessionalCircularProgress(
                  
                ),
              ),
            );
          } else if (state is AuthErrorState) {
            return AuthPage(); // Return to auth page on error
          }
          print('state is $state');
          return const Scaffold(
            body: Center(
              child: ProfessionalCircularProgress(
                // This is a custom loading widget
                // You can replace it with your own loading widget
              ),
            ),
          );
          
        }
        
      )
      
    ),
     
     );
  }
}
