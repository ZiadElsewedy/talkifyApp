import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Profile/Pages/components/WhiteCircleIndicator.dart';
import 'package:talkifyapp/features/Profile/domain/entites/ProfileUser.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/Posts/presentation/cubits/post_cubit.dart';
import 'package:talkifyapp/features/auth/domain/entities/AppUser.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:talkifyapp/features/Posts/domain/Entite/Posts.dart';
import 'package:talkifyapp/features/Posts/PostComponents/commentTile.dart';

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

class _PostTileState extends State<PostTile> {
  late final postCubit = context.read<PostCubit>();
  late final profileCubit = context.read<ProfileCubit>();
  AppUser? currentUser;
  ProfileUser? PostUser;
  bool isOwnPost = false;

  @override
  void initState() {
    super.initState();
    initializeData();
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
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete?.call();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
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
    builder: (context) => AlertDialog(
      title: const Text('Add a new comment'),
      content: TextField(
        controller: commentController,
        decoration: const InputDecoration(
          hintText: 'Write your comment...',
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel' , style: TextStyle(color: Colors.red)),
        ),
        TextButton(
          onPressed: () async {
            if (commentController.text.trim().isNotEmpty) {
               addComment();
              if (mounted) {
                Navigator.pop(context);
              }
            }
          },
          child: const Text('Add' , style: TextStyle(color: Colors.green)),
        ),
      ],
    ),
  );
}
// user tapped comment button 
void addComment(){
  final content = commentController.text.trim();
  if (content.isNotEmpty){
    postCubit.addComment(widget.post.id, currentUser!.id, currentUser!.name, currentUser!.profilePictureUrl, content);
    commentController.clear();
  }
}

@override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user info and options
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // User avatar
                Hero(
                  tag: 'profile_${widget.post.UserId}_${widget.post.id}',
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: colorScheme.primary.withOpacity(0.2),
                    child: widget.post.UserProfilePic.isNotEmpty
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: widget.post.UserProfilePic,
                              height: 48,
                              width: 48,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const PercentCircleIndicator(),
                              errorWidget: (context, url, error) => Text(
                                widget.post.UserName.isNotEmpty
                                    ? widget.post.UserName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          )  
                        : Text(
                            widget.post.UserName.isNotEmpty
                                ? widget.post.UserName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                // User name and time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.UserName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        timeago.format(widget.post.timestamp),
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // More options button
                if (isOwnPost)
                  IconButton(
                    icon: Icon(Icons.more_vert, color: colorScheme.primary),
                    onPressed: showDeleteConfirmation,
                  ),
              ],
            ),
          ),

          // Caption
          if (widget.post.Text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 16,
                  ),
                  children: [
                    TextSpan(
                      text: widget.post.Text,
                    ),
                  ],
                ),
              ),
            ),

          // Post image
          if (widget.post.imageUrl.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(4)),
                child: CachedNetworkImage(
                  imageUrl: widget.post.imageUrl,
                  height: 400,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 400,
                    color: colorScheme.surface,
                    child: const Center(child: PercentCircleIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 400,
                    color: colorScheme.surface,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: colorScheme.error, size: 40),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load image',
                          style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Post actions (like, comment, share)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Like button with animation
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: toggleLikePost,
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Icon(
                                widget.post.likes.contains(currentUser?.id) 
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: widget.post.likes.contains(currentUser?.id) 
                                    ? Colors.red 
                                    : colorScheme.onSurface,
                                size: 22,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.post.likes.length.toString(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: widget.post.likes.contains(currentUser?.id) 
                                      ? Colors.red
                                      : colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Comment button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: OpenCommentBox,
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.chat_bubble_outline, 
                                color: colorScheme.onSurface,
                                size: 22,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.post.comments.length.toString(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Share button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.share_outlined, 
                            color: colorScheme.onSurface,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Delete button (only for post owner)
                    if (isOwnPost)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: showDeleteConfirmation,
                          borderRadius: BorderRadius.circular(24),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.delete_outline, 
                              color: colorScheme.error,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    
                    // Bookmark button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.bookmark_border, 
                            color: colorScheme.onSurface,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Comments section
          if (widget.post.comments.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 8),
              child: Text(
                'Comments' ,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.post.comments.length,
              itemBuilder: (context, index) {
                final comment = widget.post.comments[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: CommentTile(
                    comment: comment,
                    isCommentOwner: comment.userId == currentUser?.id,
                    onDelete: comment.userId == currentUser?.id ? () {
                      postCubit.deleteComment(
                        widget.post.id,
                        comment.commentId,
                      );
                    } : null,
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
