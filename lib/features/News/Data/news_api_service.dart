import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:talkifyapp/features/News/Domain/Entitie/news_article.dart';

class NewsApiService {
  static const String _baseUrl = 'https://newsapi.org/v2';
  static const String _apiKey = '2d0fdd63b5a1443e82ad99921a11c720';
  
  // Fetch top headlines (general news)
  Future<List<NewsArticle>> fetchEgyptNews() async {
    // Using top-headlines endpoint without country restriction for general news
    return _getNewsData('$_baseUrl/top-headlines?language=en&apiKey=$_apiKey');
  }
  
  // Fetch breaking news
  Future<List<NewsArticle>> fetchEgyptBreakingNews() async {
    // Get the very latest headlines from multiple sources
    return _getNewsData('$_baseUrl/top-headlines?language=en&sortBy=publishedAt&apiKey=$_apiKey');
  }
  
  // Fetch politics news
  Future<List<NewsArticle>> fetchEgyptPoliticsNews() async {
    // Politics is not a standard category, so search for politics in top headlines
    return _getNewsData('$_baseUrl/everything?q=politics&language=en&sortBy=publishedAt&pageSize=15&apiKey=$_apiKey');
  }
  
  // Fetch news by category
  Future<List<NewsArticle>> fetchNewsByCategory(String category) async {
    // Map our UI categories to API supported categories
    String apiCategory;
    
    switch(category.toLowerCase()) {
      case 'sports':
        apiCategory = 'sports';
        break;
      case 'business':
        apiCategory = 'business';
        break;
      case 'technology':
        apiCategory = 'technology';
        break;
      case 'culture':
        apiCategory = 'entertainment';
        break;
      case 'health':
        apiCategory = 'health';
        break;
      default:
        apiCategory = 'general';
        break;
    }
    
    // First try top-headlines with category
    final topHeadlinesUrl = '$_baseUrl/top-headlines?category=$apiCategory&language=en&apiKey=$_apiKey';
    print('Fetching category news from: $topHeadlinesUrl');
    
    try {
      final articles = await _getNewsData(topHeadlinesUrl);
      if (articles.isNotEmpty) {
        return articles;
      }
    } catch (e) {
      print('Error with category top-headlines: $e');
    }
    
    // If no results, try the everything endpoint with more specific search
    final everythingUrl = '$_baseUrl/everything?q=$apiCategory&language=en&sortBy=relevancy&pageSize=20&apiKey=$_apiKey';
    print('Trying everything endpoint: $everythingUrl');
    
    return _getNewsData(everythingUrl);
  }
  
  // Search news with query
  Future<List<NewsArticle>> searchNews(String query) async {
    // First try top-headlines with query
    final topHeadlinesUrl = '$_baseUrl/top-headlines?q=$query&language=en&apiKey=$_apiKey';
    
    try {
      final articles = await _getNewsData(topHeadlinesUrl);
      if (articles.isNotEmpty) {
        return articles;
      }
    } catch (e) {
      print('Error with top headlines search: $e');
    }
    
    // Fall back to everything endpoint for broader search
    return _getNewsData('$_baseUrl/everything?q=$query&language=en&sortBy=publishedAt&pageSize=20&apiKey=$_apiKey');
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
          
          // Filter to ensure minimum quality standards while letting most articles through
          final filteredArticles = articles.where((article) {
            return article['title'] != null && 
                  article['title'].toString().trim().isNotEmpty;
          }).toList();
          
          // Ensure each article has its source category properly tagged
          return filteredArticles.map((article) {
            // If the URL contains category info, enhance the article data
            final url = article['url']?.toString().toLowerCase() ?? '';
            
            // Try to detect the article category from URL if possible
            String detectedCategory = '';
            if (url.contains('sport') || url.contains('athletic') || url.contains('football')) {
              detectedCategory = 'sports';
            } else if (url.contains('business') || url.contains('finance') || url.contains('economy')) {
              detectedCategory = 'business';
            } else if (url.contains('tech') || url.contains('gadget')) {
              detectedCategory = 'technology';
            } else if (url.contains('entertain') || url.contains('celebr') || url.contains('culture') || url.contains('art')) {
              detectedCategory = 'entertainment';
            } else if (url.contains('health') || url.contains('medical') || url.contains('doctor')) {
              detectedCategory = 'health';
            }
            
            // Only add category info if detected
            if (detectedCategory.isNotEmpty) {
              if (article['source'] != null && article['source'] is Map) {
                (article['source'] as Map)['category'] = detectedCategory;
              }
            }
            
            return NewsArticle.fromJson(article);
          }).toList();
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