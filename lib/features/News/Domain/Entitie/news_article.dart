class NewsArticle {
  final String id;
  final String title;
  final String description;
  final String content;
  final String author;
  final String sourceName;
  final String url;
  final String imageUrl;
  final DateTime publishedAt;

  NewsArticle({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.author,
    required this.sourceName,
    required this.url,
    required this.imageUrl,
    required this.publishedAt,
  });

  // Create a copy with modified fields
  NewsArticle copyWith({
    String? id,
    String? title,
    String? description,
    String? content,
    String? author,
    String? sourceName,
    String? url,
    String? imageUrl,
    DateTime? publishedAt,
  }) {
    return NewsArticle(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      content: content ?? this.content,
      author: author ?? this.author,
      sourceName: sourceName ?? this.sourceName,
      url: url ?? this.url,
      imageUrl: imageUrl ?? this.imageUrl,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }

  // Factory method to create a NewsArticle from a JSON map
  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: json['url'] ?? '',  // Using URL as ID since News API doesn't provide unique IDs
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      content: json['content'] ?? '',
      author: json['author'] ?? 'Unknown',
      sourceName: json['source']?['name'] ?? 'Unknown Source',
      url: json['url'] ?? '',
      imageUrl: json['urlToImage'] ?? '',
      publishedAt: json['publishedAt'] != null 
          ? DateTime.parse(json['publishedAt']) 
          : DateTime.now(),
    );
  }

  // Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'content': content,
      'author': author,
      'sourceName': sourceName,
      'url': url,
      'imageUrl': imageUrl,
      'publishedAt': publishedAt.toIso8601String(),
    };
  }
} 