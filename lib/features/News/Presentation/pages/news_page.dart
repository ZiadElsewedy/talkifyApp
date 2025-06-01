import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/News/Domain/Entitie/news_article.dart';
import 'package:talkifyapp/features/News/Domain/repo/news_repository.dart';
import 'package:talkifyapp/features/News/Presentation/Cubit/news_cubit.dart';
import 'package:talkifyapp/features/News/Presentation/Cubit/news_states.dart';
import 'package:talkifyapp/features/News/Presentation/components/news_card.dart';
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
  
  final List<String> _categories = [
    'General',
    'Business',
    'Sports',
    'Technology',
    'Entertainment',
    'Health',
    'Science',
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
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      final category = _categories[_tabController.index].toLowerCase();
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Egypt News',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 1,
          ),
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
              indicatorColor: Colors.blue,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
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
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Egypt news...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _loadInitialNews();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              onSubmitted: _handleSearch,
            ),
          ),
          
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
                            fontSize: 16,
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
                          size: 60,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Something went wrong',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
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
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _newsCubit.refreshNews,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No news articles found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try another category or search term',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return RefreshIndicator(
                    onRefresh: () => _newsCubit.refreshNews(),
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
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No news articles found in this category',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try another category',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return RefreshIndicator(
                    onRefresh: () => _newsCubit.refreshNews(),
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
                        size: 60,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No news loaded',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
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
} 