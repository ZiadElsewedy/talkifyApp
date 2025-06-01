import 'package:talkifyapp/features/News/Data/news_api_service.dart';
import 'package:talkifyapp/features/News/Domain/Entitie/news_article.dart';
import 'package:talkifyapp/features/News/Domain/repo/news_repository.dart';

class NewsRepositoryImpl implements NewsRepository {
  final NewsApiService _apiService;

  NewsRepositoryImpl({NewsApiService? apiService})
      : _apiService = apiService ?? NewsApiService();

  @override
  Future<List<NewsArticle>> fetchEgyptNews() async {
    try {
      final articles = await _apiService.fetchEgyptNews();
      print('Repository: Got ${articles.length} Egypt news articles');
      return articles;
    } catch (e) {
      print('Repository Error in fetchEgyptNews: $e');
      // Return empty list instead of throwing to avoid app crashes
      return [];
    }
  }

  @override
  Future<List<NewsArticle>> fetchEgyptBreakingNews() async {
    try {
      final articles = await _apiService.fetchEgyptBreakingNews();
      print('Repository: Got ${articles.length} Egypt breaking news articles');
      return articles;
    } catch (e) {
      print('Repository Error in fetchEgyptBreakingNews: $e');
      return [];
    }
  }

  @override
  Future<List<NewsArticle>> fetchEgyptPoliticsNews() async {
    try {
      final articles = await _apiService.fetchEgyptPoliticsNews();
      print('Repository: Got ${articles.length} Egypt politics news articles');
      return articles;
    } catch (e) {
      print('Repository Error in fetchEgyptPoliticsNews: $e');
      return [];
    }
  }

  @override
  Future<List<NewsArticle>> fetchNewsByCategory(String category) async {
    try {
      final articles = await _apiService.fetchNewsByCategory(category);
      print('Repository: Got ${articles.length} articles for category $category');
      return articles;
    } catch (e) {
      print('Repository Error in fetchNewsByCategory: $e');
      // Return empty list instead of throwing
      return [];
    }
  }

  @override
  Future<List<NewsArticle>> searchNews(String query) async {
    try {
      final articles = await _apiService.searchNews(query);
      print('Repository: Got ${articles.length} articles for search "$query"');
      return articles;
    } catch (e) {
      print('Repository Error in searchNews: $e');
      // Return empty list instead of throwing
      return [];
    }
  }
} 