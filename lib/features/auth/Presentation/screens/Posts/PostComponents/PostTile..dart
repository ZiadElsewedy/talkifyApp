import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Profile/Pages/components/WhiteCircleIndicator.dart';
import 'package:talkifyapp/features/Profile/domain/entites/ProfileUser.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/Posts/presentation/cubits/post_cubit.dart';
import 'package:talkifyapp/features/auth/domain/entities/AppUser.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:talkifyapp/features/auth/Presentation/screens/Posts/domain/Entite/Posts.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/LOADING!.dart';

import '../../../../../Profile/presentation/Cubits/ProfileCubit.dart';

class PostTile extends StatefulWidget {
  final Post post;
  final VoidCallback? onDelete;
  final bool? isCurrentUser;

  const PostTile({
    super.key,
    required this.post,
    this.onDelete,
    this.isCurrentUser = true, 
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
    _initializeData();
  }

  Future<void> _initializeData() async {
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


  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user info and options
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // User avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[200],
                  child: widget.post.UserProfilePic.isNotEmpty
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: widget.post.UserProfilePic,
                            height: 40,
                            width: 40,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const PercentCircleIndicator(),
                            errorWidget: (context, url, error) => Text(
                              widget.post.UserName[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )  
                      : Text(
                          widget.post.UserName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                // User name and time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.UserName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        timeago.format(widget.post.timestamp),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // More options button
                if (isOwnPost)
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: _showDeleteConfirmation,
                  ),
              ],
            ),
          ),

          // Post image
          if (widget.post.imageUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: widget.post.imageUrl,
              height: 400,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 400,
                color: Colors.grey[200],
                child: const Center(child: PercentCircleIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                height: 400,
                color: Colors.grey[200],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[400], size: 40),
                    const SizedBox(height: 8),
                    Text(
                      'Failed to load image',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),

          // Post actions (like, comment, share)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite_border),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.send_outlined),
                  onPressed: () {},
                ),
                const Spacer(),
                if (isOwnPost)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: _showDeleteConfirmation,
                  ),
                IconButton(
                  icon: const Icon(Icons.bookmark_border),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Likes count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              '0 likes',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),

          // Caption
          if (widget.post.Text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    TextSpan(
                      text: '${widget.post.UserName} ',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    TextSpan(
                      text: widget.post.Text,
                      style: const TextStyle(
                        fontSize: 14,
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
}