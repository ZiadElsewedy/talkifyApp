import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Profile/presentation/Cubits/ProfileCubit.dart';
import 'package:talkifyapp/features/Profile/presentation/Profile_states.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/LOADING!.dart';
import 'package:talkifyapp/features/auth/domain/entities/AppUser.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.userId});
  final String? userId; // Optional user ID parameter for the profile page
  // Constructor to initialize the user ID if needed

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final authCubit = context.read<AuthCubit>(); // Initialize the AuthCubit
  late final profileCubit = context.read<ProfileCubit>(); // Initialize the ProfileCubit
  // current User !
  late AppUser? CurrentUser = authCubit.GetCurrentUser(); // Get the current user
  
 // on init method
 @override
  void initState() {
    super.initState();
    // Fetch the user profile when the widget is initialized
    if (widget.userId != null) {
      // load the user profile first 
      profileCubit.fetchUserProfile(widget.userId!);
    } else {
      // Handle the case where userId is null if needed
      print('User ID is null');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(CurrentUser!.email),
        foregroundColor: const Color.fromARGB(255, 111, 111, 111), // Display the user's name or 'Profile'
        centerTitle: true,
      ),
      body: BlocBuilder<ProfileCubit, ProfileStates>(
        builder: (context, state) {
          if (state is ProfileLoadingState) {
            return const Center(child: ProfessionalCircularProgress());
          } else if (state is ProfileLoadedState) {
            final user = state.user;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(user.profilePictureUrl),
                  ),
                  const SizedBox(height: 20),
                  Text(user.name, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 10),
                  Text(user.bio, style: const TextStyle(fontSize: 16)),
                ],
              ),
            );
          } else if (state is ProfileErrorState) {
            return Center(child: Text(state.error));
          }
          return const Center(child: Text('No profile data available.'));
        },
      ),
    );
  }
}