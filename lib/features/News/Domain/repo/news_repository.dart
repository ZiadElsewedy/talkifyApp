import 'package:talkifyapp/features/News/Domain/Entitie/news_article.dart';

abstract class NewsRepository {
  // Fetch top headlines worldwide
  Future<List<NewsArticle>> fetchTopHeadlines();
  
  // Fetch breaking news
  Future<List<NewsArticle>> fetchBreakingNews();
  
  // Fetch politics news
  Future<List<NewsArticle>> fetchPoliticsNews();
  
  // Fetch news by category (business, entertainment, health, science, sports, technology)
  Future<List<NewsArticle>> fetchNewsByCategory(String category);
  
  // Search news with a specific query
  Future<List<NewsArticle>> searchNews(String query);
} 