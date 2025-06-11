import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:talkifyapp/features/Posts/domain/Entite/Posts.dart';
import 'package:talkifyapp/features/Posts/presentation/cubits/post_cubit.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:video_player/video_player.dart';

class SharedPostPreview extends StatefulWidget {
  final String postId;
  final VoidCallback? onTap;
  
  const SharedPostPreview({
    Key? key,
    required this.postId,
    this.onTap,
  }) : super(key: key);
  
  @override
  _SharedPostPreviewState createState() => _SharedPostPreviewState();
}

class _SharedPostPreviewState extends State<SharedPostPreview> with SingleTickerProviderStateMixin {
  Post? post;
  bool isLoading = true;
  String? error;
  
  // Animation for tapping
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  
  // Video player controller
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _loadPost();
    
    // Initialize animation controller
    _scaleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 100),
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _scaleController.dispose();
    _videoController?.dispose();
    super.dispose();
  }
  
  Future<void> _loadPost() async {
    try {
      // Extract actual post ID from format "post:{postId}"
      String postId = widget.postId;
      if (postId.startsWith("post:")) {
        postId = postId.substring(5);
      }
      
      final postCubit = context.read<PostCubit>();
      final loadedPost = await postCubit.getPostById(postId);
      
      if (mounted) {
        setState(() {
          post = loadedPost;
          isLoading = false;
        });
        
        // Initialize video controller if it's a video post
        if (post != null && post!.isVideo && post!.imageUrl.isNotEmpty) {
          _initializeVideoController();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = 'Could not load post: $e';
          isLoading = false;
        });
      }
    }
  }
  
  Future<void> _initializeVideoController() async {
    _videoController = VideoPlayerController.network(post!.imageUrl);
    try {
      await _videoController!.initialize();
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing video: $e');
      if (mounted) {
        setState(() {
          _isVideoInitialized = false;
        });
      }
    }
  }
  
  void _onTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.reverse();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.grey[200]! : Colors.black87;
    final subTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final cardColor = isDarkMode ? Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDarkMode ? Color(0xFF2C2C2C) : Colors.grey[300]!;
    final footerColor = isDarkMode ? Color(0xFF121212) : Colors.grey[100]!;
    final footerBorderColor = isDarkMode ? Color(0xFF2C2C2C) : Colors.grey[200]!;
    final iconColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final placeholderColor = isDarkMode ? Color(0xFF2C2C2C) : Colors.grey[200]!;

    if (isLoading) {
      return _buildLoadingState(isDarkMode, placeholderColor, subTextColor);
    }
    
    if (error != null || post == null) {
      return _buildErrorState(isDarkMode, placeholderColor, subTextColor);
    }
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            onTap: widget.onTap,
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Black header bar with "Shared Post" indicator
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDarkMode ? Theme.of(context).colorScheme.primary : Colors.black,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.share,
                    size: 12,
                    color: Colors.white,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Shared Post',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            
            // Post content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with user info
                  Row(
                    children: [
                      // User profile picture
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: post!.UserProfilePic.isNotEmpty
                            ? CachedNetworkImageProvider(post!.UserProfilePic)
                            : null,
                        backgroundColor: placeholderColor,
                        child: post!.UserProfilePic.isEmpty
                            ? Text(
                                post!.UserName[0].toUpperCase(),
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      
                      // Username and time
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post!.UserName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: textColor,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              timeago.format(post!.timestamp),
                              style: TextStyle(
                                fontSize: 11,
                                color: subTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // Text content (if any)
                  if (post!.Text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 4),
                      child: Text(
                        post!.Text,
                        style: TextStyle(
                          fontSize: 13,
                          color: textColor,
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
              
            // Media content (image or video)
            if (post!.imageUrl.isNotEmpty)
              Container(
                height: 160,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Show video player if it's a video and initialized
                    if (post!.isVideo && _isVideoInitialized && _videoController != null)
                      AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      )
                    // Otherwise show the image or loading state
                    else
                      CachedNetworkImage(
                        imageUrl: post!.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: placeholderColor,
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isDarkMode ? Colors.white38 : Colors.black45,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: placeholderColor,
                          child: Center(
                            child: Icon(
                              Icons.error_outline,
                              size: 24,
                              color: subTextColor,
                            ),
                          ),
                        ),
                      ),
                    
                    // Play button overlay for videos
                    if (post!.isVideo)
                      GestureDetector(
                        onTap: () {
                          if (_isVideoInitialized && _videoController != null) {
                            if (_videoController!.value.isPlaying) {
                              _videoController!.pause();
                            } else {
                              _videoController!.play();
                            }
                            setState(() {});
                          }
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isVideoInitialized && _videoController != null && _videoController!.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
            // Footer with stats
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: footerColor,
                border: Border(
                  top: BorderSide(
                    color: footerBorderColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Likes count
                  Icon(
                    Icons.favorite,
                    size: 14,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post!.likes.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.grey[300]! : Colors.grey[700]!,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Comments count
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 14,
                    color: iconColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post!.comments.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.grey[300]! : Colors.grey[700]!,
                    ),
                  ),
                  
                  Spacer(),
                  
                  // Tap to view indicator
                  Row(
                    children: [
                      Text(
                        'Tap to view',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDarkMode ? Colors.grey[400]! : Colors.grey[700]!,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 10,
                        color: isDarkMode ? Colors.grey[400]! : Colors.grey[700]!,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLoadingState(bool isDarkMode, Color placeholderColor, Color textColor) {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: placeholderColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Color(0xFF2C2C2C) : Colors.grey[300]!,
          width: 1
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isDarkMode ? Colors.white70 : Colors.black,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Loading post...',
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorState(bool isDarkMode, Color placeholderColor, Color textColor) {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: placeholderColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Color(0xFF2C2C2C) : Colors.grey[300]!,
          width: 1
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 28,
              color: textColor,
            ),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                error ?? 'Post not available',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 