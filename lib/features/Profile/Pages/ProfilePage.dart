import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Profile/presentation/Cubits/ProfileCubit.dart';
import 'package:talkifyapp/features/Profile/presentation/Profile_states.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/LOADING!.dart';
import 'package:talkifyapp/features/auth/domain/entities/AppUser.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.userId});
  final String? userId; // Optional user ID parameter for the profile page
  // Constructor to initialize the user ID if needed
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late AuthCubit authCubit;
  late ProfileCubit profileCubit;
  late AppUser? currentUser;

  @override
  void initState() {
    super.initState();
    authCubit = BlocProvider.of<AuthCubit>(context);
    profileCubit = BlocProvider.of<ProfileCubit>(context);
    profileCubit.fetchUserProfile(widget.userId!);
    // Fetch the current user from the AuthCubit
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileStates>(
      builder: (context, state) {
        if (state is ProfileLoadedState) {
          final user = state.profileuser;
          return Scaffold(
            appBar: AppBar(
              title:  Text(user.name , style: const TextStyle(color: Color.fromARGB(255, 95, 95, 95)),),
              centerTitle: true,
              
            ),
            body: Column(
              children: [
                Center(
                  child: Text(user.email , style: const TextStyle(color: Color.fromARGB(255, 95, 95, 95), fontSize: 20 , ) ,),
                )
              ],
            ) ,
          );
        } else if (state is ProfileLoadingState) {
          return const Center(
            child: ProfessionalCircularProgress(),
          );
        } else if (state is ProfileErrorState) {
          return Center(
            child: Text(state.error),
          );
        }
        // Default return to satisfy the linter
        return const SizedBox.shrink();
      },
    );
  }
}