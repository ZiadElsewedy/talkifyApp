import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:talkifyapp/features/Chat/domain/entite/message.dart';
import 'package:talkifyapp/features/Chat/domain/entite/chat_room.dart';
import 'package:talkifyapp/features/Chat/persentation/Cubits/chat_cubit.dart';
import 'package:talkifyapp/features/Chat/persentation/Cubits/chat_states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/user_profile_page.dart';
import 'package:talkifyapp/features/Chat/Utils/chat_styles.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/components/audio_message_player.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/document_viewer_page.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/components/video_message_player.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/components/fullscreen_video_player.dart';

class AnimatedMessageBubble extends StatefulWidget {
  final Message message;
  final bool isFromCurrentUser;
  final int index;

  const AnimatedMessageBubble({
    super.key,
    required this.message,
    required this.isFromCurrentUser,
    required this.index,
  });

  @override
  State<AnimatedMessageBubble> createState() => _AnimatedMessageBubbleState();
}

class _AnimatedMessageBubbleState extends State<AnimatedMessageBubble> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _longPressActive = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(widget.isFromCurrentUser ? 0.3 : -0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    // Add a small delay based on index for staggered animation
    Future.delayed(Duration(milliseconds: widget.index * 50), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          onLongPress: () {
            setState(() {
              _longPressActive = true;
            });
            _showMessageOptions(context);
          },
          onTap: () {
            if (_longPressActive) {
              setState(() {
                _longPressActive = false;
              });
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
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
                    child: Stack(
                      children: [
                        Hero(
                          tag: 'avatar_${widget.message.senderId}_${widget.message.id}',
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: widget.message.senderAvatar.isNotEmpty
                                ? CachedNetworkImageProvider(widget.message.senderAvatar)
                                : null,
                            child: widget.message.senderAvatar.isEmpty
                                ? Text(
                                    widget.message.senderName.isNotEmpty 
                                        ? widget.message.senderName[0].toUpperCase() 
                                        : 'U',
                                    style: const TextStyle(fontSize: 12, color: Colors.black),
                                  )
                                : null,
                          ),
                        ),
                      ],
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
                    decoration: ChatStyles.messageBubbleDecoration(
                      isFromCurrentUser: widget.isFromCurrentUser
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
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        
                        if (!widget.isFromCurrentUser && widget.message.senderName.isNotEmpty)
                          const SizedBox(height: 4),
                        
                        // Message content
                        _buildMessageContent(context),
                        
                        // Timestamp and status
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              timeago.format(widget.message.timestamp),
                              style: TextStyle(
                                fontSize: 10,
                                color: widget.isFromCurrentUser
                                    ? Colors.white.withOpacity(0.7)
                                    : Colors.grey[600],
                              ),
                            ),
                            
                            // Message status for current user
                            if (widget.isFromCurrentUser) ...[
                              const SizedBox(width: 4),
                              _buildStatusIcon(context),
                              // Removed read receipt avatar to avoid duplicate indicators
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
                                      : Colors.grey[600],
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
        ),
      ),
    );
  }

  void _openUserProfile(BuildContext context) {
    if (widget.isFromCurrentUser) return;
    
    // Add hero animation for smooth transition
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
          UserProfilePage(
            userId: widget.message.senderId,
            userName: widget.message.senderName,
            initialAvatarUrl: widget.message.senderAvatar,
            heroTag: 'avatar_${widget.message.senderId}_${widget.message.id}',
          ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 0.05);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          
          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve)
          );
          
          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Message options',
                  style: ChatStyles.titleStyle,
                ),
              ),
              
              const Divider(),
              
              if (widget.isFromCurrentUser)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: ChatStyles.errorColor),
                  title: const Text('Delete message'),
                  subtitle: const Text('Removes from database permanently'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _confirmDeleteMessage(context);
                  },
                ),
              
              if (widget.message.type == MessageType.image)
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('View image'),
                  onTap: () {
                    Navigator.of(context).pop();
                    if (widget.message.fileUrl != null) {
                      _showFullScreenImage(context, widget.message.fileUrl!);
                    }
                  },
                ),
                
              if (widget.message.type == MessageType.video)
                ListTile(
                  leading: const Icon(Icons.video_library_outlined),
                  title: const Text('Watch video'),
                  onTap: () {
                    Navigator.of(context).pop();
                    if (widget.message.fileUrl != null) {
                      _openFullscreenVideo(context, widget.message.fileUrl!, widget.message.fileName);
                    }
                  },
                ),
              
              if (widget.message.type == MessageType.document)
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Open document'),
                  onTap: () {
                    Navigator.of(context).pop();
                    if (widget.message.fileUrl != null) {
                      _openDocument(context, widget.message.fileUrl!, widget.message.fileName ?? 'Document');
                    }
                  },
                ),
              
              if (widget.message.type == MessageType.text)
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
        ),
      ),
    );
  }

  void _confirmDeleteMessage(BuildContext context) {
    // Store message ID locally to avoid widget reference issues
    final String messageId = widget.message.id;
    
    // Store a reference to the cubit to avoid context issues later
    final chatCubit = context.read<ChatCubit>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message', style: ChatStyles.titleStyle),
        content: const Text(
          'Are you sure you want to delete this message? It will be permanently removed for everyone and cannot be recovered.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              
              // Run a delete animation before actually removing the message
              _animationController.reverse().then((_) {
                // Use stored references instead of accessing widget or context
                chatCubit.deleteMessage(messageId);
              });
            },
            style: TextButton.styleFrom(foregroundColor: ChatStyles.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) => 
          _FullScreenImageViewer(imageUrl: imageUrl),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
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

  Widget _buildMessageContent(BuildContext context) {
    switch (widget.message.type) {
      case MessageType.text:
        return Text(
          widget.message.content,
          style: widget.isFromCurrentUser
              ? ChatStyles.messageSentTextStyle
              : ChatStyles.messageTextStyle,
        );
      
      case MessageType.image:
        return _buildImageMessage(context);
      
      case MessageType.video:
        return _buildVideoMessage(context);
      
      case MessageType.audio:
        return _buildAudioMessage(context);
      
      case MessageType.document:
        return _buildDocumentMessage(context);
        
      case MessageType.file:
        return _buildFileMessage(context);
      
      default:
        return Text(
          widget.message.content,
          style: widget.isFromCurrentUser
              ? ChatStyles.messageSentTextStyle
              : ChatStyles.messageTextStyle,
        );
    }
  }

  Widget _buildImageMessage(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.message.fileUrl != null)
          GestureDetector(
            onTap: () => _showFullScreenImage(context, widget.message.fileUrl!),
            child: Hero(
              tag: widget.message.id,
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
          ),
        
        if (widget.message.content.isNotEmpty && widget.message.content != widget.message.fileName)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              widget.message.content,
              style: widget.isFromCurrentUser
                  ? ChatStyles.messageSentTextStyle
                  : ChatStyles.messageTextStyle,
            ),
          ),
      ],
    );
  }

  Widget _buildVideoMessage(BuildContext context) {
    // Check if video URL is available
    if (widget.message.fileUrl != null) {
      return GestureDetector(
        onTap: () => _openFullscreenVideo(context, widget.message.fileUrl!, widget.message.fileName),
        child: VideoMessagePlayer(
          videoUrl: widget.message.fileUrl!,
          isCurrentUser: widget.isFromCurrentUser,
          caption: widget.message.content != widget.message.fileName ? widget.message.content : null,
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

  Widget _buildAudioMessage(BuildContext context) {
    return AudioMessagePlayer(
      message: widget.message,
      isCurrentUser: widget.isFromCurrentUser,
    );
  }

  Widget _buildFileMessage(BuildContext context) {
    // File message implementation (unchanged but styled)
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
            Icons.attach_file,
            color: widget.isFromCurrentUser ? Colors.white : Colors.black,
            size: 24,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.message.fileName ?? 'File',
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

  Widget _buildDocumentMessage(BuildContext context) {
    // Get document type from metadata
    final String documentType = widget.message.metadata?['documentType'] ?? 'generic';
    final String? fileExtension = widget.message.metadata?['fileExtension'] ?? '';
    
    // Choose icon based on document type
    IconData documentIcon;
    Color iconColor;
    
    switch (documentType) {
      case 'pdf':
        documentIcon = Icons.picture_as_pdf;
        iconColor = Colors.red;
        break;
      case 'word':
        documentIcon = Icons.description;
        iconColor = Colors.blue;
        break;
      case 'excel':
        documentIcon = Icons.table_chart;
        iconColor = Colors.green;
        break;
      case 'powerpoint':
        documentIcon = Icons.slideshow;
        iconColor = Colors.orange;
        break;
      case 'text':
        documentIcon = Icons.text_snippet;
        iconColor = Colors.grey;
        break;
      default:
        documentIcon = Icons.insert_drive_file;
        iconColor = Colors.grey;
    }
    
    return GestureDetector(
      onTap: () {
        if (widget.message.fileUrl != null) {
          _openDocument(context, widget.message.fileUrl!, widget.message.fileName ?? 'Document');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.isFromCurrentUser 
              ? Colors.black.withOpacity(0.2)
              : Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                documentIcon,
                color: iconColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.message.fileName ?? 'Document',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: widget.isFromCurrentUser
                          ? Colors.white
                          : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (fileExtension != null && fileExtension.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            fileExtension.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: iconColor,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.download,
                        size: 12,
                        color: widget.isFromCurrentUser
                            ? Colors.white.withOpacity(0.6)
                            : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tap to view or download',
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: widget.isFromCurrentUser
                              ? Colors.white.withOpacity(0.6)
                              : Colors.grey[600],
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
    );
  }

  void _openDocument(BuildContext context, String documentUrl, String fileName) {
    // Show a loading indicator
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
            Text('Opening document...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );
    
    // Launch document viewer
    _launchDocumentViewer(context, documentUrl, fileName);
  }
  
  void _launchDocumentViewer(BuildContext context, String documentUrl, String fileName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentViewerPage(documentUrl: documentUrl, fileName: fileName),
      ),
    );
  }

  Widget _buildStatusIcon(BuildContext context) {
    switch (widget.message.status) {
      case MessageStatus.sending:
        return Tooltip(
          message: 'Sending...',
          child: const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        );
      
      case MessageStatus.sent:
        return Tooltip(
          message: 'Sent',
          child: const Icon(
            Icons.check,  // Use single check for sent
            size: 12,
            color: Colors.white,
          ),
        );
      
      case MessageStatus.delivered:
        return Tooltip(
          message: 'Delivered',
          child: const Icon(
            Icons.done_all,
            size: 12,
            color: Colors.white,
          ),
        );
      
      case MessageStatus.read:
        // Show read receipt with avatar if available
        if (widget.message.readBy.isNotEmpty) {
          return _buildReadReceiptAvatar(context);
        } else {
          return Tooltip(
            message: 'Read',
            child: const Icon(
              Icons.done_all,
              size: 12,
              color: Colors.blue,
            ),
          );
        }
      
      case MessageStatus.failed:
        return Tooltip(
          message: 'Failed to send',
          child: const Icon(
            Icons.error_outline,
            size: 12,
            color: Colors.red,
          ),
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

  Widget _buildReadReceiptAvatar(BuildContext context) {
    final chatCubit = context.read<ChatCubit>();
    final chatRoom = chatCubit.getChatRoomById(widget.message.chatRoomId);
    
    if (chatRoom != null) {
      // Find the first reader who is not the sender
      final otherParticipantId = widget.message.readBy.firstWhere(
        (id) => id != widget.message.senderId,
        orElse: () => '',
      );
      
      if (otherParticipantId.isNotEmpty && chatRoom.participantAvatars.containsKey(otherParticipantId)) {
        final avatarUrl = chatRoom.participantAvatars[otherParticipantId] ?? '';
        
        return Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipOval(
            child: avatarUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: avatarUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.person, size: 10, color: Colors.grey),
                  ),
                )
              : Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.person, size: 10, color: Colors.grey),
                ),
          ),
        );
      }
    }
    
    // Fallback if we can't find the avatar
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue,
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: const Center(
        child: Icon(
          Icons.visibility,
          color: Colors.white,
          size: 10,
        ),
      ),
    );
  }
}

class _FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  
  const _FullScreenImageViewer({required this.imageUrl});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.download),
            ),
            onPressed: () {
              // Download functionality would go here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Download feature coming soon')),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Hero(
          tag: imageUrl,
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
    );
  }
} 