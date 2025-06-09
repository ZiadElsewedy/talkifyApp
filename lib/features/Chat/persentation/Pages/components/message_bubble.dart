import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:talkifyapp/features/Chat/domain/entite/message.dart';
import 'package:talkifyapp/features/Chat/persentation/Cubits/chat_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/components/SharedPostPreview.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/user_profile_page.dart';
import 'package:talkifyapp/features/Posts/PostComponents/PostTile..dart';
import 'package:talkifyapp/features/Posts/domain/Entite/Posts.dart';
import 'package:talkifyapp/features/Posts/presentation/cubits/post_cubit.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/components/video_message_player.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/components/fullscreen_video_player.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isFromCurrentUser;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isFromCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isFromCurrentUser 
        ? Colors.white 
        : (isDarkMode ? Colors.white : Colors.black87);
    
    // Special handling for system messages
    if (message.isSystemMessage) {
      return _buildSystemMessage(context, isDarkMode);
    }
    
    return GestureDetector(
      onLongPress: () => _showMessageOptions(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: isFromCurrentUser 
              ? MainAxisAlignment.end 
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar for other users
            if (!isFromCurrentUser) ...[
              GestureDetector(
                onTap: () => _openUserProfile(context),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  backgroundImage: message.senderAvatar.isNotEmpty
                      ? CachedNetworkImageProvider(message.senderAvatar)
                      : null,
                  child: message.senderAvatar.isEmpty
                      ? Text(
                          message.senderName.isNotEmpty 
                              ? message.senderName[0].toUpperCase() 
                              : 'U',
                          style: TextStyle(
                            fontSize: 12, 
                            color: isDarkMode ? Colors.white : Colors.black
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 8),
            ],
            
            // Message bubble
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isFromCurrentUser
                      ? (isDarkMode ? Colors.blue.shade800 : Colors.black)
                      : (isDarkMode ? Colors.grey[800] : Colors.grey[300]),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: isFromCurrentUser 
                        ? const Radius.circular(16) 
                        : const Radius.circular(4),
                    bottomRight: isFromCurrentUser 
                        ? const Radius.circular(4) 
                        : const Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sender name for group chats
                    if (!isFromCurrentUser && message.senderName.isNotEmpty)
                      GestureDetector(
                        onTap: () => _openUserProfile(context),
                        child: Text(
                          message.senderName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    
                    if (!isFromCurrentUser && message.senderName.isNotEmpty)
                      const SizedBox(height: 4),
                    
                    // Message content
                    _buildMessageContent(context, textColor),
                    
                    // Timestamp and status
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeago.format(message.timestamp),
                          style: TextStyle(
                            fontSize: 10,
                            color: isFromCurrentUser
                                ? Colors.white.withOpacity(0.7)
                                : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                          ),
                        ),
                        
                        // Message status for current user
                        if (isFromCurrentUser) ...[
                          const SizedBox(width: 4),
                          _buildStatusIcon(context),
                        ],
                        
                        // Edited indicator
                        if (message.isEdited) ...[
                          const SizedBox(width: 4),
                          Text(
                            'edited',
                            style: TextStyle(
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                              color: isFromCurrentUser
                                  ? Colors.white.withOpacity(0.7)
                                  : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Spacer for current user messages
            if (isFromCurrentUser) const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
  
  // Build system message (centered, gray, italic)
  Widget _buildSystemMessage(BuildContext context, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.content,
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                timeago.format(message.timestamp),
                style: TextStyle(
                  fontSize: 10,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openUserProfile(BuildContext context) {
    if (isFromCurrentUser) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfilePage(
          userId: message.senderId,
          userName: message.senderName,
          initialAvatarUrl: message.senderAvatar,
        ),
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Message Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isFromCurrentUser)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete message for everyone'),
                subtitle: const Text('Removes from database permanently'),
                onTap: () {
                  Navigator.of(context).pop();
                  _confirmDeleteMessage(context);
                },
              ),
            if (message.type == MessageType.image)
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('View image'),
                onTap: () {
                  Navigator.of(context).pop();
                  if (message.fileUrl != null) {
                    _showFullScreenImage(context, message.fileUrl!);
                  }
                },
              ),
            if (message.type == MessageType.video)
              ListTile(
                leading: const Icon(Icons.video_library_outlined),
                title: const Text('Watch video'),
                onTap: () {
                  Navigator.of(context).pop();
                  if (message.fileUrl != null) {
                    _openFullscreenVideo(context, message.fileUrl!, message.fileName);
                  }
                },
              ),
            if (message.type == MessageType.text)
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy text'),
                onTap: () {
                  Navigator.of(context).pop();
                  // Copy functionality would go here
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteMessage(BuildContext context) {
    // Store message ID locally to avoid widget reference issues
    final String messageId = message.id;
    
    // Store a reference to the cubit to avoid context issues later
    final chatCubit = context.read<ChatCubit>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message? It will be permanently removed for everyone and cannot be recovered.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              
              // Use stored references instead of accessing widget or context
              chatCubit.deleteMessage(messageId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text('Image', style: TextStyle(color: Colors.white)),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.error,
                  color: Colors.white,
                  size: 50,
                ),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, Color textColor) {
    // Check if this is a shared post message
    bool isSharedPost = message.replyToMessageId != null && 
                        message.replyToMessageId!.startsWith("post:") &&
                        (message.metadata != null && message.metadata!['sharedType'] == 'post');
    
    // Handle shared post that includes video (direct sharing with video)
    if (message.type == MessageType.video && message.metadata != null && message.metadata!['sharedType'] == 'post') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message caption
          if (message.content.isNotEmpty && message.content != message.fileName)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                message.content,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor,
                ),
              ),
            ),
          
          // Video player
          if (message.fileUrl != null)
            VideoMessagePlayer(
              videoUrl: message.fileUrl!,
              isCurrentUser: isFromCurrentUser,
              caption: null, // Don't show duplicate caption
              timestamp: message.timestamp,
            ),
          
          // Compact post info footer
          Container(
            margin: EdgeInsets.only(top: 6),
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isFromCurrentUser ? Colors.black.withOpacity(0.2) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_circle,
                  size: 12,
                  color: isFromCurrentUser ? Colors.white70 : Colors.grey.shade700,
                ),
                SizedBox(width: 4),
                Text(
                  message.metadata!['postUserName'] ?? 'Post',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isFromCurrentUser ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    
    // Handle shared post that includes image (direct sharing with image)
    if (message.type == MessageType.image && message.metadata != null && message.metadata!['sharedType'] == 'post') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message caption
          if (message.content.isNotEmpty && message.content != message.fileName)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                message.content,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor,
                ),
              ),
            ),
          
          // Post image
          if (message.fileUrl != null)
            GestureDetector(
              onTap: () => _showFullScreenImage(context, message.fileUrl!),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: 250,
                  maxWidth: 300,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: message.fileUrl!,
                    placeholder: (context, url) => Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: const Icon(Icons.error),
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          
          // Compact post info footer
          Container(
            margin: EdgeInsets.only(top: 6),
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isFromCurrentUser ? Colors.black.withOpacity(0.2) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_circle,
                  size: 12,
                  color: isFromCurrentUser ? Colors.white70 : Colors.grey.shade700,
                ),
                SizedBox(width: 4),
                Text(
                  message.metadata!['postUserName'] ?? 'Post',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isFromCurrentUser ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    
    // Handle shared post as text message with SharedPostPreview (old method)
    if (message.replyToMessageId != null && message.replyToMessageId!.startsWith("post:")) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show the message text first
          Text(
            message.content,
            style: TextStyle(
              fontSize: 16,
              color: textColor,
            ),
          ),
          
          // Show the shared post preview
          SizedBox(height: 8),
          SharedPostPreview(
            postId: message.replyToMessageId!,
            onTap: () async {
              // Extract post ID
              String postId = message.replyToMessageId!;
              if (postId.startsWith("post:")) {
                postId = postId.substring(5);
              }
              
              // Get post and show in a dialog
              try {
                final postCubit = context.read<PostCubit>();
                final post = await postCubit.getPostById(postId);
                
                if (post != null) {
                  _showPostDialog(context, post);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to load post: $e')),
                );
              }
            },
          ),
        ],
      );
    }
    
    // Handle regular message types
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: TextStyle(
            fontSize: 16,
            color: textColor,
          ),
        );
      
      case MessageType.image:
        return _buildImageMessage(context, textColor);
      
      case MessageType.video:
        return _buildVideoMessage(context, textColor);
      
      case MessageType.audio:
        return _buildAudioMessage(context, textColor);
      
      case MessageType.file:
        return _buildFileMessage(context, textColor);
      
      default:
        return Text(
          message.content,
          style: TextStyle(
            fontSize: 16,
            color: textColor,
          ),
        );
    }
  }

  void _showPostDialog(BuildContext context, Post post) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with close button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      Text(
                        'Shared Post',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Divider(),
                // Post tile in a scrollable container
                Flexible(
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    child: PostTile(post: post),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageMessage(BuildContext context, Color textColor) {
    // Check if this is a shared post image
    bool isSharedPost = message.metadata != null && message.metadata!['sharedType'] == 'post';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.fileUrl != null)
          GestureDetector(
            onTap: isSharedPost 
                ? () async {
                    // Extract post ID
                    String postId = '';
                    if (message.replyToMessageId != null && message.replyToMessageId!.startsWith("post:")) {
                      postId = message.replyToMessageId!.substring(5);
                    } else if (message.metadata != null && message.metadata!['postId'] != null) {
                      postId = message.metadata!['postId'];
                    }
                    
                    if (postId.isNotEmpty) {
                      // Get post and show in a dialog
                      try {
                        final postCubit = context.read<PostCubit>();
                        final post = await postCubit.getPostById(postId);
                        
                        if (post != null) {
                          _showPostDialog(context, post);
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to load post: $e')),
                        );
                      }
                    } else {
                      // If can't determine post ID, just show the image
                      _showFullScreenImage(context, message.fileUrl!);
                    }
                  }
                : () => _showFullScreenImage(context, message.fileUrl!),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: message.fileUrl!,
                placeholder: (context, url) => Container(
                  height: 200,
                  width: 200,
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  width: 200,
                  color: Colors.grey[300],
                  child: const Icon(Icons.error),
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
        
        if (message.content.isNotEmpty && message.content != message.fileName)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              message.content,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
              ),
            ),
          ),
      ],
    );
  }

  void _openFullscreenVideo(BuildContext context, String videoUrl, String? title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullscreenVideoPlayer(
          videoUrl: videoUrl,
          title: title,
        ),
      ),
    );
  }
  
  Widget _buildVideoMessage(BuildContext context, Color textColor) {
    // Check if video URL is available
    if (message.fileUrl != null) {
      return GestureDetector(
        onTap: () => _openFullscreenVideo(context, message.fileUrl!, message.fileName),
        child: VideoMessagePlayer(
          videoUrl: message.fileUrl!,
          isCurrentUser: isFromCurrentUser,
          caption: message.content != message.fileName ? message.content : null,
          timestamp: message.timestamp,
        ),
      );
    }
    
    // Fallback if no video URL is available
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isFromCurrentUser 
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.play_circle_filled,
                color: isFromCurrentUser ? Colors.white : Colors.black,
                size: 32,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.fileName ?? 'Video',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isFromCurrentUser
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                    if (message.fileSize != null)
                      Text(
                        _formatFileSize(message.fileSize!),
                        style: TextStyle(
                          fontSize: 12,
                          color: isFromCurrentUser
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        if (message.content.isNotEmpty && message.content != message.fileName)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              message.content,
              style: TextStyle(
                fontSize: 14,
                color: isFromCurrentUser
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAudioMessage(BuildContext context, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isFromCurrentUser 
            ? Colors.black.withOpacity(0.2)
            : Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.audiotrack,
            color: isFromCurrentUser ? Colors.white : Colors.black,
            size: 24,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.fileName ?? 'Audio',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isFromCurrentUser
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
                if (message.fileSize != null)
                  Text(
                    _formatFileSize(message.fileSize!),
                    style: TextStyle(
                      fontSize: 12,
                      color: isFromCurrentUser
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileMessage(BuildContext context, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isFromCurrentUser 
            ? Colors.black.withOpacity(0.2)
            : Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.attach_file,
            color: isFromCurrentUser ? Colors.white : Colors.black,
            size: 24,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.fileName ?? 'File',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isFromCurrentUser
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
                if (message.fileSize != null)
                  Text(
                    _formatFileSize(message.fileSize!),
                    style: TextStyle(
                      fontSize: 12,
                      color: isFromCurrentUser
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(BuildContext context) {
    switch (message.status) {
      case MessageStatus.sending:
        return const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
      
      case MessageStatus.sent:
        return const Icon(
          Icons.check,
          size: 12,
          color: Colors.white,
        );
      
      case MessageStatus.delivered:
        return const Icon(
          Icons.done_all,
          size: 12,
          color: Colors.white,
        );
      
      case MessageStatus.read:
        return Icon(
          Icons.done_all,
          size: 12,
          color: Colors.blue[300],
        );
      
      case MessageStatus.failed:
        return const Icon(
          Icons.error_outline,
          size: 12,
          color: Colors.red,
        );
      
      default:
        return const SizedBox.shrink();
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    int i = (bytes.bitLength - 1) ~/ 10;
    return '${(bytes / (1 << (i * 10))).toStringAsFixed(1)} ${suffixes[i]}';
  }
} 