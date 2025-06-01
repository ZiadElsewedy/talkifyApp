import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:talkifyapp/features/News/Domain/Entitie/news_article.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsDetailPage extends StatelessWidget {
  final NewsArticle article;
  
  const NewsDetailPage({
    Key? key,
    required this.article,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeaderImage(),
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                color: Colors.white,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.share),
                  color: Colors.white,
                  onPressed: () {
                    // Share functionality could be added here
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Share functionality to be implemented')),
                    );
                  },
                ),
              ),
            ],
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source and Date
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          article.sourceName,
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formatDate(article.publishedAt),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Title
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  
                  if (article.author.isNotEmpty && article.author != 'Unknown')
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Text(
                        'By ${article.author}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 20),
                  
                  // Content
                  Text(
                    article.content.isNotEmpty
                        ? article.content
                        : article.description,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Read Full Article Button
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () => _showArticleDialog(context, article.url),
                      icon: const Icon(Icons.language),
                      label: const Text('Read Full Article'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderImage() {
    return article.imageUrl.isNotEmpty
        ? Image.network(
            article.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey.shade200,
                child: Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.grey.shade400,
                    size: 50,
                  ),
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey.shade100,
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            (loadingProgress.expectedTotalBytes ?? 1)
                        : null,
                    strokeWidth: 2,
                    color: Colors.blue.shade300,
                  ),
                ),
              );
            },
          )
        : Container(
            color: Colors.grey.shade200,
            child: Center(
              child: Icon(
                Icons.newspaper,
                color: Colors.grey.shade400,
                size: 50,
              ),
            ),
          );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy • h:mm a').format(date);
  }

  Future<void> _launchURL(String url) {
    // Simply print the URL for debugging - no async/await needed
    print('Article URL: $url');
    return Future.value();
  }

  void _showArticleDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Article Link'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Unable to open the article in browser.'),
                const SizedBox(height: 8),
                Text(
                  url,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
} 