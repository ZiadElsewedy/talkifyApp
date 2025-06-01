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
      emit(NewsLoaded(articles));
    } catch (e) {
      emit(NewsError('Failed to fetch Egypt news: $e'));
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
  
  // Load multiple categories at once
  Future<void> loadAllCategories() async {
    try {
      emit(NewsLoading());
      
      // Define categories to fetch
      final categories = ['general', 'business', 'sports', 'technology', 'entertainment', 'health', 'science'];
      
      // Clear cache
      _articlesByCategory.clear();
      
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
      await fetchNewsByCategory(currentState.category);
    } else if (currentState is NewsCategoriesLoaded) {
      await loadAllCategories();
    } else {
      await fetchEgyptNews();
    }
  }
} 