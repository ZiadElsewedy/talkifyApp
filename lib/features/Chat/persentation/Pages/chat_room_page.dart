import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:talkifyapp/features/Chat/domain/entite/message.dart';
import 'package:talkifyapp/features/Chat/domain/entite/chat_room.dart';
import 'package:talkifyapp/features/Chat/persentation/Cubits/chat_cubit.dart';
import 'package:talkifyapp/features/Chat/persentation/Cubits/chat_states.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/components/message_bubble.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/components/WhiteCircleIndicator.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/user_profile_page.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/group_info_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomPage extends StatefulWidget {
  final ChatRoom chatRoom;

  const ChatRoomPage({
    super.key,
    required this.chatRoom,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  final List<Message> _messages = [];
  bool _otherUserIsOnline = false;
  Stream<DocumentSnapshot>? _userStatusStream;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _markMessagesAsRead();
    _messageController.addListener(_onTyping);
    _setupUserStatusListener();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
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
        SnackBar(content: Text('Failed to pick file: $e')),
      );
    }
  }

  String _getChatTitle() {
    final currentUser = context.read<AuthCubit>().GetCurrentUser();
    if (currentUser == null) return 'Chat';

    // Check if a group name is set
    if (widget.chatRoom.participantNames.containsKey('groupName')) {
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
          MaterialPageRoute(
            builder: (context) => UserProfilePage(
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
        MaterialPageRoute(
          builder: (context) => GroupInfoPage(
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
        title: GestureDetector(
          onTap: _openUserProfile,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getChatTitle(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                  if (widget.chatRoom.participants.length == 2)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _otherUserIsOnline ? Colors.green : Colors.grey,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _otherUserIsOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            fontSize: 12,
                            color: _otherUserIsOnline ? Colors.green : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.info_outline, size: 16, color: Colors.black54),
            ],
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        shadowColor: Colors.black12,
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.black),
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
            icon: const Icon(Icons.call, color: Colors.black),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Voice call feature coming soon!'),
                  backgroundColor: Colors.black,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {
              // TODO: Show chat options
            },
          ),
        ],
      ),
      body: Column(
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
                      content: Text('Message deleted permanently from database'),
                      backgroundColor: Colors.black,
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else if (state is SendMessageError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else if (state is MediaUploadError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
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
                    return MessageBubble(
                      message: message,
                      isFromCurrentUser: isFromCurrentUser,
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
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Text(
                          '${typingUsers.join(', ')} ${typingUsers.length == 1 ? 'is' : 'are'} typing...',
                          style: const TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  );
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
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.black),
                  onPressed: _pickAndSendFile,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
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
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.black,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMessagesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation by sending a message',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
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
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load messages',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadMessages,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
} 