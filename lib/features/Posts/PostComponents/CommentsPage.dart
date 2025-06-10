import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math';
import 'package:talkifyapp/features/Posts/domain/Entite/Comments.dart';
import 'package:talkifyapp/features/Posts/PostComponents/commentTile.dart';
import 'package:talkifyapp/features/Posts/presentation/cubits/post_cubit.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/auth/domain/entities/AppUser.dart';
import 'package:talkifyapp/features/Posts/presentation/cubits/post_states.dart';

/// A page that displays and manages comments for a post
///
/// Features:
/// - View comments with newest first
/// - Add new comments
/// - Delete own comments
/// - Refresh comments to get updates
class CommentsPage extends StatefulWidget {
  // Post and comment data
  final List<Comments> comments;
  final String postId;
  
  // User information
  final String currentUserId;
  final String postOwnerId;
  
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

class _CommentsPageState extends State<CommentsPage> with SingleTickerProviderStateMixin {
  // State variables
  late List<Comments> _localComments;
  final TextEditingController _commentController = TextEditingController();
  late final PostCubit _postCubit;
  AppUser? _currentUser;
  bool _isLoading = false;
  bool _isSubmitting = false;
  
  // Keep track of the current snackbar to avoid multiple snackbars
  ScaffoldFeatureController? _currentSnackBarController;
  
  // Animation controller for the fade-in effect
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Black and white color constants
  final Color _blackColor = Colors.black;
  final Color _whiteColor = Colors.white;
  final Color _lightGrey = Colors.grey[200]!;
  final Color _mediumGrey = Colors.grey[400]!;
  final Color _darkGrey = Colors.grey[800]!;

  @override
  void initState() {
    super.initState();
    _postCubit = context.read<PostCubit>();
    _currentUser = context.read<AuthCubit>().GetCurrentUser();
    
    // Sort comments with newest first
    _localComments = List<Comments>.from(widget.comments)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    
    _animationController.forward();
  }

