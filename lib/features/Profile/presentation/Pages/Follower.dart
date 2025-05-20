// User connections page showing followers and following
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Profile/domain/entites/ProfileUser.dart';
import 'package:talkifyapp/features/Profile/presentation/Cubits/ProfileCubit.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/ProfilePage.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/components/FollowButtom.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';

/// A page that displays a user's followers and following lists
/// with the ability to follow/unfollow users and navigate to their profiles
class FollowerPage extends StatefulWidget {
  final List<String> followers;      // List of follower user IDs
  final List<String> following;      // List of following user IDs
  final VoidCallback onTapFollowers; // Callback when followers tab is tapped
  final VoidCallback onTapFollowing; // Callback when following tab is tapped
  
  const FollowerPage({
    super.key, 
    required this.followers, 
    required this.following,
    required this.onTapFollowers,
    required this.onTapFollowing,
  });

  @override
  State<FollowerPage> createState() => FollowerPageState();
}

class FollowerPageState extends State<FollowerPage> with SingleTickerProviderStateMixin {
  // Define our black and white colors explicitly
  static const Color pureBlack = Color(0xFF000000);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color lightGrey = Color(0xFFE0E0E0);
  static const Color mediumGrey = Color(0xFF757575);
  static const Color darkGrey = Color(0xFF424242);
  
  List<ProfileUser> followerUsers = [];
  List<ProfileUser> followingUsers = [];
  bool isLoading = true;
  String? currentUserId;
  bool isRefreshing = false;
  TabController? _tabController;
  String searchQuery = '';
  List<ProfileUser> filteredFollowerUsers = [];
  List<ProfileUser> filteredFollowingUsers = [];

  // Lists to store user profile data

  @override
  void initState() {
    super.initState();
    _initializeTabController();

    getCurrentUser();    // Get the current user's ID
    fetchUserDetails();  // Fetch follower and following user details
  }

