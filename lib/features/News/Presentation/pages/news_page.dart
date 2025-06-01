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
  List<NewsArticle> _breakingNews = [];
  bool _isLoadingBreaking = false;
  
  final List<String> _categories = [
    'Egypt News',
    'Politics',
    'Business',
    'Sports',
    'Technology',
    'Culture',
    'Health',
  ];

  @override
  void initState() {
    super.initState();
    
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(_handleTabChange);
    
    _newsCubit = context.read<NewsCubit>();
    _loadInitialNews();
  }

  void _loadInitialNews() {
    // Load Egypt news (general category)
    _newsCubit.fetchEgyptNews();
    
    // Also load breaking news for the Egypt News tab
    _loadBreakingNews();
  }

  Future<void> _loadBreakingNews() async {
    setState(() {
      _isLoadingBreaking = true;
    });
    
    try {
      final cubit = context.read<NewsCubit>();
      final repository = cubit.newsRepository;
      _breakingNews = await repository.fetchEgyptBreakingNews();
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
    if (!_tabController.indexIsChanging) {
      String category;
      
      // Map our custom categories to API categories
      switch (_tabController.index) {
        case 0: // Egypt News
          _newsCubit.fetchEgyptNews();
          // Also refresh breaking news when switching to Egypt News tab
          _loadBreakingNews();
          return;
        case 1: // Politics
          _newsCubit.fetchEgyptPoliticsNews();
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
        default:
          category = 'general';
          break;
      }
      
      _newsCubit.fetchNewsByCategory(category);
    }
  }

  void _handleSearch(String query) {
    if (query.isNotEmpty) {
      _newsCubit.searchNews(query);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        title: Row(
          children: [
            Icon(
              Icons.newspaper,
              color: Colors.black,
              size: 24,
            ),
            SizedBox(width: 10),
            Text(
              'Talkify News',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorWeight: 3,
              indicatorColor: Colors.black,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 15,
              ),
              tabs: _categories.map((category) => 
                Tab(text: category)
              ).toList(),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search news...',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 20),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[600], size: 20),
                  onPressed: () {
                    _searchController.clear();
                    _loadInitialNews();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: TextStyle(fontSize: 14, color: Colors.black),
              onSubmitted: _handleSearch,
            ),
          ),
          
          // Breaking news section (only show for Egypt News tab)
          if (_tabController.index == 0 && _breakingNews.isNotEmpty) 
            _buildBreakingNewsSection(),
          
          // News content
          Expanded(
            child: BlocBuilder<NewsCubit, NewsState>(
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
                            color: Colors.grey[600],
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
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Something went wrong',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
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
                      padding: const EdgeInsets.only(bottom: 24),
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
                  // This state is used when multiple categories are loaded at once
                  final currentCategory = _categories[_tabController.index].toLowerCase();
                  final articles = state.articlesByCategory[currentCategory] ?? [];
                  
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
                            'No news articles found in this category',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try another category',
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
                      padding: const EdgeInsets.only(bottom: 24),
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
                }
                
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

  Widget _buildBreakingNewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'BREAKING',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Latest updates from Egypt',
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        
        // Horizontal breaking news list
        SizedBox(
          height: 140,
          child: _isLoadingBreaking 
            ? Center(child: CircularProgressIndicator(color: Colors.grey[700]))
            : ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 12),
                itemCount: _breakingNews.length,
                itemBuilder: (context, index) {
                  final article = _breakingNews[index];
                  return _buildBreakingNewsCard(article);
                },
              ),
        ),
        
        // Divider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Divider(color: Colors.grey[300], height: 1),
        ),
      ],
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
        margin: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
                          color: Colors.grey[200],
                          child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: Icon(Icons.newspaper, color: Colors.grey[400]),
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
                        color: Colors.black,
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
                        color: Colors.grey[600],
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
} 