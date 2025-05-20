import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Posts/domain/Entite/Posts.dart';
import 'package:talkifyapp/features/Posts/PostComponents/PostTile..dart';
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
  List<Post> userPosts = [];
  final ScrollController _scrollController = ScrollController();
  bool _showNameInHeader = false;

  @override
  void initState() {
    super.initState();
    authCubit = BlocProvider.of<AuthCubit>(context);
    profileCubit = BlocProvider.of<ProfileCubit>(context);
    postCubit = BlocProvider.of<PostCubit>(context);
    currentUser = authCubit.GetCurrentUser();
    initializeProfile();
    
    _scrollController.addListener(_scrollListener);
  }
  
  void _scrollListener() {
    if (_scrollController.offset > 200 && !_showNameInHeader) {
      setState(() {
        _showNameInHeader = true;
      });
    } else if (_scrollController.offset <= 200 && _showNameInHeader) {
      setState(() {
        _showNameInHeader = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> initializeProfile() async {
    if (widget.userId != null) {
      await profileCubit.fetchUserProfile(widget.userId!);
      await fetchUserPosts();
      await fetchUserPostCount();
    }
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

  Future<void> fetchUserPosts() async {
    try {
      final posts = await postCubit.postRepo.fetechPostsByUserId(widget.userId!);
      if (mounted) {
        setState(() {
          userPosts = posts;
        });
      }
    } catch (e) {
      print('Error fetching user posts: $e');
    }
  }

  Future<void> handleFollowAction() async {
    if (currentUser == null || widget.userId == null) return;

    try {
      await profileCubit.toggleFollow(currentUser!.id, widget.userId!);
      
      // Refresh the profile to ensure we have the latest state
      await profileCubit.fetchUserProfile(widget.userId!);
      
      if (mounted) {
        final isFollowing = await profileCubit.profileRepo.isFollowing(currentUser!.id, widget.userId!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isFollowing ? 'Followed successfully' : 'Unfollowed successfully'),
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
    }
  }

  Future<void> handlePostDelete(Post post, int index) async {
    try {
      await postCubit.postRepo.deletePost(post.id);
      if (mounted) {
        setState(() {
          userPosts.removeAt(index);
          userPostCount--;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post deleted successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> refreshProfile() async {
    if (widget.userId != null) {
      await profileCubit.fetchUserProfile(widget.userId!);
      await fetchUserPostCount();
      await Future.delayed(const Duration(milliseconds: 800));
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
            backgroundColor: const Color(0xFFF9F9F9),
            body: RefreshIndicator(
              color: Colors.black,
              onRefresh: refreshProfile,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                controller: _scrollController,
                slivers: [
                  // Modern App Bar with background image
                  SliverAppBar(
                    expandedHeight: 270,
                    pinned: true,
                    backgroundColor: Colors.black,
                    elevation: 0,
                    title: AnimatedOpacity(
                      opacity: _showNameInHeader ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        user.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: refreshProfile,
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
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Background Image
                          CachedNetworkImage(
                            imageUrl: user.backgroundprofilePictureUrl,
                            placeholder: (context, url) => Container(
                              color: const Color(0xFFEEEEEE),
                              child: const Center(child: PercentCircleIndicator()),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: const Color(0xFFEEEEEE),
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
                                  Colors.black.withOpacity(0.4),
                                  Colors.black.withOpacity(0.2),
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
                                            handleFollowAction();
                                          },
                                          onTapFollowing: () {
                                            // Handle unfollow action from the following tab
                                            handleFollowAction();
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
                                            handleFollowAction();
                                          },
                                          onTapFollowing: () {
                                            // Handle unfollow action from the following tab
                                            handleFollowAction();
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
                                const SizedBox(height: 10),
                                // Subtle indicator to encourage scrolling
                              
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Profile Content
                  SliverToBoxAdapter(
                    child: Container(
                      color: const Color(0xFFF9F9F9),
                      child: Column(
                        children: [
                          const SizedBox(height: 20), 
                          // Bio Section
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isOwner)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 25),
                                    child: Row(
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
                                            key: ValueKey('profilefollowbutton${user.id}${user.followers.contains(currentUser!.id)}'),
                                            currentUserId: currentUser!.id,
                                            otherUserId: user.id,
                                            isFollowing: user.followers.contains(currentUser!.id),
                                            onFollow: (isFollowing) async {
                                              try {
                                                await handleFollowAction();
                                                // We don't need to setState here because the parent widget will be rebuilt
                                                // when the profile is refreshed in handleFollowAction
                                              } catch (e) {
                                                // Error is already handled in handleFollowAction
                                                rethrow;
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                Row(
                                  children: [
                                    Container(
                                      height: 24,
                                      width: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Bio',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                Mybio(bioText: user.bio),
                              ],
                            ),
                          ),
                          const SizedBox(height: 25),
                          // Posts Section
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            margin: const EdgeInsets.only(bottom: 30),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      height: 24,
                                      width: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Posts',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        spreadRadius: 1,
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Colors.grey.withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: userPosts.isEmpty
                                      ? AnimatedContainer(
                                          duration: const Duration(milliseconds: 300),
                                          height: 200,
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.post_add_outlined,
                                                  size: 50,
                                                  color: Colors.black.withOpacity(0.3),
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  'No posts yet',
                                                  style: TextStyle(
                                                    color: Colors.black54,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                                Text(
                                                  'Posts will appear here',
                                                  style: TextStyle(
                                                    color: Colors.black38,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                if (isOwner) const SizedBox(height: 16),
                                                if (isOwner)
                                                  OutlinedButton(
                                                    onPressed: () {
                                                      // Navigate to create post
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(
                                                          content: Text('Create post feature coming soon!'),
                                                          backgroundColor: Colors.black,
                                                        ),
                                                      );
                                                    },
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor: Colors.black,
                                                      side: const BorderSide(color: Colors.black),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                    ),
                                                    child: const Text('Create a post'),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        )
                                      : ListView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          itemCount: userPosts.length,
                                          itemBuilder: (context, index) {
                                            final post = userPosts[index];
                                            return PostTile(
                                              post: post,
                                              onDelete: () async {
                                                await handlePostDelete(post, index);
                                              },
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (state is ProfileLoadingState) {
          return const Scaffold(
            backgroundColor: Color(0xFFF9F9F9),
            body: Center(
              child: ProfessionalCircularProgress(),
            ),
          );
        } else if (state is ProfileErrorState) {
          return Scaffold(
            backgroundColor: Color(0xFFF9F9F9),
            appBar: AppBar(
              backgroundColor: Colors.black,
              elevation: 0,
              title: const Text('Profile'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.black,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: initializeProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
