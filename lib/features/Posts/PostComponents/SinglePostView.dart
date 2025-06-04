import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Posts/domain/Entite/Posts.dart';
import 'package:talkifyapp/features/Posts/presentation/cubits/post_cubit.dart';
import 'package:talkifyapp/features/Posts/PostComponents/PostTile..dart';
import 'package:talkifyapp/features/Posts/PostComponents/SafePostTile.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/auth/domain/entities/AppUser.dart';

class SinglePostView extends StatefulWidget {
  final String postId;

  const SinglePostView({
    Key? key, 
    required this.postId,
  }) : super(key: key);

  @override
  State<SinglePostView> createState() => _SinglePostViewState();
}

class _SinglePostViewState extends State<SinglePostView> {
  bool _isLoading = true;
  Post? _post;
  String? _error;
  AppUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadPost();
    _getCurrentUser();
  }

  void _getCurrentUser() {
    final authCubit = context.read<AuthCubit>();
    _currentUser = authCubit.GetCurrentUser();
  }

  Future<void> _loadPost() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      final postCubit = context.read<PostCubit>();
      final post = await postCubit.getPostById(widget.postId);
      
      if (mounted) {
        // Check if post is actually returned (could be null if post was deleted or not found)
        if (post == null) {
          setState(() {
            _post = null;
            _error = 'Post not found or may have been deleted';
            _isLoading = false;
          });
          return;
        }
        
        // Verify that important post properties are not null
        if (post.UserId == null || post.UserName == null) {
          setState(() {
            _post = null;
            _error = 'Post data is incomplete';
            _isLoading = false;
          });
          return;
        }
        
        setState(() {
          _post = post;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading post: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load post: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Post',
          style: TextStyle(color: Colors.black),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _post != null
                  ? _buildPostContent()
                  : _buildEmptyState(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.black),
          SizedBox(height: 16),
          Text('Loading post...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              _error ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.post_add, size: 60, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Post not found',
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostContent() {
    // Check if post is actually not null before rendering
    if (_post == null) {
      return _buildEmptyState();
    }
    
    try {
      return SingleChildScrollView(
        child: Column(
          children: [
            // Use SafePostTile instead of PostTile for better error handling
            SafePostTile(
              post: _post!,
              onDelete: () {
                Navigator.pop(context, true); // Return true to indicate deletion
              },
            ),
            // Add some padding at the bottom
            SizedBox(height: 40),
          ],
        ),
      );
    } catch (e) {
      // If any error occurs while rendering the post (e.g., null properties in the post),
      // show error view instead of crashing
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Error displaying post: ${e.toString()}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
  }
} 