  /// Refreshes the comments list from the server
  Future<void> _refreshComments() async {
    if (_isLoading) return; // Prevent multiple refresh calls
    
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Use the PostCubit to refresh the posts data
      await _postCubit.fetchAllPosts();
      
    } catch (e) {
      _showErrorSnackBar('Failed to refresh comments: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Adds a new comment to the post
  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSubmitting) return;

    // Validate user is logged in
    if (_currentUser == null) {
      _showErrorSnackBar('You must be logged in to comment');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Create a temporary comment for immediate UI feedback
      final newComment = Comments(
        commentId: 'local_${DateTime.now().millisecondsSinceEpoch}',
        content: text,
        postId: widget.postId,
        userId: _currentUser!.id,
        userName: _currentUser!.name,
        profilePicture: _currentUser!.profilePictureUrl,
        createdAt: DateTime.now(),
      );

      // Update UI and clear input field
      setState(() {
        _localComments.insert(0, newComment);
        _commentController.clear();
      });

      // Save to database
      await _postCubit.addComment(
        widget.postId,
        _currentUser!.id,
        _currentUser!.name,
        _currentUser!.profilePictureUrl,
        text,
      );

      // Refresh to get server-generated ID
      await _refreshComments();
      
    } catch (e) {
      _showErrorSnackBar('Failed to save comment: $e');
      
      // Remove the local comment since it failed to save
      if (mounted) {
        setState(() {
          _localComments.removeWhere((c) => 
            c.commentId.startsWith('local_') && c.content == text);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  /// Deletes a comment from the post
  Future<void> _deleteComment(String commentId) async {
    try {
      // Remove from local state first for immediate UI feedback
      setState(() {
        _localComments.removeWhere((c) => c.commentId == commentId);
      });

      // Only delete from database if it's a real comment (not a local temporary one)
      if (!commentId.startsWith('local_')) {
        await _postCubit.deleteComment(widget.postId, commentId);
        await _refreshComments();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to delete comment: $e');
    }
  }

  /// Shows an error message to the user
  /// 
  /// Handles dismissing any existing SnackBar before showing a new one
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    // First hide any existing SnackBar
    if (_currentSnackBarController != null) {
      _currentSnackBarController!.close();
      _currentSnackBarController = null;
    }
    
    // Hide any other SnackBars that might be showing
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    // Show the new SnackBar and save its controller
    _currentSnackBarController = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: _whiteColor),
        ),
        backgroundColor: _blackColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        elevation: 4,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: _whiteColor,
          onPressed: () {
            _currentSnackBarController?.close();
            _currentSnackBarController = null;
          },
        ),
      ),
    );
    
    // Clear the controller when the SnackBar is dismissed
    _currentSnackBarController!.closed.then((_) {
      if (mounted) {
        _currentSnackBarController = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDarkMode ? Theme.of(context).scaffoldBackgroundColor : Colors.white;
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(context),
      body: BlocConsumer<PostCubit, PostState>(
        listener: _postStateListener,
        builder: (context, state) {
          final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
          final Color backgroundColor = isDarkMode ? Theme.of(context).scaffoldBackgroundColor : Colors.white;
          return Column(
            children: [
              Expanded(
                child: _buildCommentsList(state),
              ),
              _buildCommentInput(state),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color appBarColor = isDarkMode ? Theme.of(context).colorScheme.surface : Colors.white;
    final Color titleColor = isDarkMode ? Colors.white : Colors.black87;
    final Color iconColor = isDarkMode ? Colors.grey[400]! : Colors.black87;
    return AppBar(
      title: Text(
        'Comments',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          letterSpacing: 0.5,
          color: titleColor,
        ),
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: appBarColor,
      iconTheme: IconThemeData(color: iconColor),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded, 
            size: 18,
            color: iconColor,
          ),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.refresh_rounded,
            size: 20,
            color: iconColor,
          ),
          onPressed: _refreshComments,
        ),
      ],
    );
  }

  /// Builds the comments list with loading indicator
  Widget _buildCommentsList(PostState state) {
    return Stack(
      children: [
        FadeTransition(
          opacity: _fadeAnimation,
          child: _localComments.isEmpty
              ? _buildEmptyCommentsView()
              : ListView.builder(
                  itemCount: _localComments.length,
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final comment = _localComments[index];
                    final bool isOwner = widget.currentUserId == widget.postOwnerId || 
                                       widget.currentUserId == comment.userId;
                    
                    // Add staggered animation for each item
                    return AnimatedOpacity(
                      duration: Duration(milliseconds: 300 + (index * 30)),
                      opacity: 1.0,
                      curve: Curves.easeInOut,
                      child: AnimatedPadding(
                        duration: Duration(milliseconds: 300 + (index * 30)),
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: CommentTile(
                          comment: comment,
                          isCommentOwner: isOwner,
                          onDelete: isOwner 
                              ? () => _deleteComment(comment.commentId)
                              : null,
                          postId: widget.postId,
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (_isLoading || state is PostsLoading)
          Container(
            color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.7),
            child: Center(
              child: CircularProgressIndicator(
                color: _blackColor,
                strokeWidth: 3,
              ),
            ),
          ),
      ],
    );
  }

  /// Builds the empty state view when there are no comments
  Widget _buildEmptyCommentsView() {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    final Color textColor = isDarkMode ? Colors.grey[200]! : Colors.black87;
    final Color subTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final Color iconColor = isDarkMode ? Colors.grey[400]! : Colors.black87;
    final Color circleBg = isDarkMode ? Colors.grey[800]! : Colors.grey[200]!;
    final Color buttonBg = isDarkMode ? Colors.blue[700]! : Colors.black;
    final Color buttonText = Colors.white;

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: circleBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 64,
                color: iconColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No comments yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Be the first to share your thoughts on this post!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: subTextColor,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => FocusScope.of(context).requestFocus(FocusNode()),
              icon: Icon(Icons.add_comment_rounded, color: buttonText),
              label: Text(
                'Add Comment',
                style: TextStyle(color: buttonText),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonBg,
                foregroundColor: buttonText,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the comment input field at the bottom
  Widget _buildCommentInput(PostState state) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDarkMode ? Colors.black : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color hintTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[500]!;
    final Color inputFillColor = isDarkMode ? Color(0xFF1E1E1E) : Colors.grey[100]!;
    final Color borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
    final Color sendButtonBg = const Color.fromARGB(255, 93, 94, 95);
    final Color sendButtonFg = Colors.white;
    final bool isSubmitEnabled = !_isSubmitting && !(state is PostsLoading);
    
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Share your thoughts...',
                  hintStyle: TextStyle(
                    color: hintTextColor,
                    fontSize: 16,
                  ),
                  filled: true,
                  fillColor: inputFillColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide(color: borderColor, width: 0.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide(color: const Color.fromARGB(255, 94, 94, 95), width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide(color: borderColor, width: 0.5),
                  ),
                ),
                style: TextStyle(
                  fontSize: 16,
                  color: textColor,
                ),
                cursorColor: Colors.blueAccent,
                cursorWidth: 2,
              ),
            ),
            const SizedBox(width: 12),
            _buildSendButton(isSubmitEnabled, sendButtonBg, sendButtonFg),
          ],
        ),
      ),
    );
  }

  /// Builds the send button with loading indicator
  Widget _buildSendButton(bool isEnabled, Color buttonColor, Color fgColor) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            buttonColor,
            buttonColor.withBlue(min(buttonColor.blue + 30, 255)),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: buttonColor.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? _addComment : null,
          borderRadius: BorderRadius.circular(24),
          child: Center(
            child: _isSubmitting
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                    ),
                  )
                : Icon(
                    Icons.send_rounded,
                    color: fgColor,
                    size: 24,
                  ),
          ),
        ),
      ),
    );
  }

  /// Listener for post state changes
  void _postStateListener(BuildContext context, PostState state) {
    if (state is PostsLoaded) {
      try {
        // Find the current post and update local comments
        final currentPost = state.posts.firstWhere(
          (post) => post.id == widget.postId,
          orElse: () => throw Exception('Post not found'),
        );
        
        if (mounted) {
          setState(() {
            _localComments = List<Comments>.from(currentPost.comments)
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          });
        }
      } catch (e) {
        _showErrorSnackBar('Error: $e');
      }
    } else if (state is PostsError) {
      _showErrorSnackBar(state.message);
    }
  }

  @override
  void dispose() {
    // Clean up any showing SnackBar when the widget is disposed
    if (_currentSnackBarController != null) {
      _currentSnackBarController!.close();
      _currentSnackBarController = null;
    }
    
    _commentController.dispose();
    _animationController.dispose();
    super.dispose();
  }
} 