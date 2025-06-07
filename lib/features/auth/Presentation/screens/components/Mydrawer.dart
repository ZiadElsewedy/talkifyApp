// this code for drawer 
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/News/Data/news_repository_impl.dart';
import 'package:talkifyapp/features/News/Presentation/Cubit/news_cubit.dart';
import 'package:talkifyapp/features/News/Presentation/pages/news_page.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/components/ProfilePicFunction.dart';
import 'package:talkifyapp/features/Search/Presentation/SearchPage.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/chat_list_page.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/ProfilePage.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/ConfirmLogOut.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/MyDrawerTile.dart';
import 'package:talkifyapp/features/Profile/presentation/Cubits/ProfileCubit.dart';
import 'package:talkifyapp/features/Profile/presentation/Cubits/Profile_states.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/About/AboutPage.dart';
import 'package:talkifyapp/features/Posts/pages/SavedPostsPage.dart';
import 'package:talkifyapp/features/Posts/presentation/HomePage.dart';
import 'package:talkifyapp/features/Settings/SettingsPage.dart';

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
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDarkMode ? Colors.grey[700] : Color.fromARGB(255, 92, 89, 89);
    
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Header section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  BlocBuilder<ProfileCubit, ProfileStates>(
                    builder: (context, state) {
                      return ProfilePicFunction(
                        state: state,
                        profilePictureUrl: state is ProfileLoadedState ? state.profileuser.profilePictureUrl : null,
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            
            Divider(
              color: dividerColor,
              thickness: 1.5,
              height: 1,
            ),
            
            // Scrollable menu items
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  children: [
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
                      icon: Icons.newspaper,
                      title: 'N E W S',
                      onTap: () {
                        Navigator.of(context).pop();
                        
                        // Create the NewsRepositoryImpl instance
                        final newsRepository = NewsRepositoryImpl();
                        
                        // Navigate to the NewsPage with NewsCubit provider
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => BlocProvider(
                              create: (context) => NewsCubit(
                                newsRepository: newsRepository,
                              ),
                              child: const NewsPage(),
                            ),
                          ),
                        );
                      },
                    ),
                    MyDrawerTile(
                      icon: Icons.bookmark,
                      title: 'S A V E D   P O S T S',
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SavedPostsPage(),
                          ),
                        );
                      },
                    ),
                    MyDrawerTile(
                      icon: Icons.chat,
                      title: 'C H A T S',
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const ChatListPage(),
                          ),
                        );
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
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SettingsPage(),
                          ),
                        );
                      },
                    ),
                    MyDrawerTile(
                      icon: Icons.info_outline,
                      title: 'A B O U T',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AboutPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // Logout button at bottom
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Column(
                children: [
                  Divider(
                    color: dividerColor,
                    thickness: 1,
                    height: 1,
                  ),
                  MyDrawerTile(
                    icon: Icons.logout,
                    title: 'L O G O U T',
                    iconColor: isDarkMode ? Colors.redAccent[100] : Colors.red[700],
                    textColor: isDarkMode ? Colors.redAccent[100] : Colors.red[700],
                    onTap: () async {
                      final shouldLogout = await showConfirmLogoutDialog(context);

                      if (shouldLogout == true) {
                        try {
                          // Show loading indicator
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Logging out...'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                          
                          // Perform logout
                          await context.read<AuthCubit>().logout();
                          
                          // Force immediate navigation to the auth page
                          if (mounted) {
                            // Clear the entire navigation stack and go to first route (auth page)
                            Navigator.of(context).popUntil((route) => route.isFirst);
                            
                            // If that doesn't work, try pushing a replacement route
                            // This is a fallback approach
                            if (mounted) {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                '/', // Root route - usually your auth page
                                (route) => false, // Remove all previous routes
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Logout failed: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}