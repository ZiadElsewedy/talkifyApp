import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:talkifyapp/features/News/Domain/Entitie/news_article.dart';

class NewsDetailPage extends StatefulWidget {
  final NewsArticle article;

  const NewsDetailPage({Key? key, required this.article}) : super(key: key);

  @override
  State<NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  late ScrollController _scrollController;
  bool _showAppBarTitle = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.offset > 180 && !_showAppBarTitle) {
      setState(() {
        _showAppBarTitle = true;
      });
    } else if (_scrollController.offset <= 180 && _showAppBarTitle) {
      setState(() {
        _showAppBarTitle = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final appBarBg = isDarkMode ? colorScheme.surface : Colors.white;
    final appBarText = isDarkMode ? Colors.white : Colors.black;
    final iconColor = isDarkMode ? Colors.white : Colors.black;
    final detailTitle = isDarkMode ? Colors.white : Colors.black;
    final detailSubText = isDarkMode ? Colors.grey[400]! : Colors.grey[800]!;
    final detailDesc = isDarkMode ? Colors.grey[300]! : Colors.grey[800]!;
    final detailContent = isDarkMode ? Colors.grey[200]! : Colors.grey[800]!;
    final detailDivider = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final buttonBg = isDarkMode ? Colors.blue[900]! : Colors.black;
    final buttonText = Colors.white;
    final bottomBarBg = isDarkMode ? colorScheme.surface : Colors.white;
    final bottomBarIcon = isDarkMode ? Colors.white : Colors.black;
    final bottomBarShadow = isDarkMode ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05);

    return Scaffold(
      backgroundColor: scaffoldBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: _showAppBarTitle ? 2 : 0,
        backgroundColor: _showAppBarTitle ? appBarBg : Colors.transparent,
        iconTheme: IconThemeData(
          color: _showAppBarTitle ? appBarText : Colors.white,
        ),
        title: AnimatedOpacity(
          opacity: _showAppBarTitle ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 250),
          child: Text(
            widget.article.title,
            style: TextStyle(
              color: appBarText,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.share,
              color: _showAppBarTitle ? appBarText : Colors.white,
            ),
            onPressed: _shareArticle,
          ),
        ],
        systemOverlayStyle: _showAppBarTitle
            ? (isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            : (isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.light),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Featured image
          SliverToBoxAdapter(
            child: Stack(
              children: [
                // Image with gradient overlay
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black,
                  ),
                  child: widget.article.imageUrl.isNotEmpty
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              widget.article.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: isDarkMode ? Colors.grey[900] : Colors.grey[800],
                                  child: Center(
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      color: Colors.grey[400],
                                      size: 50,
                                    ),
                                  ),
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: isDarkMode ? Colors.grey[900] : Colors.grey[800],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                );
                              },
                            ),
                            // Gradient overlay
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7),
                                  ],
                                  stops: const [0.5, 1.0],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Icon(
                            Icons.newspaper,
                            color: Colors.grey[400],
                            size: 80,
                          ),
                        ),
                ),
                
                // Category tag
                Positioned(
                  top: 100,
                  left: 16,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: buttonBg,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      _getCategoryName(widget.article.category),
                      style: TextStyle(
                        color: buttonText,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                // Title and source info
                Positioned(
                  bottom: 20,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.article.title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: detailTitle,
                          shadows: [
                            Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 3,
                              color: Colors.black.withOpacity(0.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            widget.article.sourceName,
                            style: TextStyle(
                              color: buttonText,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: buttonText,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(widget.article.publishedAt),
                            style: TextStyle(
                              color: buttonText,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Article content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author
                  if (widget.article.author != 'Unknown')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                            child: Icon(
                              Icons.person,
                              size: 18,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Written by',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: detailSubText,
                                ),
                              ),
                              Text(
                                widget.article.author,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: detailTitle,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  
                  // Description
                  if (widget.article.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        widget.article.description,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: detailDesc,
                          height: 1.5,
                        ),
                      ),
                    ),
                  
                  // Content
                  if (widget.article.content.isNotEmpty)
                    Text(
                      _formatContent(widget.article.content),
                      style: TextStyle(
                        fontSize: 16,
                        color: detailContent,
                        height: 1.6,
                      ),
                    ),
                  
                  const SizedBox(height: 30),
                  
                  // Read full article button
                  InkWell(
                    onTap: _openArticleUrl,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: buttonBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Read Full Article',
                        style: TextStyle(
                          color: buttonText,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  
                  // Footer info
                  Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(color: detailDivider),
                        SizedBox(height: 16),
                        Text(
                          'Source: ${widget.article.sourceName}',
                          style: TextStyle(
                            fontSize: 14,
                            color: detailSubText,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Published: ${DateFormat('MMMM d, yyyy').format(widget.article.publishedAt)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: detailSubText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: bottomBarBg,
          boxShadow: [
            BoxShadow(
              color: bottomBarShadow,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomButton(Icons.bookmark_border, 'Save', iconColor: bottomBarIcon),
              _buildBottomButton(Icons.share, 'Share', onTap: _shareArticle, iconColor: bottomBarIcon),
              _buildBottomButton(Icons.open_in_browser, 'Open', onTap: _openArticleUrl, iconColor: bottomBarIcon),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton(IconData icon, String label, {VoidCallback? onTap, Color? iconColor}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: iconColor),
            SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: iconColor)),
          ],
        ),
      ),
    );
  }

  String _formatContent(String content) {
    // Remove [+123 chars] from content
    String cleanContent = content.replaceAll(RegExp(r'\[\+\d+ chars\]'), '');
    // Add periods at the end if missing
    if (!cleanContent.endsWith('.') && !cleanContent.endsWith('!') && !cleanContent.endsWith('?')) {
      cleanContent += '.';
    }
    return cleanContent;
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

  String _getCategoryName(String category) {
    // Capitalize first letter
    if (category.isEmpty) return 'General';
    return category[0].toUpperCase() + category.substring(1);
  }

  Future<void> _openArticleUrl() async {
    final Uri url = Uri.parse(widget.article.url);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open article URL'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _shareArticle() async {
    try {
      await Share.share(
        '${widget.article.title}\n\nRead more: ${widget.article.url}',
        subject: widget.article.title,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not share article'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
} 