// this code for drawer 
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/Profile/Pages/ProfilePage.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/ConfirmLogOut.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/LOADING!.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/MyDrawerTile.dart';
import 'package:talkifyapp/features/Profile/presentation/Cubits/ProfileCubit.dart';
import 'package:talkifyapp/features/Profile/presentation/Cubits/Profile_states.dart';
 
class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the current user ID
    final currentUser = context.read<AuthCubit>().GetCurrentUser();
    if (currentUser != null) {
      // Fetch the user profile when drawer is built
      context.read<ProfileCubit>().fetchUserProfile(currentUser.id);
    }

    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        
        child:  
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                BlocBuilder<ProfileCubit, ProfileStates>(
                  builder: (context, state) {
                    if (state is ProfileLoadedState) {
                      return Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[200],
                        ),
                        child: ClipOval(
                          child: state.profileuser.profilePictureUrl.isNotEmpty
                              ? Image.network(
                                  state.profileuser.profilePictureUrl,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: ProfessionalCircularProgress(),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.person, size: 50, color: Colors.grey[400]);
                                  },
                                )
                              : Icon(Icons.person, size: 50, color: Colors.grey[400]),
                        ),
                      );
                    } else if (state is ProfileLoadingState) {
                      return Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[200],
                        ),
                        child: const Center(
                          child: ProfessionalCircularProgress(),
                        ),
                      );
                    } else {
                      return Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[200],
                        ),
                        child: Icon(Icons.person, size: 50, color: Colors.grey[400]),
                      );
                    }
                  },
                ),
                const SizedBox(height: 30),
                Divider(
                  color:Color.fromARGB(255, 92, 89, 89),
                  thickness: 1.5,
                ), 
          MyDrawerTile(
            icon: Icons.home,
            title: 'H O M E',
            onTap: () {
              // Handle home tap
              Navigator.of(context).pop(); // Close the drawer
            },
          ),
          MyDrawerTile(
            icon: Icons.person,
            title: 'P R O F I L E',
            onTap: () {
              // we need to get the current user id
              final user = context.read<AuthCubit>().GetCurrentUser();
              final uid = user!.id;
              Navigator.of(context).pop();
              // Navigate to the profile page
              // You can pass the user ID if needed
              Navigator.of(context).push( MaterialPageRoute(builder: (context) => ProfilePage(
                userId: uid,
              )),
              );
              // Handle profile tap
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
          Spacer(),
          MyDrawerTile(
            icon: Icons.logout,
            title: 'L O G O U T',
            onTap: () async {
              final shouldLogout = await showConfirmLogoutDialog(context);
              if (shouldLogout == true) {
                context.read<AuthCubit>().logout();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Logged out successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
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