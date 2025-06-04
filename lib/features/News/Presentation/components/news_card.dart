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
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final cardBg = isDarkMode ? Colors.grey[900]! : Colors.white;
    final cardShadow = isDarkMode ? Colors.black.withOpacity(0.15) : Colors.black.withOpacity(0.08);
    final borderColor = isDarkMode ? Colors.grey[800]! : Colors.grey[200]!;
    final sourceBg = isDarkMode ? Colors.grey[800]! : Colors.grey[200]!;
    final sourceText = isDarkMode ? Colors.grey[200]! : Colors.grey[800]!;
    final dateText = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final titleText = isDarkMode ? Colors.white : Colors.black;
    final descText = isDarkMode ? Colors.grey[400]! : Colors.grey[700]!;
    final readMoreText = isDarkMode ? Colors.blue[200]! : Colors.grey[900]!;
    final readMoreIcon = isDarkMode ? Colors.blue[200]! : Colors.grey[900]!;
    final dividerColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final imageBg = isDarkMode ? Colors.grey[800]! : Colors.grey[200]!;
    final imageIcon = isDarkMode ? Colors.grey[600]! : Colors.grey[400]!;

    return GestureDetector(
      onTap: () => _openDetailPage(context),
      child: Container(
        margin: EdgeInsets.symmetric(
          vertical: isFeatureCard ? 12 : 8,
          horizontal: isFeatureCard ? 16 : 12,
        ),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(isFeatureCard ? 12 : 10),
          boxShadow: [
            BoxShadow(
              color: cardShadow,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: borderColor, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: isFeatureCard ? _buildFeatureCard(context, sourceBg, sourceText, dateText, titleText, descText, readMoreText, readMoreIcon, imageBg, imageIcon) : _buildRegularCard(sourceBg, sourceText, dateText, titleText, descText, readMoreText, readMoreIcon, imageBg, imageIcon),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, Color sourceBg, Color sourceText, Color dateText, Color titleText, Color descText, Color readMoreText, Color readMoreIcon, Color imageBg, Color imageIcon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image
        SizedBox(
          height: 200,
          width: double.infinity,
          child: _buildImage(imageBg, imageIcon),
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
                      color: sourceBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      article.sourceName,
                      style: TextStyle(
                        color: sourceText,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  // Date
                  Text(
                    _formatDate(article.publishedAt),
                    style: TextStyle(
                      color: dateText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Title
              Text(
                article.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                  color: titleText,
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
                  color: descText,
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
                    style: TextButton.styleFrom(
                      foregroundColor: readMoreText,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Read More',
                          style: TextStyle(
                            color: readMoreText,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: readMoreIcon,
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

  Widget _buildRegularCard(Color sourceBg, Color sourceText, Color dateText, Color titleText, Color descText, Color readMoreText, Color readMoreIcon, Color imageBg, Color imageIcon) {
    return Builder(
      builder: (context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              bottomLeft: Radius.circular(10),
            ),
            child: SizedBox(
              width: 120,
              height: 120,
              child: _buildImage(imageBg, imageIcon),
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
                      color: sourceText,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Title
                  Text(
                    article.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                      color: titleText,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(article.publishedAt),
                        style: TextStyle(
                          color: dateText,
                          fontSize: 12,
                        ),
                      ),
                      // Read More text link
                      InkWell(
                        onTap: () => _openDetailPage(context),
                        child: Text(
                          'Read More',
                          style: TextStyle(
                            color: readMoreText,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                            decorationColor: readMoreIcon,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(Color bg, Color iconColor) {
    return article.imageUrl.isNotEmpty
        ? Image.network(
            article.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: bg,
                child: Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: iconColor,
                    size: 30,
                  ),
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: bg,
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            (loadingProgress.expectedTotalBytes ?? 1)
                        : null,
                    strokeWidth: 2,
                    color: iconColor,
                  ),
                ),
              );
            },
          )
        : Container(
            color: bg,
            child: Center(
              child: Icon(
                Icons.newspaper,
                color: iconColor,
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