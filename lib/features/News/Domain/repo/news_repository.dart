import 'package:talkifyapp/features/News/Domain/Entitie/news_article.dart';

abstract class NewsRepository {
  // Fetch top headlines related to Egypt
  Future<List<NewsArticle>> fetchEgyptNews();
  
  // Fetch breaking news about Egypt
  Future<List<NewsArticle>> fetchEgyptBreakingNews();
  
  // Fetch Egypt politics news
  Future<List<NewsArticle>> fetchEgyptPoliticsNews();
  
  // Fetch news by category (business, entertainment, health, science, sports, technology)
  Future<List<NewsArticle>> fetchNewsByCategory(String category);
  
  // Search news with a specific query
  Future<List<NewsArticle>> searchNews(String query);
} 