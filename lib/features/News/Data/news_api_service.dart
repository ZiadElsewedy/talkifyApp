import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:talkifyapp/features/News/Domain/Entitie/news_article.dart';

class NewsApiService {
  static const String _baseUrl = 'https://newsapi.org/v2';
  static const String _apiKey = '2d0fdd63b5a1443e82ad99921a11c720';
  
  // Fetch top headlines from Egypt
  Future<List<NewsArticle>> fetchEgyptNews() async {
    // Using 'everything' endpoint with Egypt query for better results
    return _getNewsData('$_baseUrl/everything?q=Egypt&language=en&sortBy=publishedAt&pageSize=15&apiKey=$_apiKey');
  }
  
  // Fetch breaking news about Egypt
  Future<List<NewsArticle>> fetchEgyptBreakingNews() async {
    return _getNewsData('$_baseUrl/everything?q=Egypt+breaking&language=en&sortBy=publishedAt&pageSize=10&apiKey=$_apiKey');
  }
  
  // Fetch Egypt politics news
  Future<List<NewsArticle>> fetchEgyptPoliticsNews() async {
    return _getNewsData('$_baseUrl/everything?q=Egypt+politics&language=en&sortBy=publishedAt&pageSize=15&apiKey=$_apiKey');
  }
  
  // Fetch news by category in Egypt
  Future<List<NewsArticle>> fetchNewsByCategory(String category) async {
    // Combining category with Egypt for better results
    return _getNewsData('$_baseUrl/everything?q=$category+Egypt&language=en&sortBy=publishedAt&pageSize=15&apiKey=$_apiKey');
  }
  
  // Search news with query and filter for Egypt
  Future<List<NewsArticle>> searchNews(String query) async {
    return _getNewsData('$_baseUrl/everything?q=$query+Egypt&language=en&sortBy=publishedAt&pageSize=15&apiKey=$_apiKey');
  }
  
  // Helper method to fetch and parse data
  Future<List<NewsArticle>> _getNewsData(String url) async {
    try {
      print('Fetching news from: $url'); // Debug log
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['status'] == 'ok') {
          final List<dynamic> articles = data['articles'] ?? [];
          print('Received ${articles.length} articles'); // Debug log
          
          // Filter out articles with null or empty fields
          final filteredArticles = articles.where((article) {
            return article['title'] != null && 
                  article['description'] != null &&
                  article['urlToImage'] != null;
          }).toList();
          
          return filteredArticles.map((article) => NewsArticle.fromJson(article)).toList();
        } else {
          print('API Error: ${data['message']}'); // Debug log
          throw Exception('API Error: ${data['message']}');
        }
      } else {
        print('Failed to load news: ${response.statusCode}'); // Debug log
        throw Exception('Failed to load news: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching news: $e'); // Debug log
      throw Exception('Error fetching news: $e');
    }
  }
} 