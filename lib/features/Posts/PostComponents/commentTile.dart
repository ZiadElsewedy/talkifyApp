import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Posts/domain/Entite/Comments.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/components/WhiteCircleIndicator.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:talkifyapp/features/Posts/presentation/cubits/post_cubit.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/auth/domain/entities/AppUser.dart';
import 'dart:math' as math;

class CommentTile extends StatefulWidget {
  final Comments comment;
  final Function()? onDelete;
  final bool isCommentOwner;
  final String postId;

  const CommentTile({
    super.key,
    required this.comment,
    this.onDelete,
    this.isCommentOwner = false,
    required this.postId,
  });

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  bool _isReplying = false;
  bool _showReplies = false;
  final TextEditingController _replyController = TextEditingController();
  AppUser? _currentUser;
  
  @override
  void initState() {
    super.initState();
    _currentUser = context.read<AuthCubit>().GetCurrentUser();
  }
  
  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _showDeleteConfirmation(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    final Color textColor = isDarkMode ? Colors.grey[200]! : Colors.black87;
    final Color subTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final Color iconColor = isDarkMode ? Colors.red[300]! : Colors.red[700]!;
    final Color buttonColor = isDarkMode ? Colors.red[700]! : Colors.black;
    final Color cancelColor = isDarkMode ? Colors.grey[400]! : Colors.black54;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: iconColor),
            const SizedBox(width: 8),
            Text('Delete Comment', style: TextStyle(color: textColor)),
          ],
        ),
        content: Text('Are you sure you want to delete this comment?', style: TextStyle(color: subTextColor)),
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: cancelColor),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Call the onDelete callback after confirmation
              if (widget.onDelete != null) {
                widget.onDelete!();
              }
            },
            style: TextButton.styleFrom(foregroundColor: iconColor),
            child: Text('Delete', style: TextStyle(color: iconColor)),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteReplyConfirmation(BuildContext context, String replyId) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    final Color textColor = isDarkMode ? Colors.grey[200]! : Colors.black87;
    final Color subTextColor = isDarkMode ? Colors.grey[400]! : Colors.black87;
    final Color iconColor = isDarkMode ? Colors.red[300]! : Colors.red[700]!;
    final Color buttonColor = isDarkMode ? Colors.red[700]! : Colors.black;
    final Color cancelColor = isDarkMode ? Colors.grey[400]! : Colors.black54;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: iconColor),
            const SizedBox(width: 8),
            Text('Delete Reply', style: TextStyle(color: textColor)),
          ],
        ),
        content: Text('Are you sure you want to delete this reply?', style: TextStyle(color: subTextColor)),
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: cancelColor),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteReply(replyId);
            },
            style: TextButton.styleFrom(foregroundColor: iconColor),
            child: Text('Delete', style: TextStyle(color: iconColor)),
          ),
        ],
      ),
    );
  }
  
  void _toggleLikeComment() async {
    if (_currentUser == null) return;
    
    try {
      // Optimistically update UI
      setState(() {
        if (widget.comment.likes.contains(_currentUser!.id)) {
          widget.comment.likes.remove(_currentUser!.id);
        } else {
          widget.comment.likes.add(_currentUser!.id);
        }
      });
      
      // Update in backend
      await context.read<PostCubit>().toggleLikeCommentLocal(
        widget.postId,
        widget.comment.commentId,
        _currentUser!.id,
      );
    } catch (e) {
      // Show error and revert UI if failed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to like comment: $e')),
      );
    }
  }
  
  void _addReply() async {
    if (_currentUser == null) return;
    
    final content = _replyController.text.trim();
    if (content.isEmpty) return;
    
    try {
      // Generate a temporary ID for immediate UI feedback
      final tempReplyId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      
      // Create a temporary reply for UI
      final newReply = Reply(
        replyId: tempReplyId,
        content: content,
        userId: _currentUser!.id,
        userName: _currentUser!.name,
        profilePicture: _currentUser!.profilePictureUrl,
        createdAt: DateTime.now(),
        likes: [],
      );
      
      // Update UI immediately - create a new list to avoid direct modification
      setState(() {
        final updatedReplies = List<Reply>.from(widget.comment.replies)..add(newReply);
        widget.comment.replies.clear();  // Clear first, then add all
        widget.comment.replies.addAll(updatedReplies);
        _replyController.clear();
        _isReplying = false;
        _showReplies = true;
      });
      
      // Update in backend
      await context.read<PostCubit>().addReplyToCommentLocal(
        widget.postId,
        widget.comment.commentId,
        _currentUser!.id,
        _currentUser!.name,
        _currentUser!.profilePictureUrl,
        content,
      );
    } catch (e) {
      // Show error if failed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add reply: ${e.toString().substring(0, math.min(e.toString().length, 100))}')),
      );
    }
  }
  
  void _deleteReply(String replyId) async {
    if (_currentUser == null) return;
    
    try {
      // Find the reply first to verify it exists
      final replyIndex = widget.comment.replies.indexWhere((reply) => reply.replyId == replyId);
      if (replyIndex == -1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reply not found')),
        );
        return;
      }
      
      // Optimistically update UI - create a new list to avoid direct modification
      setState(() {
        final updatedReplies = List<Reply>.from(widget.comment.replies)
          ..removeWhere((reply) => reply.replyId == replyId);
        widget.comment.replies.clear();  // Clear first, then add all
        widget.comment.replies.addAll(updatedReplies);
      });
      
      // Update in backend
      await context.read<PostCubit>().deleteReplyLocal(
        widget.postId,
        widget.comment.commentId,
        replyId,
      );
    } catch (e) {
      // Show error if failed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete reply: ${e.toString().substring(0, math.min(e.toString().length, 100))}')),
      );
    }
  }
  
  void _toggleLikeReply(String replyId) async {
    if (_currentUser == null) return;
    
    try {
      // Find the reply
      final replyIndex = widget.comment.replies.indexWhere((reply) => reply.replyId == replyId);
      if (replyIndex == -1) {
        // Reply not found in local state, show error and return
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot find reply to like')),
        );
        return;
      }
      
      final reply = widget.comment.replies[replyIndex];
      
      // Create a new list to avoid direct modification
      List<String> updatedLikes = List<String>.from(reply.likes);
      
      // Optimistically update UI
      setState(() {
        if (updatedLikes.contains(_currentUser!.id)) {
          updatedLikes.remove(_currentUser!.id);
        } else {
          updatedLikes.add(_currentUser!.id);
        }
        
        // Create a new reply with the updated likes
        final updatedReply = Reply(
          replyId: reply.replyId,
          content: reply.content,
          userId: reply.userId,
          userName: reply.userName,
          profilePicture: reply.profilePicture,
          createdAt: reply.createdAt,
          likes: updatedLikes,
        );
        
        // Update the reply in the replies list
        widget.comment.replies[replyIndex] = updatedReply;
      });
      
      // Update in backend
      await context.read<PostCubit>().toggleLikeReplyLocal(
        widget.postId,
        widget.comment.commentId,
        replyId,
        _currentUser!.id,
      );
    } catch (e) {
      // Show error if failed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not like reply: ${e.toString().substring(0, math.min(e.toString().length, 100))}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use theme-based colors
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    final Color textColor = isDarkMode ? Colors.grey[200]! : Colors.black87;
    final Color subTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final Color iconColor = isDarkMode ? Colors.grey[400]! : Colors.black54;
    final Color dividerColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final Color likeColor = isDarkMode ? Colors.red[300]! : Colors.red[700]!;
    final Color commentBg = isDarkMode ? Colors.grey[800]! : Colors.grey[100]!;
    final Color shadowColor = isDarkMode ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05);
    
    final bool isCommentLiked = _currentUser != null && widget.comment.likes.contains(_currentUser!.id);
    final int likeCount = widget.comment.likes.length;
    final int replyCount = widget.comment.replies.length;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dividerColor),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main comment content
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: commentBg,
                  child: widget.comment.profilePicture.isNotEmpty
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: widget.comment.profilePicture,
                            height: 36,
                            width: 36,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const PercentCircleIndicator(
                              strokeWidth: 2,
                            ),
                            errorWidget: (context, url, error) => Text(
                              widget.comment.userName.isNotEmpty
                                  ? widget.comment.userName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      : Text(
                          widget.comment.userName.isNotEmpty
                              ? widget.comment.userName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.comment.userName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeago.format(widget.comment.createdAt),
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          if (widget.isCommentOwner && widget.onDelete != null)
                            GestureDetector(
                              onTap: () => _showDeleteConfirmation(context),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: commentBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(
                                  Icons.delete_outline,
                                  size: 16,
                                  color: iconColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: commentBg.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.comment.content,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Comment actions (like, reply)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                // Like button
                GestureDetector(
                  onTap: _toggleLikeComment,
                  child: Row(
                    children: [
                      Icon(
                        isCommentLiked ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: isCommentLiked ? likeColor : iconColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        likeCount > 0 ? '$likeCount' : 'Like',
                        style: TextStyle(
                          fontSize: 12,
                          color: isCommentLiked ? likeColor : iconColor,
                          fontWeight: isCommentLiked ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                
                // Reply button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isReplying = !_isReplying;
                      if (_isReplying) {
                        _showReplies = true;
                      }
                    });
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.reply,
                        size: 16,
                        color: iconColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Reply',
                        style: TextStyle(
                          fontSize: 12,
                          color: iconColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                
                // Show/hide replies
                if (replyCount > 0)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showReplies = !_showReplies;
                      });
                    },
                    child: Row(
                      children: [
                        Icon(
                          _showReplies ? Icons.expand_less : Icons.expand_more,
                          size: 16,
                          color: iconColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _showReplies ? 'Hide replies' : 'Show $replyCount ${replyCount == 1 ? 'reply' : 'replies'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: iconColor,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // Reply input field
          if (_isReplying)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: commentBg,
                    child: _currentUser?.profilePictureUrl.isNotEmpty == true
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: _currentUser!.profilePictureUrl,
                              height: 28,
                              width: 28,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const PercentCircleIndicator(
                                strokeWidth: 2,
                              ),
                              errorWidget: (context, url, error) => Text(
                                _currentUser?.name.isNotEmpty == true
                                    ? _currentUser!.name[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          )
                        : Text(
                            _currentUser?.name.isNotEmpty == true
                                ? _currentUser!.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      decoration: InputDecoration(
                        hintText: 'Write a reply...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: subTextColor,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: commentBg),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: commentBg),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: textColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        isDense: true,
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor,
                      ),
                      maxLines: 3,
                      minLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _addReply,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: textColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.send,
                        size: 18,
                        color: cardColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Replies list
          if (_showReplies && widget.comment.replies.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.comment.replies.length,
              padding: const EdgeInsets.only(left: 40, right: 12, bottom: 12),
              itemBuilder: (context, index) {
                final reply = widget.comment.replies[index];
                final bool isReplyLiked = _currentUser != null && reply.likes.contains(_currentUser!.id);
                final bool isReplyOwner = _currentUser != null && reply.userId == _currentUser!.id;
                
                return Container(
                  margin: const EdgeInsets.only(top: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: commentBg,
                        child: reply.profilePicture.isNotEmpty
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: reply.profilePicture,
                                  height: 28,
                                  width: 28,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const PercentCircleIndicator(
                                    strokeWidth: 2,
                                  ),
                                  errorWidget: (context, url, error) => Text(
                                    reply.userName.isNotEmpty
                                        ? reply.userName[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              )
                            : Text(
                                reply.userName.isNotEmpty
                                    ? reply.userName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  reply.userName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  timeago.format(reply.createdAt),
                                  style: TextStyle(
                                    color: subTextColor,
                                    fontSize: 11,
                                  ),
                                ),
                                const Spacer(),
                                if (isReplyOwner)
                                  GestureDetector(
                                    onTap: () => _showDeleteReplyConfirmation(context, reply.replyId),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: commentBg,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Icon(
                                        Icons.delete_outline,
                                        size: 14,
                                        color: iconColor,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                              decoration: BoxDecoration(
                                color: commentBg.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                reply.content,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Reply like button
                            GestureDetector(
                              onTap: () => _toggleLikeReply(reply.replyId),
                              child: Row(
                                children: [
                                  Icon(
                                    isReplyLiked ? Icons.favorite : Icons.favorite_border,
                                    size: 14,
                                    color: isReplyLiked ? likeColor : iconColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    reply.likes.length > 0 ? '${reply.likes.length}' : 'Like',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isReplyLiked ? likeColor : iconColor,
                                      fontWeight: isReplyLiked ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
