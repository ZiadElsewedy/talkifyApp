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
    
    // Get current user
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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'T A L K I F Y',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 4,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            onPressed: () {
              // Search functionality placeholder
              Navigator.push(context, MaterialPageRoute(builder: (context) => SearchPage()));
            },
            icon: Icon(Icons.search, color: Colors.black54),
            tooltip: 'Search',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorWeight: 3,
              indicatorColor: Colors.black,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              labelStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              tabs: [
                Tab(
                  icon: _tabController.index == 0 
                      ? Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('For You', style: TextStyle(color: Colors.black)),
                        )
                      : Text('For You'),
                ),
                Tab(
                  icon: _tabController.index == 1
                      ? Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('Following', style: TextStyle(color: Colors.black)),
                        )
                      : Text('Following'),
                ),
                Tab(
                  icon: _tabController.index == 2
                      ? Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('Trending', style: TextStyle(color: Colors.black)),
                        )
                      : Text('Trending'),
                ),
              ],
            ),
          ),
        ),
      ),
      drawer: const MyDrawer(),
      body: BlocBuilder<PostCubit, PostState>(
        builder: (context, state) {
          // Handle upload progress state - integrate with loaded posts
          if (state is PostsUploadingProgress) {
            return RefreshIndicator(
              color: Colors.black,
              backgroundColor: Colors.white,
              onRefresh: refreshPosts,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Display the uploading post at the top
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
                      child: UploadingPostTile(
                        post: state.post,
                        progress: state.progress,
                      ),
                    ),
                  ),
                  
                  // Separator
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'PREVIOUS POSTS',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                    ),
                  ),
                  
                  // Loading indicator for previous posts
                  SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: PercentCircleIndicator(
                          size: 40,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
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
                      color: Colors.black54,
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
                      color: Colors.grey[400],
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
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _tabController.index == 1 && currentUser != null
                          ? 'Follow more people to see their posts'
                          : 'Be the first to share something!',
                      style: TextStyle(
                        color: Colors.grey[600],
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
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ],
                ),
              );
            }
            
            return RefreshIndicator(
              color: Colors.black,
              backgroundColor: Colors.white,
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
                    color: Colors.red[300],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Something went wrong',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
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
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ],
              ),
            );
          }

          return const Center(child: PercentCircleIndicator(color: Colors.black));
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
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            elevation: 4,
          ),
        ),
      ),
    );
  }
}

