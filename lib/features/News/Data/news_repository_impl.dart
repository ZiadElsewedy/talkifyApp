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
      print('Repository: Fetching top headlines');
      final articles = await _apiService.fetchGeneralNews();
      
      if (articles.isEmpty) {
        print('Repository: Got empty general news, trying fallback');
        // Try with secondary endpoints
        try {
          final fallbackArticles = await _apiService.fetchBreakingNews();
          if (fallbackArticles.isNotEmpty) {
            print('Repository: Got ${fallbackArticles.length} fallback articles');
            return fallbackArticles;
          }
        } catch (fallbackError) {
          print('Repository: Error with fallback: $fallbackError');
        }
        
        // If still empty, return at least some mock data
        return _getMockGeneralNews();
      }
      
      return articles;
    } catch (e) {
      print('Error in repository - fetchTopHeadlines: $e');
      return _getMockGeneralNews();
    }
  }

  @override
  Future<List<NewsArticle>> fetchBreakingNews() async {
    try {
      return await _apiService.fetchBreakingNews();
    } catch (e) {
      print('Error in repository - fetchBreakingNews: $e');
      rethrow;
    }
  }

  @override
  Future<List<NewsArticle>> fetchPoliticsNews() async {
    try {
      return await _apiService.fetchPoliticsNews();
    } catch (e) {
      print('Error in repository - fetchPoliticsNews: $e');
      rethrow;
    }
  }

  @override
  Future<List<NewsArticle>> fetchNewsByCategory(String category) async {
    try {
      return await _apiService.fetchNewsByCategory(category);
    } catch (e) {
      print('Error in repository - fetchNewsByCategory: $e');
      rethrow;
    }
  }

  @override
  Future<List<NewsArticle>> searchNews(String query) async {
    try {
      return await _apiService.searchNews(query);
    } catch (e) {
      print('Error in repository - searchNews: $e');
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getEgyptianNewsSources() async {
    return [
      {
        'id': 'almasryalyoum',
        'name': 'Al-Masry Al-Youm',
        'description': 'Leading Egyptian newspaper',
        'url': 'https://www.almasryalyoum.com/',
        'language': 'ar',
        'country': 'eg',
        'logoUrl': 'https://www.almasryalyoum.com/content/images/logo.png',
      },
      {
        'id': 'egypttoday',
        'name': 'Egypt Today',
        'description': 'Egypt\'s leading English news website',
        'url': 'https://www.egypttoday.com/',
        'language': 'en',
        'country': 'eg',
        'logoUrl': 'https://www.egypttoday.com/style-resource/header-logo-v1.jpg',
      },
      {
        'id': 'ahram',
        'name': 'Al-Ahram',
        'description': 'One of Egypt\'s oldest newspapers',
        'url': 'http://english.ahram.org.eg/',
        'language': 'en',
        'country': 'eg',
        'logoUrl': 'http://english.ahram.org.eg/images/logo.png',
      },
      {
        'id': 'madamasr',
        'name': 'Mada Masr',
        'description': 'Independent Egyptian news website',
        'url': 'https://www.madamasr.com/en/',
        'language': 'en',
        'country': 'eg',
        'logoUrl': 'https://www.madamasr.com/wp-content/themes/madamasr/assets/img/logo.svg',
      },
      {
        'id': 'dailynewsegypt',
        'name': 'Daily News Egypt',
        'description': 'Independent English language news source',
        'url': 'https://dailynewsegypt.com/',
        'language': 'en',
        'country': 'eg',
        'logoUrl': 'https://dailynewsegypt.com/wp-content/themes/dailynews/images/logo.png',
      },
    ];
  }

  // Provide mock general news as a last resort
  List<NewsArticle> _getMockGeneralNews() {
    final now = DateTime.now();
    
    return [
      NewsArticle(
        id: 'mock_general_1',
        title: 'Global Leaders Gather for Climate Summit',
        description: 'Representatives from over 100 countries meet to discuss climate change initiatives.',
        content: 'In a landmark gathering, world leaders have convened to address the pressing issues of climate change. The summit aims to establish new targets for emissions reductions and sustainable development practices.',
        author: 'TalkifyApp News',
        sourceName: 'TalkifyApp News Network',
        url: 'https://example.com/news/climate-summit',
                 imageUrl: 'https://picsum.photos/800/600?random=1',
        publishedAt: now.subtract(Duration(hours: 2)),
        category: 'general',
      ),
      NewsArticle(
        id: 'mock_general_2',
        title: 'Technology Innovations Reshape Healthcare Delivery',
        description: 'New technologies are transforming how healthcare services are provided globally.',
        content: 'Advanced technologies including AI diagnostics, telemedicine, and wearable health monitors are revolutionizing healthcare delivery systems worldwide, making quality care more accessible.',
        author: 'TalkifyApp Tech Reporter',
        sourceName: 'TalkifyApp Technology News',
        url: 'https://example.com/news/healthcare-tech',
                 imageUrl: 'https://picsum.photos/800/600?random=2',
        publishedAt: now.subtract(Duration(hours: 4)),
        category: 'technology',
      ),
      NewsArticle(
        id: 'mock_general_3',
        title: 'Economic Report Shows Growth Despite Challenges',
        description: 'Latest economic indicators reveal unexpected growth in multiple sectors.',
        content: 'Despite ongoing global supply chain issues, the latest economic report indicates resilient growth across several key industries, suggesting stronger economic outlook than previously predicted.',
        author: 'TalkifyApp Business Desk',
        sourceName: 'TalkifyApp Business News',
        url: 'https://example.com/news/economic-growth',
                 imageUrl: 'https://picsum.photos/800/600?random=3',
        publishedAt: now.subtract(Duration(hours: 6)),
        category: 'business',
      ),
      NewsArticle(
        id: 'mock_general_4',
        title: 'Cultural Festival Celebrates Diversity Through Art',
        description: 'Annual festival showcases artistic traditions from around the world.',
        content: 'The International Cultural Festival opened yesterday with performances, exhibitions, and workshops representing artistic traditions from over 40 countries, celebrating the rich diversity of global cultural heritage.',
        author: 'TalkifyApp Arts Correspondent',
        sourceName: 'TalkifyApp Cultural News',
        url: 'https://example.com/news/cultural-festival',
                 imageUrl: 'https://picsum.photos/800/600?random=4',
        publishedAt: now.subtract(Duration(hours: 8)),
        category: 'culture',
      ),
      NewsArticle(
        id: 'mock_general_5',
        title: 'Sports Championship Draws Record Viewership',
        description: 'Final match of international tournament breaks previous viewing records.',
        content: 'The championship final drew unprecedented global viewership, with an estimated 2 billion people tuning in across streaming and traditional broadcast platforms, setting a new record for sports viewership.',
        author: 'TalkifyApp Sports Team',
        sourceName: 'TalkifyApp Sports Coverage',
        url: 'https://example.com/news/sports-championship',
                 imageUrl: 'https://picsum.photos/800/600?random=5',
        publishedAt: now.subtract(Duration(hours: 10)),
        category: 'sports',
      ),
    ];
  }
} 