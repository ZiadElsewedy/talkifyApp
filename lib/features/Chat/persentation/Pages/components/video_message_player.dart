import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:talkifyapp/features/Chat/Utils/chat_styles.dart';
import 'package:talkifyapp/features/Chat/persentation/Pages/components/fullscreen_video_player.dart';
import 'package:intl/intl.dart';

class VideoMessagePlayer extends StatefulWidget {
  final String videoUrl;
  final bool isCurrentUser;
  final String? caption;
  final DateTime timestamp;
  
  const VideoMessagePlayer({
    Key? key,
    required this.videoUrl,
    required this.isCurrentUser,
    this.caption,
    required this.timestamp,
  }) : super(key: key);

  @override
  State<VideoMessagePlayer> createState() => _VideoMessagePlayerState();
}

class _VideoMessagePlayerState extends State<VideoMessagePlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _showControls = false;
  Timer? _hideControlsTimer;
  double _playbackSpeed = 1.0;
  
  // Available playback speeds
  final List<double> _availableSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _initializeVideoController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeVideoController() async {
    _controller = VideoPlayerController.network(widget.videoUrl);
    try {
      await _controller.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing video: $e');
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    }
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
        _startHideControlsTimer();
      }
      _showControls = true;
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) {
        _startHideControlsTimer();
      }
    });
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller.value.isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _setPlaybackSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
      _controller.setPlaybackSpeed(speed);
    });
    _startHideControlsTimer();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
  
  void _openFullscreenVideo(BuildContext context) {
    // Pause the current player before opening fullscreen
    _controller.pause();
    
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => FullscreenVideoPlayer(
          videoUrl: widget.videoUrl,
          title: widget.caption,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    ).then((_) {
      // Resume playing the inline player when returning from fullscreen
      // if it was playing before
      if (mounted && _controller.value.isPlaying) {
        _controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isCurrentUser ? Colors.white : Colors.black87;
    final secondaryColor = widget.isCurrentUser ? Colors.white70 : Colors.black54;
    final bool isMessageRead = true; // This would come from the message data
    final String formattedTime = DateFormat('h:mm a').format(widget.timestamp);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 250, // Fixed width for chat bubbles
          height: 180, // Fixed height for videos in chat
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.black,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Video player
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _isInitialized
                    ? AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      )
                    : Container(
                        color: Colors.grey.shade800,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: Colors.white,
                              ),
                              SizedBox(height: 16),
                              Text(
                                "Loading video...",
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),

              // Gesture detector for controls
              Positioned.fill(
                child: GestureDetector(
                  onTap: _toggleControls,
                  behavior: HitTestBehavior.opaque,
                  child: Container(color: Colors.transparent),
                ),
              ),

              // Video controls overlay
              if (_showControls && _isInitialized)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Play/Pause button
                      IconButton(
                        icon: Icon(
                          _controller.value.isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          color: Colors.white,
                          size: 48,
                        ),
                        onPressed: _togglePlayPause,
                      ),
                      const SizedBox(height: 8),
                      
                      // Progress bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row( 
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,

                          children: [
                            Text(
                              _formatDuration(_controller.value.position),
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            Expanded(
                              child: Slider(
                                value: _controller.value.position.inMilliseconds.toDouble(),
                                min: 0.0,
                                max: _controller.value.duration.inMilliseconds.toDouble(),
                                onChanged: (value) {
                                  _controller.seekTo(Duration(milliseconds: value.toInt()));
                                },
                                activeColor: Colors.white,
                                inactiveColor: Colors.white38,
                                thumbColor: Colors.white,
                              ),
                            ),
                            Text(
                              _formatDuration(_controller.value.duration),
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),

                      // Fullscreen button instead of playback speed in chat view
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        
                      ),
                    ],
                  ),
                ),

              // Play button overlay when not playing
              if (!_showControls && _isInitialized && !_controller.value.isPlaying)
                GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
                
              // Fullscreen button
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _openFullscreenVideo(context),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.fullscreen,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Caption/text if provided
        if (widget.caption != null && widget.caption!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              widget.caption!,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
              ),
            ),
          ),
          
        // Message status indicator (only for current user's messages)
        // We'll only show time, no duplicate read indicators
        Padding(
          padding: const EdgeInsets.only(top: 4, right: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: widget.isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Text(
                formattedTime,
                style: TextStyle(
                  fontSize: 10,
                  color: secondaryColor.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 