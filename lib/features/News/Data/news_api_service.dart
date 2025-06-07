import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:talkifyapp/features/News/Domain/Entitie/news_article.dart';

class NewsApiService {
  static const String _baseUrl = 'https://newsapi.org/v2';
  static const String _apiKey = '2d0fdd63b5a1443e82ad99921a11c720';
  
  // NewsData.io API for Egyptian news
  static const String _newsDataBaseUrl = 'https://newsdata.io/api/1';
  static const String _newsDataApiKey = 'pub_fd9ba2b855324de3a2359e5bcf39ce31';
  
  // Egyptian news sources from NewsData.io
  static const List<String> _egyptianSources = [
    'almasryalyoum', 'elaosboa', 'shorouknews', 'yallakora', 
    'almesryoon', 'egypt_today', 'alnaharegypt'
  ];
  
  // Fetch top headlines (general news)
  Future<List<NewsArticle>> fetchEgyptNews() async {
    try {
      // Try to fetch from NewsData.io first
      final egyptNews = await _getNewsDataEgypt(
        '$_newsDataBaseUrl/news?country=eg&apikey=$_newsDataApiKey'
      );
      
      if (egyptNews.isNotEmpty) {
        print('Got ${egyptNews.length} Egyptian news articles from NewsData.io');
        return egyptNews;
      }
    } catch (e) {
      print('Error fetching Egyptian news from NewsData.io: $e');
    }
    
    // Fall back to original implementation
    return _getNewsData('$_baseUrl/top-headlines?language=en&apiKey=$_apiKey');
  }
  
  // Fetch breaking news
  Future<List<NewsArticle>> fetchEgyptBreakingNews() async {
    try {
      // Try to fetch Egypt breaking news from NewsData.io
      final egyptNews = await _getNewsDataEgypt(
        '$_newsDataBaseUrl/news?country=eg&category=top&apikey=$_newsDataApiKey'
      );
      
      if (egyptNews.isNotEmpty) {
        print('Got ${egyptNews.length} Egyptian breaking news from NewsData.io');
        return egyptNews;
      }
    } catch (e) {
      print('Error fetching Egyptian breaking news from NewsData.io: $e');
    }
    
    // Fall back to original implementation
    return _getNewsData('$_baseUrl/top-headlines?language=en&sortBy=publishedAt&apiKey=$_apiKey');
  }
  
  // Fetch politics news
  Future<List<NewsArticle>> fetchEgyptPoliticsNews() async {
    try {
      // Try to fetch Egypt politics news from NewsData.io
      final egyptNews = await _getNewsDataEgypt(
        '$_newsDataBaseUrl/news?country=eg&category=politics&apikey=$_newsDataApiKey'
      );
      
      if (egyptNews.isNotEmpty) {
        print('Got ${egyptNews.length} Egyptian politics news from NewsData.io');
        return egyptNews;
      }
    } catch (e) {
      print('Error fetching Egyptian politics news from NewsData.io: $e');
    }
    
    // Fall back to original implementation
    return _getNewsData('$_baseUrl/everything?q=politics&language=en&sortBy=publishedAt&pageSize=15&apiKey=$_apiKey');
  }
  
  // Fetch news by category with Egyptian news prioritized
  Future<List<NewsArticle>> fetchNewsByCategory(String category) async {
    // Map our UI categories to NewsData.io categories
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
        apiCategory = 'top';
        break;
    }
    
    try {
      // Try to fetch from NewsData.io first for Egyptian news by category
      final egyptNews = await _getNewsDataEgypt(
        '$_newsDataBaseUrl/news?country=eg&category=$apiCategory&apikey=$_newsDataApiKey'
      );
      
      if (egyptNews.isNotEmpty) {
        print('Got ${egyptNews.length} Egyptian news articles for category $category from NewsData.io');
        return egyptNews;
      }
    } catch (e) {
      print('Error fetching Egyptian news by category from NewsData.io: $e');
    }

    // If no results, fall back to original implementation
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
  
  // Search news with query, including Egyptian news
  Future<List<NewsArticle>> searchNews(String query) async {
    try {
      // Try to search Egyptian news from NewsData.io first
      final egyptNews = await _getNewsDataEgypt(
        '$_newsDataBaseUrl/news?country=eg&q=$query&apikey=$_newsDataApiKey'
      );
      
      if (egyptNews.isNotEmpty) {
        print('Got ${egyptNews.length} Egyptian news articles for search "$query" from NewsData.io');
        return egyptNews;
      }
    } catch (e) {
      print('Error searching Egyptian news from NewsData.io: $e');
    }
    
    // Fall back to original implementation
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
  
  // Helper method to fetch and parse data from NewsData.io API for Egyptian news
  Future<List<NewsArticle>> _getNewsDataEgypt(String url) async {
    try {
      print('Fetching Egyptian news from NewsData.io: $url'); // Debug log
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['status'] == 'success') {
          final List<dynamic> articles = data['results'] ?? [];
          print('Received ${articles.length} Egyptian news articles from NewsData.io'); // Debug log
          
          // Filter to ensure minimum quality standards
          final filteredArticles = articles.where((article) {
            return article['title'] != null && 
                  article['title'].toString().trim().isNotEmpty;
          }).toList();
          
          // Convert to NewsArticle objects
          return filteredArticles.map((article) {
            // Try to detect the article category
            String detectedCategory = article['category']?.isNotEmpty == true 
                ? article['category'][0] 
                : 'general';
            
            return NewsArticle(
              id: article['article_id'] ?? article['link'] ?? '',
              title: article['title'] ?? '',
              description: article['description'] ?? '',
              content: article['content'] ?? '',
              author: article['creator']?.isNotEmpty == true ? article['creator'][0] : 'Unknown',
              sourceName: article['source_id'] ?? 'Egyptian News',
              url: article['link'] ?? '',
              imageUrl: article['image_url'] ?? '',
              publishedAt: article['pubDate'] != null 
                  ? DateTime.parse(article['pubDate']) 
                  : DateTime.now(),
              category: detectedCategory,
            );
          }).toList();
        } else {
          print('NewsData.io API Error: ${data['message'] ?? "Unknown error"}'); // Debug log
          throw Exception('NewsData.io API Error: ${data['message'] ?? "Unknown error"}');
        }
      } else {
        print('Failed to load news from NewsData.io: ${response.statusCode}'); // Debug log
        throw Exception('Failed to load news from NewsData.io: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching news from NewsData.io: $e'); // Debug log
      throw Exception('Error fetching news from NewsData.io: $e');
    }
  }
  
  // Original helper method to fetch and parse data from News API
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

  // Get available Egyptian news sources
  Future<List<Map<String, dynamic>>> getEgyptianNewsSources() async {
    try {
      final url = '$_newsDataBaseUrl/sources?country=eg&apikey=$_newsDataApiKey';
      print('Fetching Egyptian news sources from: $url');
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['status'] == 'success') {
          final List<dynamic> sources = data['results'] ?? [];
          print('Received ${sources.length} Egyptian news sources');
          
          return sources.map<Map<String, dynamic>>((source) => source as Map<String, dynamic>).toList();
        } else {
          print('NewsData.io API Error: ${data['message'] ?? "Unknown error"}');
          throw Exception('NewsData.io API Error: ${data['message'] ?? "Unknown error"}');
        }
      } else {
        print('Failed to load Egyptian news sources: ${response.statusCode}');
        throw Exception('Failed to load Egyptian news sources: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching Egyptian news sources: $e');
      throw Exception('Error fetching Egyptian news sources: $e');
    }
  }
} 