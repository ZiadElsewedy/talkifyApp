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

class PostSharingService {
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
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => _ChatSelectionDialog(
        post: post,
        currentUser: currentUser,
      ),
    );
  }
}

class _ChatSelectionDialog extends StatefulWidget {
  final Post post;
  final AppUser currentUser;
  
  const _ChatSelectionDialog({
    required this.post,
    required this.currentUser,
  });
  
  @override
  _ChatSelectionDialogState createState() => _ChatSelectionDialogState();
}

class _ChatSelectionDialogState extends State<_ChatSelectionDialog> {
  String? selectedChatRoomId;
  TextEditingController messageController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    // Set default message
    messageController.text = 'Check out this post from ${widget.post.UserName}';
  }
  
  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    
    return Dialog(
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(
          maxHeight: keyboardVisible ? screenHeight * 0.7 : screenHeight * 0.8,
          maxWidth: 500,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              decoration: BoxDecoration(
                color: Colors.black,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.share_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Share Post',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            ),
            
            // Main content in a scrollable area
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Post preview
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile picture
                          CircleAvatar(
                            radius: 20,
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
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  timeago.format(widget.post.timestamp),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(height: 8),
                                if (widget.post.Text.isNotEmpty)
                                  Text(
                                    widget.post.Text,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 14),
                                  ),
                                if (widget.post.imageUrl.isNotEmpty) ...[
                                  SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      height: 100, // Reduced height to save space
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Add a message',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: messageController,
                        decoration: InputDecoration(
                          hintText: 'Write a message...',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.black, width: 1.5),
                          ),
                          contentPadding: EdgeInsets.all(16),
                        ),
                        maxLines: 2, // Reduced to 2 lines max
                        minLines: 1, // Allow collapsing to 1 line
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                    
                    // Divider
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
                    ),
                    
                    // "Select chat" title
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Text(
                        'Select a chat',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    
                    // Chat list - using a fixed height container with ListView
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: keyboardVisible ? 150 : 250, // Adjust height based on keyboard
                      ),
                      child: BlocBuilder<ChatCubit, ChatState>(
                        builder: (context, state) {
                          if (state is ChatRoomsLoading) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: CircularProgressIndicator(color: Colors.black),
                              ),
                            );
                          } else if (state is ChatRoomsLoaded) {
                            final chatRooms = state.chatRooms;
                            
                            if (chatRooms.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.chat_bubble_outline,
                                        size: 48,
                                        color: Colors.grey.shade400,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'No chats available',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Start a conversation first',
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            
                            return ListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              shrinkWrap: true,
                              itemCount: chatRooms.length,
                              itemBuilder: (context, index) {
                                final chatRoom = chatRooms[index];
                                final isSelected = selectedChatRoomId == chatRoom.id;
                                
                                // Get chat name - for 1-on-1 chats, use other person's name
                                String chatName = 'Chat';
                                String? chatAvatar;
                                
                                if (chatRoom.participants.length == 2) {
                                  final otherUserId = chatRoom.participants
                                      .firstWhere((id) => id != widget.currentUser.id);
                                  chatName = chatRoom.participantNames[otherUserId] ?? 'User';
                                  chatAvatar = chatRoom.participantAvatars[otherUserId];
                                } else {
                                  // For group chats, use default name "Group Chat"
                                  chatName = chatRoom.isGroupChat ? "Group Chat" : "Chat";
                                }
                                
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: ListTile(
                                    dense: true, // Make list tiles more compact
                                    visualDensity: VisualDensity.compact,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    tileColor: isSelected ? Colors.grey.shade200 : null,
                                    leading: CircleAvatar(
                                      radius: 16, // Smaller avatar
                                      backgroundColor: isSelected 
                                          ? Colors.black 
                                          : Colors.grey.shade300,
                                      backgroundImage: chatAvatar != null && chatAvatar.isNotEmpty
                                          ? CachedNetworkImageProvider(chatAvatar)
                                          : null,
                                      child: (chatAvatar == null || chatAvatar.isEmpty)
                                          ? Icon(
                                              Icons.person,
                                              color: isSelected 
                                                  ? Colors.white 
                                                  : Colors.grey.shade600,
                                              size: 16,
                                            )
                                          : null,
                                    ),
                                    title: Text(
                                      chatName,
                                      style: TextStyle(
                                        fontWeight: isSelected 
                                            ? FontWeight.bold 
                                            : FontWeight.normal,
                                        color: Colors.black87,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: chatRoom.lastMessage != null
                                        ? Text(
                                            chatRoom.lastMessage!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          )
                                        : null,
                                    trailing: isSelected
                                        ? Icon(
                                            Icons.check_circle,
                                            color: Colors.black,
                                            size: 18,
                                          )
                                        : null,
                                    selected: isSelected,
                                    onTap: () {
                                      setState(() {
                                        selectedChatRoomId = chatRoom.id;
                                      });
                                    },
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
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Action buttons
            Container(
              padding: const EdgeInsets.all(16),
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
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Cancel button
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Smaller padding
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  // Share button
                  ElevatedButton(
                    onPressed: selectedChatRoomId == null
                        ? null
                        : () async {
                            try {
                              await PostSharingService.sharePostToChat(
                                context: context,
                                post: widget.post,
                                chatRoomId: selectedChatRoomId!,
                                currentUser: widget.currentUser,
                                customMessage: messageController.text.trim(),
                              );
                              Navigator.pop(context);
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade500,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Smaller padding
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Share',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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
} 