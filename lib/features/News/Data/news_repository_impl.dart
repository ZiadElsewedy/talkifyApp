import 'package:talkifyapp/features/News/Data/news_api_service.dart';
import 'package:talkifyapp/features/News/Domain/Entitie/news_article.dart';
import 'package:talkifyapp/features/News/Domain/repo/news_repository.dart';

class NewsRepositoryImpl implements NewsRepository {
  final NewsApiService _apiService;

  NewsRepositoryImpl({NewsApiService? apiService})
      : _apiService = apiService ?? NewsApiService();

  @override
  Future<List<NewsArticle>> fetchTopHeadlines() async {
    try {
      final articles = await _apiService.fetchEgyptNews();
      print('Repository: Got ${articles.length} top headlines');
      return articles;
    } catch (e) {
      print('Repository Error in fetchTopHeadlines: $e');
      // Return empty list instead of throwing to avoid app crashes
      return [];
    }
  }

  @override
  Future<List<NewsArticle>> fetchBreakingNews() async {
    try {
      final articles = await _apiService.fetchEgyptBreakingNews();
      print('Repository: Got ${articles.length} breaking news articles');
      return articles;
    } catch (e) {
      print('Repository Error in fetchBreakingNews: $e');
      return [];
    }
  }

  @override
  Future<List<NewsArticle>> fetchPoliticsNews() async {
    try {
      final articles = await _apiService.fetchEgyptPoliticsNews();
      print('Repository: Got ${articles.length} politics news articles');
      return articles;
    } catch (e) {
      print('Repository Error in fetchPoliticsNews: $e');
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

  @override
  Future<List<Map<String, dynamic>>> getEgyptianNewsSources() async {
    try {
      final sources = await _apiService.getEgyptianNewsSources();
      print('Repository: Got ${sources.length} Egyptian news sources');
      return sources;
    } catch (e) {
      print('Repository Error in getEgyptianNewsSources: $e');
      // Return empty list instead of throwing
      return [];
    }
  }
} 