import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/News/Domain/Entitie/news_article.dart';
import 'package:talkifyapp/features/News/Domain/repo/news_repository.dart';
import 'package:talkifyapp/features/News/Presentation/Cubit/news_states.dart';

class NewsCubit extends Cubit<NewsState> {
  final NewsRepository newsRepository;
  
  // Cache for articles by category
  final Map<String, List<NewsArticle>> _articlesByCategory = {};
  
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
      safeEmit(NewsLoaded(articles, category: 'general'));
    } catch (e) {
      safeEmit(NewsError('Failed to fetch top headlines: $e'));
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
    
    if (currentState is NewsLoaded) {
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
    } else if (currentState is NewsCategoriesLoaded) {
      await loadAllCategories();
    } else {
      await fetchTopHeadlines();
    }
  }
} 