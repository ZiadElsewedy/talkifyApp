import 'package:flutter/material.dart';
import 'package:talkifyapp/features/Chat/domain/entite/message.dart';
import 'package:talkifyapp/features/Chat/domain/entite/chat_room.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/chat_room_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';

/// A service to show in-app toast notifications for chat messages
class ChatNotificationService {
  static OverlayEntry? _currentNotification;
  static bool _isVisible = false;
  static AudioPlayer? _audioPlayer;
  
  // Key prefix for storing muted chat rooms in SharedPreferences
  static const String _mutedChatPrefix = 'muted_chat_';
  
  /// Shows a chat notification if the chat is not muted
  static Future<void> showChatMessageNotification({
    required BuildContext context,
    required String senderName,
    required String messageText,
    required String senderId,
    required String chatRoomId,
    String? senderAvatar,
    String? chatRoomName,
    bool isGroupChat = false,
    ChatRoom? chatRoom,
    bool playSound = true,
  }) async {
    // Check if this chat is muted
    final isMuted = await isChatMuted(chatRoomId);
    if (isMuted) {
      print('Chat notification suppressed - chat is muted: $chatRoomId');
      return; // Don't show notification for muted chats
    }
    
    // Don't show notification if one is already visible
    if (_isVisible) {
      _currentNotification?.remove();
      _isVisible = false;
    }
    
    // Play notification sound if enabled
    if (playSound) {
      _playNotificationSound();
    }
    
    // Create the overlay entry
    final overlay = Overlay.of(context);
    final notification = OverlayEntry(
      builder: (context) => _ChatNotification(
        senderName: senderName,
        messageText: messageText,
        senderAvatar: senderAvatar,
        chatRoomName: chatRoomName,
        isGroupChat: isGroupChat,
        onTap: () {
          // Navigate to chat room
          if (chatRoom != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatRoomPage(
                  chatRoom: chatRoom,
                ),
              ),
            );
          }
          
          // Dismiss notification
          _currentNotification?.remove();
          _isVisible = false;
          _currentNotification = null;
        },
        onDismiss: () {
          _currentNotification?.remove();
          _isVisible = false;
          _currentNotification = null;
        },
      ),
    );
    
    _currentNotification = notification;
    _isVisible = true;
    
    // Show notification
    overlay.insert(notification);
    
    // Auto dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (_currentNotification == notification && _isVisible) {
        _currentNotification?.remove();
        _isVisible = false;
        _currentNotification = null;
      }
    });
  }
  
  /// Play notification sound
  static Future<void> _playNotificationSound() async {
    try {
      // Create a new player instance each time to avoid issues
      _audioPlayer?.dispose();
      _audioPlayer = AudioPlayer();
      
      // Using your existing notification sound file
      await _audioPlayer?.setAsset('lib/assets/notification.wav');
      await _audioPlayer?.play();
    } catch (e) {
      print('Error playing notification sound: $e');
    }
  }
  
  /// Check if a chat room is muted
  static Future<bool> isChatMuted(String chatRoomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('$_mutedChatPrefix$chatRoomId') ?? false;
    } catch (e) {
      print('Error checking if chat is muted: $e');
      return false;
    }
  }
  
  /// Mute notifications for a specific chat room
  static Future<void> muteChat(String chatRoomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_mutedChatPrefix$chatRoomId', true);
      print('Chat muted: $chatRoomId');
    } catch (e) {
      print('Error muting chat: $e');
    }
  }
  
  /// Unmute notifications for a specific chat room
  static Future<void> unmuteChat(String chatRoomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_mutedChatPrefix$chatRoomId', false);
      print('Chat unmuted: $chatRoomId');
    } catch (e) {
      print('Error unmuting chat: $e');
    }
  }
  
  /// Toggle mute status for a chat room
  static Future<bool> toggleMuteStatus(String chatRoomId) async {
    final isMuted = await isChatMuted(chatRoomId);
    if (isMuted) {
      await unmuteChat(chatRoomId);
      return false; // Now unmuted
    } else {
      await muteChat(chatRoomId);
      return true; // Now muted
    }
  }
  
  /// Get a list of all muted chat room IDs
  static Future<List<String>> getMutedChats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      return keys
          .where((key) => key.startsWith(_mutedChatPrefix) && prefs.getBool(key) == true)
          .map((key) => key.substring(_mutedChatPrefix.length))
          .toList();
    } catch (e) {
      print('Error getting muted chats: $e');
      return [];
    }
  }
}

/// The actual chat notification widget
class _ChatNotification extends StatefulWidget {
  final String senderName;
  final String messageText;
  final String? senderAvatar;
  final String? chatRoomName;
  final bool isGroupChat;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  
  const _ChatNotification({
    required this.senderName,
    required this.messageText,
    required this.onTap,
    required this.onDismiss,
    this.senderAvatar,
    this.chatRoomName,
    this.isGroupChat = false,
  });

  @override
  State<_ChatNotification> createState() => _ChatNotificationState();
}

class _ChatNotificationState extends State<_ChatNotification> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Set up animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    
    // Define animation (slide in from top)
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));
    
    // Add a subtle scale animation
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.95, end: 1.0),
        weight: 100.0,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    // Start animation
    _controller.forward();
    
    // Add listener for when user dismisses by swiping
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        widget.onDismiss();
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _offsetAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Material(
            color: Colors.transparent,
            child: SafeArea(
              child: GestureDetector(
                onTap: widget.onTap,
                onVerticalDragEnd: (details) {
                  if (details.velocity.pixelsPerSecond.dy < -100) {
                    // If swiped up with velocity, dismiss immediately
                    widget.onDismiss();
                  } else if (details.velocity.pixelsPerSecond.dy > 100) {
                    // If swiped down with velocity, animate out
                    _controller.reverse().then((_) => widget.onDismiss());
                  } else {
                    // If just a tap or small swipe, dismiss
                    widget.onDismiss();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar
                        if (widget.senderAvatar != null && widget.senderAvatar!.isNotEmpty)
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: CachedNetworkImageProvider(widget.senderAvatar!),
                            backgroundColor: Colors.grey.shade300,
                          )
                        else
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey.shade300,
                            child: Text(
                              widget.senderName.isNotEmpty ? widget.senderName[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        
                        const SizedBox(width: 12),
                        
                        // Content
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // New Message title
                              Text(
                                "New Message",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              
                              // Sender + message
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: widget.senderName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ": ${widget.messageText}",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Chat icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.black87,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 