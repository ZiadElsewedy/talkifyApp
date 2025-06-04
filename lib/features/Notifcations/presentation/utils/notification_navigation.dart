import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Notifcations/Domain/Entite/Notification.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/ProfilePage.dart';
import 'package:talkifyapp/features/Posts/data/firebase_post_repo.dart';
import 'package:talkifyapp/features/Posts/domain/Entite/Posts.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/auth/domain/entities/AppUser.dart';
import 'package:talkifyapp/features/Posts/PostComponents/PostTile..dart';

/// Utility class for navigating to the correct screen based on notification type
class NotificationNavigation {
  static final FirebasePostRepo _postRepo = FirebasePostRepo();
  
  /// Navigate to the appropriate screen based on notification type
  static Future<void> navigateToDestination(
    BuildContext context, 
    NotificationType type,
    String targetId,
    String triggerUserId,
  ) async {
    switch (type) {
      case NotificationType.like:
      case NotificationType.comment:
        await _navigateToPost(context, targetId);
        break;
        
      case NotificationType.reply:
        await _navigateToPost(context, targetId);
        break;
        
      case NotificationType.follow:
        _navigateToProfile(context, triggerUserId);
        break;
      
      // Add more cases for other notification types as needed
      default:
        // Default to profile page of the user who triggered the notification
        _navigateToProfile(context, triggerUserId);
        break;
    }
  }
  
  /// Navigate to a post's detail screen
  static Future<void> _navigateToPost(BuildContext context, String postId) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      // Fetch the post data
      final Post? post = await _postRepo.getPostById(postId);
      
      // Close loading indicator
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      if (post != null) {
        // Get current user
        final currentUser = context.read<AuthCubit>().GetCurrentUser();
        if (currentUser == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You must be logged in to view this post')),
          );
          return;
        }
        
        // Navigate to the post using PostTile which already exists and handles display
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostTile(post: post),
          ),
        );
      } else {
        // Post not found
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post not found or has been deleted')),
        );
      }
    } catch (e) {
      // Close loading indicator if error occurs
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading post: ${e.toString()}')),
      );
    }
  }
  
  /// Navigate to a user's profile page
  static void _navigateToProfile(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(userId: userId),
      ),
    );
  }
} 