import 'dart:io';
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
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/document_viewer_page.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/components/audio_message_player.dart';

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
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
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
    // Check if audio URL is available
    if (widget.message.fileUrl != null) {
      return AudioMessagePlayer(
        message: widget.message,
        isCurrentUser: widget.isFromCurrentUser,
      );
    }
    
    // Fallback if no audio URL is available
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
    
    // Determine file type icon and color
    IconData fileIcon = Icons.insert_drive_file;
    Color iconColor = Colors.blue;
    bool isPdf = false;
    
    if (widget.message.fileName != null) {
      if (extension == 'pdf') {
        fileIcon = Icons.picture_as_pdf;
        iconColor = Colors.red;
        isPdf = true;
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
    
    void handleDocumentTap() {
      if (widget.message.fileUrl != null) {
        print("Tapped document: ${widget.message.fileName}");
        // Show feedback before opening
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening ${isPdf ? 'PDF' : 'document'}...'),
            duration: const Duration(seconds: 1),
          ),
        );
        
        // Adding a small delay to make tap feedback visible
        Future.delayed(const Duration(milliseconds: 150), () {
          _openFile(widget.message.fileUrl!);
        });
      }
    }
    
    return GestureDetector(
      onTap: handleDocumentTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: isDarkMode 
              ? const Color(0xFF1E1E1E) // Darker background for dark mode
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (!isDarkMode) // Only apply shadow in light mode
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
          border: Border.all(
            color: isPdf 
                ? (isDarkMode ? Colors.redAccent.withOpacity(0.6) : Colors.red.withOpacity(0.2))
                : (isDarkMode ? colorScheme.primary.withOpacity(0.5) : colorScheme.primary.withOpacity(0.2)),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: handleDocumentTap,
              splashColor: iconColor.withOpacity(0.1),
              highlightColor: iconColor.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Document icon with color background
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(isDarkMode ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        fileIcon,
                        color: iconColor,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.message.fileName ?? 'File',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
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
                              if (widget.message.fileSize != null)
                                const SizedBox(width: 8),
                              Text(
                                extension.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: iconColor.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isPdf ? Icons.visibility : Icons.open_in_new,
                        size: 20,
                        color: iconColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
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
                Text('Preparing document...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Get file extension and determine if it's a PDF
      String extension = '';
      if (widget.message.fileName != null && widget.message.fileName!.contains('.')) {
        extension = widget.message.fileName!.split('.').last.toLowerCase();
      }

      // Determine if this is a PDF document
      final String? fileExtension = widget.message.metadata?['fileExtension'] as String?;
      final bool isPdf = extension == 'pdf' || fileExtension == 'pdf' || 
                          (widget.message.fileName != null && widget.message.fileName!.toLowerCase().contains('.pdf'));
      
      print("Opening file: ${widget.message.fileName}, URL: $fileUrl");
      print("Extension: $extension, isPdf: $isPdf");
      
      // If we have a valid filename
      if (widget.message.fileName != null) {
        // Force a short delay for UI feedback
        await Future.delayed(const Duration(milliseconds: 100));
        
        try {
          // Attempt to download the file first to verify it exists and is accessible
          final response = await http.head(Uri.parse(fileUrl))
              .timeout(const Duration(seconds: 5));
              
          if (response.statusCode != 200) {
            throw Exception('Document not available (Status: ${response.statusCode})');
          }
          
          // Open the document viewer
          await Navigator.of(context).push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (context) => DocumentViewerPage(
                documentUrl: fileUrl,
                fileName: widget.message.fileName!,
              ),
            ),
          );
          return;
        } catch (e) {
          print("Error with document: $e");
          // Fall through to external app opening
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Trying alternative method to open document...'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
      
      // Try external app opening as fallback
      final Uri url = Uri.parse(fileUrl);
      bool launched = false;
      
      // First prepare a download to a temporary location (this often helps with problematic files)
      try {
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = "${timestamp}_${widget.message.fileName ?? 'document'}";
        final filePath = "${tempDir.path}/$fileName";
        final file = File(filePath);
        
        // Download the file
        final response = await http.get(Uri.parse(fileUrl));
        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes);
          
          // Try to open the local file
          final fileUri = Uri.file(filePath);
          if (await canLaunchUrl(fileUri)) {
            launched = await launchUrl(fileUri, mode: LaunchMode.externalApplication);
          }
        }
      } catch (e) {
        print("Error in temporary download: $e");
        // Continue to other methods if this fails
      }
      
      // If local file approach failed, try direct URL methods
      if (!launched) {
        try {
          if (await canLaunchUrl(url)) {
            launched = await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        } catch (e) {
          print("Error launching in external app: $e");
        }
      }
      
      // Try another launch mode if still not successful
      if (!launched) {
        try {
          launched = await launchUrl(url, mode: LaunchMode.externalNonBrowserApplication);
        } catch (e) {
          print("Error launching in non-browser mode: $e");
        }
      }
      
      // Last resort
      if (!launched) {
        try {
          launched = await launchUrl(url);
        } catch (e) {
          print("Error launching with default mode: $e");
        }
      }
      
      // If all attempts fail, show download option
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not open document. Try downloading it instead.'),
            action: SnackBarAction(
              label: 'DOWNLOAD',
              onPressed: () => _downloadFile(fileUrl, widget.message.fileName ?? 'document'),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print("Error in _openFile: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open document: ${e.toString().split(':').first}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
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