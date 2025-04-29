// this code for drawer 
import 'package:flutter/material.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/MyDrawerTile.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person, size: 80, color: const Color.fromARGB(255, 92, 89, 89)),
                SizedBox(height: 10),
                Text(
                  'User Name',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          MyDrawerTile(
            icon: Icons.home,
            title: 'Home',
            onTap: () {
              // Handle home tap
            },
          ),
          MyDrawerTile(
            icon: Icons.person,
            title: 'Profile',
            onTap: () {
              // Handle profile tap
            },
          ),
          MyDrawerTile(
            icon: Icons.settings,
            title: 'Settings',
            onTap: () {
              // Handle settings tap
            },
          ),
          MyDrawerTile(
            icon: Icons.info_outline,
            title: 'About',
            onTap: () {
              // Handle about tap
            },
          ),
          MyDrawerTile(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () {
              // Handle logout tap
            },
          ),
        ],
      ),
    );
  }
}