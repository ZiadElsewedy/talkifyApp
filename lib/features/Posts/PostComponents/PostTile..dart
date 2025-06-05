import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Posts/PostComponents/CommentsPage.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/ProfilePage.dart';
import 'package:talkifyapp/features/Profile/domain/entites/ProfileUser.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/Posts/presentation/cubits/post_cubit.dart';
import 'package:talkifyapp/features/auth/domain/entities/AppUser.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:talkifyapp/features/Posts/domain/Entite/Posts.dart';
import 'package:talkifyapp/features/Posts/domain/Entite/Comments.dart';
import 'package:talkifyapp/features/Posts/presentation/cubits/post_sharing_service.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
//import 'package:talkifyapp/features/Posts/presentation/Pages/CommentsPage.dart';

import '../../Profile/presentation/Cubits/ProfileCubit.dart';

class PostTile extends StatefulWidget {
  final Post post;
  final VoidCallback? onDelete;

  const PostTile({
    super.key,
    required this.post,
    this.onDelete,
  });
  
  @override
  State<PostTile> createState() => _PostTileState();
}

class _PostTileState extends State<PostTile> with TickerProviderStateMixin {
  late final postCubit = context.read<PostCubit>();
  late final profileCubit = context.read<ProfileCubit>();
  AppUser? currentUser;
  ProfileUser? PostUser;
  bool isOwnPost = false;
  bool showAllComments = false;

  // Animation controllers
  late AnimationController _likeAnimationController;
  late AnimationController _scaleAnimationController;
  late Animation<double> _scaleAnimation;
  
  // Video player controller
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _showVideoControls = false;
  bool _isFullScreen = false;
  double _playbackSpeed = 1.0;
  
  // Available playback speeds
  final List<double> _availableSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
  
  // Timer for hiding video controls
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    initializeData();
    
    // Initialize animation controllers
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // Initialize video controller if needed
    if (widget.post.isVideo && widget.post.imageUrl.isNotEmpty) {
      _initializeVideoController();
    }
  }

  Future<void> _initializeVideoController() async {
    _videoController = VideoPlayerController.network(widget.post.imageUrl);
    try {
      print('Initializing video controller for URL: ${widget.post.imageUrl}');
      await _videoController!.initialize();
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
        print('Video controller initialized successfully');
      }
    } catch (e) {
      print('Error initializing video: $e');
      // Show error state in UI
      if (mounted) {
        setState(() {
          _isVideoInitialized = false;
        });
      }
    }
  }

  Future<void> initializeData() async {
    await GetCurrentUser();
    await FetchPostUser();
  }

  Future<void> GetCurrentUser() async {
    try {
      final authCubit = context.read<AuthCubit>();
      currentUser = authCubit.GetCurrentUser();
      if (mounted) {
        setState(() {
          isOwnPost = (widget.post.UserId == currentUser?.id);
        });
      }
    } catch (e) {
      debugPrint('Error getting current user: $e');
    }
  }

  Future<void> FetchPostUser() async {
    try {
      final fetchedUser = await profileCubit.GetUserProfileByUsername(widget.post.UserName);
      if (fetchedUser != null && mounted) {
        setState(() {
          PostUser = fetchedUser;
        });
      }
    } catch (e) {
      debugPrint('Error fetching post user: $e');
    }
  }

/*
Likes
*/

// user tapped like button 
void toggleLikePost(){
  // Check if user is logged in
  if (currentUser == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please log in to like posts'))
    );
    return;
  }

  // current like status 
  final isLiked = widget.post.likes.contains(currentUser!.id);

  // optimistically like & update UI 
  setState(() {
    if (isLiked){
      widget.post.likes.remove(currentUser!.id); // unliked
    }
    else{
      widget.post.likes.add(currentUser!.id); // liked
      _likeAnimationController.forward().then((_) {
        _likeAnimationController.reverse();
      });
    }
  });

  // update like in database
  postCubit.toggleLikePost(widget.post.id, currentUser!.id).catchError((error){
    print('Error toggling like: $error');
    
    // if there's an error, revert back to original values
    setState(() {
      if (isLiked){
        widget.post.likes.add(currentUser!.id); // revert unlike 
      }
      else{
        widget.post.likes.remove(currentUser!.id); // revert like 
      }
    });
    
    // Show error to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to update like: ${error.toString()}'))
    );
  });
}

/*
Save Post
*/

