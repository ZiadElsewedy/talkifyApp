// this code for drawer 
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/MyDrawerTile.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        
        child:  
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Icon(Icons.person, size: 80, color: const Color.fromARGB(255, 92, 89, 89)),
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
            onTap: () {
              context.read<AuthCubit>().logout();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Logged out successfully'),
                  backgroundColor: Colors.green,
                ));
              // Handle logout tap
            },
          ),
           ],
            ),
          ),
      ),
    );
  }
}