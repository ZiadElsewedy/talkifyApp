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
import 'package:talkifyapp/features/Communities/domain/entites/Community.dart';
import 'package:talkifyapp/features/Communities/presentation/cubit/community_cubit.dart';
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
  bool _isLoading = true;
  bool _isRecordingVoice = false;
  List<Message> _messages = [];
  
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
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        title: Text(
          widget.communityName ?? 'Community Chat',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
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
              Icons.event,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CommunityEventsPage(
                    communityId: widget.communityId,
                    communityName: widget.communityName ?? 'Community Chat',
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: () {
              // Navigate to Community Info page
              if (_chatRoom != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CommunityInfoPage(
                      chatRoom: _chatRoom!,
                      communityId: widget.communityId,
                      communityName: widget.communityName,
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
            
            // Load messages
            context.read<ChatCubit>().loadMessages(_chatRoom!.id);
          } else if (state is ChatRoomForCommunityNotFound) {
            // Create a new community chat
            final currentUser = context.read<AuthCubit>().GetCurrentUser();
            if (currentUser == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('User not logged in. Please log in to chat.'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            
            // Show creating chat room indicator
            setState(() {
              _isLoading = true;
            });
            
            print('Creating community chat room for community: ${widget.communityId}');
            
            // Get community members to add to the chat room
            _findOrCreateChatRoom();
          } else if (state is ChatRoomCreating) {
            setState(() {
              _isLoading = true;
            });
          } else if (state is ChatRoomCreationError) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to create chat room: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is ChatRoomCreated) {
            print("DEBUG: ChatRoomCreated state received with ID: ${state.chatRoom.id}");
            setState(() {
              _chatRoom = state.chatRoom;
              _isLoading = false;
            });
            
            // Load messages for the new chat room
            context.read<ChatCubit>().loadMessages(_chatRoom!.id);
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Community chat room created successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            
            // Make sure community is added to the chat
            if (_chatRoom!.communityId == null) {
              print("DEBUG: WARNING - Chat room was created but communityId is null!");
              // Try to fix it by updating the chat room
              try {
                _chatRoom = _chatRoom!.copyWith(communityId: widget.communityId);
                print("DEBUG: Updated chat room with communityId: ${_chatRoom!.communityId}");
              } catch (e) {
                print("DEBUG: Error updating chat room: $e");
              }
            }
          } else if (state is MessagesLoaded) {
            setState(() {
              _messages = state.messages;
            });
            
            // Scroll to bottom after messages load
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });
          } else if (state is UploadingMedia) {
            // Show progress indicator for media uploads
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
          if (_isLoading) {
            return const Center(
              child: chat_indicator.PercentCircleIndicator(),
            );
          }
          
          if (_chatRoom == null) {
            return const Center(
              child: Text('Error loading community chat'),
            );
          }
          
          // Show uploading indicator if needed
          Widget? uploadingMediaWidget;
          if (state is UploadingMedia) {
            // You could implement a custom widget for showing upload progress
          }
          
          return Column(
            children: [
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyChat(isDarkMode)
                    : Stack(
                        children: [
                          _buildMessageList(isDarkMode),
                          if (uploadingMediaWidget != null)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: uploadingMediaWidget,
                            ),
                        ],
                      ),
              ),
              _buildMessageInput(isDarkMode),
            ],
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
            size: 80,
            color: isDarkMode ? Colors.white54 : Colors.black38,
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.white54 : Colors.black38,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to send a message!',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white38 : Colors.black26,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMessageList(bool isDarkMode) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final currentUser = context.read<AuthCubit>().GetCurrentUser();
        final isMe = currentUser != null && message.senderId == currentUser.id;
        
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
      color: isDarkMode ? Colors.black : Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.add_circle_outline,
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
            onPressed: () => _showAttachmentOptions(isDarkMode),
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.white54 : Colors.black38,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[900] : Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.send,
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
} 