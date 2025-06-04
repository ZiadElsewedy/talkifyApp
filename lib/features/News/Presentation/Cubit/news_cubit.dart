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
  
  // Fetch top headlines
  Future<void> fetchTopHeadlines() async {
    try {
      emit(NewsLoading());
      final articles = await newsRepository.fetchTopHeadlines();
      emit(NewsLoaded(articles, category: 'general'));
    } catch (e) {
      emit(NewsError('Failed to fetch top headlines: $e'));
    }
  }
  
  // Fetch breaking news
  Future<void> fetchBreakingNews() async {
    try {
      emit(NewsLoading());
      final articles = await newsRepository.fetchBreakingNews();
      emit(NewsLoaded(articles, category: 'breaking'));
    } catch (e) {
      emit(NewsError('Failed to fetch breaking news: $e'));
    }
  }
  
  // Fetch politics news
  Future<void> fetchPoliticsNews() async {
    try {
      emit(NewsLoading());
      final articles = await newsRepository.fetchPoliticsNews();
      emit(NewsLoaded(articles, category: 'politics'));
    } catch (e) {
      emit(NewsError('Failed to fetch politics news: $e'));
    }
  }
  
  // Fetch news by category
  Future<void> fetchNewsByCategory(String category) async {
    try {
      emit(NewsLoading());
      final articles = await newsRepository.fetchNewsByCategory(category);
      
      // Cache the results
      _articlesByCategory[category] = articles;
      
      emit(NewsLoaded(articles, category: category));
    } catch (e) {
      emit(NewsError('Failed to fetch $category news: $e'));
    }
  }
  
  // Search news
  Future<void> searchNews(String query) async {
    if (query.isEmpty) {
      return fetchTopHeadlines();
    }
    
    try {
      emit(NewsLoading());
      final articles = await newsRepository.searchNews(query);
      emit(NewsLoaded(articles, category: 'search'));
    } catch (e) {
      emit(NewsError('Failed to search news: $e'));
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
      emit(NewsLoading());
      
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
      
      emit(NewsCategoriesLoaded(_articlesByCategory));
    } catch (e) {
      emit(NewsError('Failed to load categories: $e'));
    }
  }

  // Refresh news for current state
  Future<void> refreshNews() async {
    final currentState = state;
    
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
    } else {
      await fetchTopHeadlines();
    }
  }
} 