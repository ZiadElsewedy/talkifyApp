import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Posts/domain/Entite/Comments.dart';
import 'package:talkifyapp/features/Posts/PostComponents/commentTile.dart';
import 'package:talkifyapp/features/Posts/presentation/cubits/post_cubit.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/auth/domain/entities/AppUser.dart';
import 'package:talkifyapp/features/Posts/presentation/cubits/post_states.dart';

class CommentsPage extends StatefulWidget {
  final List<Comments> comments;
  final String currentUserId;
  final String postOwnerId;
  final String postId;
  const CommentsPage({
    Key? key, 
    required this.comments, 
    required this.currentUserId, 
    required this.postOwnerId,
    required this.postId,
  }) : super(key: key);

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  late List<Comments> localComments;
  final TextEditingController _controller = TextEditingController();
  late final PostCubit _postCubit;
  AppUser? currentUser;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _postCubit = context.read<PostCubit>();
    currentUser = context.read<AuthCubit>().GetCurrentUser();
    localComments = List<Comments>.from(widget.comments)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> refreshComments() async {
    try {
      setState(() {
        isLoading = true;
      });
      
      // Fetch all posts to get updated comments
      await _postCubit.fetechAllPosts();
      
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh comments: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> addComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    try {
      if (currentUser == null) {
        throw Exception("User not logged in");
      }

      // Add comment locally first for immediate feedback
      final newComment = Comments(
        commentId: 'local_${DateTime.now().millisecondsSinceEpoch}',
        content: text,
        postId: widget.postId,
        userId: currentUser!.id,
        userName: currentUser!.name,
        profilePicture: currentUser!.profilePictureUrl,
        createdAt: DateTime.now(),
      );

      setState(() {
        localComments.insert(0, newComment);
        _controller.clear();
      });

      // Save to database with actual user information
      await _postCubit.addComment(  // Changed from addCommentLocal to addComment
        widget.postId,
        currentUser!.id,
        currentUser!.name,
        currentUser!.profilePictureUrl,
        text,
      );

      // Refresh comments after adding
      await refreshComments();
    } catch (e) {
      // If saving to database fails, show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save comment: $e'),
            backgroundColor: Colors.red,
          ),
        );
        // Remove the local comment since it failed to save
        setState(() {
          localComments.removeAt(0);
        });
      }
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      // Remove locally first
      setState(() {
        localComments.removeWhere((c) => c.commentId == commentId);
      });

      // Delete from database and refresh
      if (!commentId.startsWith('local_')) {
        await _postCubit.deleteComment(widget.postId, commentId);  // Changed from deleteCommentLocal to deleteComment
        await refreshComments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete comment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Add refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: refreshComments,
          ),
        ],
      ),
      body: BlocConsumer<PostCubit, PostState>(
        listener: (context, state) {
          if (state is PostsLoaded) {
            // Find the current post and update local comments
            final currentPost = state.posts.firstWhere(
              (post) => post.id == widget.postId,
              orElse: () => throw Exception('Post not found'),
            );
            setState(() {
              localComments = List<Comments>.from(currentPost.comments)
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            });
          } else if (state is PostsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ListView.builder(
                      itemCount: localComments.length,
                      itemBuilder: (context, index) {
                        final comment = localComments[index];
                        final isOwner = widget.currentUserId == widget.postOwnerId || 
                                      widget.currentUserId == comment.userId;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                          child: CommentTile(
                            comment: comment,
                            isCommentOwner: isOwner,
                            onDelete: isOwner
                                ? () => deleteComment(comment.commentId)
                                : null,
                          ),
                        );
                      },
                    ),
                    if (isLoading || state is PostsLoading)
                      const Center(
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),
              Container(
                color: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            hintText: 'Write a comment...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: state is! PostsLoading ? addComment : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
} 