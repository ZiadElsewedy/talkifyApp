import 'package:talkifyapp/features/Chat/domain/entite/message.dart';
import 'package:talkifyapp/features/Chat/domain/entite/chat_room.dart';

/// Utility class to detect and handle user mentions in chat messages
class MentionDetector {
  /// Extract mentioned user IDs from a message
  /// 
  /// Format for mentions: @[userId:displayName]
  /// Example: "Hello @[user123:John Doe], how are you?"
  static List<String> extractMentionedUserIds(String messageContent) {
    final List<String> mentionedIds = [];
    
    // RegExp to match @[userId:displayName] format
    final RegExp mentionRegex = RegExp(r'@\[([^:]+):[^\]]+\]');
    
    // Find all matches in the message content
    final matches = mentionRegex.allMatches(messageContent);
    
    // Extract the user IDs from the matches
    for (var match in matches) {
      if (match.groupCount >= 1) {
        final userId = match.group(1);
        if (userId != null && userId.isNotEmpty) {
          mentionedIds.add(userId);
        }
      }
    }
    
    return mentionedIds;
  }
  
  /// Format display text for mentions in a message
  /// 
  /// Converts @[userId:displayName] to @displayName for display
  static String formatMessageWithMentions(String messageContent) {
    // RegExp to match @[userId:displayName] format
    final RegExp mentionRegex = RegExp(r'@\[([^:]+):([^\]]+)\]');
    
    // Replace matches with @displayName format
    return messageContent.replaceAllMapped(mentionRegex, (match) {
      if (match.groupCount >= 2) {
        final displayName = match.group(2);
        return '@$displayName';
      }
      return match.group(0) ?? '';
    });
  }
  
  /// Format user mention for storing in the message content
  /// 
  /// Creates the @[userId:displayName] format from user info
  static String formatUserMention(String userId, String displayName) {
    return '@[$userId:$displayName]';
  }
  
  /// Process a message and trigger notifications for mentioned users
  static Future<void> processMentionsAndNotify({
    required Message message,
    required ChatRoom chatRoom,
    required Function(Message, ChatRoom, String) notifyMentionedUser,
  }) async {
    // Extract mentioned user IDs from the message
    final mentionedUserIds = extractMentionedUserIds(message.content);
    
    // Send notifications to each mentioned user
    for (final userId in mentionedUserIds) {
      // Skip if the mentioned user is the sender
      if (userId == message.senderId) continue;
      
      // Skip if the user is not a participant in the chat
      if (!chatRoom.participants.contains(userId)) continue;
      
      // Skip if the user has left the chat
      if (chatRoom.leftParticipants[userId] == true) continue;
      
      // Notify the mentioned user
      await notifyMentionedUser(message, chatRoom, userId);
    }
  }
} 