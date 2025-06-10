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
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/document_viewer_page.dart';

class MessageBubble extends StatefulWidget {
  final Message message;
  final bool isFromCurrentUser;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isFromCurrentUser,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = widget.isFromCurrentUser 
        ? Colors.white 
        : (isDarkMode ? Colors.white : Colors.black87);
    
    // Special handling for system messages
    if (widget.message.isSystemMessage) {
      return _buildSystemMessage(context, isDarkMode);
    }
    
    return GestureDetector(
      onLongPress: () => _showMessageOptions(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: widget.isFromCurrentUser 
              ? MainAxisAlignment.end 
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar for other users
            if (!widget.isFromCurrentUser) ...[
              GestureDetector(
                onTap: () => _openUserProfile(context),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  backgroundImage: widget.message.senderAvatar.isNotEmpty
                      ? CachedNetworkImageProvider(widget.message.senderAvatar)
                      : null,
                  child: widget.message.senderAvatar.isEmpty
                      ? Text(
                          widget.message.senderName.isNotEmpty 
                              ? widget.message.senderName[0].toUpperCase() 
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
                  color: widget.isFromCurrentUser
                      ? (isDarkMode ? Colors.blue.shade800 : Colors.black)
                      : (isDarkMode ? Colors.grey[800] : Colors.grey[300]),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: widget.isFromCurrentUser 
                        ? const Radius.circular(16) 
                        : const Radius.circular(4),
                    bottomRight: widget.isFromCurrentUser 
                        ? const Radius.circular(4) 
                        : const Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sender name for group chats
                    if (!widget.isFromCurrentUser && widget.message.senderName.isNotEmpty)
                      GestureDetector(
                        onTap: () => _openUserProfile(context),
                        child: Text(
                          widget.message.senderName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    
                    if (!widget.isFromCurrentUser && widget.message.senderName.isNotEmpty)
                      const SizedBox(height: 4),
                    
                    // Message content
                    _buildMessageContent(context, textColor),
                    
                    // Timestamp and status
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeago.format(widget.message.timestamp),
                          style: TextStyle(
                            fontSize: 10,
                            color: widget.isFromCurrentUser
                                ? Colors.white.withOpacity(0.7)
                                : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                          ),
                        ),
                        
                        // Message status for current user
                        if (widget.isFromCurrentUser) ...[
                          const SizedBox(width: 4),
                          _buildStatusIcon(context),
                        ],
                        
                        // Edited indicator
                        if (widget.message.isEdited) ...[
                          const SizedBox(width: 4),
                          Text(
                            'edited',
                            style: TextStyle(
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                              color: widget.isFromCurrentUser
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
            if (widget.isFromCurrentUser) const SizedBox(width: 8),
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
                widget.message.content,
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                timeago.format(widget.message.timestamp),
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
    if (widget.isFromCurrentUser) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfilePage(
          userId: widget.message.senderId,
          userName: widget.message.senderName,
          initialAvatarUrl: widget.message.senderAvatar,
        ),
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey[850] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.message.type == MessageType.image)
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: textColor),
                title: Text('View image', style: TextStyle(color: textColor)),
                onTap: () {
                  Navigator.of(context).pop();
                  if (widget.message.fileUrl != null) {
                    _showFullScreenImage(context, widget.message.fileUrl!);
                  }
                },
              ),
              
            if (widget.message.type == MessageType.video)
              ListTile(
                leading: Icon(Icons.video_library_outlined, color: textColor),
                title: Text('Watch video', style: TextStyle(color: textColor)),
                onTap: () {
                  Navigator.of(context).pop();
                  if (widget.message.fileUrl != null) {
                    _openFullscreenVideo(context, widget.message.fileUrl!, widget.message.fileName);
                  }
                },
              ),
              
            if (widget.message.type == MessageType.file || widget.message.type == MessageType.document)
              ListTile(
                leading: Icon(Icons.open_in_new, color: textColor),
                title: Text('Open file', style: TextStyle(color: textColor)),
                onTap: () {
                  Navigator.of(context).pop();
                  if (widget.message.fileUrl != null) {
                    _openFile(widget.message.fileUrl!);
                  }
                },
              ),
              
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red),
              title: Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.of(context).pop();
                // Delete functionality using the correct method signature
                context.read<ChatCubit>().deleteMessage(widget.message.id);
              },
            ),
          ],
        ),
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
    bool isSharedPost = widget.message.replyToMessageId != null && 
                        widget.message.replyToMessageId!.startsWith("post:") &&
                        (widget.message.metadata != null && widget.message.metadata!['sharedType'] == 'post');
    
    // Handle shared post that includes video (direct sharing with video)
    if (widget.message.type == MessageType.video && widget.message.metadata != null && widget.message.metadata!['sharedType'] == 'post') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message caption
          if (widget.message.content.isNotEmpty && widget.message.content != widget.message.fileName)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                widget.message.content,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor,
                ),
              ),
            ),
          
          // Video player
          if (widget.message.fileUrl != null)
            VideoMessagePlayer(
              videoUrl: widget.message.fileUrl!,
              isCurrentUser: widget.isFromCurrentUser,
              caption: null, // Don't show duplicate caption
              timestamp: widget.message.timestamp,
            ),
          
          // Compact post info footer
          Container(
            margin: EdgeInsets.only(top: 6),
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: widget.isFromCurrentUser ? Colors.black.withOpacity(0.2) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_circle,
                  size: 12,
                  color: widget.isFromCurrentUser ? Colors.white70 : Colors.grey.shade700,
                ),
                SizedBox(width: 4),
                Text(
                  widget.message.metadata!['postUserName'] ?? 'Post',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: widget.isFromCurrentUser ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    
    // Handle shared post that includes image (direct sharing with image)
    if (widget.message.type == MessageType.image && widget.message.metadata != null && widget.message.metadata!['sharedType'] == 'post') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message caption
          if (widget.message.content.isNotEmpty && widget.message.content != widget.message.fileName)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                widget.message.content,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor,
                ),
              ),
            ),
          
          // Post image
          if (widget.message.fileUrl != null)
            GestureDetector(
              onTap: () => _showFullScreenImage(context, widget.message.fileUrl!),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: 250,
                  maxWidth: 300,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: widget.message.fileUrl!,
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
              color: widget.isFromCurrentUser ? Colors.black.withOpacity(0.2) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_circle,
                  size: 12,
                  color: widget.isFromCurrentUser ? Colors.white70 : Colors.grey.shade700,
                ),
                SizedBox(width: 4),
                Text(
                  widget.message.metadata!['postUserName'] ?? 'Post',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: widget.isFromCurrentUser ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    
    // Handle shared post as text message with SharedPostPreview (old method)
    if (widget.message.replyToMessageId != null && widget.message.replyToMessageId!.startsWith("post:")) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show the message text first
          Text(
            widget.message.content,
            style: TextStyle(
              fontSize: 16,
              color: textColor,
            ),
          ),
          
          // Show the shared post preview
          SizedBox(height: 8),
          SharedPostPreview(
            postId: widget.message.replyToMessageId!,
            onTap: () async {
              // Extract post ID
              String postId = widget.message.replyToMessageId!;
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
    switch (widget.message.type) {
      case MessageType.text:
        return Text(
          widget.message.content,
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
          widget.message.content,
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
    bool isSharedPost = widget.message.metadata != null && widget.message.metadata!['sharedType'] == 'post';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.message.fileUrl != null)
          GestureDetector(
            onTap: isSharedPost 
                ? () async {
                    // Extract post ID
                    String postId = '';
                    if (widget.message.replyToMessageId != null && widget.message.replyToMessageId!.startsWith("post:")) {
                      postId = widget.message.replyToMessageId!.substring(5);
                    } else if (widget.message.metadata != null && widget.message.metadata!['postId'] != null) {
                      postId = widget.message.metadata!['postId'];
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
                      _showFullScreenImage(context, widget.message.fileUrl!);
                    }
                  }
                : () => _showFullScreenImage(context, widget.message.fileUrl!),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: widget.message.fileUrl!,
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
        
        if (widget.message.content.isNotEmpty && widget.message.content != widget.message.fileName)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              widget.message.content,
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
          title: title ?? 'Video',
        ),
      ),
    );
  }
  
  Widget _buildVideoMessage(BuildContext context, Color textColor) {
    // Check if video URL is available
    if (widget.message.fileUrl != null) {
      return GestureDetector(
        onTap: () => _openFullscreenVideo(context, widget.message.fileUrl!, widget.message.fileName),
        child: VideoMessagePlayer(
          videoUrl: widget.message.fileUrl!,
          isCurrentUser: widget.isFromCurrentUser,
          caption: widget.message.content != widget.message.fileName ? widget.message.content : null,
          timestamp: widget.message.timestamp,
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
            color: widget.isFromCurrentUser 
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.play_circle_filled,
                color: widget.isFromCurrentUser ? Colors.white : Colors.black,
                size: 32,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.message.fileName ?? 'Video',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: widget.isFromCurrentUser
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                    if (widget.message.fileSize != null)
                      Text(
                        _formatFileSize(widget.message.fileSize!),
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.isFromCurrentUser
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
        
        if (widget.message.content.isNotEmpty && widget.message.content != widget.message.fileName)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              widget.message.content,
              style: TextStyle(
                fontSize: 14,
                color: widget.isFromCurrentUser
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
        color: widget.isFromCurrentUser 
            ? Colors.black.withOpacity(0.2)
            : Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.audiotrack,
            color: widget.isFromCurrentUser ? Colors.white : Colors.black,
            size: 24,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.message.fileName ?? 'Audio',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: widget.isFromCurrentUser
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
                if (widget.message.fileSize != null)
                  Text(
                    _formatFileSize(widget.message.fileSize!),
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.isFromCurrentUser
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
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    
    // Extract file extension
    String extension = '';
    if (widget.message.fileName != null && widget.message.fileName!.contains('.')) {
      extension = widget.message.fileName!.split('.').last.toLowerCase();
    }
    
    // Determine file type icon
    IconData fileIcon = Icons.insert_drive_file;
    Color iconColor = Colors.blue;
    
    if (widget.message.fileName != null) {
      if (extension == 'pdf') {
        fileIcon = Icons.picture_as_pdf;
        iconColor = Colors.red;
      } else if (extension == 'doc' || extension == 'docx') {
        fileIcon = Icons.description;
        iconColor = Colors.blue;
      } else if (extension == 'xls' || extension == 'xlsx') {
        fileIcon = Icons.table_chart;
        iconColor = Colors.green;
      } else if (extension == 'ppt' || extension == 'pptx') {
        fileIcon = Icons.slideshow;
        iconColor = Colors.orange;
      } else if (extension == 'zip' || extension == 'rar') {
        fileIcon = Icons.archive;
        iconColor = Colors.brown;
      } else if (extension == 'txt') {
        fileIcon = Icons.text_snippet;
        iconColor = Colors.grey;
      }
    }
    
    return GestureDetector(
      onTap: () {
        if (widget.message.fileUrl != null) {
          _openFile(widget.message.fileUrl!);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDarkMode 
              ? colorScheme.surfaceVariant.withOpacity(0.5)
              : Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode 
                ? colorScheme.primary.withOpacity(0.1) 
                : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // File icon with colored background
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                fileIcon,
                color: iconColor,
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.message.fileName ?? 'File',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (widget.message.fileSize != null)
                    Text(
                      _formatFileSize(widget.message.fileSize!),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode 
                            ? Colors.grey[400] 
                            : Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.file_download_outlined,
                size: 16,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(BuildContext context) {
    switch (widget.message.status) {
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

  Future<void> _openFile(String fileUrl) async {
    try {
      final Uri url = Uri.parse(fileUrl);
      
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Opening file...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // Check file extension from fileName
      String extension = '';
      if (widget.message.fileName != null && widget.message.fileName!.contains('.')) {
        extension = widget.message.fileName!.split('.').last.toLowerCase();
      }
      
      // Specifically handle PDFs and documents
      if ((extension == 'pdf' || widget.message.type == MessageType.document) && 
          widget.message.fileName != null) {
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DocumentViewerPage(
              documentUrl: fileUrl,
              fileName: widget.message.fileName!,
            ),
          ),
        );
        return;
      }
      
      // For other files, try to open with external app
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // If can't launch directly, show error message with download option
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cannot open this file type directly'),
            action: SnackBarAction(
              label: 'DOWNLOAD',
              onPressed: () => _downloadFile(fileUrl, widget.message.fileName ?? 'download'),
            ),
          ),
        );
      }
    } catch (e) {
      // Handle errors
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening file: $e')),
      );
    }
  }
  
  Future<void> _downloadFile(String fileUrl, String fileName) async {
    try {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission required to download files')),
        );
        return;
      }
      
      // Show download in progress message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Starting download...')),
      );
      
      // Let external apps handle the download (browser or download manager)
      final Uri url = Uri.parse(fileUrl);
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading file: $e')),
      );
    }
  }
} 