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
  Future<List<NewsArticle>> fetchGeneralNews() async {
    try {
      // Fetch general news with top-headlines endpoint and sources that work well
      final url = '$_baseUrl/top-headlines?country=us&category=general&apiKey=$_apiKey';
      print('Fetching general news from: $url');
      
      final articles = await _getNewsData(url);
      if (articles.isNotEmpty) {
        print('Got ${articles.length} general news articles');
        return articles;
      }
    } catch (e) {
      print('Error fetching general news: $e');
    }
    
    // Try with another region if US fails
    try {
      final ukUrl = '$_baseUrl/top-headlines?country=gb&category=general&apiKey=$_apiKey';
      print('Trying UK general news: $ukUrl');
      
      final articles = await _getNewsData(ukUrl);
      if (articles.isNotEmpty) {
        print('Got ${articles.length} UK general news articles');
        return articles;
      }
    } catch (e) {
      print('Error fetching UK general news: $e');
    }
    
    // Fall back to "everything" endpoint with specific query
    try {
      final fallbackUrl = '$_baseUrl/everything?q=news+today&language=en&sortBy=publishedAt&pageSize=30&apiKey=$_apiKey';
      print('Fetching fallback general news from: $fallbackUrl');
      
      final articles = await _getNewsData(fallbackUrl);
      if (articles.isNotEmpty) {
        return articles;
      }
    } catch (e) {
      print('Error fetching fallback general news: $e');
    }
    
    // Fall back to sources that are known to work well
    try {
      final sourcesUrl = '$_baseUrl/everything?sources=bbc-news,cnn,reuters,associated-press&language=en&pageSize=30&apiKey=$_apiKey';
      print('Trying reliable sources: $sourcesUrl');
      
      final articles = await _getNewsData(sourcesUrl);
      if (articles.isNotEmpty) {
        return articles;
      }
    } catch (e) {
      print('Error fetching from reliable sources: $e');
    }
    
    // Try with NewsData.io for general news
    try {
      final egyptNews = await _getNewsDataEgypt(
        '$_newsDataBaseUrl/news?category=top&language=en&apikey=$_newsDataApiKey'
      );
      
      if (egyptNews.isNotEmpty) {
        print('Got ${egyptNews.length} general news from NewsData.io');
        return egyptNews;
      }
    } catch (e) {
      print('Error fetching general news from NewsData.io: $e');
    }
    
    // Return mock data as last resort to prevent UI breaking
    return _generateMockArticles('general');
  }
  
  // Fetch top headlines (general news) - original implementation
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
    
    try {
    // Fall back to original implementation
      return _getNewsData('$_baseUrl/top-headlines?country=eg&apiKey=$_apiKey');
    } catch (e) {
      print('Error fetching Egyptian news from NewsAPI: $e');
      
      // Return mock data as last resort
      return _generateMockArticles('egypt');
    }
  }
  
  // Fetch breaking news
  Future<List<NewsArticle>> fetchBreakingNews() async {
    try {
      // Fetch breaking news with improved parameters
      final url = '$_baseUrl/top-headlines?category=general&language=en&sortBy=publishedAt&pageSize=20&apiKey=$_apiKey';
      print('Fetching breaking news from: $url');
      
      final articles = await _getNewsData(url);
      if (articles.isNotEmpty) {
        print('Got ${articles.length} breaking news articles');
        return articles;
      }
    } catch (e) {
      print('Error fetching breaking news: $e');
    }
    
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
    
    // Try one more fallback with broader query
    try {
      final fallbackUrl = '$_baseUrl/everything?q=breaking+news&language=en&sortBy=publishedAt&pageSize=20&apiKey=$_apiKey';
      final articles = await _getNewsData(fallbackUrl);
      if (articles.isNotEmpty) {
        return articles;
      }
    } catch (e) {
      print('Error with breaking news fallback: $e');
    }
    
    // Return mock data as last resort
    return _generateMockArticles('breaking');
  }
  
  // Fetch politics news
  Future<List<NewsArticle>> fetchPoliticsNews() async {
    try {
      // Try to fetch politics news directly from NewsAPI
      final url = '$_baseUrl/top-headlines?category=politics&language=en&pageSize=20&apiKey=$_apiKey';
      print('Fetching politics news from: $url');
      
      final articles = await _getNewsData(url);
      if (articles.isNotEmpty) {
        print('Got ${articles.length} politics news articles');
        return articles;
      }
    } catch (e) {
      print('Error fetching politics news: $e');
    }
    
    try {
      // Try with everything endpoint
      final everythingUrl = '$_baseUrl/everything?q=politics&language=en&sortBy=publishedAt&pageSize=20&apiKey=$_apiKey';
      print('Trying everything endpoint for politics: $everythingUrl');
      
      final articles = await _getNewsData(everythingUrl);
      if (articles.isNotEmpty) {
        return articles;
      }
    } catch (e) {
      print('Error with politics everything endpoint: $e');
    }
    
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
    
    // Return mock data as last resort
    return _generateMockArticles('politics');
  }
  
  // Fetch news by category with Egyptian news prioritized
  Future<List<NewsArticle>> fetchNewsByCategory(String category) async {
    // Try to fetch from NewsAPI first
    try {
      // First try top-headlines with category
      final String apiCategory = _mapCategoryToNewsApi(category);
      final topHeadlinesUrl = '$_baseUrl/top-headlines?category=$apiCategory&language=en&pageSize=30&apiKey=$_apiKey';
      print('Fetching category news from: $topHeadlinesUrl');
      
      final articles = await _getNewsData(topHeadlinesUrl);
      if (articles.isNotEmpty) {
        return articles;
      }
    } catch (e) {
      print('Error with category top-headlines: $e');
    }
    
    // Map our UI categories to NewsData.io categories
    String apiCategory = _mapCategoryToNewsDataIo(category);
    
    try {
      // Try to fetch from NewsData.io for Egyptian news by category
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

    // If no results, try the everything endpoint with more specific search
    try {
      final everythingUrl = '$_baseUrl/everything?q=$category&language=en&sortBy=relevancy&pageSize=20&apiKey=$_apiKey';
      print('Trying everything endpoint: $everythingUrl');
      
      final articles = await _getNewsData(everythingUrl);
      if (articles.isNotEmpty) {
        return articles;
      }
    } catch (e) {
      print('Error with everything endpoint: $e');
    }
    
    // Return mock data as last resort
    return _generateMockArticles(category);
  }
  
  // Search news with query, including Egyptian news
  Future<List<NewsArticle>> searchNews(String query) async {
    try {
      // First try top-headlines with query
      final topHeadlinesUrl = '$_baseUrl/top-headlines?q=$query&language=en&apiKey=$_apiKey';
      
      final articles = await _getNewsData(topHeadlinesUrl);
      if (articles.isNotEmpty) {
        return articles;
      }
    } catch (e) {
      print('Error with top headlines search: $e');
    }
    
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
    
    // Fall back to everything endpoint for broader search
    try {
      final everythingUrl = '$_baseUrl/everything?q=$query&language=en&sortBy=publishedAt&pageSize=20&apiKey=$_apiKey';
      final articles = await _getNewsData(everythingUrl);
      if (articles.isNotEmpty) {
        return articles;
      }
    } catch (e) {
      print('Error with everything endpoint: $e');
    }
    
    // Return mock data with search query as category
    return _generateMockArticles('search: $query');
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
          
          // Filter to ensure minimum quality standards and require images
          final filteredArticles = articles.where((article) {
            final hasTitle = article['title'] != null && 
                  article['title'].toString().trim().isNotEmpty;
            final hasImage = article['image_url'] != null && 
                           article['image_url'].toString().trim().isNotEmpty;
            
            return hasTitle && hasImage;
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
  
  // Improved helper method to fetch and parse data from News API
  Future<List<NewsArticle>> _getNewsData(String url) async {
    try {
      print('Fetching news from: $url'); // Debug log
      
      // Add timeout to prevent hanging requests
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('Request timed out for: $url');
          throw Exception('Request timed out');
        },
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['status'] == 'ok') {
          final List<dynamic> articles = data['articles'] ?? [];
          print('Received ${articles.length} articles'); // Debug log
          
          if (articles.isEmpty) {
            print('API returned empty articles list despite OK status');
            return [];
          }
          
          // Filter to ensure minimum quality standards and require images
          final filteredArticles = articles.where((article) {
            final hasTitle = article['title'] != null && 
                  article['title'].toString().trim().isNotEmpty;
            final hasImage = article['urlToImage'] != null && 
                           article['urlToImage'].toString().trim().isNotEmpty;
            
            return hasTitle && hasImage;
          }).toList();
          
          if (filteredArticles.isEmpty) {
            print('All articles were filtered out due to quality issues');
            return [];
          }
          
          // Ensure each article has its source category properly tagged
          return filteredArticles.map((article) {
            // Extract source information
            final Map<String, dynamic> source = article['source'] ?? {};
            final String sourceName = source['name'] ?? 'Unknown';
            
            // Extract category from URL or default to general
            String category = 'general';
            final String url = article['url']?.toString().toLowerCase() ?? '';
            
            // Try to detect category from URL or content
            if (url.contains('/business/') || 
                url.contains('/economy/') || 
                url.contains('/finance/')) {
              category = 'business';
            } else if (url.contains('/sport/') || 
                      url.contains('/sports/')) {
              category = 'sports';
            } else if (url.contains('/tech/') || 
                      url.contains('/technology/') || 
                      url.contains('/science/')) {
              category = 'technology';
            } else if (url.contains('/culture/') || 
                      url.contains('/entertainment/') || 
                      url.contains('/arts/') || 
                      url.contains('/lifestyle/')) {
              category = 'culture';
            } else if (url.contains('/health/') || 
                      url.contains('/wellness/')) {
              category = 'health';
            } else if (url.contains('/politics/') || 
                      url.contains('/government/') || 
                      url.contains('/election/')) {
              category = 'politics';
            }
            
            // Extract the image URL safely - some articles may not have images
            final String imageUrl = article['urlToImage'] ?? '';
            
            // Create a valid DateTime from the publishedAt field or use current time
            DateTime publishedAt;
            try {
              publishedAt = article['publishedAt'] != null 
                ? DateTime.parse(article['publishedAt']) 
                : DateTime.now();
            } catch (e) {
              publishedAt = DateTime.now();
            }
            
            return NewsArticle(
              id: article['url'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
              title: article['title'] ?? 'Untitled Article',
              description: article['description'] ?? 'No description available',
              content: article['content'] ?? 'No content available',
              author: article['author'] ?? 'Unknown',
              sourceName: sourceName,
              url: article['url'] ?? '',
              imageUrl: imageUrl,
              publishedAt: publishedAt,
              category: category,
            );
          }).toList();
        } else {
          print('News API Error: ${data['message'] ?? "Unknown error"}'); // Debug log
          return [];
        }
      } else if (response.statusCode == 429) {
        print('Rate limit exceeded for NewsAPI. Status code: ${response.statusCode}');
        return [];
      } else {
        print('Failed to load news: ${response.statusCode}'); // Debug log
        return [];
      }
    } catch (e) {
      print('Error fetching news: $e'); // Debug log
      return [];
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
          return sources.map<Map<String, dynamic>>((source) => source as Map<String, dynamic>).toList();
        } else {
          print('NewsData.io API Error: ${data['message'] ?? "Unknown error"}');
          // Return static fallback sources
          return _getStaticEgyptianSources();
        }
      } else {
        print('Failed to load sources: ${response.statusCode}');
        return _getStaticEgyptianSources();
      }
    } catch (e) {
      print('Error fetching Egyptian news sources: $e');
      return _getStaticEgyptianSources();
    }
  }
  
  // Map UI categories to NewsAPI categories
  String _mapCategoryToNewsApi(String category) {
    switch(category.toLowerCase()) {
      case 'sports':
        return 'sports';
      case 'business':
        return 'business';
      case 'technology':
        return 'technology';
      case 'culture':
        return 'entertainment';
      case 'health':
        return 'health';
      case 'politics':
        return 'general'; // NewsAPI doesn't have politics category
      default:
        return 'general';
    }
  }
  
  // Map UI categories to NewsData.io categories
  String _mapCategoryToNewsDataIo(String category) {
    switch(category.toLowerCase()) {
      case 'sports':
        return 'sports';
      case 'business':
        return 'business';
      case 'technology':
        return 'technology';
      case 'culture':
        return 'entertainment';
      case 'health':
        return 'health';
      case 'politics':
        return 'politics';
      default:
        return 'top';
    }
  }
  
  // Generate mock articles as fallback when all APIs fail
  List<NewsArticle> _generateMockArticles(String category) {
    final now = DateTime.now();
    
    return List.generate(10, (index) {
      final id = '${category}_fallback_$index';
      
      String title, description, content;
      switch(category.toLowerCase()) {
        case 'business':
          title = 'Business News: Economic Growth Continues Despite Challenges';
          description = 'Market analysts predict sustained economic growth despite global inflation concerns.';
          content = 'Economic experts have forecasted a steady growth trajectory for the next quarter, despite ongoing challenges related to supply chain disruptions and inflation concerns. Consumer confidence remains relatively high according to recent surveys.';
          break;
        case 'sports':
          title = 'Sports Update: Championship Finals Set to Begin Next Week';
          description = 'The long-awaited championship finals will begin next week with team rivalries at an all-time high.';
          content = 'After a season of unexpected turns, the championship finals are now set to begin next week. Fans are eagerly anticipating what analysts are calling "the most evenly matched final in decades."';
          break;
        case 'technology':
          title = 'Tech Breakthrough: New AI Model Breaks Efficiency Records';
          description = 'Researchers announce a new AI model that uses significantly less computing power while maintaining high accuracy.';
          content = 'A team of researchers has developed a groundbreaking AI model that requires only a fraction of the computing resources of previous models while achieving similar or better results across standard benchmarks.';
          break;
        case 'politics':
          title = 'Political Analysis: New Policies Aim to Address Economic Disparities';
          description = 'Government announces comprehensive plan to tackle economic inequality through targeted initiatives.';
          content = 'The administration unveiled a series of policy proposals designed to address growing economic disparities. The multi-faceted approach includes tax reforms, education funding, and small business support programs.';
          break;
        case 'health':
          title = 'Health Research: Study Finds New Benefits of Regular Exercise';
          description = 'A comprehensive study reveals additional cognitive benefits from consistent physical activity.';
          content = 'Researchers have discovered that regular exercise not only improves physical health but also enhances cognitive function in ways previously not understood. The study followed participants over a five-year period.';
          break;
        case 'culture':
          title = 'Arts and Culture: International Film Festival Announces Lineup';
          description = 'This year\'s international film festival will showcase works from over 40 countries.';
          content = 'The annual International Film Festival has announced its official selection, featuring over 120 films from 43 countries. The diverse lineup includes both established directors and emerging talent from around the world.';
          break;
        case 'breaking':
          title = 'Breaking News: International Summit Reaches Historic Agreement';
          description = 'World leaders announce breakthrough agreement on climate change initiatives at international summit.';
          content = 'After days of intense negotiations, participants at the International Climate Summit have reached what many are calling a "historic" agreement on emissions targets and sustainable development funding.';
          break;
        default:
          title = 'General News Update: Community Development Project Launches';
          description = 'A new initiative aims to revitalize urban areas through community-led development projects.';
          content = 'The newly launched community development program will focus on infrastructure improvement, small business support, and educational opportunities in underserved urban areas.';
      }
      
      return NewsArticle(
        id: id,
        title: '$title ${index + 1}',
        description: description,
        content: content,
        author: 'TalkifyApp News Team',
        sourceName: 'TalkifyApp News',
        url: 'https://example.com/news/$id',
        imageUrl: 'https://picsum.photos/800/600?random=$index&category=$category',
        publishedAt: now.subtract(Duration(hours: index)),
        category: category,
      );
    });
  }
  
  // Static Egyptian news sources as fallback
  List<Map<String, dynamic>> _getStaticEgyptianSources() {
    return [
      {
        'id': 'almasryalyoum',
        'name': 'Al-Masry Al-Youm',
        'description': 'Leading Egyptian newspaper',
        'url': 'https://www.almasryalyoum.com/',
        'language': 'ar',
        'country': 'eg',
      },
      {
        'id': 'egypttoday',
        'name': 'Egypt Today',
        'description': 'Egypt\'s leading English news website',
        'url': 'https://www.egypttoday.com/',
        'language': 'en',
        'country': 'eg',
      },
      {
        'id': 'ahram',
        'name': 'Al-Ahram',
        'description': 'One of Egypt\'s oldest newspapers',
        'url': 'http://english.ahram.org.eg/',
        'language': 'en',
        'country': 'eg',
      },
      {
        'id': 'madamasr',
        'name': 'Mada Masr',
        'description': 'Independent Egyptian news website',
        'url': 'https://www.madamasr.com/en/',
        'language': 'en',
        'country': 'eg',
      },
      {
        'id': 'dailynewsegypt',
        'name': 'Daily News Egypt',
        'description': 'Independent English language news source',
        'url': 'https://dailynewsegypt.com/',
        'language': 'en',
        'country': 'eg',
      },
    ];
  }
} 