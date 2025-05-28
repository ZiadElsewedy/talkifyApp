import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
                      if (widget.post.imageUrl.isNotEmpty) _buildImageContent(),
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
            count: 0,
            onTap: () {},
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.bookmark_border,
                  size: 16,
                  color: Colors.black87,
                ),
                const SizedBox(width: 4),
                Text(
                  'Save',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
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
