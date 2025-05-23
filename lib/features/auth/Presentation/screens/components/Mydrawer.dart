// this code for drawer 
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/components/ProfilePicFunction.dart';
import 'package:talkifyapp/features/Search/Presentation/SearchPage.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/chat_list_page.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/ProfilePage.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/ConfirmLogOut.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/MyDrawerTile.dart';
import 'package:talkifyapp/features/Profile/presentation/Cubits/ProfileCubit.dart';
import 'package:talkifyapp/features/Profile/presentation/Cubits/Profile_states.dart';
 
class MyDrawer extends StatefulWidget {
  const MyDrawer({super.key});

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  @override
  void initState() {
    super.initState();
    refreshProfile();
  }

  void refreshProfile() {
    if (!mounted) return;
    final currentUser = context.read<AuthCubit>().GetCurrentUser();
    if (currentUser != null) {
      context.read<ProfileCubit>().fetchUserProfile(currentUser.id);
    }
  }

  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              BlocBuilder<ProfileCubit, ProfileStates>(
                builder: (context, state) {
                  return ProfilePicFunction(
                    state: state,
                    profilePictureUrl: state is ProfileLoadedState ? state.profileuser.profilePictureUrl : null,
                  );
                },
              ),
              const SizedBox(height: 30),
              Divider(
                color: Color.fromARGB(255, 92, 89, 89),
                thickness: 1.5,
              ), 
              MyDrawerTile(
                icon: Icons.home,
                title: 'H O M E',
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
              MyDrawerTile(
                icon: Icons.person,
                title: 'P R O F I L E',
                onTap: () {
                  final user = context.read<AuthCubit>().GetCurrentUser();
                  final uid = user!.id;
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProfilePage(userId: uid),
                    ),
                  ).then((_) {
                    refreshProfile();
                  });
                },
              ),
              MyDrawerTile(
                icon: Icons.chat,
                title: 'C H A T S',
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ChatListPage(),
                    ),
                  ).then((_) {
                    refreshProfile();
                  });
                },
              ),
              MyDrawerTile(
                icon: Icons.search,
                title: 'S E A R C H',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => SearchPage()),
                  ).then((_) {
                    refreshProfile();
                  });
                },
              ),
              MyDrawerTile(
                icon: Icons.settings,
                title: 'S E T T I N G S',
                onTap: () {
                  // Handle settings tap
                },
              ),
              MyDrawerTile(
                icon: Icons.info_outline,
                title: 'A B O U T',
                onTap: () {
                  // Handle about tap
                },
              ),
              const Spacer(),
              MyDrawerTile(
                icon: Icons.logout,
                title: 'L O G O U T',
                onTap: () async {
                  final shouldLogout = await showConfirmLogoutDialog(context);
                  if (shouldLogout == true) {
                    context.read<AuthCubit>().logout();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Logged out successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}