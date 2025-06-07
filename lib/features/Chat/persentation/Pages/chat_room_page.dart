import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:talkifyapp/features/Chat/domain/entite/message.dart';
import 'package:talkifyapp/features/Chat/domain/entite/chat_room.dart';
import 'package:talkifyapp/features/Chat/persentation/Cubits/chat_cubit.dart';
import 'package:talkifyapp/features/Chat/persentation/Cubits/chat_states.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/components/animated_message_bubble.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/components/animated_typing_indicator.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/components/voice_note_recorder.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/components/uploading_video_bubble.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/components/WhiteCircleIndicator.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/user_profile_page.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/group_info_page.dart';
import 'package:talkifyapp/features/Chat/Utils/chat_styles.dart';
import 'package:talkifyapp/features/Chat/Utils/page_transitions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:talkifyapp/features/Chat/service/chat_message_listener.dart';
import 'package:talkifyapp/features/Chat/service/chat_notification_service.dart';

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
  bool _isRecordingVoice = false;

  @override
  void initState() {
    super.initState();
    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeInController.forward();
    
    // Set current chat room ID to prevent notifications for this chat
    ChatMessageListener().setCurrentChatRoomId(widget.chatRoom.id);
    
    _loadMessages();
    _markMessagesAsRead();
    _messageController.addListener(_onTyping);
    _setupUserStatusListener();
  }

  @override
  void dispose() {
    // Clear current chat room ID when leaving the chat
    ChatMessageListener().setCurrentChatRoomId(null);
    
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
    final currentUser = context.read<AuthCubit>().GetCurrentUser();
    if (currentUser != null) {
      // Use the user-specific message loading method
      context.read<ChatCubit>().loadChatMessagesForUser(widget.chatRoom.id, currentUser.id);
    } else {
      // Fallback to regular message loading if no user is authenticated
      context.read<ChatCubit>().loadChatMessages(widget.chatRoom.id);
    }
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
    // Use a small delay to ensure the list has been updated
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
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
          } else if (['pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'txt'].contains(extension)) {
            messageType = MessageType.document;
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
  
  Future<void> _pickAndSendDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'txt', 'csv'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        final currentUser = context.read<AuthCubit>().GetCurrentUser();
        
        if (currentUser == null) return;

        // Always use document type for these file extensions
        context.read<ChatCubit>().sendMediaMessage(
          chatRoomId: widget.chatRoom.id,
          senderId: currentUser.id,
          senderName: currentUser.name,
          senderAvatar: currentUser.profilePictureUrl,
          filePath: file.path!,
          fileName: file.name,
          type: MessageType.document,
          metadata: {
            'fileSize': file.size,
            'fileExtension': file.extension,
          },
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick document: $e'), 
          backgroundColor: Colors.black,
        ),
      );
    }
  }

  Future<void> _pickAndSendVideo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'], // Common video formats
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        final currentUser = context.read<AuthCubit>().GetCurrentUser();
        
        if (currentUser == null) return;

        // Send as video type
        context.read<ChatCubit>().sendMediaMessage(
          chatRoomId: widget.chatRoom.id,
          senderId: currentUser.id,
          senderName: currentUser.name,
          senderAvatar: currentUser.profilePictureUrl,
          filePath: file.path!,
          fileName: file.name,
          type: MessageType.video,
          metadata: {
            'fileSize': file.size,
            'fileExtension': file.extension,
          },
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick video: $e'), 
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
        _navigateToUserProfile(
          userId: otherParticipantId,
          userName: widget.chatRoom.participantNames[otherParticipantId] ?? 'Unknown User',
          avatarUrl: widget.chatRoom.participantAvatars[otherParticipantId] ?? '',
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

  void _navigateToUserProfile({
    required String userId,
    required String userName,
    required String avatarUrl,
  }) {
    Navigator.push(
      context,
      PageTransitions.heroDetailTransition(
        page: UserProfilePage(
          userId: userId,
          userName: userName,
          initialAvatarUrl: avatarUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final Color scaffoldBackgroundColor = colorScheme.background;
    final Color appBarBackgroundColor = colorScheme.surface;
    final Color appBarForegroundColor = colorScheme.onSurface;
    final Color appBarIconBackgroundColor = isDarkMode ? colorScheme.surfaceVariant : Colors.grey[100]!;
    final Color appBarIconColor = colorScheme.onSurfaceVariant;
    final Color titleContainerColor = isDarkMode ? colorScheme.surface.withOpacity(0.5) : Colors.grey.withOpacity(0.05);
    final Color titleTextColor = colorScheme.onSurface;
    final Color subtitleTextColor = colorScheme.onSurfaceVariant;
    final Color onlineStatusColor = Colors.green; // Or your specific online color
    final Color offlineStatusColor = Colors.grey; // Or your specific offline color
    final Color snackBarBackgroundColor = colorScheme.inverseSurface;
    final Color snackBarTextColor = colorScheme.onInverseSurface;
    final Color errorColor = colorScheme.error;
    final Color popupMenuButtonBackgroundColor = colorScheme.surface;
    final Color popupMenuIconColor = colorScheme.onSurface;
    final Color popupMenuItemTextColor = colorScheme.onSurface;
    final Color dialogBackgroundColor = colorScheme.surface;
    final Color dialogTitleColor = colorScheme.onSurface;
    final Color dialogContentColor = colorScheme.onSurfaceVariant;
    final Color dialogButtonTextColor = colorScheme.primary;
    final Color dialogDestructiveButtonTextColor = colorScheme.error;
    final Color lastSeenIndicatorBackgroundColor = isDarkMode ? colorScheme.surfaceVariant.withOpacity(0.5) : Colors.grey[50]!;
    final Color lastSeenIndicatorIconColor = colorScheme.primary;
    final Color lastSeenIndicatorTextColor = colorScheme.onSurfaceVariant;
    final Color inputContainerBackgroundColor = colorScheme.surface;
    final Color inputContainerShadowColor = colorScheme.shadow.withOpacity(0.05);
    final Color inputFieldBackgroundColor = isDarkMode ? colorScheme.surfaceVariant : Colors.grey.shade200;
    final Color inputFieldHintTextColor = colorScheme.onSurfaceVariant.withOpacity(0.6);
    final Color inputIconColor = colorScheme.onSurfaceVariant;
    final Color sendButtonIconColor = colorScheme.primary;
    final Color micButtonIconColor = colorScheme.primary;

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: appBarIconBackgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_back, size: 20, color: appBarIconColor),
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
                color: titleContainerColor,
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
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: titleTextColor,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_right,
                              size: 16,
                              color: subtitleTextColor,
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
                                  color: _otherUserIsOnline ? onlineStatusColor : offlineStatusColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _otherUserIsOnline ? 'Online' : 'Offline',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _otherUserIsOnline ? onlineStatusColor : offlineStatusColor,
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
        backgroundColor: appBarBackgroundColor,
        foregroundColor: appBarForegroundColor,
        elevation: 1,
        shadowColor: Colors.black12, // Consider colorScheme.shadow
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: appBarIconBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.videocam, size: 20, color: appBarIconColor),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Video call feature coming soon!', style: TextStyle(color: snackBarTextColor)),
                  backgroundColor: snackBarBackgroundColor,
                ),
              );
            },
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: appBarIconBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.call, size: 20, color: appBarIconColor),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Voice call feature coming soon!', style: TextStyle(color: snackBarTextColor)),
                  backgroundColor: snackBarBackgroundColor,
                ),
              );
            },
          ),
          PopupMenuButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: appBarIconBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.more_vert, size: 20, color: appBarIconColor),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: popupMenuButtonBackgroundColor,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'search',
                child: Row(
                  children: [
                    Icon(Icons.search, color: popupMenuIconColor),
                    const SizedBox(width: 12),
                    Text('Search in conversation', style: TextStyle(color: popupMenuItemTextColor)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.cleaning_services_outlined, color: popupMenuIconColor),
                    const SizedBox(width: 12),
                    Text('Clear chat history', style: TextStyle(color: popupMenuItemTextColor)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'mute',
                child: FutureBuilder<bool>(
                  future: ChatNotificationService.isChatMuted(widget.chatRoom.id),
                  builder: (context, snapshot) {
                    final isMuted = snapshot.data ?? false;
                    return Row(
                      children: [
                        Icon(
                          isMuted ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
                          color: popupMenuIconColor,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isMuted ? 'Unmute notifications' : 'Mute notifications',
                          style: TextStyle(color: popupMenuItemTextColor),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'search') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Search feature coming soon!', style: TextStyle(color: snackBarTextColor)),
                    backgroundColor: snackBarBackgroundColor,
                  ),
                );
              } else if (value == 'clear') {
                // Show confirmation dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: dialogBackgroundColor,
                    title: Text('Clear Chat History', style: TextStyle(color: dialogTitleColor)),
                    content: Text('Are you sure you want to clear all messages? This action cannot be undone.', style: TextStyle(color: dialogContentColor)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel', style: TextStyle(color: dialogButtonTextColor)),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Implement clear chat functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Clear chat feature coming soon!', style: TextStyle(color: snackBarTextColor)),
                              backgroundColor: snackBarBackgroundColor,
                            ),
                          );
                        },
                        style: TextButton.styleFrom(foregroundColor: dialogDestructiveButtonTextColor),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
              } else if (value == 'mute') {
                // Toggle mute status
                final isMuted = await ChatNotificationService.isChatMuted(widget.chatRoom.id);
                if (isMuted) {
                  await ChatNotificationService.unmuteChat(widget.chatRoom.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notifications unmuted'),
                        backgroundColor: Colors.black,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } else {
                  await ChatNotificationService.muteChat(widget.chatRoom.id);
                  if (mounted) {
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
                // Force refresh to update the menu item
                setState(() {});
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
                      SnackBar(
                        content: Text('Message deleted permanently', style: TextStyle(color: snackBarTextColor)),
                        backgroundColor: snackBarBackgroundColor,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else if (state is SendMessageError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message, style: TextStyle(color: snackBarTextColor)),
                        backgroundColor: errorColor,
                      ),
                    );
                  } else if (state is MediaUploadError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message, style: TextStyle(color: snackBarTextColor)),
                        backgroundColor: errorColor,
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

                  // Check if there's an uploading video
                  Widget? uploadingVideoWidget;
                  if (state is UploadingMediaProgress && state.type == MessageType.video) {
                    uploadingVideoWidget = Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: UploadingVideoBubble(
                        localFilePath: state.localFilePath,
                        progress: state.progress,
                        isFromCurrentUser: state.isFromCurrentUser,
                        caption: state.caption,
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (uploadingVideoWidget != null ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Show uploading video at the end
                      if (uploadingVideoWidget != null && index == _messages.length) {
                        return uploadingVideoWidget;
                      }
                      
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
            
            // Last seen message indicator
            BlocBuilder<ChatCubit, ChatState>(
              builder: (context, state) {
                if (state is MessagesLoaded && state.chatRoomId == widget.chatRoom.id) {
                  final currentUser = context.read<AuthCubit>().GetCurrentUser();
                  if (currentUser == null) return const SizedBox.shrink();
                  
                  // Filter messages sent by the current user
                  final myMessages = state.messages
                      .where((msg) => msg.senderId == currentUser.id)
                      .toList();
                  
                  if (myMessages.isEmpty) return const SizedBox.shrink();
                  
                  // Get the last read message (messages with status == MessageStatus.read)
                  final readMessages = myMessages
                      .where((msg) => msg.status == MessageStatus.read)
                      .toList();
                  
                  if (readMessages.isEmpty) return const SizedBox.shrink();
                                    
                  // Get the other participant (for 1-on-1 chats)
                  String otherParticipantId = '';
                  String otherParticipantName = '';
                  String otherParticipantAvatar = '';
                  
                  if (widget.chatRoom.participants.length == 2) {
                    otherParticipantId = widget.chatRoom.participants.firstWhere(
                      (id) => id != currentUser.id,
                      orElse: () => '',
                    );
                    
                    otherParticipantName = widget.chatRoom.participantNames[otherParticipantId] ?? 'User';
                    otherParticipantAvatar = widget.chatRoom.participantAvatars[otherParticipantId] ?? '';
                  } else {
                    // For group chats, we could show multiple users who have seen the message
                    // For simplicity, we'll just note that it's been seen in the group
                    otherParticipantName = 'Someone';
                  }
                  
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    color: lastSeenIndicatorBackgroundColor,
                    child: Row(
                      children: [
                        Icon(Icons.done_all, size: 16, color: lastSeenIndicatorIconColor),
                        const SizedBox(width: 8),
                        if (otherParticipantAvatar.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: CircleAvatar(
                              radius: 10,
                              backgroundImage: CachedNetworkImageProvider(otherParticipantAvatar),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            widget.chatRoom.participants.length == 2
                                ? '$otherParticipantName has seen your message'
                                : 'Seen in group',
                            style: TextStyle(
                              fontSize: 12,
                              color: lastSeenIndicatorTextColor,
                              fontStyle: FontStyle.italic,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Chat input at the bottom
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
              decoration: BoxDecoration(
                color: inputContainerBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: inputContainerShadowColor,
                    offset: const Offset(0, -1),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: _isRecordingVoice 
                ? VoiceNoteRecorder(
                    chatRoomId: widget.chatRoom.id,
                    onCancelRecording: () {
                      setState(() {
                        _isRecordingVoice = false;
                      });
                    },
                  )
                : Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.add, color: inputIconColor),
                        onPressed: _showAttachmentOptions,
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: inputFieldBackgroundColor,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: TextField(
                            controller: _messageController,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            textCapitalization: TextCapitalization.sentences,
                            style: TextStyle(color: colorScheme.onSurface),
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(color: inputFieldHintTextColor),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _messageController.text.trim().isEmpty
                          ? IconButton(
                              icon: Icon(Icons.mic, color: micButtonIconColor),
                              onPressed: () {
                                setState(() {
                                  _isRecordingVoice = true;
                                });
                              },
                            )
                          : IconButton(
                              icon: Icon(Icons.send, color: sendButtonIconColor),
                              onPressed: _sendMessage,
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
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color iconContainerColor = isDarkMode ? colorScheme.surfaceVariant : Colors.grey[100]!;
    final Color iconColor = isDarkMode ? colorScheme.onSurfaceVariant : Colors.grey[400]!;
    final Color titleColor = isDarkMode ? colorScheme.onSurface : Colors.grey[700]!;
    final Color subtitleColor = isDarkMode ? colorScheme.onSurfaceVariant : Colors.grey[500]!;
    final Color buttonBackgroundColor = colorScheme.primary;
    final Color buttonForegroundColor = colorScheme.onPrimary;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: iconContainerColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Be the first to say hello!',
            style: TextStyle(
              fontSize: 16,
              color: subtitleColor,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              _messageController.text = 'Hello! 👋';
              FocusScope.of(context).requestFocus(FocusNode());
            },
            icon: Icon(Icons.waving_hand, color: buttonForegroundColor),
            label: Text('Say Hello', style: TextStyle(color: buttonForegroundColor)),
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonBackgroundColor,
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
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color iconColor = colorScheme.error;
    final Color titleColor = isDarkMode ? colorScheme.onSurface : Colors.grey[700]!;
    final Color messageColor = isDarkMode ? colorScheme.onSurfaceVariant : Colors.grey[600]!;
    final Color buttonBackgroundColor = colorScheme.primary;
    final Color buttonForegroundColor = colorScheme.onPrimary;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: iconColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load messages',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: messageColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _loadMessages,
            icon: Icon(Icons.refresh, color: buttonForegroundColor),
            label: Text('Try Again', style: TextStyle(color: buttonForegroundColor)),
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonBackgroundColor,
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
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color avatarBackgroundColor = isDarkMode ? colorScheme.surfaceVariant : Colors.grey[200]!;
    final Color avatarTextColor = isDarkMode ? colorScheme.onSurfaceVariant : Colors.black87;
    final Color avatarShadowColor = colorScheme.shadow.withOpacity(0.1);

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
    
    return GestureDetector(
      onTap: () => _navigateToUserProfile(
        userId: otherParticipantId,
        userName: userName,
        avatarUrl: avatarUrl,
      ),
      child: Hero(
        tag: 'avatar_$otherParticipantId',
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: avatarShadowColor,
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: avatarBackgroundColor,
            backgroundImage: avatarUrl.isNotEmpty 
                ? CachedNetworkImageProvider(avatarUrl)
                : null,
            child: avatarUrl.isEmpty
                ? Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: avatarTextColor,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupAvatar() {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color avatarBackgroundColor = isDarkMode ? colorScheme.surfaceVariant : Colors.grey[200]!;
    final Color avatarTextColor = isDarkMode ? colorScheme.onSurfaceVariant : Colors.black87;
    final Color avatarShadowColor = colorScheme.shadow.withOpacity(0.1);

    return Hero(
      tag: 'group_${widget.chatRoom.id}',
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: avatarShadowColor,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: avatarBackgroundColor,
          child: Text(
            _getGroupNameAbbreviation(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: avatarTextColor,
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

  void _showAttachmentOptions() {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color bottomSheetBackgroundColor = colorScheme.surface;

    showModalBottomSheet(
      context: context,
      backgroundColor: bottomSheetBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.photo,
                  label: 'Photo',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndSendFile();
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.videocam,
                  label: 'Video',
                  color: Colors.pink,
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndSendVideo();
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement camera capture
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Camera feature coming soon')),
                    );
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.mic,
                  label: 'Voice',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _isRecordingVoice = true;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.insert_drive_file,
                  label: 'Document',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndSendDocument();
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.location_on,
                  label: 'Location',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement location sharing
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Location sharing coming soon')),
                    );
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.person,
                  label: 'Contact',
                  color: Colors.indigo,
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement contact sharing
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Contact sharing coming soon')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color labelColor = isDarkMode ? colorScheme.onSurfaceVariant : Colors.grey[800]!;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
} 