import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/News/Domain/Entitie/news_article.dart';
import 'package:talkifyapp/features/News/Domain/repo/news_repository.dart';
import 'package:talkifyapp/features/News/Presentation/Cubit/news_cubit.dart';
import 'package:talkifyapp/features/News/Presentation/Cubit/news_states.dart';
import 'package:talkifyapp/features/News/Presentation/components/news_card.dart';
import 'package:talkifyapp/features/News/Presentation/pages/news_detail_page.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/components/WhiteCircleIndicator.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({Key? key}) : super(key: key);

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  late final NewsCubit _newsCubit;
  late final ScrollController _scrollController;
  List<NewsArticle> _breakingNews = [];
  bool _isLoadingBreaking = false;
  bool _showBreakingNews = true;
  bool _breakingNewsVisible = true;
  List<Map<String, dynamic>> _egyptianSources = [];
  bool _isLoadingEgyptianSources = false;
  bool _showEgyptianSources = false;
  
  // Animation controller for breaking news section
  late AnimationController _animationController;
  late Animation<double> _breakingNewsAnimation;
  
  final List<String> _categories = [
    'Top Headlines',
    'Politics',
    'Business',
    'Sports',
    'Technology',
    'Culture',
    'Health',
    'Egyptian News',
  ];

  @override
  void initState() {
    super.initState();
    
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(_handleTabChange);
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScroll);
    
    // Setup animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _breakingNewsAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.value = 1.0; // Start visible
    
    // Get the NewsCubit after the widget is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _newsCubit = context.read<NewsCubit>();
        _loadInitialNews();
      }
    });
  }
  
  void _handleScroll() {
    // Hide breaking news when scrolling down
    if (_scrollController.position.pixels > 10 && _breakingNewsVisible) {
      setState(() {
        _breakingNewsVisible = false;
      });
      _animationController.reverse();
    } else if (_scrollController.position.pixels <= 10 && !_breakingNewsVisible && _showBreakingNews) {
      setState(() {
        _breakingNewsVisible = true;
      });
      _animationController.forward();
    }
  }

  void _loadInitialNews() {
    if (!mounted) return;
    // Load top headlines (general category)
    _newsCubit.fetchTopHeadlines();
    
    // Also load breaking news for the Top Headlines tab
    _loadBreakingNews();
  }

  Future<void> _loadBreakingNews() async {
    setState(() {
      _isLoadingBreaking = true;
    });
    
    try {
      final cubit = context.read<NewsCubit>();
      final repository = cubit.newsRepository;
      _breakingNews = await repository.fetchBreakingNews();
    } catch (e) {
      print('Error loading breaking news: $e');
      _breakingNews = [];
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingBreaking = false;
        });
      }
    }
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging || !mounted) return;

    // Delay the action slightly to ensure we don't call emit after dispose
    Future.microtask(() {
      if (!mounted) return;
      
      String category;
      
      // Map our custom categories to API categories
      switch (_tabController.index) {
        case 0: // Top Headlines
          _newsCubit.fetchTopHeadlines();
          // Also refresh breaking news when switching to Top Headlines tab
          _loadBreakingNews();
          setState(() {
            _showBreakingNews = true;
            _breakingNewsVisible = true;
          });
          _animationController.forward();
          return;
        case 1: // Politics
          _newsCubit.fetchPoliticsNews();
          setState(() {
            _showBreakingNews = false;
            _breakingNewsVisible = false;
          });
          _animationController.reverse();
          return;
        case 2: // Business
          category = 'business';
          break;
        case 3: // Sports
          category = 'sports';
          break;
        case 4: // Technology
          category = 'technology';
          break;
        case 5: // Culture
          category = 'entertainment';
          break;
        case 6: // Health
          category = 'health';
          break;
        case 7: // Egyptian News
          _loadEgyptianSources();
          setState(() {
            _showBreakingNews = false;
            _breakingNewsVisible = false;
          });
          _animationController.reverse();
          return;
        default:
          category = 'general';
          break;
      }
      
      setState(() {
        _showBreakingNews = false;
        _breakingNewsVisible = false;
      });
      _animationController.reverse();
      _newsCubit.fetchNewsByCategory(category);
    });
  }

  void _handleSearch(String query) {
    if (!mounted) return;
    
    if (query.isNotEmpty) {
      _newsCubit.searchNews(query);
      setState(() {
        _showBreakingNews = false;
        _breakingNewsVisible = false;
      });
      _animationController.reverse();
    }
  }

  Future<void> _loadEgyptianSources() async {
    setState(() {
      _isLoadingEgyptianSources = true;
      _showEgyptianSources = true;
    });
    
    try {
      final cubit = context.read<NewsCubit>();
      _egyptianSources = await cubit.getEgyptianNewsSources();
    } catch (e) {
      print('Error loading Egyptian sources: $e');
      _egyptianSources = [];
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingEgyptianSources = false;
        });
      }
    }
  }

  void _selectEgyptianSource(String sourceId, String sourceName) {
    _newsCubit.fetchNewsFromEgyptianSource(sourceId);
    
    // Show a loading state
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loading news from $sourceName...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final scaffoldBg = isDarkMode ? Theme.of(context).scaffoldBackgroundColor : Colors.white;
    final appBarBg = isDarkMode ? colorScheme.surface : Colors.white;
    final appBarText = colorScheme.inversePrimary;
    final tabSelectedBg = isDarkMode ? Colors.grey[800] : Colors.white;
    final tabSelectedText = isDarkMode ? Colors.white : Colors.black;
    final tabUnselectedText = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final tabIndicator = isDarkMode ? Colors.white : Colors.black;
    final searchBg = isDarkMode ? Colors.grey[900]! : Colors.grey[100]!;
    final searchText = isDarkMode ? Colors.white : Colors.black;
    final searchHint = isDarkMode ? Colors.grey[500]! : Colors.grey[500]!;
    final searchIcon = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
    final focusedBorderColor = isDarkMode ? Colors.blue[400]! : Colors.black;
    final breakingBg = isDarkMode ? Colors.blue[900] : Colors.orange[700];
    final breakingText = Colors.white;
    final breakingSubText = isDarkMode ? Colors.grey[300] : Colors.grey[800];
    
    // Colors for error states
    final errorIconColor = isDarkMode ? Colors.grey[400] : Colors.grey[400];
    final errorTextColor = isDarkMode ? Colors.grey[200] : Colors.black;
    final errorSubTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final loadingTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    
    // Colors for dividers
    final dividerColor = isDarkMode ? Colors.grey[800] : Colors.grey[300];
    
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: appBarBg,
        title: const Text(
          'News',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: tabIndicator,
          indicatorWeight: 3,
          labelColor: tabSelectedText,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelColor: tabUnselectedText,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: _categories.map((category) => 
            Tab(
              text: category,
              height: 40,
            )
          ).toList(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar (hide when Egyptian News tab is selected)
          if (_tabController.index != 7)
            Container(
              color: appBarBg,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search news...',
                      hintStyle: TextStyle(color: searchHint, fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: searchIcon, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.clear, color: searchIcon, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _loadInitialNews();
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: focusedBorderColor),
                      ),
                      filled: true,
                      fillColor: searchBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    style: TextStyle(fontSize: 14, color: searchText),
                    onSubmitted: _handleSearch,
                  ),
                  
                  // Breaking news section (only for Top Headlines tab)
                  if (_showBreakingNews && _tabController.index == 0)
                    SizeTransition(
                      sizeFactor: _breakingNewsAnimation,
                      child: FadeTransition(
                        opacity: _breakingNewsAnimation,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: breakingBg,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Breaking News',
                                      style: TextStyle(
                                        color: breakingText,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Latest breaking updates',
                                    style: TextStyle(
                                      color: breakingSubText,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              
                              // Horizontal breaking news list
                              SizedBox(
                                height: 140,
                                child: _isLoadingBreaking 
                                  ? Center(child: CircularProgressIndicator(color: focusedBorderColor))
                                  : _breakingNews.isEmpty 
                                      ? Center(
                                          child: Text(
                                            'No breaking news available',
                                            style: TextStyle(color: errorSubTextColor, fontSize: 14),
                                          ),
                                        )
                                      : ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                          itemCount: _breakingNews.length,
                                          itemBuilder: (context, index) {
                                            final article = _breakingNews[index];
                                            return _buildBreakingNewsCard(article);
                                          },
                                        ),
                              ),
                              
                              // Divider
                              Divider(color: dividerColor, height: 1),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          
          // News content
          Expanded(
            child: _tabController.index == 7
                ? _buildEgyptianSourcesSection() // Show Egyptian news sources for tab 7
                : BlocBuilder<NewsCubit, NewsState>(
                    builder: (context, state) {
                      if (state is NewsLoading) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const PercentCircleIndicator(),
                              const SizedBox(height: 16),
                              Text(
                                'Loading news...',
                                style: TextStyle(
                                  color: loadingTextColor,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      } else if (state is NewsError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 50,
                                color: errorIconColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Something went wrong',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: errorTextColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 40),
                                child: Text(
                                  state.message,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: errorSubTextColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _newsCubit.refreshNews,
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text('Try Again'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                  textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else if (state is NewsLoaded) {
                        final articles = state.articles;
                        
                        if (articles.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.newspaper,
                                  size: 50,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No news articles found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try another category or search term',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        return RefreshIndicator(
                          onRefresh: () => _newsCubit.refreshNews(),
                          color: Colors.black,
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.only(bottom: 24, top: 8),
                            itemCount: articles.length,
                            itemBuilder: (context, index) {
                              final article = articles[index];
                              
                              // Show first article as feature card
                              if (index == 0) {
                                return NewsCard(
                                  article: article,
                                  isFeatureCard: true,
                                );
                              }
                              
                              return NewsCard(
                                article: article,
                                isFeatureCard: false,
                              );
                            },
                          ),
                        );
                      } else if (state is NewsCategoriesLoaded) {
                        // Handle multiple categories loaded state
                        return Center(
                          child: Text('Categories loaded'),
                        );
                      }
                      
                      // Default state
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.newspaper,
                              size: 50,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No news loaded',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakingNewsCard(NewsArticle article) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewsDetailPage(article: article),
          ),
        );
      },
      child: Container(
        width: 250,
        margin: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.black.withOpacity(0.2) 
                : Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
              child: SizedBox(
                width: 90,
                height: double.infinity,
                child: article.imageUrl.isNotEmpty
                  ? Image.network(
                      article.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200],
                          child: Icon(Icons.image_not_supported, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[600] : Colors.grey[400]),
                        );
                      },
                    )
                  : Container(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200],
                      child: Icon(Icons.newspaper, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[600] : Colors.grey[400]),
                    ),
              ),
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      article.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    Spacer(),
                    
                    // Time
                    Text(
                      _formatBreakingTime(article.publishedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
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
  }
  
  String _formatBreakingTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  Widget _buildEgyptianSourcesSection() {
    if (_isLoadingEgyptianSources) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const PercentCircleIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading Egyptian news sources...',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_egyptianSources.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.language_outlined,
              size: 50,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Egyptian news sources found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please try again later',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadEgyptianSources,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ],
        ),
      );
    }

    // Display available Egyptian sources
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _egyptianSources.length,
      itemBuilder: (context, index) {
        final source = _egyptianSources[index];
        final sourceName = source['name'] ?? 'Unknown Source';
        final sourceId = source['id'] ?? '';
        final sourceDescription = source['description'] ?? 'No description available';
        final sourceIcon = source['icon'] ?? '';
        final sourceCategory = source['category'] != null && source['category'] is List && (source['category'] as List).isNotEmpty
            ? (source['category'] as List)[0]
            : 'News';

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => _selectEgyptianSource(sourceId, sourceName),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source Icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: sourceIcon.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              sourceIcon,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(Icons.language, color: Colors.grey[400], size: 30),
                            ),
                          )
                        : Icon(Icons.language, color: Colors.grey[400], size: 30),
                  ),
                  const SizedBox(width: 16),
                  // Source Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sourceName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sourceDescription,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Category tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            sourceCategory,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
} 