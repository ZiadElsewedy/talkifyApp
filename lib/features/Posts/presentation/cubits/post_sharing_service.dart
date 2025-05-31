import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Posts/domain/Entite/Posts.dart';
import 'package:talkifyapp/features/Chat/persentation/Cubits/chat_cubit.dart';
import 'package:talkifyapp/features/Chat/persentation/Cubits/chat_states.dart';
import 'package:talkifyapp/features/Chat/domain/entite/message.dart';
import 'package:talkifyapp/features/Chat/domain/entite/chat_room.dart';
import 'package:talkifyapp/features/auth/domain/entities/AppUser.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:talkifyapp/features/Posts/presentation/cubits/post_cubit.dart';

class PostSharingService {
  // Store recent recipients in memory for this session
  static List<String> _recentRecipients = [];
  static const int _maxRecentRecipients = 5;
  
  /// Share a post to a chat room
  static Future<void> sharePostToChat({
    required BuildContext context,
    required Post post,
    required String chatRoomId,
    required AppUser currentUser,
    String? customMessage,
  }) async {
    try {
      final chatCubit = context.read<ChatCubit>();
      final postCubit = context.read<PostCubit>();
      
      // Create a formatted message with post details
      final formattedMessage = customMessage != null && customMessage.isNotEmpty
          ? customMessage
          : 'Check out this post from ${post.UserName}';
      
      // Create metadata for the post details
      final postMetadata = {
        'postId': post.id,
        'postUserId': post.UserId,
        'postUserName': post.UserName,
        'postUserProfilePic': post.UserProfilePic,
        'postText': post.Text,
        'postTimestamp': post.timestamp.millisecondsSinceEpoch,
        'sharedType': 'post',
      };
      
      if (post.imageUrl.isNotEmpty) {
        // If the post has an image, send it as an image message type with direct URL
        await chatCubit.sendMediaUrlMessage(
          chatRoomId: chatRoomId,
          senderId: currentUser.id,
          senderName: currentUser.name,
          senderAvatar: currentUser.profilePictureUrl,
          mediaUrl: post.imageUrl,
          displayName: 'Post from ${post.UserName}',
          type: MessageType.image,
          content: formattedMessage,
          replyToMessageId: "post:${post.id}",
          metadata: postMetadata,
        );
      } else {
        // If no image, send as a text message with post reference
        await chatCubit.sendTextMessage(
          chatRoomId: chatRoomId,
          senderId: currentUser.id,
          senderName: currentUser.name,
          senderAvatar: currentUser.profilePictureUrl,
          content: formattedMessage,
          replyToMessageId: "post:${post.id}",
        );
      }
      
      // Save this recipient as recent
      _addRecentRecipient(chatRoomId);
      
      // Increment share count for the post
      await postCubit.incrementShareCount(post.id);
      
    } catch (e) {
      print('Error sharing post: $e');
      throw Exception('Failed to share post: $e');
    }
  }
  
  /// Show chat selection dialog to choose where to share the post
  static Future<void> showChatSelectionDialog({
    required BuildContext context,
    required Post post,
    required AppUser currentUser,
  }) async {
    final chatCubit = context.read<ChatCubit>();
    
    // Load user's chat rooms if not already loaded
    if (chatCubit.state is! ChatRoomsLoaded) {
      await chatCubit.loadUserChatRooms(currentUser.id);
    }
    
    // Show dialog to select chat
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EnhancedShareSheet(
        post: post,
        currentUser: currentUser,
      ),
    );
  }
  
  /// Add a chatroom to recent recipients list
  static void _addRecentRecipient(String chatRoomId) {
    // Remove if already exists to avoid duplicates
    _recentRecipients.remove(chatRoomId);
    
    // Add to beginning of list
    _recentRecipients.insert(0, chatRoomId);
    
    // Keep only the most recent 5
    if (_recentRecipients.length > _maxRecentRecipients) {
      _recentRecipients = _recentRecipients.sublist(0, _maxRecentRecipients);
    }
  }
  
  /// Get list of recent recipients
  static List<String> getRecentRecipients() {
    return List.from(_recentRecipients);
  }
}

class _EnhancedShareSheet extends StatefulWidget {
  final Post post;
  final AppUser currentUser;
  
  const _EnhancedShareSheet({
    required this.post,
    required this.currentUser,
  });
  
  @override
  _EnhancedShareSheetState createState() => _EnhancedShareSheetState();
}

class _EnhancedShareSheetState extends State<_EnhancedShareSheet> with SingleTickerProviderStateMixin {
  String? selectedChatRoomId;
  TextEditingController messageController = TextEditingController();
  TextEditingController searchController = TextEditingController();
  late List<String> recentRecipientIds;
  bool isSearching = false;
  String searchQuery = '';
  TabController? _tabController;
  bool isSending = false;
  
  // Tab indices
  static const int _allChatsTab = 0;
  static const int _recentTab = 1;
  static const int _groupsTab = 2;
  
