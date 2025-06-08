import 'package:flutter/material.dart';
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
      begin: const Offset(-0.1, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    // Stagger the animation based on index
    Future.delayed(Duration(milliseconds: widget.index * 50), () {
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
            setState(() {
              _isOtherUserOnline = userData?['isOnline'] ?? false;
            });
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
      // For group chats, create a name from participant names
      final participantNames = widget.chatRoom.participantNames.values.toList();
      if (participantNames.isEmpty) {
        return "Group Chat";
      } else if (participantNames.length <= 3) {
        return participantNames.join(", ");
      } else {
        // Show first 2 names + count of others
        return "${participantNames.take(2).join(", ")} + ${participantNames.length - 2} others";
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
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isDarkMode
                ? (hasUnread ? Colors.grey[850] : Theme.of(context).colorScheme.surface)
                : (hasUnread ? Colors.grey[50] : Colors.white),
            borderRadius: BorderRadius.circular(12),
            boxShadow: hasUnread 
                ? [
                    BoxShadow(
                      color: isDarkMode 
                          ? Colors.black.withOpacity(0.2)
                          : Colors.black.withOpacity(0.05),
                      offset: const Offset(0, 2),
                      blurRadius: 5,
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: widget.onTap,
              onLongPress: () => _showOptionsDialog(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    _buildAvatar(otherParticipant, isDarkMode),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTitle(context, otherParticipant, hasUnread, isDarkMode),
                          const SizedBox(height: 4),
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
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                backgroundImage: avatarUrl.isNotEmpty 
                    ? CachedNetworkImageProvider(avatarUrl)
                    : null,
                child: avatarUrl.isEmpty 
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        style: TextStyle(
                          fontSize: 18,
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
                  width: 16,
                  height: 16,
                decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDarkMode ? Colors.grey[850]! : Colors.white,
                      width: 2,
                    ),
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
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 28,
          backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
          child: Icon(
            Icons.group,
            size: 24,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
      );
    }
  }

  Widget _buildTitle(BuildContext context, String otherParticipantId, bool hasUnread, bool isDarkMode) {
    String chatName = '';
    
    if (widget.chatRoom.isGroupChat) {
      // For group chats, use the concatenated names of participants
      chatName = widget.chatRoom.participants.length > 2
          ? "Group: ${widget.chatRoom.participantNames.values.join(", ")}"
          : "";
      
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
              fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
              color: isDarkMode 
                  ? (hasUnread ? Colors.white : Colors.grey[300])
                  : (hasUnread ? Colors.black87 : Colors.black54),
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
        fontSize: 14,
              color: isDarkMode
                  ? (hasUnread ? Colors.grey[300] : Colors.grey[500])
                  : (hasUnread ? Colors.black54 : Colors.grey[600]),
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
          Text(
          widget.chatRoom.lastMessageTime != null 
              ? timeago.format(widget.chatRoom.lastMessageTime!)
              : '',
            style: TextStyle(
              fontSize: 12,
            color: isDarkMode
                ? (hasUnread ? Colors.grey[300] : Colors.grey[500])
                : (hasUnread ? Colors.black54 : Colors.grey[500]),
            fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        const SizedBox(height: 4),
        if (hasUnread)
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.blue[700] : Colors.black,
              shape: BoxShape.circle,
            ),
            child: Text(
              unreadCount > 99 ? '99+' : unreadCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  void _showOptionsDialog(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.chatRoom.participants.length > 2 
                            ? Icons.group 
                            : Icons.person,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _getParticipantName(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                leading: Icon(
                  Icons.archive_outlined, 
                  color: isDarkMode ? Colors.white : null
                ),
                title: Text(
                  'Archive chat',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Archive feature coming soon!'),
                      backgroundColor: Colors.black,
                    ),
                  );
                },
              ),
              FutureBuilder<bool>(
                future: ChatNotificationService.isChatMuted(widget.chatRoom.id),
                builder: (context, snapshot) {
                  final isMuted = snapshot.data ?? false;
                  return ListTile(
                    leading: Icon(
                      isMuted ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
                      color: isDarkMode ? Colors.white : null
                    ),
                    title: Text(
                      isMuted ? 'Unmute notifications' : 'Mute notifications',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    onTap: () async {
                      Navigator.of(context).pop();
                      
                      if (isMuted) {
                        // Unmute the chat
                        await ChatNotificationService.unmuteChat(widget.chatRoom.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Notifications unmuted for this chat'),
                              backgroundColor: Colors.black,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      } else {
                        // Mute the chat
                        await ChatNotificationService.muteChat(widget.chatRoom.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Notifications muted for this chat'),
                              backgroundColor: Colors.black,
                              duration: const Duration(seconds: 2),
                              action: SnackBarAction(
                                label: 'UNDO',
                                onPressed: () async {
                                  await ChatNotificationService.unmuteChat(widget.chatRoom.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Notifications unmuted'),
                                        backgroundColor: Colors.black,
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  }
                                },
                                textColor: Colors.white,
                              ),
                            ),
                          );
                        }
                      }
                      
                      // Force widget to rebuild to reflect the updated mute status
                      if (mounted) {
                        setState(() {});
                      }
                    },
                  );
                }
              ),
              const Divider(),
              ListTile(
                leading: Icon(
                  Icons.delete_outline, 
                  color: isDarkMode ? Colors.white : ChatStyles.errorColor
                ),
                title: Text(
                  'Delete chat',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _confirmDeleteChat(context);
                },
              ),
              if (widget.chatRoom.participants.length > 2)
                ListTile(
                  leading: Icon(
                    Icons.exit_to_app,
                    color: isDarkMode ? Colors.white : null
                  ),
                  title: Text(
                    'Leave group',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _confirmLeaveGroup(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteChat(BuildContext context) {
    final bool isGroupChat = widget.chatRoom.participants.length > 2;
    // Safely check if user is admin - handle case where admins list may be null in existing records
    final bool isAdmin = widget.chatRoom.admins.any((adminId) => adminId == widget.currentUserId);
    
    // Keep a reference to cubit to avoid widget deactivation issues
    final chatCubit = context.read<ChatCubit>();
    
    if (isGroupChat) {
      if (isAdmin) {
        // Admin can delete the group chat for everyone
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Group Chat'),
            content: const Text(
              'As an admin, you can either delete this group for everyone or just leave the group. What would you like to do?'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _leaveGroupChat(context);
                },
                child: const Text('Leave Group'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  
                  // Show confirmation for deleting the entire group
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete for Everyone'),
                      content: const Text(
                        'This will delete the group and all messages for all members. This action cannot be undone.'
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            
                            // Run delete animation and delete the chat room
                            _animationController.reverse().then((_) {
                              // Use the stored reference to avoid widget deactivation issues
                              chatCubit.deleteChatRoom(widget.chatRoom.id);
                            });
                          },
                          style: TextButton.styleFrom(foregroundColor: ChatStyles.errorColor),
                          child: const Text('Delete for Everyone'),
                        ),
                      ],
                    ),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: ChatStyles.errorColor),
                child: const Text('Delete for Everyone'),
              ),
            ],
          ),
        );
      } else {
        // Regular members can only leave the group
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Leave Group Chat'),
            content: const Text(
              'You cannot delete the group chat as you are not an admin. Would you like to leave the group instead?'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _leaveGroupChat(context);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.black),
                child: const Text('Leave Group'),
              ),
            ],
          ),
        );
      }
    } else {
      // For one-on-one chats, we just hide the chat for the current user
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Chat'),
          content: const Text(
            'How would you like to delete this chat?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                
                // Run delete animation
                _animationController.reverse().then((_) {
                  // Use the stored reference to avoid widget deactivation issues
                  chatCubit.hideChatForUser(
                    chatRoomId: widget.chatRoom.id,
                    userId: widget.currentUserId,
                  );
                });
              },
              style: TextButton.styleFrom(foregroundColor: Colors.black),
              child: const Text('Hide Chat Only'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                
                // Run delete animation
                _animationController.reverse().then((_) {
                  // Use the stored reference to avoid widget deactivation issues
                  chatCubit.hideChatAndDeleteHistoryForUser(
                    chatRoomId: widget.chatRoom.id,
                    userId: widget.currentUserId,
                  );
                });
              },
              style: TextButton.styleFrom(foregroundColor: ChatStyles.errorColor),
              child: const Text('Delete Chat & History'),
            ),
          ],
        ),
      );
    }
  }

  void _leaveGroupChat(BuildContext context) {
    // Get the user name from the chat room
    final String userName = 
        widget.chatRoom.participantNames[widget.currentUserId] ?? 'A user';
    
    // Keep a reference to cubit to avoid widget deactivation issues
    final chatCubit = context.read<ChatCubit>();
    
    // Run leave animation and leave the group chat
    _animationController.reverse().then((_) {
      chatCubit.leaveGroupChat(
        chatRoomId: widget.chatRoom.id,
        userId: widget.currentUserId,
        userName: userName,
      );
    });
  }

  void _confirmLeaveGroup(BuildContext context) {
    // Keep a reference to cubit to avoid widget deactivation issues
    final chatCubit = context.read<ChatCubit>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text(
          'Are you sure you want to leave this group? You will no longer receive messages from this group.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _leaveGroupChat(context);
            },
            style: TextButton.styleFrom(foregroundColor: ChatStyles.errorColor),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
} 