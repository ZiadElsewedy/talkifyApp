import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:talkifyapp/features/Chat/domain/entite/message.dart';
import 'package:talkifyapp/features/Chat/persentation/Cubits/chat_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/components/video_message_player.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/components/fullscreen_video_player.dart';
import 'package:talkifyapp/features/Communities/presentation/screens/components/community_audio_player.dart';

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
              CircleAvatar(
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
              const SizedBox(width: 8),
            ],
            
            // Message bubble
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                child: Column(
                  crossAxisAlignment: widget.isFromCurrentUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    // Sender name for group chats
                    if (!widget.isFromCurrentUser && widget.message.senderName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 4),
                        child: Text(
                          widget.message.senderName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    
                    // Message content
                    _buildMessageContent(context, textColor),
                    
                    // Timestamp 
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                      child: Text(
                        timeago.format(widget.message.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: widget.isFromCurrentUser
                              ? Colors.white.withOpacity(0.7)
                              : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                        ),
                      ),
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
              
            if (widget.message.type == MessageType.audio)
              ListTile(
                leading: Icon(Icons.headphones, color: textColor),
                title: Text('Listen to voice note', style: TextStyle(color: textColor)),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
              
            if (widget.isFromCurrentUser) 
              ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red),
                title: Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.of(context).pop();
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
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = widget.isFromCurrentUser
        ? (isDarkMode ? Colors.blue.shade800 : Colors.black)
        : (isDarkMode ? Colors.grey[800] : Colors.grey[300]);
    
    Widget content;
    
    switch (widget.message.type) {
      case MessageType.text:
        content = Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bubbleColor,
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
          child: Text(
            widget.message.content,
            style: TextStyle(
              fontSize: 16,
              color: textColor,
            ),
          ),
        );
        break;
        
      case MessageType.image:
        content = ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.message.fileUrl != null)
                GestureDetector(
                  onTap: () => _showFullScreenImage(context, widget.message.fileUrl!),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
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
              
              if (widget.message.content.isNotEmpty && widget.message.content != widget.message.fileName)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.message.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor,
                    ),
                  ),
                ),
            ],
          ),
        );
        break;
        
      case MessageType.video:
        content = VideoMessagePlayer(
          videoUrl: widget.message.fileUrl!,
          isCurrentUser: widget.isFromCurrentUser,
          caption: widget.message.content != widget.message.fileName ? widget.message.content : null,
          timestamp: widget.message.timestamp,
        );
        break;
        
      case MessageType.audio:
        content = CommunityAudioPlayer(
          message: widget.message,
          isFromCurrentUser: widget.isFromCurrentUser,
        );
        break;
        
      default:
        content = Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            widget.message.content,
            style: TextStyle(
              fontSize: 16,
              color: textColor,
            ),
          ),
        );
    }
    
    return content;
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
} 