  void _initializeTabController() {
    _tabController = TabController(length: 2, vsync: this);
    _tabController?.addListener(() {
      if (!_tabController!.indexIsChanging) {
        setState(() {
          // Update filtered lists when tab changes
          if (_tabController!.index == 0) {
            filteredFollowerUsers = List.from(followerUsers);
          } else {
            filteredFollowingUsers = List.from(followingUsers);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }
  
  /// Retrieves the current user's ID from the AuthCubit
  void getCurrentUser() {
    final authCubit = context.read<AuthCubit>();
    final user = authCubit.GetCurrentUser();
    if (user != null) {
      currentUserId = user.id;
    }
  }

  void filterUsers(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredFollowerUsers = followerUsers.where((user) =>
        user.name.toLowerCase().contains(searchQuery) ||
        user.email.toLowerCase().contains(searchQuery)
      ).toList();
      
      filteredFollowingUsers = followingUsers.where((user) =>
        user.name.toLowerCase().contains(searchQuery) ||
        user.email.toLowerCase().contains(searchQuery)
      ).toList();
    });
  }
  
  /// Fetches detailed profile information for all followers and following users
  Future<void> fetchUserDetails() async {
    if (isRefreshing) return;
    
    setState(() {
      isRefreshing = true;
      isLoading = true;
      followerUsers = [];
      followingUsers = [];
      filteredFollowerUsers = [];
      filteredFollowingUsers = [];
    });
    
    final profileCubit = context.read<ProfileCubit>();
    
    try {
      // Fetch follower details
      final Set<String> processedFollowerIds = {};
      for (String id in widget.followers) {
        if (processedFollowerIds.contains(id)) continue;
        
        final user = await profileCubit.GetUserProfileByUsername(id);
        if (user != null && mounted) {
          setState(() {
            followerUsers.add(user);
            processedFollowerIds.add(id);
          });
        }
      }
      
      // Fetch following details 
      final Set<String> processedFollowingIds = {};
      for (String id in widget.following) {
        if (processedFollowingIds.contains(id)) continue;
        
        final user = await profileCubit.GetUserProfileByUsername(id);
        if (user != null && mounted) {
          setState(() {
            followingUsers.add(user);
            processedFollowingIds.add(id);
          });
        }
      }

      // Initialize filtered lists
      filteredFollowerUsers = List.from(followerUsers);
      filteredFollowingUsers = List.from(followingUsers);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading users: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          isRefreshing = false;
        });
      }
    }
  }

  /// Refreshes a specific user's data in both followers and following lists
  Future<void> refreshUserData(String userId) async {
    final profileCubit = context.read<ProfileCubit>();
    
    try {
      final updatedUser = await profileCubit.GetUserProfileByUsername(userId);
      if (updatedUser != null && mounted) {
        setState(() {
          // Update in followers list
          final followerIndex = followerUsers.indexWhere((u) => u.id == userId);
          if (followerIndex != -1) {
            followerUsers[followerIndex] = updatedUser;
            
            // Also update in filtered list
            final filteredIndex = filteredFollowerUsers.indexWhere((u) => u.id == userId);
            if (filteredIndex != -1) {
              filteredFollowerUsers[filteredIndex] = updatedUser;
            }
          }
          
          // Update in following list
          final followingIndex = followingUsers.indexWhere((u) => u.id == userId);
          if (followingIndex != -1) {
            followingUsers[followingIndex] = updatedUser;
            
            // Also update in filtered list
            final filteredIndex = filteredFollowingUsers.indexWhere((u) => u.id == userId);
            if (filteredIndex != -1) {
              filteredFollowingUsers[filteredIndex] = updatedUser;
            }
          }
        });
      }
    } catch (e) {
      print('Error refreshing user data: $e');
    }
  }

  /// Handles the follow/unfollow action for a user
  /// Updates the UI optimistically and reverts changes if the API call fails
  Future<void> handleFollowToggle(ProfileUser user, bool isCurrentlyFollowing) async {
    if (currentUserId == null) return;
    
    final profileCubit = context.read<ProfileCubit>();
    
    // Store original state for rollback
    final originalFollowers = List<String>.from(user.followers);
    final originalFollowing = List<String>.from(user.following);
    
    // Optimistically update UI
    setState(() {
      if (isCurrentlyFollowing) {
        user.followers.remove(currentUserId);
        if (followingUsers.contains(user)) {
          followingUsers.removeWhere((followingUser) => followingUser.id == user.id);
          filteredFollowingUsers.removeWhere((followingUser) => followingUser.id == user.id);
        }
      } else {
        user.followers.add(currentUserId!);
        if (!followingUsers.contains(user)) {
          followingUsers.add(user);
          if (user.name.toLowerCase().contains(searchQuery) ||
              user.email.toLowerCase().contains(searchQuery)) {
            filteredFollowingUsers.add(user);
          }
        }
      }
    });
    
    try {
      await profileCubit.toggleFollow(currentUserId!, user.id);
      
      // Call the callbacks to update parent profile
      if (isCurrentlyFollowing) {
        widget.onTapFollowing();
      } else {
        widget.onTapFollowers();
      }
      
      // Refresh the user data to ensure it's up to date
      await refreshUserData(user.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCurrentlyFollowing ? 'Unfollowed successfully' : 'Followed successfully'),
            backgroundColor: pureBlack,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Revert UI changes if there's an error
      setState(() {
        // Create a new ProfileUser with the original state
        final updatedUser = ProfileUser(
          id: user.id,
          name: user.name,
          email: user.email,
          profilePictureUrl: user.profilePictureUrl,
          followers: originalFollowers,
          following: originalFollowing,
          phoneNumber: user.phoneNumber,
          bio: user.bio,
          backgroundprofilePictureUrl: user.backgroundprofilePictureUrl,
          HintDescription: user.HintDescription,
        );
        
        // Update the user in the lists
        final followerIndex = followerUsers.indexWhere((u) => u.id == user.id);
        if (followerIndex != -1) {
          followerUsers[followerIndex] = updatedUser;
          final filteredIndex = filteredFollowerUsers.indexWhere((u) => u.id == user.id);
          if (filteredIndex != -1) {
            filteredFollowerUsers[filteredIndex] = updatedUser;
          }
        }
        
        final followingIndex = followingUsers.indexWhere((u) => u.id == user.id);
        if (followingIndex != -1) {
          followingUsers[followingIndex] = updatedUser;
          final filteredIndex = filteredFollowingUsers.indexWhere((u) => u.id == user.id);
          if (filteredIndex != -1) {
            filteredFollowingUsers[filteredIndex] = updatedUser;
          }
        }
        
        if (isCurrentlyFollowing) {
          if (!followingUsers.contains(updatedUser)) {
            followingUsers.add(updatedUser);
            if (updatedUser.name.toLowerCase().contains(searchQuery) ||
                updatedUser.email.toLowerCase().contains(searchQuery)) {
              filteredFollowingUsers.add(updatedUser);
            }
          }
        } else {
          followingUsers.removeWhere((followingUser) => followingUser.id == updatedUser.id);
          filteredFollowingUsers.removeWhere((followingUser) => followingUser.id == updatedUser.id);
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
  
  /// Navigates to a user's profile page and refreshes data when returning
  void navigateToUserProfile(ProfileUser user) {
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => ProfilePage(userId: user.id),
      ),
    ).then((_) async {
      if (mounted) {
        // Get the latest profile data for the current user
        final authCubit = context.read<AuthCubit>();
        final currentUser = authCubit.GetCurrentUser();
        
        if (currentUser != null) {
          // Get the latest profile data for the user we just visited
          final profileCubit = context.read<ProfileCubit>();
          final updatedVisitedUser = await profileCubit.GetUserProfileByUsername(user.id);
          
          if (updatedVisitedUser != null) {
            setState(() {
              // Check if the current user is still following this user
              final isStillFollowing = updatedVisitedUser.followers.contains(currentUser.id);
              
              // If not following anymore, remove from following lists
              if (!isStillFollowing) {
                followingUsers.removeWhere((u) => u.id == user.id);
                filteredFollowingUsers.removeWhere((u) => u.id == user.id);
                
                // Show a message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User removed from your following list'),
                    duration: Duration(seconds: 1),
                  ),
                );
              } else {
                // Otherwise, just update the user data
                final followingIndex = followingUsers.indexWhere((u) => u.id == user.id);
                if (followingIndex != -1) {
                  followingUsers[followingIndex] = updatedVisitedUser;
                }
                
                final filteredIndex = filteredFollowingUsers.indexWhere((u) => u.id == user.id);
                if (filteredIndex != -1) {
                  filteredFollowingUsers[filteredIndex] = updatedVisitedUser;
                }
              }
              
              // Also update in followers list if present
              final followerIndex = followerUsers.indexWhere((u) => u.id == user.id);
              if (followerIndex != -1) {
                followerUsers[followerIndex] = updatedVisitedUser;
              }
              
              final filteredFollowerIndex = filteredFollowerUsers.indexWhere((u) => u.id == user.id);
              if (filteredFollowerIndex != -1) {
                filteredFollowerUsers[filteredFollowerIndex] = updatedVisitedUser;
              }
            });
          }
        }
        
        // Refresh the entire list to ensure everything is up to date
        fetchUserDetails();
      }
    });
  }

  /// Builds an empty state widget with a message and icon
  Widget buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 80,
            color: mediumGrey,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              color: darkGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(
                fontSize: 14,
                color: mediumGrey,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  /// Builds a scrollable list of users with follow/unfollow functionality
  Widget buildUserList(List<ProfileUser> users, bool isFollowingList) {
    return ListView.builder(
      itemCount: users.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final user = users[index];
        final bool isFollowing = currentUserId != null && user.followers.contains(currentUserId);
        final bool followsYou = currentUserId != null && user.following.contains(currentUserId!);
        final bool isCurrentUser = currentUserId == user.id;
        
        final String uniqueHeroTag = isFollowingList 
            ? 'profile_following_${index}_${user.id}'
            : 'profile_follower_${index}_${user.id}';
            
        return GestureDetector(
          onTap: () => navigateToUserProfile(user),
          child: Card(
            elevation: 0,
            color: pureWhite,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(
                color: lightGrey,
                width: 1,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Hero(
                tag: uniqueHeroTag,
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: pureBlack,
                  backgroundImage: user.profilePictureUrl.isNotEmpty
                      ? NetworkImage(user.profilePictureUrl)
                      : null,
                  child: user.profilePictureUrl.isEmpty
                      ? const Icon(Icons.person, color: pureWhite)
                      : null,
                ),
              ),
              title: Text(
                user.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: pureBlack,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isFollowingList 
                        ? (currentUserId == widget.following.first ? "You are following" : "Following")
                        : (followsYou ? "Follows you" : "Follower"),
                    style: const TextStyle(
                      fontSize: 14,
                      color: darkGrey,
                    ),
                  ),
                  if (user.bio.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      user.bio,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: mediumGrey,
                      ),
                    ),
                  ],
                ],
              ),
              trailing: !isCurrentUser ? FollowButton(
                key: ValueKey('follow_button_${user.id}_${isFollowing ? 'following' : 'not_following'}'),
                currentUserId: currentUserId!,
                otherUserId: user.id,
                isFollowing: isFollowing,
                onFollow: (wasFollowing) async {
                  await handleFollowToggle(user, isFollowing);
                  return;
                },
              ) : null,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: pureWhite,
        appBar: AppBar(
          backgroundColor: pureWhite,
          foregroundColor: pureBlack,
          title: const Text(
            'Connections',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: pureBlack,
            ),
          ),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: pureBlack),
              onPressed: () {
                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Refreshing users...'),
                    duration: Duration(seconds: 1),
                  ),
                );
                // Refresh all users
                fetchUserDetails();
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(100),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    onChanged: filterUsers,
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon: const Icon(Icons.search, color: mediumGrey),
                      filled: true,
                      fillColor: lightGrey.withOpacity(0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  indicatorWeight: 3,
                  indicatorColor: pureBlack,
                  labelColor: pureBlack,
                  unselectedLabelColor: mediumGrey,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  tabs: [
                    Tab(
                      text: 'Followers (${filteredFollowerUsers.length})',
                    ),
                    Tab(
                      text: 'Following (${filteredFollowingUsers.length})',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: RefreshIndicator(
          color: pureBlack,
          onRefresh: fetchUserDetails,
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: pureBlack))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Followers tab
                    filteredFollowerUsers.isEmpty 
                        ? buildEmptyState('No followers found')
                        : buildUserList(filteredFollowerUsers, false),
                        
                    // Following tab
                    filteredFollowingUsers.isEmpty 
                        ? buildEmptyState('No following found')
                        : buildUserList(filteredFollowingUsers, true),
                  ],
                ),
        ),
      ),
    );
  }
}
