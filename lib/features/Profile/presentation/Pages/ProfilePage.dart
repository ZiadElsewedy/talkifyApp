import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:talkifyapp/features/Posts/domain/Entite/Posts.dart';
import 'package:talkifyapp/features/Posts/PostComponents/PostTile..dart';
import 'package:talkifyapp/features/Posts/presentation/cubits/post_cubit.dart';
import 'package:talkifyapp/features/Profile/presentation/Cubits/Profile_states.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/EditProfilePage.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/Follower.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/components/Bio.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/components/FollowButtom.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/components/message_button.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/components/MutualFriendsWidget.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/components/SuggestedUsersWidget.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/components/ProfilePicFunction.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/components/WhiteCircleIndicator.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/profileStats.dart';
import 'package:talkifyapp/features/Profile/presentation/Cubits/ProfileCubit.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/LOADING!.dart';
import 'package:talkifyapp/features/auth/domain/entities/AppUser.dart';
import 'package:talkifyapp/features/Chat/persentation/Cubits/chat_cubit.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/chat_room_page.dart';
import 'package:talkifyapp/features/Profile/domain/entites/ProfileUser.dart';
import 'package:talkifyapp/features/Posts/pages/upload_post_page.dart';

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

  bool _isLoadingPosts = false;
  bool _isDeletingPost = false;
  bool _isLoadingMutualFriends = false;
  bool _isLoadingSuggestedUsers = false;

  List<ProfileUser> _mutualFriends = [];
  List<ProfileUser> _suggestedUsers = [];

  bool _isScrolled = false;
  bool _showSuggestions = true;

  @override
  void initState() {
    super.initState();
    authCubit = BlocProvider.of<AuthCubit>(context);
    profileCubit = BlocProvider.of<ProfileCubit>(context);
    postCubit = BlocProvider.of<PostCubit>(context);
    currentUser = authCubit.GetCurrentUser();
    
    // Initialize profile data
    initializeProfile();
    
    _scrollController.addListener(_scrollListener);
  }
  
  void _scrollListener() {
    if (_scrollController.offset > 200 && !_showNameInHeader) {
      setState(() {
        _showNameInHeader = true;
        _isScrolled = true;
      });
    } else if (_scrollController.offset <= 200 && _showNameInHeader) {
      setState(() {
        _showNameInHeader = false;
        _isScrolled = false;
      });
    } else if (_scrollController.offset > 50 && !_isScrolled) {
      setState(() {
        _isScrolled = true;
      });
    } else if (_scrollController.offset <= 50 && _isScrolled) {
      setState(() {
        _isScrolled = false;
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
      await _fetchUserPosts();
      await fetchUserPostCount();
      
      // Don't fetch mutual friends for own profile
      if (currentUser != null && currentUser!.id != widget.userId) {
        await _fetchMutualFriends();
        
        // Only fetch suggested users when viewing OTHER profiles
        await _fetchSuggestedUsers();
      }
    }
  }
  
  Future<void> fetchUserPostCount() async {
    try {
      final posts = await postCubit.fetchUserPosts(widget.userId!);
      if (mounted) {
        setState(() {
          userPostCount = posts.length;
        });
      }
    } catch (e) {
      print('Error fetching user post count: $e');
    }
  }

  Future<void> _fetchUserPosts() async {
    setState(() {
      _isLoadingPosts = true;
    });
    try {
      if (widget.userId != null) {
        final posts = await postCubit.fetchUserPosts(widget.userId!);
        if (mounted) {
          setState(() {
            userPosts = posts;
            _isLoadingPosts = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPosts = false;
        });
      }
      print('Error fetching user posts: $e');
    }
  }
  
  Future<void> _fetchMutualFriends() async {
    if (currentUser == null || widget.userId == null || currentUser!.id == widget.userId) {
      return;
    }
    
    setState(() {
      _isLoadingMutualFriends = true;
    });
    
    try {
      final mutualFriends = await profileCubit.getMutualFriends(
        currentUser!.id,
        widget.userId!
      );
      
      if (mounted) {
        setState(() {
          _mutualFriends = mutualFriends;
          _isLoadingMutualFriends = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMutualFriends = false;
        });
      }
      print('Error fetching mutual friends: $e');
    }
  }
  
  Future<void> _fetchSuggestedUsers() async {
    if (currentUser == null) {
      return;
    }
    
    setState(() {
      _isLoadingSuggestedUsers = true;
    });
    
    try {
      print("Fetching suggested users for: ${currentUser!.id}");
      final suggestedUsers = await profileCubit.getSuggestedUsers(
        currentUser!.id,
        limit: 10,
      );
      
      print("Fetched ${suggestedUsers.length} suggested users");
      
      if (mounted) {
        // If we got no suggestions, create local dummy ones
        List<ProfileUser> usersList = List.from(suggestedUsers);
        
        if (usersList.isEmpty && currentUser != null) {
          print("Creating local dummy suggestions");
          
          // Create at least 2 dummy suggested users
          usersList.add(ProfileUser(
            id: 'local_dummy_1',
            name: 'Sarah Johnson',
            email: 'test1@example.com',
            phoneNumber: '',
            profilePictureUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=100',
            bio: 'Photographer and traveler',
            backgroundprofilePictureUrl: '',
            HintDescription: 'Travel enthusiast',
            followers: [],
            following: [],
          ));
          
          usersList.add(ProfileUser(
            id: 'local_dummy_2',
            name: 'Michael Chen',
            email: 'test2@example.com',
            phoneNumber: '',
            profilePictureUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=100',
            bio: 'Software developer',
            backgroundprofilePictureUrl: '',
            HintDescription: 'Tech & gaming',
            followers: [],
            following: [],
          ));
          
          usersList.add(ProfileUser(
            id: 'local_dummy_3',
            name: 'Emma Williams',
            email: 'test3@example.com',
            phoneNumber: '',
            profilePictureUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=100',
            bio: 'Digital artist',
            backgroundprofilePictureUrl: '',
            HintDescription: 'Creative mind',
            followers: [],
            following: [],
          ));
        }
        
        setState(() {
          _suggestedUsers = usersList;
          _isLoadingSuggestedUsers = false;
        });
      }
    } catch (e) {
      print("Error fetching suggested users: $e");
      
      // On error, still create dummy suggested users
      if (mounted) {
        setState(() {
          _suggestedUsers = [
            ProfileUser(
              id: 'error_dummy_1',
              name: 'Alex Morgan',
              email: 'error1@example.com',
              phoneNumber: '',
              profilePictureUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?q=80&w=100',
              bio: 'Fitness coach',
              backgroundprofilePictureUrl: '',
              HintDescription: 'Health enthusiast',
              followers: [],
              following: [],
            ),
            ProfileUser(
              id: 'error_dummy_2',
              name: 'James Wilson',
              email: 'error2@example.com',
              phoneNumber: '',
              profilePictureUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=100',
              bio: 'Music producer',
              backgroundprofilePictureUrl: '',
              HintDescription: 'Beats & melodies',
              followers: [],
              following: [],
            ),
          ];
          _isLoadingSuggestedUsers = false;
        });
      }
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
  
  Future<void> handleSuggestedUserFollowToggle(String userId, bool isFollowing) async {
    if (currentUser == null) return;
    
    try {
      await profileCubit.toggleFollow(currentUser!.id, userId);
      
      // If we just followed the user, remove them from suggestions
      if (isFollowing) {
        setState(() {
          _suggestedUsers.removeWhere((user) => user.id == userId);
        });
      }
      
      // Show a snackbar with the result
      if (mounted) {
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

  void _deletePost(Post post) async {
    try {
      // Show loading indicator
      setState(() {
        _isDeletingPost = true;
      });
      
      // Delete the post using the cubit's method
      await postCubit.deletePost(post.id);
      
      // Update UI
      setState(() {
        userPosts.removeWhere((p) => p.id == post.id);
        _isDeletingPost = false;
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted successfully'))
      );
    } catch (e) {
      // Update UI
      setState(() {
        _isDeletingPost = false;
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete post: $e'))
      );
    }
  }

  Future<void> refreshProfile() async {
    if (widget.userId != null) {
      await profileCubit.fetchUserProfile(widget.userId!);
      await fetchUserPostCount();
      
      // Refresh mutual friends and suggested users too
      if (currentUser != null && currentUser!.id != widget.userId) {
        await _fetchMutualFriends();
      }
      
      if (currentUser != null && currentUser!.id == widget.userId) {
        await _fetchSuggestedUsers();
      }
      
      await Future.delayed(const Duration(milliseconds: 800));
    }
  }

  Future<void> _startChatWithUser() async {
    if (currentUser == null || widget.userId == null) return;

    try {
      // Show loading state
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Starting chat...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      final profileState = profileCubit.state;
      if (profileState is ProfileLoadedState) {
        final user = profileState.profileuser;
        
        // Create participant lists
        final participantIds = [currentUser!.id, widget.userId!];
        final participantNames = {
          currentUser!.id: currentUser!.name,
          widget.userId!: user.name,
        };
        final participantAvatars = {
          currentUser!.id: currentUser!.profilePictureUrl,
          widget.userId!: user.profilePictureUrl,
        };

        // Find or create chat room
        final chatRoom = await context.read<ChatCubit>().findOrCreateChatRoom(
          participantIds: participantIds,
          participantNames: participantNames,
          participantAvatars: participantAvatars,
        );

        if (chatRoom != null && mounted) {
          // Navigate to chat room
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatRoomPage(chatRoom: chatRoom),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Add a separate method to the top of the class to manually load suggestions
  void _manuallyLoadSuggestions() {
    if (currentUser != null) {
      setState(() {
        _isLoadingSuggestedUsers = true;
      });
      
      _fetchSuggestedUsers().then((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Suggestions refreshed'),
              backgroundColor: Colors.black,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      });
    }
  }

  // Toggle suggestions visibility
  void _toggleSuggestions() {
    setState(() {
      _showSuggestions = !_showSuggestions;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final appBarBg = colorScheme.surface;
    final appBarText = colorScheme.inversePrimary;
    final cardBg = isDarkMode ? Colors.grey[900]! : Colors.white;
    final cardText = isDarkMode ? Colors.grey[200]! : Colors.black87;
    final cardSubText = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final dividerColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final iconColor = isDarkMode ? Colors.grey[400]! : Colors.black54;
    final buttonBg = isDarkMode ? Colors.blue[900]! : Colors.black;
    final buttonFg = Colors.white;
    final followBg = isDarkMode ? Colors.white : Colors.black;
    final followFg = isDarkMode ? Colors.black : Colors.white;
    final followBorder = isDarkMode ? Colors.grey[700]! : Colors.grey.shade300;
    bool isOwner = currentUser != null && widget.userId != null && currentUser!.id == widget.userId;
    return BlocBuilder<ProfileCubit, ProfileStates>(
      builder: (context, state) {
        if (state is ProfileLoadedState) {
          final user = state.profileuser;
          return Scaffold(
            backgroundColor: scaffoldBg,
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
                    backgroundColor: _isScrolled ? Colors.black : appBarBg,
                    elevation: _isScrolled ? 4 : 0,
                    title: AnimatedOpacity(
                      opacity: _showNameInHeader ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            user.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 60,
                            height: 70,
                            child: Lottie.asset(
                              'lib/assets/profile.json',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
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
                                      tag: 'avatar_${user.id}',
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
                                            style: TextStyle(
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
                                              color: isDarkMode ? cardSubText : Colors.grey[400],
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
                                          // Add mutual friends text below username
                                          if (!isOwner && currentUser != null && _mutualFriends.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 6.0),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.people,
                                                    size: 14,
                                                    color: Colors.white.withOpacity(0.8),
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    "${_mutualFriends.length} Mutual ${_mutualFriends.length == 1 ? 'Connection' : 'Connections'}",
                                                    style: TextStyle(
                                                      color: Colors.white.withOpacity(0.8),
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w500,
                                                      shadows: [
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
                      color: cardBg,
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
                                            onPressed: _startChatWithUser,
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
                                        color: isDarkMode ? Colors.white : Colors.black,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Bio',
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.white : Colors.black87,
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
                          
                          // Suggested Users Section - Only show when viewing OTHER profiles
                          if (_showSuggestions && currentUser != null && !isOwner)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              margin: const EdgeInsets.only(top: 8, bottom: 16),
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.grey[850] : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDarkMode ? const Color.fromARGB(255, 23, 23, 23)! : Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            height: 16,
                                            width: 3,
                                            decoration: BoxDecoration(
                                              color: isDarkMode ? Colors.white : Colors.black,
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Suggested For You',
                                            style: TextStyle(
                                              color: isDarkMode ? Colors.white : Colors.black87,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Add buttons to refresh and hide suggestions
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.refresh,
                                              color: isDarkMode ? Colors.white70 : Colors.black87,
                                              size: 18,
                                            ),
                                            onPressed: _manuallyLoadSuggestions,
                                            tooltip: 'Refresh suggestions',
                                            padding: EdgeInsets.all(4),
                                            constraints: BoxConstraints(),
                                          ),
                                          SizedBox(width: 4),
                                          IconButton(
                                            icon: Icon(
                                              Icons.close,
                                              color: isDarkMode ? Colors.white70 : Colors.black87,
                                              size: 18,
                                            ),
                                            onPressed: _toggleSuggestions,
                                            tooltip: 'Hide suggestions',
                                            padding: EdgeInsets.all(4),
                                            constraints: BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Show loading indicator or empty state if no suggestions
                                  if (_isLoadingSuggestedUsers)
                                    Container(
                                      height: 100,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            isDarkMode ? Colors.white : Colors.black,
                                          ),
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  else if (_suggestedUsers.isEmpty)
                                    Container(
                                      height: 100,
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "No suggestions available",
                                              style: TextStyle(
                                                color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                                                fontSize: 14,
                                              ),
                                            ),
                                            SizedBox(height: 12),
                                            ElevatedButton(
                                              onPressed: _manuallyLoadSuggestions,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[800],
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                minimumSize: Size(0, 0),
                                                textStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                              ),
                                              child: Text("Refresh"),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  else
                                    // New implementation of suggested users list
                                    SizedBox(
                                      height: 120,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: _suggestedUsers.length > 5 ? 5 : _suggestedUsers.length,
                                        itemBuilder: (context, index) {
                                          final user = _suggestedUsers[index];
                                          return GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => ProfilePage(userId: user.id),
                                                ),
                                              );
                                            },
                                            child: Container(
                                              width: 75,
                                              margin: EdgeInsets.only(right: 16),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  // Profile Image with simple border
                                                  Container(
                                                    width: 60,
                                                    height: 60,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                                                        width: 1,
                                                      ),
                                                      color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(30),
                                                      child: CachedNetworkImage(
                                                        imageUrl: user.profilePictureUrl,
                                                        fit: BoxFit.cover,
                                                        placeholder: (context, url) => Container(
                                                          color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                                          child: Icon(
                                                            Icons.person,
                                                            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                                                            size: 30,
                                                          ),
                                                        ),
                                                        errorWidget: (context, url, error) => Container(
                                                          color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                                          child: Icon(
                                                            Icons.person,
                                                            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                                                            size: 30,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  // Name
                                                  Text(
                                                    user.name,
                                                    textAlign: TextAlign.center,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: isDarkMode ? Colors.white : Colors.black,
                                                      fontWeight: FontWeight.w500,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  // Follow Button - Make it simple for mobile
                                                  SizedBox(
                                                    height: 24,
                                                    width: double.infinity,
                                                    child: OutlinedButton(
                                                      onPressed: () => handleSuggestedUserFollowToggle(user.id, true),
                                                      style: OutlinedButton.styleFrom(
                                                        foregroundColor: isDarkMode ? Colors.white : Colors.black,
                                                        backgroundColor: Colors.transparent,
                                                        side: BorderSide(
                                                          color: isDarkMode ? Colors.white : Colors.black,
                                                          width: 1,
                                                        ),
                                                        padding: EdgeInsets.zero,
                                                        minimumSize: Size.zero,
                                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        textStyle: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                      child: Text('Follow'),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
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
                                        color: isDarkMode ? Colors.white : Colors.black,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Posts',
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.white : Colors.black87,
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
                                    color: cardBg,
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
                                      color: dividerColor,
                                      width: 1,
                                    ),
                                  ),
                                  child: _buildPostsContent(iconColor, cardSubText, isOwner),
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
          final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
          return Scaffold(
            backgroundColor: isDarkMode ? Theme.of(context).scaffoldBackgroundColor : Color(0xFFF9F9F9),
            body: Center(
              child: ProfessionalCircularProgress(),
            ),
          );
        } else if (state is ProfileErrorState) {
          final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
          return Scaffold(
            backgroundColor: isDarkMode ? Theme.of(context).scaffoldBackgroundColor : Color(0xFFF9F9F9),
            appBar: AppBar(
              backgroundColor: isDarkMode ? Colors.grey[900] : Colors.black,
              elevation: 0,
              title: Text('Profile', style: TextStyle(color: Colors.white)),
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode 
                        ? Colors.black.withOpacity(0.2) 
                        : Colors.black.withOpacity(0.08),
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
                      color: isDarkMode ? Colors.grey[400] : Colors.black,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.error,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[300] : Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: initializeProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode ? Colors.blue[700] : Colors.black,
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
  
  // Extracted method to build posts content to avoid duplication
  Widget _buildPostsContent(Color iconColor, Color cardSubText, bool isOwner) {
    if (_isLoadingPosts) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (userPosts.isEmpty) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.post_add_outlined,
                size: 50,
                color: iconColor,
              ),
              const SizedBox(height: 10),
              Text(
                'No posts yet',
                style: TextStyle(
                  color: cardSubText,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Posts will appear here',
                style: TextStyle(
                  color: cardSubText,
                  fontSize: 14,
                ),
              ),
              if (isOwner) const SizedBox(height: 16),
              if (isOwner)
                OutlinedButton(
                  onPressed: () {
                    // Navigate to create post page instead of showing a snackbar
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UploadPostPage(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                    side: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                    ),
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
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: userPosts.length,
      itemBuilder: (context, index) {
        final post = userPosts[index];
        return PostTile(
          post: post,
          onDelete: () {
            _deletePost(post);
          },
        );
      },
    );
  }
}
