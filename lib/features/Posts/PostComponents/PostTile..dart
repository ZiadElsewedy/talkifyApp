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

  // update like
  postCubit.toggleLikePost(widget.post.id, currentUser!.id).catchError((error){
    // if there's an error, get back to original values
    setState(() {
    if (isLiked){
      widget.post.likes.add(currentUser!.id); // revert unlike 
    }
    else{
      widget.post.likes.remove(currentUser!.id); // revert like 
    }
  });
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
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
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
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
                                  color: theme.colorScheme.primary,
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
                              color: theme.colorScheme.primary,
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
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // More options button
                if (isOwnPost)
                  IconButton(
                    icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurface),
                    onPressed: showDeleteConfirmation,
                  ),
              ],
            ),
          ),

          // Post image
          if (widget.post.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: widget.post.imageUrl,
                height: 400,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 400,
                  color: theme.colorScheme.surface,
                  child: const Center(child: PercentCircleIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 400,
                  color: theme.colorScheme.surface,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: theme.colorScheme.error, size: 40),
                      const SizedBox(height: 8),
                      Text(
                        'Failed to load image',
                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Post actions (like, comment, share)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: toggleLikePost,
                  child: Icon( widget.post.likes.contains(currentUser!.id) 
                    ? Icons.favorite
                    : Icons.favorite_border,
                    color: widget.post.likes.contains(currentUser!.id) 
                    ? Colors.red : theme.colorScheme.onSurface),
                ),
                IconButton(
                  icon: Icon(Icons.chat_bubble_outline, color: theme.colorScheme.onSurface),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(Icons.send_outlined, color: theme.colorScheme.onSurface),
                  onPressed: () {},
                ),
                const Spacer(),
                if (isOwnPost)
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                    onPressed: showDeleteConfirmation,
                  ),
                IconButton(
                  icon: Icon(Icons.bookmark_border, color: theme.colorScheme.onSurface),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Likes count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              widget.post.likes.length.toString(), // likes count
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),

          // Caption
          if (widget.post.Text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 14,
                  ),
                  children: [
                    TextSpan(
                      text: '${widget.post.UserName} ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: widget.post.Text,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}