// user tapped save button
void toggleSavePost() {
  // Check if user is logged in
  if (currentUser == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please log in to save posts'))
    );
    return;
  }

  // current save status
  final isSaved = widget.post.savedBy.contains(currentUser!.id);

  // optimistically save & update UI
  setState(() {
    if (isSaved) {
      widget.post.savedBy.remove(currentUser!.id); // unsave
    } else {
      widget.post.savedBy.add(currentUser!.id); // save
      // Add a nice animation when saving
      _scaleAnimationController.forward().then((_) {
        _scaleAnimationController.reverse();
      });
    }
  });

  // update save in database
  postCubit.toggleSavePostLocal(widget.post.id, currentUser!.id).catchError((error) {
    print('Error toggling save: $error');
    
    // if there's an error, revert back to original values
    setState(() {
      if (isSaved) {
        widget.post.savedBy.add(currentUser!.id); // revert unsave
      } else {
        widget.post.savedBy.remove(currentUser!.id); // revert save
      }
    });
    
    // Show error to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to save post: ${error.toString()}'))
    );
  });
}

/*
Share Post
*/

void sharePost() {
  // Check if user is logged in
  if (currentUser == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please log in to share posts'))
    );
    return;
  }
  
  // Show share dialog
  PostSharingService.showChatSelectionDialog(
    context: context,
    post: widget.post,
    currentUser: currentUser!,
  );
}

  void showDeleteConfirmation() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red.shade700, size: 24),
            SizedBox(width: 10),
            Text(
              'Delete Post',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: Text(
          'This action cannot be undone. Are you sure you want to delete this post?',
          style: TextStyle(
            fontSize: 15,
            color: Colors.black87,
            height: 1.4,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black54,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
        actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
/*
Comments
*/

final TextEditingController commentController = TextEditingController();
void OpenCommentBox() {  
  showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      title: Row(
        children: [
          Icon(Icons.chat_bubble_outline, color: Colors.blue.shade700, size: 24),
          SizedBox(width: 10),
          Text(
            'Add Comment',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
        ],
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      content: Container(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share your thoughts on this post',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: commentController,
                maxLines: 4,
                minLines: 2,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Write your comment...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  contentPadding: const EdgeInsets.all(16),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
      actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.black54,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            'Cancel',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            if (commentController.text.trim().isNotEmpty) {
              addComment();
              if (mounted) {
                Navigator.pop(context);
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            'Post Comment',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}
// user tapped comment button 
void addComment() async {
  final content = commentController.text.trim();
  if (content.isNotEmpty){
    try {
      // Generate a unique local ID for the comment
      final localCommentId = "local_${DateTime.now().millisecondsSinceEpoch}";
      
      // First create a new comment locally for immediate display
      final newComment = Comments(
        commentId: localCommentId, // Use our local ID format
        content: content,
        postId: widget.post.id,
        userId: currentUser!.id,
        userName: currentUser!.name,
        profilePicture: currentUser!.profilePictureUrl,
        createdAt: DateTime.now(),
      );
      
      // Update UI immediately with new comment
      setState(() {
        widget.post.comments.add(newComment);
      });
      
      // Clear the input field
      commentController.clear();
      
      // Then save to backend without refreshing entire post list
      await postCubit.addCommentLocal(
        widget.post.id, 
        currentUser!.id, 
        currentUser!.name, 
        currentUser!.profilePictureUrl, 
        content
      );
    } catch (e) {
      // If backend save fails, show error but keep comment in UI
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Comment saved locally but not synced: $e'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

@override
  void dispose() {
    commentController.dispose();
    _likeAnimationController.dispose();
    _scaleAnimationController.dispose();
    _videoController?.dispose();
    _hideControlsTimer?.cancel();
    
    // Reset orientation and UI mode when disposing
    if (_isFullScreen) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _scaleAnimationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _scaleAnimationController.reverse();
  }

  void _onTapCancel() {
    _scaleAnimationController.reverse();
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  // Format duration to mm:ss
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
  
  // Skip forward 5 seconds
  void _skipForward() {
    if (_videoController != null && _isVideoInitialized) {
      final newPosition = _videoController!.value.position + const Duration(seconds: 5);
      final duration = _videoController!.value.duration;
      
      if (newPosition < duration) {
        _videoController!.seekTo(newPosition);
      } else {
        _videoController!.seekTo(duration);
      }
      
      _resetHideControlsTimer();
    }
  }
  
  // Skip backward 5 seconds
  void _skipBackward() {
    if (_videoController != null && _isVideoInitialized) {
      final newPosition = _videoController!.value.position - const Duration(seconds: 5);
      
      if (newPosition > Duration.zero) {
        _videoController!.seekTo(newPosition);
      } else {
        _videoController!.seekTo(Duration.zero);
      }
      
      _resetHideControlsTimer();
    }
  }
  
  // Toggle video controls visibility
  void _toggleVideoControls() {
    setState(() {
      _showVideoControls = !_showVideoControls;
    });
    
    _resetHideControlsTimer();
  }
  
  // Reset the timer that hides controls
  void _resetHideControlsTimer() {
    _hideControlsTimer?.cancel();
    if (_showVideoControls) {
      _hideControlsTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && _videoController != null && _videoController!.value.isPlaying) {
          setState(() {
            _showVideoControls = false;
          });
        }
      });
    }
  }
  
  // Toggle fullscreen mode
  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      
      // No longer changing device orientation
      // Just updating the UI for fullscreen mode
    });
    
    _resetHideControlsTimer();
  }
  
  // Show speed selection dialog
  void _showSpeedSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Playback Speed'),
          content: SizedBox(
            width: double.minPositive,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _availableSpeeds.length,
              itemBuilder: (context, index) {
                final speed = _availableSpeeds[index];
                return ListTile(
                  title: Text('${speed}x'),
                  selected: speed == _playbackSpeed,
                  onTap: () {
                    setState(() {
                      _playbackSpeed = speed;
                      _videoController?.setPlaybackSpeed(_playbackSpeed);
                    });
                    Navigator.of(context).pop();
                    _resetHideControlsTimer();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
  
  // Restart video from beginning
  void _restartVideo() {
    if (_videoController != null && _isVideoInitialized) {
      _videoController!.seekTo(Duration.zero);
      _videoController!.play();
      _resetHideControlsTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    // check if the post is owned by the current user
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: GestureDetector(
                  onTapDown: _onTapDown,
                  onTapUp: _onTapUp,
                  onTapCancel: _onTapCancel,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      if (widget.post.Text.isNotEmpty) _buildTextContent(),
                      if (widget.post.imageUrl.isNotEmpty) 
                        widget.post.isVideo ? _buildVideoContent() : _buildImageContent(),
                    ],
                  ),
                ),
              );
            },
          ),
          _buildActionBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Hero(
            tag: 'avatar_${widget.post.UserId}_${widget.post.id}',
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(userId: widget.post.UserId),
                  ),
                );
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 21,
                  backgroundImage: widget.post.UserProfilePic.isNotEmpty
                      ? CachedNetworkImageProvider(widget.post.UserProfilePic)
                      : null,
                  backgroundColor: Colors.grey.shade200,
                  child: widget.post.UserProfilePic.isEmpty
                      ? Text(
                          widget.post.UserName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post.UserName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeago.format(widget.post.timestamp),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (isOwnPost)
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_horiz,
                color: Colors.grey.shade600,
                size: 22,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 6,
              position: PopupMenuPosition.under,
              color: Colors.white,
              offset: Offset(0, 10),
              onSelected: (value) async {
                if (value == 'edit') {
                  final newCaption = await showDialog<String>(
                    context: context,
                    barrierColor: Colors.black54,
                    builder: (context) {
                      final controller = TextEditingController(text: widget.post.Text);
                      return AlertDialog(
                        backgroundColor: Colors.white,
                        title: Row(
                          children: [
                            Icon(Icons.edit_note, color: Colors.blue.shade700, size: 24),
                            SizedBox(width: 10),
                            Text(
                              'Edit Caption',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 8,
                        content: Container(
                          width: double.maxFinite,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Update your post caption',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              SizedBox(height: 16),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: TextField(
                                  controller: controller,
                                  maxLines: 5,
                                  minLines: 3,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'What\'s on your mind?',
                                    hintStyle: TextStyle(color: Colors.grey.shade400),
                                    contentPadding: const EdgeInsets.all(16),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.black54,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, controller.text.trim()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                              'Save Changes',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                  if (newCaption != null && newCaption.isNotEmpty && newCaption != widget.post.Text) {
                    // Update the post caption in the database
                    await postCubit.updatePostCaption(widget.post.id, newCaption);
                    if (mounted) setState(() {});
                  }
                } else if (value == 'delete') {
                  showDeleteConfirmation();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18, color: Colors.blue.shade700),
                      SizedBox(width: 12),
                      Text(
                        'Edit Caption',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red.shade700),
                      SizedBox(width: 12),
                      Text(
                        'Delete Post',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTextContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        widget.post.Text,
        style: const TextStyle(
          fontSize: 15,
          height: 1.4,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildVideoContent() {
    return _isFullScreen
        ? _buildFullScreenVideo()
        : Container(
      margin: EdgeInsets.only(
        top: widget.post.Text.isNotEmpty ? 12 : 0,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      height: 350,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
              child: _buildVideoPlayer(),
            ),
          );
  }
  
  Widget _buildFullScreenVideo() {
    return Container(
      color: Colors.black,
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: _buildVideoPlayer(),
    );
  }
  
  Widget _buildVideoPlayer() {
    return _isVideoInitialized && _videoController != null
          ? Stack(
              alignment: Alignment.center,
              children: [
              // Video player
                AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                ),
              
              // Overlay for tap detection
                GestureDetector(
                onTap: _toggleVideoControls,
                behavior: HitTestBehavior.translucent,
                child: Container(
                  color: Colors.transparent,
                ),
              ),
              
              // Video controls (only show when _showVideoControls is true)
              if (_showVideoControls)
                _isFullScreen 
                  ? _buildFullScreenControls()
                  : _buildNormalControls(),
              
              // Play button overlay (only when controls are not shown and video is paused)
              if (!_showVideoControls && _videoController != null && !_videoController!.value.isPlaying)
                GestureDetector(
                  onTap: _toggleVideoControls,
                  child: Container(
                    color: Colors.transparent,
                    child: Center(
                      child: Icon(
                        Icons.play_arrow,
                        color: Colors.white.withOpacity(0.7),
                        size: 50,
                      ),
                    ),
                  ),
                ),
                
              // Video completion overlay
              ValueListenableBuilder(
                valueListenable: _videoController!,
                builder: (context, VideoPlayerValue value, child) {
                  if (value.position >= value.duration && value.duration.inMilliseconds > 0) {
                    return GestureDetector(
                      onTap: _restartVideo,
                      child: Container(
                        color: Colors.black.withOpacity(0.5),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.replay,
                                color: Colors.white,
                                size: 50,
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Replay',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          )
        : Container(
            color: Colors.grey.shade200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 10),
                if (!_isVideoInitialized && widget.post.imageUrl.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Unable to load video. Tap to retry.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                if (!_isVideoInitialized && widget.post.imageUrl.isNotEmpty)
                  TextButton(
                    onPressed: _initializeVideoController,
                    child: const Text("Retry"),
                  )
              ],
            ),
          );
  }

  // New method for fullscreen controls
  Widget _buildFullScreenControls() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top bar with exit fullscreen button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.black.withOpacity(0.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.fullscreen_exit,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: _toggleFullScreen,
                  tooltip: 'Exit Fullscreen',
                ),
              ],
            ),
          ),
          
          // Spacer to push controls to bottom
          const Spacer(),
          
          // Bottom controls
          Container(
            padding: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.8],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Video progress and duration
                ValueListenableBuilder(
                  valueListenable: _videoController!,
                  builder: (context, VideoPlayerValue value, child) {
                    return Column(
                      children: [
                        // Progress slider
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                            activeTrackColor: Colors.white,
                            inactiveTrackColor: Colors.white.withOpacity(0.3),
                            thumbColor: Colors.white,
                          ),
                          child: Slider(
                            value: value.position.inMilliseconds.toDouble(),
                            min: 0,
                            max: value.duration.inMilliseconds.toDouble(),
                            onChanged: (newPosition) {
                              _videoController!.seekTo(Duration(milliseconds: newPosition.toInt()));
                              _resetHideControlsTimer();
                            },
                          ),
                        ),
                        
                        // Time indicators
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Current position
                              Text(
                                _formatDuration(value.position),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              
                              // Total duration
                              Text(
                                _formatDuration(value.duration),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Play/Pause and skip controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Restart video button
                    IconButton(
                      icon: const Icon(
                        Icons.replay,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: _restartVideo,
                      tooltip: 'Restart',
                    ),
                    
                    // Skip backward button
                    IconButton(
                      icon: const Icon(
                        Icons.replay_5,
                        color: Colors.white,
                        size: 36,
                      ),
                      onPressed: _skipBackward,
                    ),
                    
                    // Play/Pause button
                    IconButton(
                      icon: Icon(
                        _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 50,
                      ),
                      onPressed: () {
                    setState(() {
                      if (_videoController!.value.isPlaying) {
                        _videoController!.pause();
                      } else {
                        _videoController!.play();
                            // Auto-hide controls after video starts playing
                            _resetHideControlsTimer();
                      }
                    });
                  },
                    ),
                    
                    // Skip forward button
                    IconButton(
                      icon: const Icon(
                        Icons.forward_5,
                        color: Colors.white,
                        size: 36,
                      ),
                      onPressed: _skipForward,
                    ),
                    
                    // Playback speed button
                    TextButton(
                      onPressed: _showSpeedSelectionDialog,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                      child: Text(
                        '${_playbackSpeed}x',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // New method for normal (non-fullscreen) controls
  Widget _buildNormalControls() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Empty space at top
          const Spacer(),
          
          // Bottom controls in a more compact layout
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Main controls row (backward, play/pause, forward)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Skip backward button
                    IconButton(
                      icon: const Icon(
                        Icons.replay_5,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: _skipBackward,
                    ),
                    const SizedBox(width: 24),
                    
                    // Play/Pause button
                    IconButton(
                      icon: Icon(
                        _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 40,
                      ),
                      onPressed: () {
                        setState(() {
                          if (_videoController!.value.isPlaying) {
                            _videoController!.pause();
                          } else {
                            _videoController!.play();
                            // Auto-hide controls after video starts playing
                            _resetHideControlsTimer();
                          }
                        });
                      },
                    ),
                    const SizedBox(width: 24),
                    
                    // Skip forward button
                    IconButton(
                      icon: const Icon(
                        Icons.forward_5,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: _skipForward,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Video progress and duration
                ValueListenableBuilder(
                  valueListenable: _videoController!,
                  builder: (context, VideoPlayerValue value, child) {
                    return Column(
                      children: [
                        // Progress slider
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                            activeTrackColor: Colors.white,
                            inactiveTrackColor: Colors.white.withOpacity(0.3),
                            thumbColor: Colors.white,
                          ),
                          child: Slider(
                            value: value.position.inMilliseconds.toDouble(),
                            min: 0,
                            max: value.duration.inMilliseconds.toDouble(),
                            onChanged: (newPosition) {
                              _videoController!.seekTo(Duration(milliseconds: newPosition.toInt()));
                              _resetHideControlsTimer();
                            },
                          ),
                        ),
                        
                        // Time and additional controls row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Current position
                            Text(
                              _formatDuration(value.position),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            
                            // Restart button
                            IconButton(
                              icon: const Icon(
                                Icons.replay,
                                color: Colors.white,
                                size: 16,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: _restartVideo,
                            ),
                            
                            // Playback speed button
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: _showSpeedSelectionDialog,
                                child: Text(
                                  '${_playbackSpeed}x',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            
                            // Fullscreen button
                            IconButton(
                              icon: const Icon(
                                Icons.fullscreen,
                                color: Colors.white,
                                size: 16,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: _toggleFullScreen,
                            ),
                            
                            // Total duration
                            Text(
                              _formatDuration(value.duration),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent() {
    return Container(
      margin: EdgeInsets.only(
        top: widget.post.Text.isNotEmpty ? 12 : 0,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      height: 350,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: widget.post.imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey.shade200,
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey.shade200,
            child: const Icon(Icons.error),
          ),
        ),
      ),
    );
  }

  Widget _buildActionBar() {
    final isLiked = widget.post.likes.contains(currentUser?.id);
    final isSaved = widget.post.savedBy.contains(currentUser?.id);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildActionButton(
            icon: isLiked ? Icons.favorite : Icons.favorite_border,
            color: isLiked ? Colors.red : Colors.grey.shade600,
            count: widget.post.likes.length,
            onTap: toggleLikePost,
            isAnimated: true,
          ),
          const SizedBox(width: 24),
          _buildActionButton(
            icon: CupertinoIcons.chat_bubble,
            color: Colors.grey.shade600,
            count: widget.post.comments.length,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CommentsPage(
                    comments: widget.post.comments,
                    currentUserId: currentUser!.id,
                    postOwnerId: widget.post.UserId,
                    postId: widget.post.id,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 24),
          _buildActionButton(
            icon: CupertinoIcons.share,
            color: Colors.black87,
            count: widget.post.shareCount,
            onTap: sharePost,
          ),
          const Spacer(),
          GestureDetector(
            onTap: toggleSavePost,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSaved ? Colors.blue.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSaved ? Colors.blue.shade300 : Colors.grey.shade300, 
                  width: 1
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    size: 16,
                    color: isSaved ? Colors.blue.shade700 : Colors.black87,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isSaved ? 'Saved' : 'Save',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSaved ? Colors.blue.shade700 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required int count,
    required VoidCallback onTap,
    bool isAnimated = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _likeAnimationController,
            builder: (context, child) {
              return Transform.scale(
                scale: isAnimated ? 1.0 + (_likeAnimationController.value * 0.3) : 1.0,
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          Text(
            _formatCount(count),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

