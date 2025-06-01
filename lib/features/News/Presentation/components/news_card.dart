import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:talkifyapp/features/News/Domain/Entitie/news_article.dart';
import 'package:talkifyapp/features/News/Presentation/pages/news_detail_page.dart';

class NewsCard extends StatelessWidget {
  final NewsArticle article;
  final bool isFeatureCard;
  
  const NewsCard({
    Key? key, 
    required this.article,
    this.isFeatureCard = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDetailPage(context),
      child: Container(
        margin: EdgeInsets.symmetric(
          vertical: isFeatureCard ? 12 : 8,
          horizontal: isFeatureCard ? 16 : 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isFeatureCard ? 16 : 12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: isFeatureCard ? _buildFeatureCard(context) : _buildRegularCard(),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image
        SizedBox(
          height: 200,
          width: double.infinity,
          child: _buildImage(),
        ),
        
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Source and Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Source Tag
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
                        fontSize: 12,
                      ),
                    ),
                  ),
                  
                  // Date
                  Text(
                    _formatDate(article.publishedAt),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Title
              Text(
                article.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              // Description
              Text(
                article.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 16),
              
              // Read More Button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _openDetailPage(context),
                    child: Row(
                      children: [
                        Text(
                          'Read More',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: Colors.blue.shade700,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRegularCard() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            bottomLeft: Radius.circular(12),
          ),
          child: SizedBox(
            width: 120,
            height: 120,
            child: _buildImage(),
          ),
        ),
        
        // Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Source
                Text(
                  article.sourceName,
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                
                const SizedBox(height: 6),
                
                // Title
                Text(
                  article.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 6),
                
                // Date
                Text(
                  _formatDate(article.publishedAt),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage() {
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
                    size: 30,
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
                size: 30,
              ),
            ),
          );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays < 1) {
      if (difference.inHours < 1) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  void _openDetailPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewsDetailPage(article: article),
      ),
    );
  }
} 