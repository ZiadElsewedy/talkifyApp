import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/News/Domain/Entitie/news_article.dart';
import 'package:talkifyapp/features/News/Domain/repo/news_repository.dart';
import 'package:talkifyapp/features/News/Presentation/Cubit/news_states.dart';

class NewsCubit extends Cubit<NewsState> {
  final NewsRepository newsRepository;
  
  // Cache for articles by category
  final Map<String, List<NewsArticle>> _articlesByCategory = {};
  
  // Cache for Egyptian news sources
  List<Map<String, dynamic>>? _egyptianSources;
  
  NewsCubit({required this.newsRepository}) : super(NewsInitial());
  
  // Safe emit method to prevent "emit after close" errors
  void safeEmit(NewsState state) {
    try {
      if (!isClosed) {
        emit(state);
      }
    } catch (e) {
      print('Error emitting state: $e');
    }
  }
  
  // Fetch top headlines
  Future<void> fetchTopHeadlines() async {
    try {
      safeEmit(NewsLoading());
      final articles = await newsRepository.fetchTopHeadlines();
      
      if (articles.isEmpty) {
        print('NewsCubit: No articles returned for top headlines');
        // Handle empty articles with a friendly error message
        safeEmit(NewsError('We\'re having trouble loading the latest news. Please try again later.'));
        return;
      }
      
      // Cache the results for quick access
      _articlesByCategory['general'] = articles;
      
      safeEmit(NewsLoaded(articles, category: 'general'));
    } catch (e) {
      print('NewsCubit: Error in fetchTopHeadlines: $e');
      
      // Check if we already have cached general news
      if (_articlesByCategory.containsKey('general') && 
          _articlesByCategory['general']!.isNotEmpty) {
        print('NewsCubit: Using cached general news');
        safeEmit(NewsLoaded(_articlesByCategory['general']!, category: 'general'));
      } else {
        safeEmit(NewsError('Unable to load news at this time. Please check your internet connection and try again.'));
      }
    }
  }
  
  // Fetch breaking news
  Future<void> fetchBreakingNews() async {
    try {
      safeEmit(NewsLoading());
      final articles = await newsRepository.fetchBreakingNews();
      safeEmit(NewsLoaded(articles, category: 'breaking'));
    } catch (e) {
      safeEmit(NewsError('Failed to fetch breaking news: $e'));
    }
  }
  
  // Fetch politics news
  Future<void> fetchPoliticsNews() async {
    try {
      safeEmit(NewsLoading());
      final articles = await newsRepository.fetchPoliticsNews();
      safeEmit(NewsLoaded(articles, category: 'politics'));
    } catch (e) {
      safeEmit(NewsError('Failed to fetch politics news: $e'));
    }
  }
  
  // Fetch news by category
  Future<void> fetchNewsByCategory(String category) async {
    try {
      safeEmit(NewsLoading());
      final articles = await newsRepository.fetchNewsByCategory(category);
      
      // Cache the results
      _articlesByCategory[category] = articles;
      
      safeEmit(NewsLoaded(articles, category: category));
    } catch (e) {
      safeEmit(NewsError('Failed to fetch $category news: $e'));
    }
  }
  
  // Search news
  Future<void> searchNews(String query) async {
    if (query.isEmpty) {
      return fetchTopHeadlines();
    }
    
    try {
      safeEmit(NewsLoading());
      final articles = await newsRepository.searchNews(query);
      safeEmit(NewsLoaded(articles, category: 'search'));
    } catch (e) {
      safeEmit(NewsError('Failed to search news: $e'));
    }
  }
  
  // Get Egyptian news sources
  Future<List<Map<String, dynamic>>> getEgyptianNewsSources() async {
    if (_egyptianSources != null && _egyptianSources!.isNotEmpty) {
      return _egyptianSources!;
    }
    
    try {
      _egyptianSources = await newsRepository.getEgyptianNewsSources();
      return _egyptianSources!;
    } catch (e) {
      print('Error fetching Egyptian news sources: $e');
      return [];
    }
  }
  
  // Fetch news from a specific Egyptian source
  Future<void> fetchNewsFromEgyptianSource(String sourceId) async {
    try {
      emit(NewsLoading());
      
      // Use search with the source ID to filter by that source
      final articles = await newsRepository.searchNews('source:$sourceId');
      
      emit(NewsLoaded(articles, category: 'egyptian_source:$sourceId'));
    } catch (e) {
      emit(NewsError('Failed to fetch news from Egyptian source $sourceId: $e'));
    }
  }
  
  // Load multiple categories at once
  Future<void> loadAllCategories() async {
    try {
      safeEmit(NewsLoading());
      
      // Define categories to fetch
      final categories = ['business', 'sports', 'technology', 'culture', 'health'];
      
      // Clear cache
      _articlesByCategory.clear();
      
      // Add general news to cache
      try {
        final topHeadlines = await newsRepository.fetchTopHeadlines();
        _articlesByCategory['general'] = topHeadlines;
      } catch (e) {
        print('Error loading top headlines: $e');
        _articlesByCategory['general'] = [];
      }
      
      // Load each category in parallel
      await Future.wait(
        categories.map((category) async {
          try {
            final articles = await newsRepository.fetchNewsByCategory(category);
            _articlesByCategory[category] = articles;
          } catch (e) {
            print('Error loading $category: $e');
            _articlesByCategory[category] = [];
          }
        })
      );
      
      safeEmit(NewsCategoriesLoaded(_articlesByCategory));
    } catch (e) {
      safeEmit(NewsError('Failed to load categories: $e'));
    }
  }

  // Refresh news for current state
  Future<void> refreshNews() async {
    final currentState = state;
    
    try {
      if (currentState is NewsLoaded) {
        if (currentState.category.startsWith('egyptian_source:')) {
          // Extract the source ID from the category
          final sourceId = currentState.category.split(':')[1];
          await fetchNewsFromEgyptianSource(sourceId);
        } else {
          switch (currentState.category) {
            case 'general':
              await fetchTopHeadlines();
              break;
            case 'breaking':
              await fetchBreakingNews();
              break;
            case 'politics':
              await fetchPoliticsNews();
              break;
            default:
              await fetchNewsByCategory(currentState.category);
              break;
          }
        }
      } else if (currentState is NewsCategoriesLoaded) {
        await loadAllCategories();
      } else if (currentState is NewsError) {
        // If we're in an error state, try to load general news
        await fetchTopHeadlines();
      } else {
        await fetchTopHeadlines();
      }
    } catch (e) {
      print('Error refreshing news: $e');
      // Even if refresh fails, don't change the state if we already have data
      if (!(state is NewsLoaded || state is NewsCategoriesLoaded)) {
        safeEmit(NewsError('Failed to refresh news. Please try again later.'));
      }
    }
  }
} 