import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:talkifyapp/features/Chat/domain/entite/message.dart';
import 'package:talkifyapp/features/Chat/domain/entite/chat_room.dart';
import 'package:talkifyapp/features/Chat/persentation/Cubits/chat_cubit.dart';
import 'package:talkifyapp/features/Chat/persentation/Cubits/chat_states.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/components/animated_message_bubble.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/components/animated_typing_indicator.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/components/WhiteCircleIndicator.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/user_profile_page.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/group_info_page.dart';
import 'package:talkifyapp/features/Chat/Utils/chat_styles.dart';
import 'package:talkifyapp/features/Chat/Utils/page_transitions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatRoomPage extends StatefulWidget {
  final ChatRoom chatRoom;

  const ChatRoomPage({
    super.key,
    required this.chatRoom,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _fadeInController;
  bool _isTyping = false;
  final List<Message> _messages = [];
  bool _otherUserIsOnline = false;
  Stream<DocumentSnapshot>? _userStatusStream;

  @override
  void initState() {
    super.initState();
    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeInController.forward();
    
    _loadMessages();
    _markMessagesAsRead();
    _messageController.addListener(_onTyping);
    _setupUserStatusListener();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _fadeInController.dispose();
    super.dispose();
  }

  void _setupUserStatusListener() {
    final currentUser = context.read<AuthCubit>().GetCurrentUser();
    if (currentUser != null && widget.chatRoom.participants.length == 2) {
      final otherParticipantId = widget.chatRoom.participants.firstWhere(
        (id) => id != currentUser.id,
        orElse: () => '',
      );
      
      if (otherParticipantId.isNotEmpty) {
        _userStatusStream = FirebaseFirestore.instance
            .collection('users')
            .doc(otherParticipantId)
            .snapshots();
            
        _userStatusStream!.listen((snapshot) {
          if (snapshot.exists && mounted) {
            final userData = snapshot.data() as Map<String, dynamic>?;
            setState(() {
              _otherUserIsOnline = userData?['isOnline'] ?? false;
            });
          }
        });
      }
    }
  }

  void _loadMessages() {
    context.read<ChatCubit>().loadChatMessages(widget.chatRoom.id);
  }

  void _markMessagesAsRead() {
    final currentUser = context.read<AuthCubit>().GetCurrentUser();
    if (currentUser != null) {
      context.read<ChatCubit>().markMessagesAsRead(
        chatRoomId: widget.chatRoom.id,
        userId: currentUser.id,
      );
    }
  }

  void _onTyping() {
    final currentUser = context.read<AuthCubit>().GetCurrentUser();
    if (currentUser != null) {
      final isCurrentlyTyping = _messageController.text.trim().isNotEmpty;
      
      if (isCurrentlyTyping != _isTyping) {
        setState(() {
          _isTyping = isCurrentlyTyping;
        });
        
        context.read<ChatCubit>().setTypingStatus(
          chatRoomId: widget.chatRoom.id,
          userId: currentUser.id,
          isTyping: isCurrentlyTyping,
        );
      }
    }
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final currentUser = context.read<AuthCubit>().GetCurrentUser();
    if (currentUser == null) return;

    context.read<ChatCubit>().sendTextMessage(
      chatRoomId: widget.chatRoom.id,
      senderId: currentUser.id,
      senderName: currentUser.name,
      senderAvatar: currentUser.profilePictureUrl,
      content: content,
    );

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollToBottomOnLoad() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    }
  }

  void _scrollToBottomOnNewMessages() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _pickAndSendFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        final currentUser = context.read<AuthCubit>().GetCurrentUser();
        
        if (currentUser == null) return;

        // Determine message type based on file extension
        MessageType messageType = MessageType.file;
        if (file.extension != null) {
          final extension = file.extension!.toLowerCase();
          if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
            messageType = MessageType.image;
          } else if (['mp4', 'mov', 'avi', 'mkv'].contains(extension)) {
            messageType = MessageType.video;
          } else if (['mp3', 'wav', 'aac', 'm4a'].contains(extension)) {
            messageType = MessageType.audio;
          }
        }

        context.read<ChatCubit>().sendMediaMessage(
          chatRoomId: widget.chatRoom.id,
          senderId: currentUser.id,
          senderName: currentUser.name,
          senderAvatar: currentUser.profilePictureUrl,
          filePath: file.path!,
          fileName: file.name,
          type: messageType,
          metadata: {
            'fileSize': file.size,
            'fileExtension': file.extension,
          },
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick file: $e'), 
          backgroundColor: Colors.black,
        ),
      );
    }
  }

  String _getChatTitle() {
    final currentUser = context.read<AuthCubit>().GetCurrentUser();
    if (currentUser == null) return 'Chat';

    // Check if a group name is set
    if (widget.chatRoom.participantNames.containsKey('groupName') && 
        widget.chatRoom.participantNames['groupName']!.isNotEmpty) {
      return widget.chatRoom.participantNames['groupName']!;
    }

    if (widget.chatRoom.participants.length == 2) {
      // 1-on-1 chat
      final otherParticipant = widget.chatRoom.participants.firstWhere(
        (id) => id != currentUser.id,
        orElse: () => widget.chatRoom.participants.first,
      );
      return widget.chatRoom.participantNames[otherParticipant] ?? 'Unknown User';
    } else {
      // Group chat without custom name
      final names = widget.chatRoom.participantNames.entries
          .where((entry) => entry.key != 'groupName' && entry.value.isNotEmpty)
          .map((entry) => entry.value)
          .take(3)
          .join(', ');
      
      String title = names.isNotEmpty ? names : 'Group Chat';
      if (widget.chatRoom.participantNames.length > 3) {
        title += ' +${widget.chatRoom.participantNames.length - 3}';
      }
      return title;
    }
  }

  void _openUserProfile() {
    final currentUser = context.read<AuthCubit>().GetCurrentUser();
    if (currentUser == null) return;

    // For 1-on-1 chats, show the other user's profile
    if (widget.chatRoom.participants.length == 2) {
      final otherParticipantId = widget.chatRoom.participants.firstWhere(
        (id) => id != currentUser.id,
        orElse: () => '',
      );
      
      if (otherParticipantId.isNotEmpty) {
        Navigator.push(
          context,
          PageTransitions.heroDetailTransition(
            page: UserProfilePage(
              userId: otherParticipantId,
              userName: widget.chatRoom.participantNames[otherParticipantId] ?? 'Unknown User',
              initialAvatarUrl: widget.chatRoom.participantAvatars[otherParticipantId] ?? '',
            ),
          ),
        );
      }
    } else {
      // For group chats, show group info
      Navigator.push(
        context,
        PageTransitions.zoomTransition(
          page: GroupInfoPage(
            chatRoom: widget.chatRoom,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, size: 20, color: Colors.black),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openUserProfile,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.withOpacity(0.05),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.chatRoom.participants.length == 2) 
                    _buildUserAvatar()
                  else
                    _buildGroupAvatar(),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                _getChatTitle(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_right,
                              size: 16,
                              color: Colors.black45,
                            ),
                          ],
                        ),
                        if (widget.chatRoom.participants.length == 2)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _otherUserIsOnline ? ChatStyles.onlineColor : ChatStyles.offlineColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _otherUserIsOnline ? 'Online' : 'Offline',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _otherUserIsOnline ? ChatStyles.onlineColor : ChatStyles.offlineColor,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        shadowColor: Colors.black12,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.videocam, size: 20, color: Colors.black),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Video call feature coming soon!'),
                  backgroundColor: Colors.black,
                ),
              );
            },
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.call, size: 20, color: Colors.black),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Voice call feature coming soon!'),
                  backgroundColor: Colors.black,
                ),
              );
            },
          ),
          PopupMenuButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.more_vert, size: 20, color: Colors.black),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'search',
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.black),
                    SizedBox(width: 12),
                    Text('Search in conversation'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.cleaning_services_outlined, color: Colors.black),
                    SizedBox(width: 12),
                    Text('Clear chat history'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'mute',
                child: Row(
                  children: [
                    Icon(Icons.notifications_off_outlined, color: Colors.black),
                    SizedBox(width: 12),
                    Text('Mute notifications'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'search') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Search feature coming soon!'),
                    backgroundColor: Colors.black,
                  ),
                );
              } else if (value == 'clear') {
                // Show confirmation dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear Chat History'),
                    content: const Text('Are you sure you want to clear all messages? This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Implement clear chat functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Clear chat feature coming soon!'),
                              backgroundColor: Colors.black,
                            ),
                          );
                        },
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
              } else if (value == 'mute') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mute notifications feature coming soon!'),
                    backgroundColor: Colors.black,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: ChatStyles.fadeInFromBottom(
        controller: _fadeInController,
        child: Column(
          children: [
            // Messages area
            Expanded(
              child: BlocConsumer<ChatCubit, ChatState>(
                listener: (context, state) {
                  if (state is MessageSent) {
                    _scrollToBottom();
                  } else if (state is MessagesLoaded) {
                    setState(() {
                      _messages
                        ..clear()
                        ..addAll(state.messages);
                    });
                    _scrollToBottomOnNewMessages();
                  } else if (state is MessageDeleted) {
                    // Remove the deleted message from local list
                    setState(() {
                      _messages.removeWhere((message) => message.id == state.messageId);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Message deleted permanently'),
                        backgroundColor: Colors.black,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else if (state is SendMessageError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: ChatStyles.errorColor,
                      ),
                    );
                  } else if (state is MediaUploadError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: ChatStyles.errorColor,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (_messages.isEmpty) {
                    // While loading, show spinner else empty state
                    if (state is MessagesLoading) {
                      return const Center(child: PercentCircleIndicator());
                    }
                    return _buildEmptyMessagesState();
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final currentUser = context.read<AuthCubit>().GetCurrentUser();
                      final isFromCurrentUser = currentUser != null && message.isFromCurrentUser(currentUser.id);
                      return AnimatedMessageBubble(
                        message: message,
                        isFromCurrentUser: isFromCurrentUser,
                        index: index,
                      );
                    },
                  );
                },
              ),
            ),

            // Typing indicator
            BlocBuilder<ChatCubit, ChatState>(
              builder: (context, state) {
                if (state is TypingStatusUpdated && 
                    state.chatRoomId == widget.chatRoom.id) {
                  final typingUsers = state.typingStatus.entries
                      .where((entry) => entry.value && 
                          entry.key != context.read<AuthCubit>().GetCurrentUser()?.id)
                      .map((entry) => widget.chatRoom.participantNames[entry.key] ?? 'User')
                      .toList();

                  if (typingUsers.isNotEmpty) {
                    return AnimatedTypingIndicator(typingUserNames: typingUsers);
                  }
                }
                return const SizedBox.shrink();
              },
            ),

            // Message input area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.shade200,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Material(
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.grey[100],
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: _pickAndSendFile,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: const Icon(Icons.attach_file, color: Colors.black, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Message...',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Colors.black),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        prefixIcon: Icon(Icons.emoji_emotions_outlined, color: Colors.grey[600]),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.mic, color: Colors.grey[600]),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Voice message feature coming soon!'),
                                backgroundColor: Colors.black,
                              ),
                            );
                          },
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Material(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(30),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: _sendMessage,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: const Icon(Icons.send, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMessagesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Be the first to say hello!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              _messageController.text = 'Hello! 👋';
              FocusScope.of(context).requestFocus(FocusNode());
            },
            icon: const Icon(Icons.waving_hand),
            label: const Text('Say Hello'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: ChatStyles.errorColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load messages',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _loadMessages,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar() {
    final currentUser = context.read<AuthCubit>().GetCurrentUser();
    if (currentUser == null || widget.chatRoom.participants.length != 2) {
      return const SizedBox.shrink();
    }
    
    final otherParticipantId = widget.chatRoom.participants.firstWhere(
      (id) => id != currentUser.id,
      orElse: () => '',
    );
    
    if (otherParticipantId.isEmpty) return const SizedBox.shrink();
    
    final avatarUrl = widget.chatRoom.participantAvatars[otherParticipantId] ?? '';
    final userName = widget.chatRoom.participantNames[otherParticipantId] ?? 'User';
    
    return Hero(
      tag: 'avatar_$otherParticipantId',
      child: Container(
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
          radius: 18,
          backgroundColor: Colors.grey[200],
          backgroundImage: avatarUrl.isNotEmpty 
              ? CachedNetworkImageProvider(avatarUrl)
              : null,
          child: avatarUrl.isEmpty
              ? Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildGroupAvatar() {
    return Hero(
      tag: 'group_${widget.chatRoom.id}',
      child: Container(
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
          radius: 18,
          backgroundColor: Colors.grey[200],
          child: Text(
            _getGroupNameAbbreviation(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
  
  String _getGroupNameAbbreviation() {
    final groupName = _getChatTitle();
    if (groupName.isEmpty) return 'GC';
    
    // If it's a list of names, get initials of first 2-3 names
    if (groupName.contains(',')) {
      return groupName
          .split(',')
          .take(2)
          .map((name) => name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '')
          .join('');
    }
    
    // Otherwise use the first letter of the group name
    return groupName.isNotEmpty ? groupName[0].toUpperCase() : 'G';
  }
} 