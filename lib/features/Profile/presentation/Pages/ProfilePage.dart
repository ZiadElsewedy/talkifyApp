import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Posts/presentation/cubits/post_cubit.dart';
import 'package:talkifyapp/features/Profile/presentation/Cubits/Profile_states.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/EditProfilePage.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/Follower.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/components/Bio.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/components/FollowButtom.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/components/Message.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/components/ProfilePicFunction.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/components/WhiteCircleIndicator.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/profileStats.dart';
import 'package:talkifyapp/features/Profile/presentation/Cubits/ProfileCubit.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/LOADING!.dart';
import 'package:talkifyapp/features/auth/domain/entities/AppUser.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.userId});
  final String? userId;
  
  @override
  State<ProfilePage> createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  late AuthCubit authCubit;
  late ProfileCubit profileCubit;
  late PostCubit postCubit;
  AppUser? currentUser;
  int userPostCount = 0;

  @override
  void initState() {
    super.initState();
    authCubit = BlocProvider.of<AuthCubit>(context);
    profileCubit = BlocProvider.of<ProfileCubit>(context);
    postCubit = BlocProvider.of<PostCubit>(context);
    currentUser = authCubit.GetCurrentUser();
    profileCubit.fetchUserProfile(widget.userId!);
    
    // Fetch user posts to get the count
    fetchUserPostCount();
  }
  
  Future<void> fetchUserPostCount() async {
    try {
      final posts = await postCubit.postRepo.fetechPostsByUserId(widget.userId!);
      if (mounted) {
        setState(() {
          userPostCount = posts.length;
        });
      }
    } catch (e) {
      print('Error fetching post count: $e');
    }
  }

  Future<void> followButtonPressed(String currentUserId, String otherUserId) async {
    final profileAsState = profileCubit.state;
    if (profileAsState is ProfileLoadedState) {
      final profileUser = profileAsState.profileuser;
      final isCurrentlyFollowing = profileUser.followers.contains(currentUserId);
      
      try {
        // Make the API call to update follow status
        await profileCubit.toggleFollow(currentUserId, otherUserId);
        
        // Refresh the profile to ensure we have the latest state
        await profileCubit.fetchUserProfile(otherUserId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isCurrentlyFollowing ? 'Unfollowed successfully' : 'Followed successfully'),
              backgroundColor: Colors.black,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update follow status: $error'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        // Re-throw the error to be handled by the FollowButton
        rethrow;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isOwner = currentUser != null && widget.userId != null && currentUser!.id == widget.userId;
    return BlocBuilder<ProfileCubit, ProfileStates>(
      builder: (context, state) {
        if (state is ProfileLoadedState) {
          final user = state.profileuser;
          return Scaffold(
            body: RefreshIndicator(
              color: Colors.black,
              onRefresh: () async {
                // Refresh profile data
                profileCubit.fetchUserProfile(widget.userId!);
                // Refresh post count
                fetchUserPostCount();
                // Wait for a reasonable time to ensure the UI updates
                await Future.delayed(const Duration(milliseconds: 800));
              },
              child: CustomScrollView(
                slivers: [
                  // Modern App Bar with background image
                  SliverAppBar(
                    expandedHeight: 270,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Background Image
                          CachedNetworkImage(
                            imageUrl: user.backgroundprofilePictureUrl,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[300],
                              child: const Center(child: PercentCircleIndicator()),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.image, size: 50, color: Colors.grey),
                            ),
                            fit: BoxFit.cover,
                          ),
                          // Gradient Overlay
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.3),
                                  Colors.black.withOpacity(0.1),
                                ],
                              ),
                            ),
                          ),
                          // Profile Content
                          Positioned(
                            bottom: 20,
                            left: 20,
                            right: 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Profile Picture
                                    Hero(
                                      tag: 'profilepicture',
                                      child: ProfilePicFunction(
                                        state: state,
                                        profilePictureUrl: user.profilePictureUrl,
                                        size: 100.0,
                                        showBorder: true,
                                        borderColor: Colors.white,
                                        borderWidth: 1.2,
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    // User Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              shadows: [
                                                Shadow(
                                                  offset: Offset(1, 1),
                                                  blurRadius: 3,
                                                  color: Colors.black45,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            user.HintDescription,
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.9),
                                              fontSize: 16,
                                              shadows: const [
                                                Shadow(
                                                  offset: Offset(1, 1),
                                                  blurRadius: 3,
                                                  color: Colors.black45,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                // Profile Stats
                                ProfileStats(
                                  profileUser: user,
                                  followCount: user.followers.length,
                                  followingCount: user.following.length,
                                  postCount: userPostCount,
                                  onTapFollowers: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => FollowerPage(
                                          followers: user.followers,
                                          following: user.following,
                                          onTapFollowers: () {
                                            // Handle follow action from the followers tab
                                            if (currentUser != null) {
                                              followButtonPressed(currentUser!.id, user.id);
                                            }
                                          },
                                          onTapFollowing: () {
                                            // Handle unfollow action from the following tab
                                            if (currentUser != null) {
                                              followButtonPressed(currentUser!.id, user.id);
                                            }
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  onTapFollowing: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => FollowerPage(
                                          followers: user.followers,
                                          following: user.following,
                                          onTapFollowers: () {
                                            // Handle follow action from the followers tab
                                            if (currentUser != null) {
                                              followButtonPressed(currentUser!.id, user.id);
                                            }
                                          },
                                          onTapFollowing: () {
                                            // Handle unfollow action from the following tab
                                            if (currentUser != null) {
                                              followButtonPressed(currentUser!.id, user.id);
                                            }
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  onTapPosts: () {
                                    // TODO: Navigate to posts list when implemented
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Posts feature coming soon!')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: () {
                          // Show loading indicator
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Refreshing profile...'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                          // Refresh profile data
                          profileCubit.fetchUserProfile(widget.userId!);
                        },
                      ),
                      if (isOwner)
                        IconButton(
                          icon: const Icon(Icons.settings, color: Colors.white),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditProfilePage(user: user),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                  // Profile Content
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 20), 
                        // Bio Section
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isOwner)
                                Row(
                                  children: [
                                    Expanded(
                                      child: MessageButton(
                                        onPressed: () {
                                          // Handle message button tap
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Message feature coming soon!'),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: FollowButton(
                                        currentUserId: currentUser!.id,
                                        otherUserId: user.id,
                                        isFollowing: user.followers.contains(currentUser!.id),
                                        onFollow: (isFollowing) => followButtonPressed(currentUser!.id, user.id),
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 20),
                              const Text(
                                'Bio',
                                style: TextStyle(
                                  color: Color.fromARGB(255, 95, 95, 95),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Mybio(bioText: user.bio),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        // Posts Section
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Posts',
                                style: TextStyle(
                                  color: Color.fromARGB(255, 95, 95, 95),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    'No posts yet',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (state is ProfileLoadingState) {
          return const Scaffold(
            body: Center(
              child: ProfessionalCircularProgress(),
            ),
          );
        } else if (state is ProfileErrorState) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.error,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => profileCubit.fetchUserProfile(widget.userId!),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}