import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Chat/domain/entite/chat_room.dart';
import 'package:talkifyapp/features/Chat/domain/entite/message.dart';
import 'package:talkifyapp/features/Chat/persentation/Cubits/chat_cubit.dart';
import 'package:talkifyapp/features/Chat/persentation/Cubits/chat_states.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/components/message_bubble.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/components/WhiteCircleIndicator.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';

class CommunityChatPage extends StatefulWidget {
  final String communityId;
  final String? communityName;
  
  const CommunityChatPage({
    Key? key,
    required this.communityId,
    this.communityName,
  }) : super(key: key);

  @override
  State<CommunityChatPage> createState() => _CommunityChatPageState();
}

class _CommunityChatPageState extends State<CommunityChatPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  ChatRoom? _chatRoom;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadCommunityChat();
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }
  
  void _loadCommunityChat() {
    final currentUser = context.read<AuthCubit>().GetCurrentUser();
    if (currentUser == null) return;
    
    // Check if a chat room already exists for this community
    context.read<ChatCubit>().getChatRoomForCommunity(widget.communityId);
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
  
  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    if (_chatRoom == null) return;
    
    final currentUser = context.read<AuthCubit>().GetCurrentUser();
    if (currentUser == null) return;
    
    context.read<ChatCubit>().sendMessage(
      chatRoom: _chatRoom!,
      content: _messageController.text.trim(),
      senderId: currentUser.id,
      senderName: currentUser.name,
      type: MessageType.text,
    );
    
    _messageController.clear();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.communityName ?? 'Community Chat',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDarkMode ? Theme.of(context).colorScheme.surface : Colors.white,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: () {
              // Show community info
            },
          ),
        ],
      ),
      body: BlocConsumer<ChatCubit, ChatState>(
        listener: (context, state) {
          if (state is ChatRoomForCommunityLoaded) {
            setState(() {
              _chatRoom = state.chatRoom;
              _isLoading = false;
            });
            
            // Load messages
            context.read<ChatCubit>().loadMessages(_chatRoom!.id);
          } else if (state is ChatRoomForCommunityNotFound) {
            // Create a new community chat
            final currentUser = context.read<AuthCubit>().GetCurrentUser();
            if (currentUser == null) return;
            
            // Create basic chat room with just the current user
            context.read<ChatCubit>().createGroupChatRoom(
              participants: [currentUser.id],
              participantNames: {currentUser.id: currentUser.name},
              participantAvatars: {currentUser.id: ''},
              unreadCount: {currentUser.id: 0},
              groupName: widget.communityName ?? 'Community Chat',
              communityId: widget.communityId,
            );
          } else if (state is ChatRoomCreated) {
            setState(() {
              _chatRoom = state.chatRoom;
              _isLoading = false;
            });
            
            // Load messages for the new chat room
            context.read<ChatCubit>().loadMessages(_chatRoom!.id);
          } else if (state is MessagesLoaded) {
            // Scroll to bottom after messages load
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });
          }
        },
        builder: (context, state) {
          if (_isLoading) {
            return const Center(
              child: PercentCircleIndicator(),
            );
          }
          
          if (_chatRoom == null) {
            return const Center(
              child: Text('Error loading community chat'),
            );
          }
          
          if (state is MessagesLoaded) {
            final messages = state.messages;
            
            return Column(
              children: [
                Expanded(
                  child: messages.isEmpty
                      ? _buildEmptyChat(isDarkMode)
                      : _buildMessageList(messages, isDarkMode),
                ),
                _buildMessageInput(isDarkMode),
              ],
            );
          }
          
          return const Center(
            child: PercentCircleIndicator(),
          );
        },
      ),
    );
  }
  
  Widget _buildEmptyChat(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 60,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation in this community',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMessageList(List<Message> messages, bool isDarkMode) {
    final currentUser = context.read<AuthCubit>().GetCurrentUser();
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.senderId == currentUser?.id;
        
        return MessageBubble(
          message: message,
          isFromCurrentUser: isMe,
        );
      },
    );
  }
  
  Widget _buildMessageInput(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: isDarkMode ? Theme.of(context).colorScheme.surface : Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _sendMessage,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.blue.shade700 : Colors.black,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 