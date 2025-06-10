import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:talkifyapp/features/Chat/domain/entite/chat_room.dart';
import 'package:talkifyapp/features/Chat/persentation/Cubits/chat_cubit.dart';
import 'package:talkifyapp/features/Chat/Utils/chat_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:talkifyapp/features/Chat/service/chat_notification_service.dart';

class ChatRoomTile extends StatefulWidget {
  final ChatRoom chatRoom;
  final String currentUserId;
  final VoidCallback onTap;
  final int index;

  const ChatRoomTile({
    super.key,
    required this.chatRoom,
    required this.currentUserId,
    required this.onTap,
    required this.index,
  });

  @override
  State<ChatRoomTile> createState() => _ChatRoomTileState();
}

class _ChatRoomTileState extends State<ChatRoomTile> with SingleTickerProviderStateMixin {
  bool _isOtherUserOnline = false;
  Stream<DocumentSnapshot>? _userStatusStream;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupUserStatusListener();
    
    // Set up animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.05, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    // Stagger the animation based on index
    Future.delayed(Duration(milliseconds: widget.index * 30), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setupUserStatusListener() {
    // Only set up listener for 1-on-1 chats
    if (widget.chatRoom.participants.length == 2) {
      final otherParticipantId = _getOtherParticipant();
      if (otherParticipantId.isNotEmpty) {
        _userStatusStream = FirebaseFirestore.instance
            .collection('users')
            .doc(otherParticipantId)
            .snapshots();
            
        _userStatusStream!.listen((snapshot) {
          if (snapshot.exists && mounted) {
            final userData = snapshot.data() as Map<String, dynamic>?;
            final isOnline = userData?['isOnline'] ?? false;
            
            // Fix: Use post-frame callback to avoid build during layout
            if (_isOtherUserOnline != isOnline) {
              SchedulerBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
            setState(() {
                    _isOtherUserOnline = isOnline;
                  });
                }
            });
            }
          }
        });
      }
    }
  }

  String _getOtherParticipant() {
    // For 1-on-1 chats, get the other participant
    if (widget.chatRoom.participants.length == 2) {
      return widget.chatRoom.participants.firstWhere(
        (id) => id != widget.currentUserId,
        orElse: () => widget.chatRoom.participants.first,
      );
    }
    // For group chats, return empty string (we'll handle differently)
    return '';
  }
  
  String _getParticipantName() {
    if (widget.chatRoom.isGroupChat) {
      // For group chats, check if there's a dedicated group name first
      if (widget.chatRoom.participantNames.containsKey('groupName') && 
          widget.chatRoom.participantNames['groupName']!.isNotEmpty) {
        return widget.chatRoom.participantNames['groupName']!;
      } else {
        // Fallback to generic group chat name
        return "Group Chat";
      }
    } else {
      // For 1-on-1 chats, get the other participant's name
      final otherParticipantId = _getOtherParticipant();
      if (otherParticipantId.isNotEmpty) {
        return widget.chatRoom.participantNames[otherParticipantId] ?? 'User';
      }
    }
    return 'Chat';
  }

  @override
  Widget build(BuildContext context) {
    // Skip rendering this tile if it's a community chat room
    if (widget.chatRoom.communityId != null) {
      return const SizedBox.shrink(); // Don't render community chats in the main chat list
    }
    
    // Get the other participant's info (for 1-on-1 chats)
    final otherParticipant = _getOtherParticipant();
    final unreadCount = widget.chatRoom.unreadCount[widget.currentUserId] ?? 0;
    final hasUnread = unreadCount > 0;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: widget.onTap,
              onLongPress: () => _showOptionsDialog(context),
              splashColor: isDarkMode 
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.06),
              highlightColor: isDarkMode 
                ? Colors.white.withOpacity(0.03)
                : Colors.black.withOpacity(0.03),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                child: Row(
                  children: [
                    _buildAvatar(otherParticipant, isDarkMode),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTitle(context, otherParticipant, hasUnread, isDarkMode),
                          const SizedBox(height: 2),
                          _buildSubtitle(context, hasUnread, isDarkMode),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildTrailing(context, hasUnread, unreadCount, isDarkMode),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String otherParticipantId, bool isDarkMode) {
    if (widget.chatRoom.participants.length == 2) {
      // 1-on-1 chat avatar with online status indicator
      final avatarUrl = widget.chatRoom.participantAvatars[otherParticipantId] ?? '';
      final name = widget.chatRoom.participantNames[otherParticipantId] ?? 'User';
      
      return Hero(
        tag: 'avatar_${widget.chatRoom.id}',
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withOpacity(0.2)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFF7F7F7),
                backgroundImage: avatarUrl.isNotEmpty 
                    ? CachedNetworkImageProvider(avatarUrl)
                    : null,
                child: avatarUrl.isEmpty 
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      )
                    : null,
              ),
            ),
            
            // Online status indicator
            if (_isOtherUserOnline)
            Positioned(
                right: 0,
              bottom: 0,
              child: Container(
                  width: 14,
                  height: 14,
                decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDarkMode ? const Color(0xFF121212) : Colors.white,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                    ),
                    ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Group chat avatar
      return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 28,
            backgroundColor: isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFF7F7F7),
            backgroundImage: widget.chatRoom.participantAvatars.containsKey('groupAvatar') && 
                            widget.chatRoom.participantAvatars['groupAvatar']!.isNotEmpty 
                ? CachedNetworkImageProvider(widget.chatRoom.participantAvatars['groupAvatar']!)
                : null,
            child: (widget.chatRoom.participantAvatars['groupAvatar'] == null ||
                    widget.chatRoom.participantAvatars['groupAvatar']!.isEmpty)
                  ? Icon(
                      Icons.group,
                      size: 20,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    )
                  : null,
          ),
      );
    }
  }

  Widget _buildTitle(BuildContext context, String otherParticipantId, bool hasUnread, bool isDarkMode) {
    String chatName = '';
    
    if (widget.chatRoom.isGroupChat) {
      // For group chats, check if there's a dedicated group name first
      if (widget.chatRoom.participantNames.containsKey('groupName') && 
          widget.chatRoom.participantNames['groupName']!.isNotEmpty) {
        chatName = widget.chatRoom.participantNames['groupName']!;
      } else {
        // Fallback to participants list if no group name is set
        chatName = "Group Chat";
      }
      
      // Limit the length
      if (chatName.length > 30) {
        chatName = chatName.substring(0, 27) + "...";
      }
    } else {
      // For 1-on-1 chats, show the other participant's name
      chatName = widget.chatRoom.participantNames[otherParticipantId] ?? 'User';
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            chatName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
              letterSpacing: 0.1,
              color: isDarkMode 
                  ? (hasUnread ? Colors.white : const Color(0xFFE0E0E0))
                  : (hasUnread ? Colors.black : const Color(0xFF303030)),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          ),
      ],
    );
  }

  Widget _buildSubtitle(BuildContext context, bool hasUnread, bool isDarkMode) {
    final lastMessage = widget.chatRoom.lastMessage ?? '';
    final lastMessageSenderId = widget.chatRoom.lastMessageSenderId ?? '';
    
    // Handle special cases for the last message display
    String displayText = '';
    
    if (lastMessage.isEmpty) {
      displayText = 'Start chatting';
    } else if (lastMessage.startsWith('📷')) {
      displayText = '📷 Photo';
    } else if (lastMessage.startsWith('🎵')) {
      displayText = '🎵 Voice message';
    } else if (lastMessage.startsWith('📄')) {
      displayText = '📄 Shared a post';
    } else {
      // Regular text message
      if (lastMessageSenderId == widget.currentUserId) {
        displayText = 'You: $lastMessage';
      } else {
        displayText = lastMessage;
      }
    }
    
    return Row(
      children: [
        Expanded(
          child: Text(
            displayText,
      style: TextStyle(
              fontSize: 13,
              color: isDarkMode
                  ? (hasUnread ? const Color(0xFFBDBDBD) : const Color(0xFF757575))
                  : (hasUnread ? const Color(0xFF505050) : const Color(0xFF757575)),
        fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTrailing(BuildContext context, bool hasUnread, int unreadCount, bool isDarkMode) {
    final lastMessageTime = widget.chatRoom.lastMessageTime;
    final String timeText = lastMessageTime != null
        ? _formatTime(lastMessageTime)
        : '';
            
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
          Text(
          timeText,
            style: TextStyle(
            fontSize: 11,
            color: isDarkMode
                ? (hasUnread ? const Color(0xFFBDBDBD) : const Color(0xFF757575))
                : (hasUnread ? const Color(0xFF505050) : const Color(0xFF757575)),
            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        const SizedBox(height: 4),
        if (hasUnread)
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white : const Color(0xFF000000),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isDarkMode
                      ? Colors.black.withOpacity(0.2)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              unreadCount > 99 ? '99+' : unreadCount.toString(),
              style: TextStyle(
                color: isDarkMode ? Colors.black : Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  // Helper method to format timestamp in a more human-readable way
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    
    if (diff.inDays >= 7) {
      // More than a week ago - show date
      return '${dateTime.day}/${dateTime.month}';
    } else if (diff.inDays >= 1) {
      // Days ago
      if (diff.inDays == 1) {
        return 'Yesterday';
      } else {
        return '${diff.inDays} days ago';
      }
    } else if (diff.inHours >= 1) {
      // Hours ago
      return '${diff.inHours} ${diff.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (diff.inMinutes >= 1) {
      // Minutes ago
      return '${diff.inMinutes} ${diff.inMinutes == 1 ? 'min' : 'mins'} ago';
    } else {
      // Just now
      return 'Just now';
    }
  }

  void _showOptionsDialog(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            _buildOptionTile(
              context,
              icon: Icons.visibility_off,
              title: 'Hide chat',
                onTap: () {
                Navigator.pop(context);
                // Hide chat functionality
              },
              isDarkMode: isDarkMode,
                      ),
            _buildOptionTile(
              context,
              icon: Icons.delete_outline,
              title: 'Delete chat',
                onTap: () {
                Navigator.pop(context);
                // Delete chat functionality
              },
              isDarkMode: isDarkMode,
              isDestructive: true,
                    ),
            const SizedBox(height: 12),
            ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDarkMode,
    bool isDestructive = false,
  }) {
    final Color textColor = isDestructive
        ? Colors.red
        : (isDarkMode ? Colors.white : Colors.black);
        
    return ListTile(
      leading: Icon(
        icon,
        color: textColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
} 