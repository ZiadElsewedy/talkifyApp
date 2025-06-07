import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Posts/PostComponents/UploadingPostTile.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/components/WhiteCircleIndicator.dart';
import 'package:talkifyapp/features/Posts/PostComponents/PostTile..dart';
import 'package:talkifyapp/features/Posts/pages/upload_post_page.dart' show UploadPostPage;
import 'package:talkifyapp/features/Posts/presentation/cubits/post_cubit.dart';
import 'package:talkifyapp/features/Posts/presentation/cubits/post_states.dart';
import 'package:talkifyapp/features/Search/Presentation/SearchPage.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/auth/domain/entities/AppUser.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/Mydrawer.dart';
import 'package:talkifyapp/features/Notifcations/presentation/pages/notifications_page.dart';
import 'package:talkifyapp/features/Notifcations/presentation/cubit/notification_cubit.dart';
import 'package:talkifyapp/features/Notifcations/presentation/cubit/notification_state.dart';
import 'package:talkifyapp/features/Notifcations/data/notification_repository_impl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:talkifyapp/features/Chat/service/chat_message_listener.dart';

class HomePage extends StatefulWidget {
  final int initialTabIndex;

  const HomePage({
    super.key,
    this.initialTabIndex = 0, // Default to home tab (index 0)
  });

  @override
  State<HomePage> createState() => _HomePageState();
}


