import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/ProfilePage.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/components/WhiteCircleIndicator.dart';
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
  bool showAllComments = false;

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
      title: const Text('Add a new comment', 
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        )
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 8,
      content: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.surface),
        ),
        child: TextField(
          controller: commentController,
          decoration: InputDecoration(
            hintText: 'Write your comment...',
            hintStyle: TextStyle(color: Colors.grey),
            contentPadding: const EdgeInsets.all(16),
            border: InputBorder.none,
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
          ),
          maxLines: 3,
          style: TextStyle(fontSize: 16),
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: Colors.red),
          label: const Text('Cancel', style: TextStyle(color: Colors.red)),
        ),
        TextButton.icon(
          onPressed: () async {
            if (commentController.text.trim().isNotEmpty) {
              addComment();
              if (mounted) {
                Navigator.pop(context);
              }
            }
          },
          icon: const Icon(Icons.send, color: Colors.green),
          label: const Text('Add', style: TextStyle(color: Colors.green)),
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
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.2),
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
                // User avatar with better shadow
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Hero(
                    tag: 'profile_${widget.post.UserId}_${widget.post.id}',
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor:  Colors.white,
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
                                    color: colorScheme.surface,
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
                ),
                const SizedBox(width: 16),
                // User name and time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfilePage(userId: widget.post.UserId),
                            ),
                          );
                        },
                        child: Text(
                          widget.post.UserName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                      Text(
                        timeago.format(widget.post.timestamp),
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 13,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                // More options button
                if (isOwnPost)
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.more_vert, color: Colors.black, size: 22),
                      onPressed: showDeleteConfirmation,
                      splashRadius: 24,
                    ),
                  ),
              ],
            ),
          ),

          // Caption
          if (widget.post.Text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 16,
                    height: 1.4,
                    letterSpacing: 0.3,
                  ),
                  children: [
                    TextSpan(
                      text: widget.post.Text,
                    ),
                  ],
                ),
              ),
            ),

          // Post image with improved design
          if (widget.post.imageUrl.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: colorScheme.onSurface.withOpacity(0.05),
                  width: 1,
                ),
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
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.post.likes.length.toString(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
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
                    
                    const SizedBox(width: 8),
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
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.post.comments.length.toString(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 8),
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
                            size: 20,
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
                              size: 20,
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
                            size: 20,
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
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: colorScheme.onSurface.withOpacity(0.05),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Comments',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.grey,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 209, 209, 209),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.post.comments.length.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: showAllComments || widget.post.comments.length <= 2 
                      ? widget.post.comments.length 
                      : 2,
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
                
                // Show more comments button
                if (widget.post.comments.length > 2 && !showAllComments)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          showAllComments = true;
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colorScheme.secondary.withOpacity(0.5)),
                        ),
                        child: Center(
                          child: Text(
                            'Show all ${widget.post.comments.length} comments',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                
                // Show less comments button (appears when showing all comments)
                if (widget.post.comments.length > 2 && showAllComments)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          showAllComments = false;
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.keyboard_arrow_up, size: 18, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                'Show less',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
