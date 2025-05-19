// User connections page showing followers and following
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Profile/domain/entites/ProfileUser.dart';
import 'package:talkifyapp/features/Profile/presentation/Cubits/ProfileCubit.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/ProfilePage.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';

class FollowerPage extends StatefulWidget {
  final List<String> followers;
  final List<String> following;
  final VoidCallback onTapFollowers;
  final VoidCallback onTapFollowing;
  
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

class FollowerPageState extends State<FollowerPage> {
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

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    fetchUserDetails();
  }
  
  void getCurrentUser() {
    final authCubit = context.read<AuthCubit>();
    final user = authCubit.GetCurrentUser();
    if (user != null) {
      currentUserId = user.id;
    }
  }
  
  Future<void> fetchUserDetails() async {
    setState(() {
      isLoading = true;
      // Clear existing lists to prevent duplicates
      followerUsers = [];
      followingUsers = [];
    });
    
    final profileCubit = context.read<ProfileCubit>();
    
    // Fetch follower details
    for (String id in widget.followers) {
      try {
        final user = await profileCubit.GetUserProfileByUsername(id);
        if (user != null && mounted) {
          setState(() {
            followerUsers.add(user);
          });
        }
      } catch (e) {
        print('Error fetching follower user: $e');
      }
    }
    
    // Fetch following details
    for (String id in widget.following) {
      try {
        final user = await profileCubit.GetUserProfileByUsername(id);
        if (user != null && mounted) {
          setState(() {
            followingUsers.add(user);
          });
        }
      } catch (e) {
        print('Error fetching following user: $e');
      }
    }
    
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }
  
  Future<void> handleFollowToggle(ProfileUser user, bool isCurrentlyFollowing) async {
    if (currentUserId == null) return;
    
    final profileCubit = context.read<ProfileCubit>();
    
    // Optimistically update UI
    setState(() {
      if (isCurrentlyFollowing) {
        // Remove current user from followers
        user.followers.remove(currentUserId);
        // If this is in the following list, update accordingly
        if (followingUsers.contains(user)) {
          // We're unfollowing, so remove from our following list
          followingUsers.removeWhere((followingUser) => followingUser.id == user.id);
        }
      } else {
        // Add current user to followers
        user.followers.add(currentUserId!);
        // If we're in the followers tab and adding a follow, we should add to our following list
        if (!followingUsers.contains(user)) {
          followingUsers.add(user);
        }
      }
    });
    
    try {
      // Make the actual API call
      await profileCubit.toggleFollow(currentUserId!, user.id);
      
      // Show success message
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
        if (isCurrentlyFollowing) {
          // Re-add current user to followers
          user.followers.add(currentUserId!);
          if (!followingUsers.contains(user)) {
            followingUsers.add(user);
          }
        } else {
          // Re-remove current user from followers
          user.followers.remove(currentUserId);
          if (followingUsers.contains(user)) {
            followingUsers.removeWhere((followingUser) => followingUser.id == user.id);
          }
        }
      });
      
      // Show error message
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
  
  void navigateToUserProfile(ProfileUser user) {
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => ProfilePage(userId: user.id),
      ),
    ).then((_) {
      // Reset and refetch data when returning from profile
      if (mounted) {
        fetchUserDetails();
      }
    });
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
          bottom: TabBar(
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
                text: 'Followers (${followerUsers.length})',
              ),
              Tab(
                text: 'Following (${followingUsers.length})',
              ),
            ],
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator(color: pureBlack))
            : TabBarView(
                children: [
                  // Followers tab
                  followerUsers.isEmpty 
                    ? buildEmptyState('No followers yet')
                    : buildUserList(followerUsers, false),
                    
                  // Following tab
                  followingUsers.isEmpty 
                    ? buildEmptyState('Not following anyone yet')
                    : buildUserList(followingUsers, true),
                ],
              ),
      ),
    );
  }
  
  Widget buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline ,
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
        ],
      ),
    );
  }
  
  Widget buildUserList(List<ProfileUser> users, bool isFollowingList) {
    return ListView.builder(
      itemCount: users.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final user = users[index];
        // Check if the current user is following this user
        final bool isFollowing = currentUserId != null && 
            (isFollowingList || user.followers.contains(currentUserId));
        
        // Generate a unique tag for each user in each list
        final String uniqueHeroTag = isFollowingList 
            ? 'profilefollowing${index}${user.id}'
            : 'profilefollower${index}${user.id}';
            
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
              subtitle: Text(
                isFollowingList ? 'You follow this account' : 'Follows you',
                style: const TextStyle(
                  fontSize: 14,
                  color: darkGrey,
                ),
              ),
              trailing: currentUserId != user.id ? OutlinedButton(
                onPressed: () => handleFollowToggle(user, isFollowing),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  side: BorderSide(
                    color: isFollowing ? mediumGrey : pureBlack,
                    width: 1.5,
                  ),
                  foregroundColor: isFollowing ? mediumGrey : pureBlack,
                ),
                child: Text(
                  isFollowing ? 'Unfollow' : 'Follow',
                  style: TextStyle(
                    color: isFollowing ? mediumGrey : pureBlack,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ) : null,
            ),
          ),
        );
      },
    );
  }
}