class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final postCubit = context.read<PostCubit>();
  late final AnimationController _backgroundController;
  late final ScrollController _scrollController;
  late TabController _tabController;
  bool _showFab = true;
  double _previousScrollPosition = 0.0;
  int _currentIndex = 0;
  AppUser? currentUser;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
    
    // Initialize tab controller for post categories
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    
    // Get current user and load notifications
    _getCurrentUser();
    
    // Fetch posts for the initial tab
    _loadPostsForCurrentTab();
    
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  void _getCurrentUser() {
    final authCubit = context.read<AuthCubit>();
    currentUser = authCubit.GetCurrentUser();
    
    // Load notifications for current user
    if (currentUser != null) {
      final notificationCubit = context.read<NotificationCubit>();
      print('HomePage: Initializing notifications for user ${currentUser!.id}');
      // Pass context for in-app notifications
      notificationCubit.initialize(currentUser!.id, context: context);
      
      // Initialize chat message listener
      print('HomePage: Initializing chat message listener');
      ChatMessageListener().initialize(context);
    } else {
      print('HomePage: Current user is null, skipping notification initialization');
    }
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    _loadPostsForCurrentTab();
  }

  Future<void> _loadPostsForCurrentTab() async {
    switch (_tabController.index) {
      case 0: // For You (All Posts)
        await fetchPosts();
        break;
      case 1: // Following
        if (currentUser != null) {
          await fetchFollowingPosts();
        } else {
          // If not logged in, show all posts
          await fetchPosts();
        }
        break;
      case 2: // Trending
        await fetchTrendingPosts();
        break;
    }
  }

  void _scrollListener() {
    // Hide FAB when scrolling down, show when scrolling up
    double scrollPositionDelta = _scrollController.position.pixels - _previousScrollPosition;
    _previousScrollPosition = _scrollController.position.pixels;
    
    // Scrolling down (positive delta)
    if (scrollPositionDelta > 0 && _showFab) {
      setState(() {
        _showFab = false;
      });
    } 
    // Scrolling up (negative delta)
    else if (scrollPositionDelta < 0 && !_showFab) {
      setState(() {
        _showFab = true;
      });
    }
  }

  Future<void> fetchPosts() async {
    await postCubit.fetchAllPosts();
  }

  Future<void> fetchFollowingPosts() async {
    if (currentUser == null) {
      return fetchPosts();
    }
    await postCubit.fetchFollowingPosts(currentUser!.id);
  }

  Future<void> fetchTrendingPosts() async {
    await postCubit.fetchPostsByCategory('trending');
  }

  Future<void> deletePost(String postId) async {
    try {
      await postCubit.deletePost(postId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Post deleted successfully'),
              ],
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
        // Refresh the posts list after deletion
        _loadPostsForCurrentTab();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Failed to delete post: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> refreshPosts() async {
    switch (_tabController.index) {
      case 0: // For You (All Posts)
        return fetchPosts();
      case 1: // Following
        if (currentUser != null) {
          return fetchFollowingPosts();
        } else {
          // If not logged in, show all posts
          return fetchPosts();
        }
      case 2: // Trending
        return fetchTrendingPosts();
      default:
        return fetchPosts();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _backgroundController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final scaffoldBg = isDarkMode ? Theme.of(context).scaffoldBackgroundColor : Colors.grey[100];
    final appBarBg = isDarkMode ? colorScheme.surface : Colors.white;
    final appBarText = isDarkMode ? colorScheme.inversePrimary : Colors.black;
    final tabSelectedBg = isDarkMode ? Colors.grey[800] : Colors.transparent;
    final tabSelectedText = isDarkMode ? Colors.white : Colors.black;
    final tabUnselectedText = isDarkMode ? Colors.grey[400] : Colors.grey[500];
    final tabIndicator = isDarkMode ? Colors.white : Colors.black;
    final iconColor = isDarkMode ? Colors.grey[300] : Colors.black87;
    final searchIconColor = isDarkMode ? Colors.grey[400] : Colors.grey[700];
    final errorIconColor = isDarkMode ? Colors.red[400] : Colors.red[300];
    final errorTextColor = isDarkMode ? Colors.white : Colors.black87;
    final errorSubTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final emptyIconColor = isDarkMode ? Colors.grey[700] : Colors.grey[400];
    final emptyTextColor = isDarkMode ? Colors.white : Colors.black87;
    final emptySubTextColor = isDarkMode ? Colors.grey[500] : Colors.grey[600];
    final fabBg = Colors.blue[700];
    final fabFg = Colors.white;
    final refreshIndicatorColor = isDarkMode ? Colors.white : Colors.blue[700];
    final refreshIndicatorBg = isDarkMode ? Colors.grey[900] : Colors.white;

    // Ensure notification cubit has the latest context
    if (currentUser != null) {
      final notificationCubit = context.read<NotificationCubit>();
      notificationCubit.setContext(context);
    }

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'T A L K I F Y',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: appBarText,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: appBarBg,
        iconTheme: IconThemeData(color: appBarText),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => SearchPage()));
            },
            icon: Icon(Icons.search, color: searchIconColor, size: 24),
            tooltip: 'Search',
          ),
          BlocBuilder<NotificationCubit, NotificationState>(
            builder: (context, state) {
              return IconButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationsPage()));
                },
                icon: Stack(
                  children: [
                    Icon(Icons.notifications, color: Colors.black54),
                    if (state.unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                          child: Text(
                            state.unreadCount > 9 ? '9+' : state.unreadCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                tooltip: 'Notifications',
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              color: appBarBg,
              border: Border(
                bottom: BorderSide(
                  color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                  width: 1.0,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorWeight: 3,
              indicatorColor: tabIndicator,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: tabSelectedText,
              unselectedLabelColor: tabUnselectedText,
              labelStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              tabs: [
                Tab(text: 'For You'),
                Tab(text: 'Following'),
                Tab(text: 'Trending'),
              ],
            ),
          ),
        ),
      ),
      drawer: const MyDrawer(),
      body: BlocBuilder<PostCubit, PostState>(
        builder: (context, state) {
          // Handle different post states
          if (state is PostsUploadingProgress) {
            // Show the uploading post together with previously loaded posts
            final previousPosts = state.previousPosts;
            
            return RefreshIndicator(
              color: Colors.black,
              backgroundColor: Colors.white,
              onRefresh: refreshPosts,
              child: ListView.builder(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(top: 8, bottom: 80),
                // Add 1 for the uploading post plus all previous posts
                itemCount: 1 + previousPosts.length,
                itemBuilder: (context, index) {
                  // First item is always the uploading post
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: UploadingPostTile(
                        post: state.post,
                        progress: state.progress,
                      ),
                    );
                  }
                  
                  // Remaining items are previous posts
                  final post = previousPosts[index - 1];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: PostTile(
                      post: post,
                      onDelete: () => deletePost(post.id),
                    ),
                  );
                },
              ),
            );
          }
          
          if (state is PostsUploading || state is PostsLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PercentCircleIndicator(
                    color: Colors.black,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading posts...',
                    style: TextStyle(
                      color: tabUnselectedText,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          } else if (state is PostsLoaded) {
            final allPosts = state.posts;

            if (allPosts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.post_add,
                      size: 80,
                      color: emptyIconColor,
                    ),
                    SizedBox(height: 16),
                    Text(
                      _tabController.index == 1 && currentUser != null
                          ? 'No posts from people you follow'
                          : _tabController.index == 2
                              ? 'No trending posts yet'
                              : 'No posts yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: emptyTextColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _tabController.index == 1 && currentUser != null
                          ? 'Follow more people to see their posts'
                          : 'Be the first to share something!',
                      style: TextStyle(
                        color: emptySubTextColor,
                      ),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UploadPostPage(),
                        ),
                      ),
                      icon: Icon(Icons.add),
                      label: Text('Create Post'),
                      style: ElevatedButton.styleFrom(

                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,

                        backgroundColor: fabBg,
                        foregroundColor: fabFg,

                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ],
                ),
              );
            }
            
            return RefreshIndicator(
              color: refreshIndicatorColor,
              backgroundColor: refreshIndicatorBg,
              onRefresh: refreshPosts,
              child: ListView.builder(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(top: 8, bottom: 80),
                itemCount: allPosts.length,
                itemBuilder: (context, index) {
                  final post = allPosts[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: PostTile(
                      post: post,
                      onDelete: () => deletePost(post.id),
                    ),
                  );
                },
              ),
            );
          } else if (state is PostsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 80,

                    color: const Color.fromARGB(255, 27, 12, 12),

                    color: errorIconColor,

                  ),
                  SizedBox(height: 16),
                  Text(
                    'Something went wrong',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: errorTextColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: errorSubTextColor,
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadPostsForCurrentTab,
                    icon: Icon(Icons.refresh),
                    label: Text('Try Again'),
                    style: ElevatedButton.styleFrom(

                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,

                      backgroundColor: fabBg,
                      foregroundColor: fabFg,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ],
              ),
            );
          }
<

          return const Center(child: PercentCircleIndicator(color: Colors.black));
=======
          
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.feed,
                  size: 60,
                  color: emptyIconColor,
                ),
                SizedBox(height: 16),
                Text(
                  'No posts available',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: emptyTextColor,
                  ),
                ),
              ],
            ),
          );

        },
      ),
      floatingActionButton: AnimatedSlide(
        duration: Duration(milliseconds: 300),
        offset: _showFab ? Offset.zero : Offset(0, 2),
        child: AnimatedOpacity(
          duration: Duration(milliseconds: 300),
          opacity: _showFab ? 1.0 : 0.0,
          child: FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const UploadPostPage(),
              ),
            ),
            icon: Icon(Icons.add_photo_alternate),
            label: Text('New Post'),
            backgroundColor: fabBg,
            foregroundColor: fabFg,
            elevation: 4,
          ),
        ),
      ),
    );
  }
}

