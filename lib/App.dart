import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/components/WhiteCircleIndicator.dart';
import 'package:talkifyapp/features/Search/Data/Firebase_search_repo.dart';
import 'package:talkifyapp/features/Search/Presentation/Cubit/Search_cubit.dart';
import 'package:talkifyapp/features/Storage/Data/Filebase_Storage_repo.dart';
import 'package:talkifyapp/features/Profile/data/Firebase_profile_repo.dart';
import 'package:talkifyapp/features/Profile/presentation/Cubits/ProfileCubit.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/AuthStates.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/Auth_screens/AuthPage.dart';
import 'package:talkifyapp/features/Posts/presentation/HomePage.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/Auth_screens/VerificationEmail.dart';
import 'package:talkifyapp/features/Posts/data/firebase_post_repo.dart';
import 'package:talkifyapp/features/Posts/presentation/cubits/post_cubit.dart';
import 'package:talkifyapp/features/auth/data/FireBase_Auth_repo.dart';
import 'package:talkifyapp/features/Chat/Data/firebase_chat_repo.dart';
import 'package:talkifyapp/features/Chat/persentation/Cubits/chat_cubit.dart';
import 'package:talkifyapp/features/Chat/Utils/audio_handler.dart';

import 'package:talkifyapp/features/Welcome/welcome_page.dart';
import 'package:talkifyapp/theme/Cubits/theme_cubit.dart';
import 'package:talkifyapp/features/Notifcations/data/notification_repository_impl.dart';
import 'package:talkifyapp/features/Notifcations/presentation/cubit/notification_cubit.dart';


// things need to do ! 
// 1. add firebase options
// bloc providers for state management
// - auth 
// - chat 
// - profile 
// - search 
// - notifications ✓
// Theme

/// Main application widget that sets up dependencies and app structure
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _audioHandler = AudioHandler();
  final _firebaseAuthRepo = FirebaseAuthRepo();
  final _firebaseChatRepo = FirebaseChatRepo();
  final _firebasePostRepo = FirebasePostRepo();
  // Repository instances
  final _firebaseProfileRepo = FirebaseProfileRepo();

  final _firebaseSearchRepo = FirebaseSearchRepo();
  final _firebaseStorageRepo = FirebaseStorageRepo();
  final _notificationRepositoryImpl = NotificationRepositoryImpl();
  // Key for SnackBar management
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  /// Shows a SnackBar with the given message and color
  void _showSnackBar(String message, Color backgroundColor) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: backgroundColor == Colors.orange || backgroundColor == Colors.red 
            ? backgroundColor 
            : Colors.black,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        
        margin: const EdgeInsets.only(
            bottom: 10, // Position under the bottom navigation bar but below New Post button
            left: 16,
            right: 16,
           
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(
          create: (context) => ThemeCubit(),
        ),
        BlocProvider<AuthCubit>(
          create: (context) => AuthCubit(_firebaseAuthRepo)..checkAuth(),
        ),
        BlocProvider<ProfileCubit>(
          create: (context) => ProfileCubit(
            profileRepo: _firebaseProfileRepo,
            Storage: _firebaseStorageRepo,
          ),
        ),
        BlocProvider<PostCubit>(
          create: (context) => PostCubit(
            postRepo: _firebasePostRepo, 
            storageRepo: _firebaseStorageRepo,
          ),
        ),
        BlocProvider<SearchCubit>(
          create: (context) => SearchCubit(
            searchRepo: _firebaseSearchRepo,
          ),
        ),
        BlocProvider<ChatCubit>(
          create: (context) {
            final cubit = ChatCubit(chatRepo: _firebaseChatRepo);
            // Wrap in try-catch to prevent crashes during initialization
            try {
              cubit.initialize();
            } catch (e) {
              print('Failed to initialize chat: $e');
            }
            return cubit;
          },
        ),
        BlocProvider<NotificationCubit>(
          create: (context) => NotificationCubit(
            notificationRepository: _notificationRepositoryImpl,
          ),
        ),
      ],
    

      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return WillPopScope(
            // Dispose all audio players when app is about to exit
            onWillPop: () async {
              try {
                _audioHandler.disposeAllPlayers();
              } catch (e) {
                print('Error disposing audio players: $e');
              }
              return true;
            },

              child: MaterialApp(
              scaffoldMessengerKey: _scaffoldMessengerKey,
              debugShowCheckedModeBanner: false,
              title: 'Talkify',
              theme: context.read<ThemeCubit>().themeData,
              home: BlocConsumer<AuthCubit, AuthStates>(
                // Listen to the auth cubit state changes
                listener: (context, state) {
                  // Hide any previous SnackBar to prevent multiple SnackBars error
                  _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
                  
                  if (state is AuthErrorState) {
                    _showSnackBar(state.error, Colors.red);
                  } else if (state is UnverifiedState) {
                    _showSnackBar(state.message, Colors.orange);
                  } else if (state is EmailVerificationState) {
                    _showSnackBar(state.message, Colors.blue);
                  } else if (state is Authanticated) {
                    _showSnackBar("Welcome back", Colors.green);
                  }
                },
                builder: (context, state) {
                  if (state is Authanticated) {
                    return const WelcomePage(); // Show welcome page instead of directly going to HomePage
                  } else if (state is UnverifiedState || state is EmailVerificationState) {
                    return const VerificationEmail();
                  } else if (state is UnAuthanticated || state is AuthErrorState) {
                    return const AuthPage();
                  } else if (state is AuthLoadingState) {
                    return const Scaffold(
                      body: Center(
                        child: PercentCircleIndicator(),
                      ),
                    );
                  }
                  return const AuthPage();
                }
              ),
            ),
          );
        }

      ),
    );
  }
}
