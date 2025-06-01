import 'package:talkifyapp/features/News/Domain/Entitie/news_article.dart';

abstract class NewsState {}

// Initial state
class NewsInitial extends NewsState {}

// Loading state
class NewsLoading extends NewsState {}

// Error state
class NewsError extends NewsState {
  final String message;
  NewsError(this.message);
}

// Loaded state with news articles
class NewsLoaded extends NewsState {
  final List<NewsArticle> articles;
  final String category;
  
  NewsLoaded(this.articles, {this.category = 'general'});
}

// Categories loaded state
class NewsCategoriesLoaded extends NewsState {
  final Map<String, List<NewsArticle>> articlesByCategory;
  
  NewsCategoriesLoaded(this.articlesByCategory);
} 