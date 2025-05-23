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

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _markMessagesAsRead();
    _messageController.addListener(_onTyping);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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

    if (widget.chatRoom.participants.length == 2) {
      // 1-on-1 chat
      final otherParticipant = widget.chatRoom.participants.firstWhere(
        (id) => id != currentUser.id,
        orElse: () => widget.chatRoom.participants.first,
      );
      return widget.chatRoom.participantNames[otherParticipant] ?? 'Unknown User';
    } else {
      // Group chat
      final names = widget.chatRoom.participantNames.values
          .where((name) => name.isNotEmpty)
          .take(3)
          .join(', ');
      return names.isNotEmpty ? names : 'Group Chat';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _getChatTitle(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
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