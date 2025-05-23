import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:talkifyapp/features/Chat/domain/entite/chat_room.dart';

class ChatRoomTile extends StatelessWidget {
  final ChatRoom chatRoom;
  final String currentUserId;
  final VoidCallback onTap;

  const ChatRoomTile({
    super.key,
    required this.chatRoom,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Get the other participant's info (for 1-on-1 chats)
    final otherParticipant = _getOtherParticipant();
    final unreadCount = chatRoom.unreadCount[currentUserId] ?? 0;
    final hasUnread = unreadCount > 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 0,
      color: hasUnread 
          ? Colors.grey[50]
          : Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildAvatar(otherParticipant),
        title: _buildTitle(context, otherParticipant, hasUnread),
        subtitle: _buildSubtitle(context, hasUnread),
        trailing: _buildTrailing(context, hasUnread, unreadCount),
        onTap: onTap,
      ),
    );
  }

  String _getOtherParticipant() {
    // For 1-on-1 chats, get the other participant
    if (chatRoom.participants.length == 2) {
      return chatRoom.participants.firstWhere(
        (id) => id != currentUserId,
        orElse: () => chatRoom.participants.first,
      );
    }
    // For group chats, return empty string (we'll handle differently)
    return '';
  }

  Widget _buildAvatar(String otherParticipantId) {
    if (chatRoom.participants.length == 2) {
      // 1-on-1 chat avatar
      final avatarUrl = chatRoom.participantAvatars[otherParticipantId] ?? '';
      final name = chatRoom.participantNames[otherParticipantId] ?? 'User';
      
      return CircleAvatar(
        radius: 28,
        backgroundColor: Colors.grey[200],
        backgroundImage: avatarUrl.isNotEmpty 
            ? CachedNetworkImageProvider(avatarUrl)
            : null,
        child: avatarUrl.isEmpty 
            ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black,
                ),
              )
            : null,
      );
    } else {
      // Group chat avatar
      return CircleAvatar(
        radius: 28,
        backgroundColor: Colors.grey[200],
        child: Icon(
          Icons.group,
          color: Colors.black,
          size: 30,
        ),
      );
    }
  }

  Widget _buildTitle(BuildContext context, String otherParticipantId, bool hasUnread) {
    String title;
    
    if (chatRoom.participants.length == 2) {
      title = chatRoom.participantNames[otherParticipantId] ?? 'Unknown User';
    } else {
      // Group chat title - combine participant names
      final names = chatRoom.participantNames.values
          .where((name) => name.isNotEmpty)
          .take(3)
          .join(', ');
      title = names.isNotEmpty ? names : 'Group Chat';
      
      if (chatRoom.participantNames.length > 3) {
        title += ' +${chatRoom.participantNames.length - 3}';
      }
    }

    return Text(
      title,
      style: TextStyle(
        fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
        fontSize: 16,
        color: hasUnread 
            ? Colors.black
            : Colors.black87,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSubtitle(BuildContext context, bool hasUnread) {
    String subtitle = chatRoom.lastMessage ?? 'No messages yet';
    
    // Add sender name for group chats
    if (chatRoom.participants.length > 2 && 
        chatRoom.lastMessageSenderId != null &&
        chatRoom.lastMessage != null) {
      final senderName = chatRoom.participantNames[chatRoom.lastMessageSenderId];
      if (senderName != null && senderName.isNotEmpty) {
        subtitle = chatRoom.lastMessageSenderId == currentUserId 
            ? 'You: ${chatRoom.lastMessage}'
            : '$senderName: ${chatRoom.lastMessage}';
      }
    }

    return Text(
      subtitle,
      style: TextStyle(
        fontSize: 14,
        fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
        color: hasUnread 
            ? Colors.black87
            : Colors.grey[600],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTrailing(BuildContext context, bool hasUnread, int unreadCount) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Timestamp
        if (chatRoom.lastMessageTime != null)
          Text(
            timeago.format(chatRoom.lastMessageTime!),
            style: TextStyle(
              fontSize: 12,
              color: hasUnread 
                  ? Colors.black
                  : Colors.grey[500],
              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        
        const SizedBox(height: 4),
        
        // Unread count badge
        if (hasUnread)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              unreadCount > 99 ? '99+' : unreadCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
} 