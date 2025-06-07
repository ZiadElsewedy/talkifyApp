import 'package:flutter/material.dart';
import 'package:talkifyapp/features/Posts/PostComponents/PostTile..dart';
import 'package:talkifyapp/features/Posts/domain/Entite/Posts.dart';

class SafePostTile extends StatelessWidget {
  final Post post;
  final VoidCallback? onDelete;
  
  const SafePostTile({
    Key? key,
    required this.post,
    this.onDelete,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    try {
      // Check for null or empty required properties
      if (post.id.isEmpty || post.UserId == null || post.UserName == null) {
        return _buildErrorTile(context, 'Post data is incomplete');
      }
      
      // If all required properties are present, render the actual PostTile
      return PostTile(
        post: post,
        onDelete: onDelete,
      );
    } catch (e) {
      // If any exception occurs while rendering, show error view
      return _buildErrorTile(context, 'Error: $e');
    }
  }
  
  Widget _buildErrorTile(BuildContext context, String message) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red[300],
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to display this post',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
} 