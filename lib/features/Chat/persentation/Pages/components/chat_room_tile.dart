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

  @override
  Widget build(BuildContext context) {
    // Get the other participant's info (for 1-on-1 chats)
    final otherParticipant = _getOtherParticipant();
    final unreadCount = widget.chatRoom.unreadCount[widget.currentUserId] ?? 0;
    final hasUnread = unreadCount > 0;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: hasUnread 
                ? Colors.grey[50]
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: hasUnread 
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
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
                    _buildAvatar(otherParticipant),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTitle(context, otherParticipant, hasUnread),
                          const SizedBox(height: 4),
                          _buildSubtitle(context, hasUnread),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildTrailing(context, hasUnread, unreadCount),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String otherParticipantId) {
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
              ),
            ),
            // Online status indicator
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: _isOtherUserOnline ? ChatStyles.onlineColor : ChatStyles.offlineColor,
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Group chat avatar - show the first 2-3 participants in a stacked avatar
      return _buildGroupAvatar();
    }
  }

  Widget _buildGroupAvatar() {
    // Get participants excluding current user
    final otherParticipants = widget.chatRoom.participants
        .where((id) => id != widget.currentUserId)
        .take(3)
        .toList();
    
    // If we have a custom group name, show a single avatar with the group initial
    if (widget.chatRoom.participantNames.containsKey('groupName') && 
        widget.chatRoom.participantNames['groupName']!.isNotEmpty) {
      final groupName = widget.chatRoom.participantNames['groupName']!;
      return Hero(
        tag: 'group_${widget.chatRoom.id}',
        child: Container(
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
            backgroundColor: Colors.grey[200],
            child: Text(
              groupName[0].toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.black,
              ),
            ),
          ),
        ),
      );
    }
    
    // Otherwise, show stacked avatars for the first few participants
    if (otherParticipants.isEmpty) {
      // Fallback if somehow there are no other participants
      return CircleAvatar(
        radius: 28,
        backgroundColor: Colors.grey[200],
        child: const Icon(
          Icons.group,
          color: Colors.black,
          size: 30,
        ),
      );
    }
    
    // Show stacked avatars
    return Container(
      width: 56,
      height: 56,
      child: Stack(
        children: [
          // Main avatar (largest)
          Positioned(
            top: 0,
            left: 0,
            child: _buildParticipantAvatar(
              otherParticipants[0], 
              22,
            ),
          ),
          
          // Second avatar (if available)
          if (otherParticipants.length > 1)
            Positioned(
              bottom: 0,
              right: 0,
              child: _buildParticipantAvatar(
                otherParticipants[1], 
                18,
              ),
            ),
            
          // Count badge for additional participants (if more than 2)
          if (widget.chatRoom.participants.length > 3)
            Positioned(
              bottom: 0,
              left: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    '+${widget.chatRoom.participants.length - 3}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildParticipantAvatar(String participantId, double radius) {
    final avatarUrl = widget.chatRoom.participantAvatars[participantId] ?? '';
    final name = widget.chatRoom.participantNames[participantId] ?? 'User';
    
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[200],
        backgroundImage: avatarUrl.isNotEmpty 
            ? CachedNetworkImageProvider(avatarUrl)
            : null,
        child: avatarUrl.isEmpty 
            ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: radius * 0.7,
                  color: Colors.black,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildTitle(BuildContext context, String otherParticipantId, bool hasUnread) {
    String title = _getChatTitle();
    
    if (widget.chatRoom.participants.length > 3 && !title.contains('+')) {
      title += ' +${widget.chatRoom.participants.length - 3}';
    }

    return Row(
      children: [
        Expanded(
          child: Text(
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
          ),
        ),
        
        // Online status text for 1-on-1 chats
        if (widget.chatRoom.participants.length == 2 && _isOtherUserOnline)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: ChatStyles.onlineColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Online',
                style: TextStyle(
                  fontSize: 12,
                  color: ChatStyles.onlineColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
      ],
    );
  }

  String _getChatTitle() {
    if (widget.chatRoom.participantNames.containsKey('groupName') && 
        widget.chatRoom.participantNames['groupName']!.isNotEmpty) {
      return widget.chatRoom.participantNames['groupName']!;
    }
    
    if (widget.chatRoom.participants.length == 2) {
      final otherParticipantId = _getOtherParticipant();
      return widget.chatRoom.participantNames[otherParticipantId] ?? 'Unknown User';
    } else {
      // Group chat title - combine participant names
      final names = widget.chatRoom.participantNames.entries
          .where((entry) => entry.key != 'groupName' && entry.key != widget.currentUserId && entry.value.isNotEmpty)
          .map((entry) => entry.value)
          .take(3)
          .join(', ');
      return names.isNotEmpty ? names : 'Group Chat';
    }
  }

  Widget _buildSubtitle(BuildContext context, bool hasUnread) {
    String subtitle = widget.chatRoom.lastMessage ?? 'No messages yet';
    
    // Add sender name for group chats
    if (widget.chatRoom.participants.length > 2 && 
        widget.chatRoom.lastMessageSenderId != null &&
        widget.chatRoom.lastMessage != null) {
      final senderName = widget.chatRoom.participantNames[widget.chatRoom.lastMessageSenderId];
      if (senderName != null && senderName.isNotEmpty) {
        subtitle = widget.chatRoom.lastMessageSenderId == widget.currentUserId 
            ? 'You: ${widget.chatRoom.lastMessage}'
            : '$senderName: ${widget.chatRoom.lastMessage}';
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
        if (widget.chatRoom.lastMessageTime != null)
          Text(
            timeago.format(widget.chatRoom.lastMessageTime!),
            style: TextStyle(
              fontSize: 12,
              color: hasUnread 
                  ? Colors.black
                  : Colors.grey[500],
            ),
          ),
        
        const SizedBox(height: 4),
        
        // Unread count badge
        if (hasUnread)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              unreadCount.toString(),
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

  void _showOptionsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
                  color: Colors.grey[300],
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
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.chatRoom.participants.length > 2 
                            ? Icons.group 
                            : Icons.person,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _getChatTitle(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.archive_outlined),
                title: const Text('Archive chat'),
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
                    leading: Icon(isMuted ? Icons.notifications_active_outlined : Icons.notifications_off_outlined),
                    title: Text(isMuted ? 'Unmute notifications' : 'Mute notifications'),
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
                leading: const Icon(Icons.delete_outline, color: ChatStyles.errorColor),
                title: const Text('Delete chat'),
                onTap: () {
                  Navigator.of(context).pop();
                  _confirmDeleteChat(context);
                },
              ),
              if (widget.chatRoom.participants.length > 2)
                ListTile(
                  leading: const Icon(Icons.exit_to_app),
                  title: const Text('Leave group'),
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