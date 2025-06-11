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
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          decoration: BoxDecoration(
            color: hasUnread 
              ? (isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF8F9FA))
              : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: hasUnread 
              ? Border.all(
                  color: isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFE5E7EB),
                  width: 1,
                )
              : null,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: widget.onTap,
              onLongPress: () => _showOptionsDialog(context),
              splashColor: isDarkMode 
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.08),
              highlightColor: isDarkMode 
                ? Colors.white.withOpacity(0.04)
                : Colors.black.withOpacity(0.04),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    _buildAvatar(otherParticipant, isDarkMode),
                    const SizedBox(width: 16),
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
                    const SizedBox(width: 12),
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
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFf1f3f4),
                backgroundImage: avatarUrl.isNotEmpty 
                    ? CachedNetworkImageProvider(avatarUrl)
                    : null,
                child: avatarUrl.isEmpty 
                    ? Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              isDarkMode ? const Color(0xFF4A5568) : const Color(0xFF6B73FF),
                              isDarkMode ? const Color(0xFF2D3748) : const Color(0xFF9F7AEA),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
            ),
            
            // Online status indicator with modern design
            if (_isOtherUserOnline)
            Positioned(
                right: 2,
              bottom: 2,
              child: Container(
                  width: 16,
                  height: 16,
                decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDarkMode ? const Color(0xFF121212) : Colors.white,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                        blurRadius: 4,
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
      // Group chat avatar with modern design
      return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 30,
            backgroundColor: isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFf1f3f4),
            backgroundImage: widget.chatRoom.participantAvatars.containsKey('groupAvatar') && 
                            widget.chatRoom.participantAvatars['groupAvatar']!.isNotEmpty 
                ? CachedNetworkImageProvider(widget.chatRoom.participantAvatars['groupAvatar']!)
                : null,
            child: (widget.chatRoom.participantAvatars['groupAvatar'] == null ||
                    widget.chatRoom.participantAvatars['groupAvatar']!.isEmpty)
                  ? Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            isDarkMode ? const Color(0xFF4A5568) : const Color(0xFF8B5CF6),
                            isDarkMode ? const Color(0xFF2D3748) : const Color(0xFF06B6D4),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.group_rounded,
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
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
              fontSize: 17,
              fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
              letterSpacing: -0.2,
              height: 1.2,
              color: isDarkMode 
                  ? (hasUnread ? Colors.white : const Color(0xFFE8E8E8))
                  : (hasUnread ? const Color(0xFF1F2937) : const Color(0xFF374151)),
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
                  ? (hasUnread ? const Color(0xFFB0BEC5) : const Color(0xFF78909C))
                  : (hasUnread ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
        fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
              height: 1.3,
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
            fontSize: 12,
              fontWeight: FontWeight.w500,
            color: isDarkMode
                ? (hasUnread ? const Color(0xFFB0BEC5) : const Color(0xFF78909C))
                : (hasUnread ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
            ),
          ),
        const SizedBox(height: 6),
        if (hasUnread)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode 
                  ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                  : [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: (isDarkMode ? const Color(0xFF6366F1) : const Color(0xFF3B82F6)).withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
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
    final bool isGroupChat = widget.chatRoom.isGroupChat;
    final bool isAdmin = isGroupChat && widget.chatRoom.admins.contains(widget.currentUserId);
    
    // Check if user is the creator (first admin or first participant)
    final bool isCreator = isGroupChat && (
      (widget.chatRoom.admins.isNotEmpty && widget.chatRoom.admins[0] == widget.currentUserId) ||
      (widget.chatRoom.admins.isEmpty && widget.chatRoom.participants[0] == widget.currentUserId)
    );
    
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
              // Different options based on chat type
              if (isGroupChat) ...[
                // Group chat options
                if (isAdmin) ...[
                  // Admin options
                  _buildOptionTile(
                    context,
                    icon: Icons.edit,
                    title: 'Edit group',
                    onTap: () {
                      Navigator.pop(context);
                      // Show a dialog to edit the group name
                      _showEditGroupDialog();
                    },
                    isDarkMode: isDarkMode,
                  ),
                ],
                _buildOptionTile(
                  context,
                  icon: Icons.exit_to_app,
                  title: 'Leave group',
                  onTap: () {
                    Navigator.pop(context);
                    _showLeaveGroupConfirmation();
                  },
                  isDarkMode: isDarkMode,
                ),
                if (isCreator) ...[
                  // Only creator can delete the group for everyone
                  _buildOptionTile(
                    context,
                    icon: Icons.delete_outline,
                    title: 'Delete group for everyone',
                    onTap: () {
                      Navigator.pop(context);
                      _showDeleteForEveryoneConfirmation();
                    },
                    isDarkMode: isDarkMode,
                    isDestructive: true,
                  ),
                ],
                // Everyone can delete the group chat for themselves
                _buildOptionTile(
                  context,
                  icon: Icons.visibility_off,
                  title: 'Delete for me',
                  onTap: () {
                    Navigator.pop(context);
                    _hideChatAndDeleteHistory();
                  },
                  isDarkMode: isDarkMode,
                ),
              ] else ...[
                // Regular chat options
                _buildOptionTile(
                  context,
                  icon: Icons.visibility_off,
                  title: 'Hide chat',
                  onTap: () {
                    Navigator.pop(context);
                    _hideChatForUser();
                  },
                  isDarkMode: isDarkMode,
                ),
                _buildOptionTile(
                  context,
                  icon: Icons.delete_outline,
                  title: 'Delete chat for me',
                  onTap: () {
                    Navigator.pop(context);
                    _hideChatAndDeleteHistory();
                  },
                  isDarkMode: isDarkMode,
                  isDestructive: true,
                ),
              ],
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

  void _hideChatForUser() {
    final chatCubit = context.read<ChatCubit>();
    
    chatCubit.hideChatForUser(
      chatRoomId: widget.chatRoom.id,
      userId: widget.currentUserId,
    ).then((_) {
      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chat hidden successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    }).catchError((error) {
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to hide chat: $error'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  void _showDeleteForEveryoneConfirmation() {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          'Delete Group',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will permanently delete the group and all messages for EVERYONE.',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                color: isDarkMode ? Colors.red[400] : Colors.red[700],
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: isDarkMode ? Colors.grey[300] : Colors.grey[800],
            ),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteGroupForEveryone();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete For Everyone'),
          ),
        ],
      ),
    );
  }
  
  void _deleteGroupForEveryone() {
    final chatCubit = context.read<ChatCubit>();
    
    // Directly delete the chat room without showing a local loading dialog
    // The chat_list_page will handle the loading state with its BlocConsumer
    chatCubit.deleteChatRoom(widget.chatRoom.id);
  }

  void _hideChatAndDeleteHistory() {
    final chatCubit = context.read<ChatCubit>();
    
    // Directly delete the chat history without showing a local loading dialog
    // The chat_list_page will handle the loading state with its BlocConsumer
    chatCubit.hideChatAndDeleteHistoryForUser(
      chatRoomId: widget.chatRoom.id,
      userId: widget.currentUserId,
    );
  }

  void _showLeaveGroupConfirmation() {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          'Leave Group',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to leave this group chat?',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: isDarkMode ? Colors.grey[300] : Colors.grey[800],
            ),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _leaveGroupChat();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange,
            ),
            child: const Text('Leave Group'),
          ),
        ],
      ),
    );
  }
  
  void _leaveGroupChat() {
    final chatCubit = context.read<ChatCubit>();
    final String userName = widget.chatRoom.participantNames[widget.currentUserId] ?? 'User';
    
    // Directly leave the group chat without showing a local loading dialog
    // The chat_list_page will handle the loading state with its BlocConsumer
    chatCubit.leaveGroupChat(
      chatRoomId: widget.chatRoom.id,
      userId: widget.currentUserId,
      userName: userName,
    );
  }

  // Add this method to show a dialog for editing the group
  void _showEditGroupDialog() {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final TextEditingController _groupNameController = TextEditingController(
      text: widget.chatRoom.participantNames['groupName'] ?? '',
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          'Edit Group',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _groupNameController,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                labelText: 'Group Name',
                labelStyle: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: isDarkMode ? Colors.grey[300] : Colors.grey[800],
            ),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Get the updated group name
              final String newGroupName = _groupNameController.text.trim();
              if (newGroupName.isNotEmpty) {
                // Close the dialog
                Navigator.pop(context);
                
                // Update the group name
                _updateGroupName(newGroupName);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: isDarkMode ? Colors.white : Colors.black,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  void _updateGroupName(String groupName) {
    final chatCubit = context.read<ChatCubit>();
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    chatCubit.updateChatRoomMetadata(
      chatRoomId: widget.chatRoom.id,
      metadata: {'groupName': groupName},
    ).then((_) {
      // Always check if mounted before using context
      if (!mounted) return;
      
      // Close loading indicator
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group name updated successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    }).catchError((error) {
      // Always check if mounted before using context
      if (!mounted) return;
      
      // Close loading indicator
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update group name: $error'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    });
  }
} 