import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Notifcations/Domain/Entite/Notification.dart';
import 'package:talkifyapp/features/Notifcations/Domain/Entite/chat_notification.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/ProfilePage.dart';
import 'package:talkifyapp/features/Posts/data/firebase_post_repo.dart';
import 'package:talkifyapp/features/Posts/domain/Entite/Posts.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/auth/domain/entities/AppUser.dart';
import 'package:talkifyapp/features/Posts/PostComponents/SinglePostView.dart';
import 'package:talkifyapp/features/Chat/domain/repo/chat_repo.dart';
import 'package:talkifyapp/features/Chat/Data/firebase_chat_repo.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/chat_room_page.dart';

/// Utility class for navigating to the correct screen based on notification type
class NotificationNavigation {
  static final FirebasePostRepo _postRepo = FirebasePostRepo();
  static final ChatRepo _chatRepo = FirebaseChatRepo();
  
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
      
      case NotificationType.message:
        await _navigateToChat(context, targetId);
        break;
      
      case NotificationType.mention:
        // If it's a mention in a chat, navigate to the chat
        if (targetId.startsWith('chat_')) {
          await _navigateToChat(context, targetId.substring(5));
        } else {
          // Otherwise, treat it as a mention in a post
          await _navigateToPost(context, targetId);
        }
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
      // Navigate directly to SinglePostView which handles loading and error states internally
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SinglePostView(postId: postId),
        ),
      );
    } catch (e) {
      // Show error message if navigation fails
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
  
  /// Navigate to a chat room
  static Future<void> _navigateToChat(BuildContext context, String chatRoomId) async {
    try {
      // Get the chat room from the repository
      final chatRoom = await _chatRepo.getChatRoom(chatRoomId);
      
      if (chatRoom == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat not found or was deleted')),
        );
        return;
      }
      
      // Navigate to the chat room page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatRoomPage(chatRoom: chatRoom),
        ),
      );
    } catch (e) {
      // Show error message if navigation fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening chat: ${e.toString()}')),
      );
    }
  }
  
  /// Navigate based on chat notification
  static Future<void> navigateFromChatNotification(
    BuildContext context,
    ChatNotification notification,
  ) async {
    await _navigateToChat(context, notification.chatRoomId);
  }
} 