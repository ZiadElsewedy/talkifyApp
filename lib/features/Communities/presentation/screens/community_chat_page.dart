import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:talkifyapp/features/Chat/domain/entite/chat_room.dart';
import 'package:talkifyapp/features/Chat/domain/entite/message.dart';
import 'package:talkifyapp/features/Chat/persentation/Cubits/chat_cubit.dart';
import 'package:talkifyapp/features/Chat/persentation/Cubits/chat_states.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/components/message_bubble.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/components/WhiteCircleIndicator.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/Chat/Utils/message_type_helper.dart';
import 'package:talkifyapp/features/Communities/data/repositories/community_repository_impl.dart';
import 'community_info_page.dart';
import 'community_events_page.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/components/percent_circle_indicator.dart' as chat_indicator;
import 'package:file_picker/file_picker.dart';
import 'package:talkifyapp/features/Communities/domain/Entites/community.dart';
import 'package:talkifyapp/features/Communities/presentation/cubit/community_cubit.dart';
import 'package:talkifyapp/features/Communities/presentation/cubit/community_state.dart';
import 'community_details_page.dart';

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
  Community? _community;
  bool _isLoading = true;
  bool _isRecordingVoice = false;
  List<Message> _messages = [];
  
  @override
  void initState() {
    super.initState();
    _loadCommunityChat();
    _loadCommunityDetails();
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
  
  void _loadCommunityDetails() {
    // Load community details
    context.read<CommunityCubit>().getCommunityById(widget.communityId);
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
  
  Future<void> _findOrCreateChatRoom() async {
    final currentUser = context.read<AuthCubit>().GetCurrentUser();
    if (currentUser == null || widget.communityId.isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });
    
    print("DEBUG: Looking for community chat room for community ID: ${widget.communityId}");
    
    try {
      // Try to get all members of the community
      final communityRepo = CommunityRepositoryImpl();
      final members = await communityRepo.getCommunityMembers(widget.communityId);
      
      if (members.isEmpty) {
        print("DEBUG: No members found, creating chat with just current user");
        // If no members, create chat with just current user
        context.read<ChatCubit>().createGroupChatRoom(
          participants: [currentUser.id],
          participantNames: {currentUser.id: currentUser.name},
          participantAvatars: {currentUser.id: currentUser.profilePictureUrl},
          unreadCount: {currentUser.id: 0},
          groupName: widget.communityName ?? 'Community Chat',
          communityId: widget.communityId,
        );
      } else {
        print("DEBUG: Found ${members.length} community members");
      
        // Create maps of participant IDs, names, and avatars
        final List<String> participantIds = [];
      final Map<String, String> participantNames = {};
      final Map<String, String> participantAvatars = {};
        final Map<String, int> unreadCount = {};
      
        // Add all community members
      for (final member in members) {
          participantIds.add(member.userId);
          participantNames[member.userId] = member.userName;
          participantAvatars[member.userId] = member.userAvatar;
          unreadCount[member.userId] = 0;
          
          print("DEBUG: Added member: ${member.userName} with avatar: ${member.userAvatar}");
        }
        
        // Make sure current user is included (in case they're not in the members list yet)
        if (!participantIds.contains(currentUser.id)) {
          participantIds.add(currentUser.id);
          participantNames[currentUser.id] = currentUser.name;
          participantAvatars[currentUser.id] = currentUser.profilePictureUrl;
          unreadCount[currentUser.id] = 0;
          
          print("DEBUG: Added current user: ${currentUser.name} with avatar: ${currentUser.profilePictureUrl}");
        }
        
        // Create group chat room with all community members
      context.read<ChatCubit>().createGroupChatRoom(
          participants: participantIds,
        participantNames: participantNames,
        participantAvatars: participantAvatars,
          unreadCount: unreadCount,
        groupName: widget.communityName ?? 'Community Chat',
        communityId: widget.communityId,
      );
      }
    } catch (e) {
      print("DEBUG: Error finding members: $e");
        // Fallback to creating chat with just current user
        context.read<ChatCubit>().createGroupChatRoom(
          participants: [currentUser.id],
          participantNames: {currentUser.id: currentUser.name},
          participantAvatars: {currentUser.id: currentUser.profilePictureUrl},
          unreadCount: {currentUser.id: 0},
          groupName: widget.communityName ?? 'Community Chat',
          communityId: widget.communityId,
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
  
  Future<void> _pickAndSendImage() async {
    if (_chatRoom == null) return;
    final currentUser = context.read<AuthCubit>().GetCurrentUser();
    if (currentUser == null) return;
    
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    
    if (image != null) {
      final File file = File(image.path);
      
      // Upload and send the image
      context.read<ChatCubit>().sendMediaMessage(
        chatRoomId: _chatRoom!.id,
        senderId: currentUser.id,
        senderName: currentUser.name,
        senderAvatar: currentUser.profilePictureUrl,
        filePath: file.path,
        fileName: image.name,
        type: MessageType.image,
      );
    }
  }
  
  Future<void> _pickAndSendVideo() async {
    if (_chatRoom == null) return;
    final currentUser = context.read<AuthCubit>().GetCurrentUser();
    if (currentUser == null) return;
    
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(
      source: ImageSource.gallery,
    );
    
    if (video != null) {
      final File file = File(video.path);
      
      // Upload and send the video
      context.read<ChatCubit>().sendMediaMessage(
        chatRoomId: _chatRoom!.id,
        senderId: currentUser.id,
        senderName: currentUser.name,
        senderAvatar: currentUser.profilePictureUrl,
        filePath: file.path,
        fileName: video.name,
        type: MessageType.video,
      );
    }
  }
  
  Future<void> _pickAndSendFile() async {
    if (_chatRoom == null) return;
    final currentUser = context.read<AuthCubit>().GetCurrentUser();
    if (currentUser == null) return;
    
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      final File file = File(result.files.single.path!);
      final String fileName = result.files.single.name;
      
      // Upload and send the file
      context.read<ChatCubit>().sendMediaMessage(
        chatRoomId: _chatRoom!.id,
        senderId: currentUser.id,
        senderName: currentUser.name,
        senderAvatar: currentUser.profilePictureUrl,
        filePath: file.path,
        fileName: fileName,
        type: MessageType.file,
      );
    }
  }
  
  void _takeAndSendPhoto() async {
    if (_chatRoom == null) return;
    final currentUser = context.read<AuthCubit>().GetCurrentUser();
    if (currentUser == null) return;
    
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    
    if (image != null) {
      final File file = File(image.path);
      
      // Upload and send the image
      context.read<ChatCubit>().sendMediaMessage(
        chatRoomId: _chatRoom!.id,
        senderId: currentUser.id,
        senderName: currentUser.name,
        senderAvatar: currentUser.profilePictureUrl,
        filePath: file.path,
        fileName: image.name,
        type: MessageType.image,
      );
    }
  }
  
  void _showAttachmentOptions(bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
              Text(
                'Share Media',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                  _buildAttachmentOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      _takeAndSendPhoto();
                    },
                    isDarkMode: isDarkMode,
                  ),
                _buildAttachmentOption(
                  icon: Icons.photo,
                    label: 'Gallery',
                    color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndSendImage();
                  },
                    isDarkMode: isDarkMode,
                ),
                _buildAttachmentOption(
                  icon: Icons.videocam,
                  label: 'Video',
                    color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndSendVideo();
                  },
                    isDarkMode: isDarkMode,
                ),
                _buildAttachmentOption(
                    icon: Icons.insert_drive_file,
                    label: 'File',
                    color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                      _pickAndSendFile();
                  },
                    isDarkMode: isDarkMode,
                ),
              ],
            ),
          ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
  
  // Send system message
  void _sendSystemMessage() {
    // Implementation
  }
  
  // Helper method to check if we need to show a date header
  bool _shouldShowDateHeader(int index) {
    if (index == 0) return true;
    
    final currentMessageDate = _messages[index].timestamp;
    final previousMessageDate = _messages[index - 1].timestamp;
    
    return !_isSameDay(currentMessageDate, previousMessageDate);
  }
  
  // Helper method to check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }
  
  // Build a date header widget
  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    
    String dateText;
    if (_isSameDay(date, now)) {
      dateText = 'Today';
    } else if (_isSameDay(date, yesterday)) {
      dateText = 'Yesterday';
    } else {
      dateText = '${date.day}/${date.month}/${date.year}';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Text(
          dateText,
          style: TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : Colors.black54,
          ),
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        title: BlocBuilder<CommunityCubit, CommunityState>(
          builder: (context, state) {
            if (state is CommunityDetailLoaded) {
              _community = state.community;
            }
            return _buildChatRoomTitle(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.event,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CommunityEventsPage(
                    communityId: widget.communityId,
                    communityName: _community?.name ?? widget.communityName ?? 'Community Chat',
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () {
              if (_chatRoom != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CommunityInfoPage(
                      chatRoom: _chatRoom!,
                      communityId: widget.communityId,
                      communityName: _community?.name ?? widget.communityName,
                    ),
                  ),
                );
              }
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
            // Get messages for this chat room
            context.read<ChatCubit>().loadMessages(_chatRoom!.id);
          } else if (state is ChatRoomForCommunityNotFound) {
            // Create new chat room
            _findOrCreateChatRoom();
          } else if (state is ChatRoomCreated) {
            setState(() {
              _chatRoom = state.chatRoom;
              _isLoading = false;
            });
            // Get messages for this new chat room
            context.read<ChatCubit>().loadMessages(_chatRoom!.id);
          } else if (state is MessagesLoaded) {
            setState(() {
              // Sort messages by timestamp to ensure chronological order
              _messages = List.from(state.messages)
                ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
              _isLoading = false;
            });
            // Scroll to bottom after messages are loaded
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });
          } else if (state is MessageSent) {
            // Scroll to bottom after sending a message
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });
          }
        },
        builder: (context, state) {
          if (_isLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            );
          }
          
          if (_chatRoom == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Could not load chat room',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      _findOrCreateChatRoom();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          return Column(
            children: [
              // Messages
              Expanded(
                child: _messages.isEmpty
                    ? Center(
                        child: Text(
                          'No messages yet. Be the first to say hello!',
                          style: theme.textTheme.bodyMedium,
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final currentUser = context.read<AuthCubit>().GetCurrentUser();
                          final bool isMe = currentUser?.id == message.senderId;
                          
                          // Add date header if this is a new day or first message
                          Widget? dateHeader;
                          if (index == 0 || _shouldShowDateHeader(index)) {
                            dateHeader = _buildDateHeader(message.timestamp);
                          }
                          
                          return Column(
                            children: [
                              if (dateHeader != null) dateHeader,
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: MessageBubble(
                                  message: message,
                                  isFromCurrentUser: isMe,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
              
              // Message input area
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Attachment button
                      IconButton(
                        icon: Icon(
                          Icons.add_circle_outline,
                          color: theme.colorScheme.primary,
                        ),
                        onPressed: () => _showAttachmentOptions(isDark),
                      ),
                      
                      // Text field
                      Expanded(
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 120),
                          decoration: BoxDecoration(
                            color: isDark ? Color(0xFF2C2C2C) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                          child: TextField(
                            controller: _messageController,
                            textCapitalization: TextCapitalization.sentences,
                            maxLines: null,
                            style: theme.textTheme.bodyMedium,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 10.0,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      
                      // Send button
                      IconButton(
                        icon: Icon(
                          Icons.send_rounded,
                          color: theme.colorScheme.primary,
                        ),
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildChatRoomTitle(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_chatRoom != null) {
      final String name = _community?.name ?? widget.communityName ?? 'Community Chat';
      final int memberCount = _community?.memberCount ?? _chatRoom!.participants.length;
      
      return Row(
        children: [
          // Community icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _community?.iconUrl.isNotEmpty == true ? null : theme.colorScheme.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: _community?.iconUrl.isNotEmpty == true
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: _community!.iconUrl,
                    placeholder: (context, url) => Center(
                      child: Icon(
                        Icons.group,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    errorWidget: (context, url, error) => Center(
                      child: Icon(
                        Icons.group,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    fit: BoxFit.cover,
                  ),
                )
              : Center(
                  child: Icon(
                    Icons.group,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
          ),
          const SizedBox(width: 12),
          // Community name and member count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$memberCount members',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          // Community icon placeholder
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.group,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Community name
          Expanded(
            child: Text(
              widget.communityName ?? 'Community Chat',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }
  }
} 