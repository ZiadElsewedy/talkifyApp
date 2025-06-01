import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/News/Domain/Entitie/news_article.dart';
import 'package:talkifyapp/features/News/Domain/repo/news_repository.dart';
import 'package:talkifyapp/features/News/Presentation/Cubit/news_states.dart';

class NewsCubit extends Cubit<NewsState> {
  final NewsRepository newsRepository;
  
  // Cache for articles by category
  final Map<String, List<NewsArticle>> _articlesByCategory = {};
  
  NewsCubit({required this.newsRepository}) : super(NewsInitial());
  
  // Fetch Egypt news (top headlines)
  Future<void> fetchEgyptNews() async {
    try {
      emit(NewsLoading());
      final articles = await newsRepository.fetchEgyptNews();
      emit(NewsLoaded(articles, category: 'egypt_news'));
    } catch (e) {
      emit(NewsError('Failed to fetch Egypt news: $e'));
    }
  }
  
  // Fetch Egypt breaking news
  Future<void> fetchEgyptBreakingNews() async {
    try {
      emit(NewsLoading());
      final articles = await newsRepository.fetchEgyptBreakingNews();
      emit(NewsLoaded(articles, category: 'egypt_breaking'));
    } catch (e) {
      emit(NewsError('Failed to fetch Egypt breaking news: $e'));
    }
  }
  
  // Fetch Egypt politics news
  Future<void> fetchEgyptPoliticsNews() async {
    try {
      emit(NewsLoading());
      final articles = await newsRepository.fetchEgyptPoliticsNews();
      emit(NewsLoaded(articles, category: 'politics'));
    } catch (e) {
      emit(NewsError('Failed to fetch Egypt politics news: $e'));
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
  
  // Search news related to Egypt
  Future<void> searchNews(String query) async {
    if (query.isEmpty) {
      return fetchEgyptNews();
    }
    
    try {
      emit(NewsLoading());
      final articles = await newsRepository.searchNews(query);
      emit(NewsLoaded(articles, category: 'search'));
    } catch (e) {
      emit(NewsError('Failed to search news: $e'));
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
      
      // Add Egypt news to cache
      try {
        final egyptNews = await newsRepository.fetchEgyptNews();
        _articlesByCategory['egypt_news'] = egyptNews;
      } catch (e) {
        print('Error loading Egypt news: $e');
        _articlesByCategory['egypt_news'] = [];
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
      switch (currentState.category) {
        case 'egypt_news':
          await fetchEgyptNews();
          break;
        case 'egypt_breaking':
          await fetchEgyptBreakingNews();
          break;
        case 'politics':
          await fetchEgyptPoliticsNews();
          break;
        default:
          await fetchNewsByCategory(currentState.category);
          break;
      }
    } else if (currentState is NewsCategoriesLoaded) {
      await loadAllCategories();
    } else {
      await fetchEgyptNews();
    }
  }
} 