  @override
  void initState() {
    super.initState();
    // Set default message
    messageController.text = 'Check out this post from ${widget.post.UserName}';
    
    // Get recent recipients
    recentRecipientIds = PostSharingService.getRecentRecipients();
    
    // Initialize tab controller
    _tabController = TabController(length: 3, vsync: this);
    _tabController!.addListener(() {
      // Clear search when changing tabs
      if (isSearching) {
        setState(() {
          searchController.clear();
          searchQuery = '';
          isSearching = false;
        });
      }
    });
  }
  
  @override
  void dispose() {
    messageController.dispose();
    searchController.dispose();
    _tabController?.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    // Calculate appropriate height for the bottom sheet
    final sheetHeight = keyboardVisible 
        ? screenHeight * 0.65  // Reduced height when keyboard is visible
        : screenHeight * 0.7;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      // Use constraints instead of fixed height to allow content to determine size
      constraints: BoxConstraints(
        maxHeight: sheetHeight,
        minHeight: screenHeight * 0.3, // Ensure minimum height
      ),
      child: SafeArea(
        // Only apply bottom padding
        top: false,
        child: Stack(
          children: [
            // Main content
            Column(
              mainAxisSize: MainAxisSize.min, // Use minimum space required
              children: [
                // Drag handle
                Container(
                  margin: EdgeInsets.only(top: 8),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Share Post',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Select where to share this post',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                
                // Main scrollable content
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      // Post preview
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile picture
                            CircleAvatar(
                              radius: 18,
                              backgroundImage: widget.post.UserProfilePic.isNotEmpty
                                  ? CachedNetworkImageProvider(widget.post.UserProfilePic)
                                  : null,
                              backgroundColor: Colors.grey.shade300,
                              child: widget.post.UserProfilePic.isEmpty
                                  ? Text(
                                      widget.post.UserName[0].toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    )
                                  : null,
                            ),
                            SizedBox(width: 12),
                            // Post details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.post.UserName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        timeago.format(widget.post.timestamp),
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  if (widget.post.Text.isNotEmpty)
                                    Text(
                                      widget.post.Text,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  if (widget.post.imageUrl.isNotEmpty) ...[
                                    SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        height: 160, // Increased height from 80 to 160
                                        width: double.infinity,
                                        color: Colors.grey.shade200,
                                        child: CachedNetworkImage(
                                          imageUrl: widget.post.imageUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.black,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          errorWidget: (context, url, error) => Icon(
                                            Icons.error_outline,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Custom message input
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: messageController,
                                decoration: InputDecoration(
                                  hintText: 'Add a message...',
                                  hintStyle: TextStyle(color: Colors.grey.shade400),
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  prefixIcon: Icon(Icons.message_outlined, color: Colors.grey.shade600),
                                ),
                                maxLines: 1,
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Tab bar for filters
                      TabBar(
                        controller: _tabController,
                        labelColor: Colors.black,
                        unselectedLabelColor: Colors.grey.shade600,
                        indicatorColor: Colors.black,
                        indicatorWeight: 2,
                        labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        tabs: [
                          Tab(text: 'All Chats'),
                          Tab(text: 'Recent'),
                          Tab(text: 'Groups'),
                        ],
                      ),
                      
                      // Search bar
                      AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        margin: EdgeInsets.fromLTRB(16, 8, 16, 8),
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: searchController,
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value.trim().toLowerCase();
                              isSearching = searchQuery.isNotEmpty;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.search, color: Colors.grey.shade600, size: 20),
                            suffixIcon: isSearching
                                ? IconButton(
                                    icon: Icon(Icons.clear, color: Colors.grey.shade600, size: 18),
                                    onPressed: () {
                                      searchController.clear();
                                      setState(() {
                                        searchQuery = '';
                                        isSearching = false;
                                      });
                                      // Hide keyboard when clearing search
                                      FocusScope.of(context).unfocus();
                                    },
                                  )
                                : null,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      
                      // Chat list container - FIXED HEIGHT to prevent overflow
                      Container(
                        height: keyboardVisible ? 180 : 250, // Fixed height when keyboard is showing
                        child: TabBarView(
                          controller: _tabController,
                          physics: AlwaysScrollableScrollPhysics(),
                          children: [
                            // All chats tab
                            _buildChatList(context, (chatRooms) => chatRooms),
                            
                            // Recent tab
                            _buildChatList(
                              context, 
                              (chatRooms) => chatRooms
                                  .where((room) => recentRecipientIds.contains(room.id))
                                  .toList(),
                            ),
                            
                            // Groups tab
                            _buildChatList(
                              context, 
                              (chatRooms) => chatRooms
                                  .where((room) => room.isGroupChat)
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Action buttons - This stays outside the scroll view
                AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  padding: EdgeInsets.only(
                    left: 16, 
                    right: 16, 
                    top: 16,
                    bottom: keyboardVisible ? 8 : 16 + bottomPadding
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Cancel button
                      TextButton.icon(
                        onPressed: () {
                          // Hide keyboard before closing
                          FocusScope.of(context).unfocus();
                          Navigator.pop(context);
                        },
                        icon: Icon(Icons.close, size: 18),
                        label: Text('Cancel'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                        ),
                      ),
                      
                      // Share button
                      ElevatedButton.icon(
                        onPressed: selectedChatRoomId == null || isSending
                            ? null
                            : () async {
                                // Hide keyboard first
                                FocusScope.of(context).unfocus();
                                
                                setState(() {
                                  isSending = true;
                                });
                                
                                try {
                                  await PostSharingService.sharePostToChat(
                                    context: context,
                                    post: widget.post,
                                    chatRoomId: selectedChatRoomId!,
                                    currentUser: widget.currentUser,
                                    customMessage: messageController.text.trim(),
                                  );
                                  
                                  Navigator.pop(context);
                                  
                                  // Show success indicator
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(Icons.check_circle, color: Colors.white),
                                          SizedBox(width: 12),
                                          Text('Post shared successfully'),
                                        ],
                                      ),
                                      backgroundColor: Colors.black,
                                      duration: Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  setState(() {
                                    isSending = false;
                                  });
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to share post: $e'),
                                      backgroundColor: Colors.red.shade600,
                                      duration: Duration(seconds: 3),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                }
                              },
                        icon: isSending
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Icon(Icons.send, size: 18),
                        label: Text(isSending ? 'Sharing...' : 'Share Post'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade500,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(
                            horizontal: 16, 
                            vertical: keyboardVisible ? 8 : 12
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Loading overlay
            if (isSending)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.1),
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Sharing post...',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildChatList(
    BuildContext context,
    List<ChatRoom> Function(List<ChatRoom>) filterFunction,
  ) {
    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, state) {
        if (state is ChatRoomsLoading) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: CircularProgressIndicator(color: Colors.black),
            ),
          );
        } else if (state is ChatRoomsLoaded) {
          List<ChatRoom> chatRooms = filterFunction(state.chatRooms);
          
          // Apply search filter if searching
          if (isSearching && searchQuery.isNotEmpty) {
            chatRooms = chatRooms.where((room) {
              // For 1-on-1 chats, search in other user's name
              if (room.participants.length == 2) {
                final otherUserId = room.participants
                    .firstWhere((id) => id != widget.currentUser.id, orElse: () => '');
                final otherUserName = room.participantNames[otherUserId] ?? '';
                return otherUserName.toLowerCase().contains(searchQuery);
              } else {
                // For group chats
                return "Group Chat".toLowerCase().contains(searchQuery);
              }
            }).toList();
          }
          
          if (chatRooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSearching ? Icons.search_off : Icons.chat_bubble_outline,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 16),
                  Text(
                    isSearching 
                        ? 'No chats match your search'
                        : 'No chats available',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    isSearching 
                        ? 'Try a different search term'
                        : 'Start a conversation first',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 8),
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final chatRoom = chatRooms[index];
              final isSelected = selectedChatRoomId == chatRoom.id;
              
              // Get chat name - for 1-on-1 chats, use other person's name
              String chatName = 'Chat';
              String? chatAvatar;
              
              if (chatRoom.participants.length == 2) {
                final otherUserId = chatRoom.participants
                    .firstWhere((id) => id != widget.currentUser.id, orElse: () => '');
                chatName = chatRoom.participantNames[otherUserId] ?? 'User';
                chatAvatar = chatRoom.participantAvatars[otherUserId];
              } else {
                // For group chats, use default name "Group Chat"
                chatName = chatRoom.isGroupChat ? "Group Chat" : "Chat";
              }
              
              // Check if this is a recent recipient
              final isRecent = recentRecipientIds.contains(chatRoom.id);
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.grey.shade200 : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: isSelected 
                              ? Colors.black 
                              : Colors.grey.shade300,
                          backgroundImage: chatAvatar != null && chatAvatar.isNotEmpty
                              ? CachedNetworkImageProvider(chatAvatar)
                              : null,
                          child: (chatAvatar == null || chatAvatar.isEmpty)
                              ? Icon(
                                  chatRoom.isGroupChat ? Icons.group : Icons.person,
                                  color: isSelected 
                                      ? Colors.white 
                                      : Colors.grey.shade600,
                                  size: 18,
                                )
                              : null,
                        ),
                        if (isRecent)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.history,
                                size: 12,
                                color: Colors.black,
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            chatName,
                            style: TextStyle(
                              fontWeight: isSelected 
                                  ? FontWeight.bold 
                                  : FontWeight.normal,
                              color: Colors.black87,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (chatRoom.isGroupChat)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Group',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: chatRoom.lastMessage != null
                        ? Text(
                            chatRoom.lastMessage!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          )
                        : null,
                    trailing: isSelected
                        ? Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          )
                        : null,
                    selected: isSelected,
                    onTap: () {
                      setState(() {
                        selectedChatRoomId = isSelected ? null : chatRoom.id;
                      });
                    },
                  ),
                ),
              );
            },
          );
        } else if (state is ChatRoomsError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red.shade300,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Error: ${state.message}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade400),
                  ),
                ],
              ),
            ),
          );
        }
        
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: CircularProgressIndicator(color: Colors.black),
          ),
        );
      },
    );
  }
} 